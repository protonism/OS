// 添加slub测试文件 -lzs
#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <list.h>

static void
fill_bytes(void *ptr, size_t size, unsigned int tag) {
    unsigned char *p = ptr;
    for (size_t i = 0; i < size; i++) {
        p[i] = (unsigned char)(tag + i * 17);
    }
}

static void
check_bytes(const void *ptr, size_t size, unsigned int tag) {
    const unsigned char *p = ptr;
    for (size_t i = 0; i < size; i++) {
        assert(p[i] == (unsigned char)(tag + i * 17));
    }
}

static void
check_disjoint(void *a, size_t na, void *b, size_t nb) {
    uintptr_t x = (uintptr_t)a, y = (uintptr_t)b;
    assert(x + na <= y || y + nb <= x);
}

static void
slub_sizes_check(void) {
    static const size_t sizes[] = {
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65,
        127, 128, 129, 255, 256, 257, 511, 512, 513,
        1023, 1024, 1025, 2047, 2048, 2049,
        4095, 4096, 4097, 8192, 12345
    };
    enum { N = sizeof(sizes) / sizeof(sizes[0]) };
    static void *objects[N];
    size_t before = nr_free_pages();

    assert(kmalloc(0) == NULL);
    assert(kmalloc((size_t)-1) == NULL);
    assert(kmalloc((size_t)-1 - 128) == NULL);
    assert(kmalloc((npage - nbase) * PGSIZE) == NULL);
    kfree(NULL);
    assert(nr_free_pages() == before);

    for (unsigned int i = 0; i < N; i++) {
        objects[i] = kmalloc(sizes[i]);
        assert(objects[i] != NULL);
        assert((uintptr_t)objects[i] % SLUB_ALIGNMENT == 0);
        for (unsigned int j = 0; j < i; j++) {
            check_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
        }
        fill_bytes(objects[i], sizes[i], i + 1);
    }
    for (unsigned int i = 0; i < N; i++) {
        check_bytes(objects[i], sizes[i], i + 1);
    }

    /* Free odd positions first, then verify every surviving object. */
    for (unsigned int i = 1; i < N; i += 2) {
        kfree(objects[i]);
    }
    for (unsigned int i = 0; i < N; i += 2) {
        check_bytes(objects[i], sizes[i], i + 1);
        kfree(objects[i]);
    }
    assert(nr_free_pages() == before);
    cprintf("slub_sizes_check() succeeded!\n");
}

static void
slub_reuse_check(void) {
    /* Enough entries to fill a 64-byte slab and enter a second page. */
    static void *objects[PGSIZE / 64 + 1];
    size_t before = nr_free_pages();
    size_t count = 0;
    uintptr_t first_page = 0;

    do {
        assert(count < PGSIZE / 64 + 1);
        objects[count] = kmalloc(64);
        assert(objects[count] != NULL);
        for (size_t j = 0; j < count; j++) {
            check_disjoint(objects[count], 64, objects[j], 64);
        }
        fill_bytes(objects[count], 64, count + 1);
        if (count == 0) {
            first_page = ROUNDDOWN((uintptr_t)objects[0], PGSIZE);
        }
        count++;
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
             first_page);

    assert(count > 2);
    assert(nr_free_pages() == before - 2);
    void *old = objects[0];
    kfree(old);  /* full -> partial */
    objects[0] = kmalloc(64);
    assert(objects[0] == old);
    assert(nr_free_pages() == before - 2);
    fill_bytes(objects[0], 64, 1);

    check_bytes(objects[count - 1], 64, count);
    kfree(objects[count - 1]); /* The second slab now becomes empty. */
    assert(nr_free_pages() == before - 1);

    for (size_t i = 0; i < count - 1; i++) {
        check_bytes(objects[i], 64, i + 1);
        kfree(objects[i]);
        if (i + 1 < count - 1) {
            assert(nr_free_pages() == before - 1);
        }
    }
    assert(nr_free_pages() == before);
    cprintf("slub_reuse_check() succeeded!\n");
}

static void
slub_stress_check(void) {
    enum { SLOTS = 64, ROUNDS = 3000 };
    static void *ptrs[SLOTS];
    static size_t lengths[SLOTS];
    static unsigned int tags[SLOTS];
    static const size_t sizes[] = {
        1, 16, 17, 64, 129, 512, 1025, 2048, 2049, 4096, 8192
    };
    uint32_t state = 0x12345678U;
    size_t before = nr_free_pages();

    for (unsigned int i = 0; i < SLOTS; i++) {
        ptrs[i] = NULL;
    }
    for (unsigned int round = 0; round < ROUNDS; round++) {
        state = state * 1664525U + 1013904223U;
        /* Higher bits avoid the short period of the LCG's lowest bits. */
        unsigned int slot = (state >> 16) % SLOTS;
        if (ptrs[slot] != NULL) {
            check_bytes(ptrs[slot], lengths[slot], tags[slot]);
            kfree(ptrs[slot]);
            ptrs[slot] = NULL;
        } else {
            size_t n = sizes[(state >> 8) %
                             (sizeof(sizes) / sizeof(sizes[0]))];
            ptrs[slot] = kmalloc(n);
            assert(ptrs[slot] != NULL);
            assert((uintptr_t)ptrs[slot] % SLUB_ALIGNMENT == 0);
            lengths[slot] = n;
            tags[slot] = round + 7;
            for (unsigned int j = 0; j < SLOTS; j++) {
                if (j != slot && ptrs[j] != NULL) {
                    check_disjoint(ptrs[slot], n, ptrs[j], lengths[j]);
                }
            }
            fill_bytes(ptrs[slot], n, tags[slot]);
        }
        if (round % 37 == 0) {
            for (unsigned int j = 0; j < SLOTS; j++) {
                if (ptrs[j] != NULL) {
                    check_bytes(ptrs[j], lengths[j], tags[j]);
                }
            }
        }
    }
    for (unsigned int i = 0; i < SLOTS; i++) {
        if (ptrs[i] != NULL) {
            check_bytes(ptrs[i], lengths[i], tags[i]);
            kfree(ptrs[i]);
            ptrs[i] = NULL;
        }
    }
    assert(nr_free_pages() == before);
    cprintf("slub_stress_check() succeeded!\n");
}

static void
slub_exhaustion_check(void) {
    size_t before = nr_free_pages();
    assert(before > 8);
    void *x = kmalloc(64);
    assert(x != NULL);
    fill_bytes(x, 64, 0x31);

    /* Hold every remaining page without needing a large pointer array. */
    list_entry_t held;
    list_init(&held);
    struct Page *p;
    size_t count = 0;
    while ((p = alloc_page()) != NULL) {
        assert(count < before - 1);
        list_add(&held, &p->page_link);
        count++;
    }
    assert(count == before - 1);
    assert(nr_free_pages() == 0);

    /* Existing slabs still work, but requests needing new pages fail. */
    void *y = kmalloc(64);
    assert(y != NULL);
    check_disjoint(x, 64, y, 64);
    fill_bytes(y, 64, 0x92);
    assert(kmalloc(2048) == NULL);
    assert(kmalloc(4096) == NULL);
    assert(nr_free_pages() == 0);
    check_bytes(x, 64, 0x31);
    check_bytes(y, 64, 0x92);

    kfree(y);
    kfree(x);
    assert(nr_free_pages() == 1);
    assert(kmalloc(4096) == NULL); /* Header means two pages are needed. */
    assert(nr_free_pages() == 1);

    while (!list_empty(&held)) {
        p = le2page(list_next(&held), page_link);
        list_del(&p->page_link);
        free_page(p);
    }
    assert(nr_free_pages() == before);

    x = kmalloc(4096);
    assert(x != NULL);
    fill_bytes(x, 4096, 0x53);
    check_bytes(x, 4096, 0x53);
    kfree(x);
    assert(nr_free_pages() == before);
    cprintf("slub_exhaustion_check() succeeded!\n");
}

void
slub_check(void) {
    size_t before = nr_free_pages();
    slub_sizes_check();
    slub_reuse_check();
    slub_stress_check();
    slub_exhaustion_check();
    assert(nr_free_pages() == before);
    cprintf("slub_check() succeeded!\n");
}