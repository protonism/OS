// 添加slub文件 -lzs
#include <slub.h>
#include <pmm.h>
#include <list.h>
#include <string.h>

#define SLUB_MAGIC 0x534C5542534C5542ULL
#define CACHE_COUNT 8
#define BITMAP_WORDS 4

struct kmem_cache {
    size_t size;
    list_entry_t partial;
};

/* Metadata lives at the start of the first backing page. */
struct slab {
    uint64_t magic;
    struct kmem_cache *cache;   /* NULL means a large allocation */
    struct Page *page;
    size_t npages;             /* original argument to alloc_pages */
    unsigned int capacity;
    unsigned int inuse;
    void *freelist;
    list_entry_t link;
    uint64_t used[BITMAP_WORDS];
};

static struct kmem_cache caches[CACHE_COUNT];
static const size_t cache_sizes[CACHE_COUNT] = {
    16, 32, 64, 128, 256, 512, 1024, 2048
};
static bool slub_ready;

static size_t
object_offset(void) {
    return ROUNDUP(sizeof(struct slab), SLUB_ALIGNMENT);
}

/* KADDR is commented out in this lab; use its direct-map offset. */
static void *
slub_page_address(struct Page *page) {
    return (void *)(page2pa(page) + va_pa_offset);
}

void
slub_init(void) {
    assert(!slub_ready);
    assert(object_offset() + SLUB_SMALL_MAX <= PGSIZE);
    assert((PGSIZE - object_offset()) / cache_sizes[0] <=
           BITMAP_WORDS * 64);

    for (unsigned int i = 0; i < CACHE_COUNT; i++) {
        caches[i].size = cache_sizes[i];
        list_init(&caches[i].partial);
    }
    slub_ready = 1;
}

static struct slab *
new_slab(struct kmem_cache *cache) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }

    struct slab *s = slub_page_address(page);
    memset(s, 0, sizeof(*s));
    s->magic = SLUB_MAGIC;
    s->cache = cache;
    s->page = page;
    s->npages = 1;
    s->capacity = (PGSIZE - object_offset()) / cache->size;
    list_init(&s->link);

    /* A free object's first word holds the next free object's address. */
    for (size_t i = s->capacity; i > 0; i--) {
        void *obj = (char *)s + object_offset() + (i - 1) * cache->size;
        *(void **)obj = s->freelist;
        s->freelist = obj;
    }
    list_add(&cache->partial, &s->link);
    return s;
}

void *
kmalloc(size_t size) {
    assert(slub_ready);
    if (size == 0) {
        return NULL;
    }

    if (size > SLUB_SMALL_MAX) {
        size_t offset = object_offset();
        if (size > (size_t)-1 - offset) {
            return NULL;
        }

        size_t bytes = size + offset;
        /* Avoid overflow from ROUNDUP(bytes, PGSIZE). */
        size_t n = bytes / PGSIZE + (bytes % PGSIZE != 0);
        if (n > npage - nbase) {
            return NULL;
        }

        struct Page *page = alloc_pages(n);
        if (page == NULL) {
            return NULL;
        }

        struct slab *s = slub_page_address(page);
        memset(s, 0, sizeof(*s));
        s->magic = SLUB_MAGIC;
        s->page = page;
        s->npages = n;
        s->inuse = 1;
        return (char *)s + offset;
    }

    struct kmem_cache *cache = &caches[0];
    while (cache->size < size) {
        cache++;
    }

    struct slab *s;
    if (list_empty(&cache->partial)) {
        s = new_slab(cache);
        if (s == NULL) {
            return NULL;
        }
    } else {
        s = to_struct(list_next(&cache->partial), struct slab, link);
    }

    void *obj = s->freelist;
    assert(obj != NULL);
    size_t index = ((uintptr_t)obj - (uintptr_t)s - object_offset()) /
                   cache->size;
    assert(index < s->capacity);
    uint64_t mask = 1ULL << (index % 64);
    assert((s->used[index / 64] & mask) == 0);

    s->freelist = *(void **)obj;
    s->used[index / 64] |= mask;
    s->inuse++;
    if (s->inuse == s->capacity) {
        list_del_init(&s->link);  /* Full slabs leave the partial list. */
    }
    return obj;
}

void
kfree(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    assert(slub_ready);
    assert((uintptr_t)ptr >= KERNBASE);
    uintptr_t pa = (uintptr_t)ptr - va_pa_offset;
    assert(PPN(pa) >= nbase && PPN(pa) < npage);

    struct slab *s = (struct slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    assert(s->magic == SLUB_MAGIC);
    assert(s->inuse > 0);

    if (s->cache == NULL) {
        assert(ptr == (void *)((char *)s + object_offset()));
        struct Page *page = s->page;
        size_t n = s->npages;
        s->magic = 0;
        /* Buddy expects the original request and releases its whole block. */
        free_pages(page, n);
        return;
    }

    struct kmem_cache *cache = s->cache;
    uintptr_t first = (uintptr_t)s + object_offset();
    assert((uintptr_t)ptr >= first);
    size_t delta = (uintptr_t)ptr - first;
    assert(delta % cache->size == 0);
    size_t index = delta / cache->size;
    assert(index < s->capacity);
    uint64_t mask = 1ULL << (index % 64);
    assert((s->used[index / 64] & mask) != 0);

    if (s->inuse == s->capacity) {
        list_add(&cache->partial, &s->link);
    }
    s->used[index / 64] &= ~mask;
    *(void **)ptr = s->freelist;
    s->freelist = ptr;
    s->inuse--;

    if (s->inuse == 0) {
        struct Page *page = s->page;
        list_del_init(&s->link);
        s->magic = 0;
        free_page(page);
    }
}