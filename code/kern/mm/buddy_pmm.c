// 新建buddy文件-lzs
#include <buddy_pmm.h>
#include <list.h>
#include <stdio.h>

/* 最大单块包含 2^15 页，即 128 MiB。 */
#define BUDDY_MAX_ORDER 15

/* 用第二位标记已分配块的首页，帮助检查重复释放 */
#define BUDDY_ALLOCATED (1UL << 2)

/* 每一阶分别维护一条空闲块链表。 */
static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];

static size_t buddy_nr_free;
static size_t buddy_begin_ppn;
static size_t buddy_end_ppn;

static void
buddy_init(void) {
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_init(&buddy_free_lists[order]);
    }

    buddy_nr_free = 0;
    buddy_begin_ppn = buddy_end_ppn = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    /* 本实验的 page_init() 只注册一段连续空闲区 */
    assert(buddy_nr_free == 0);

    size_t ppn = page2ppn(base);
    assert(ppn >= nbase && ppn < npage);
    assert(n <= npage - ppn);

    buddy_begin_ppn = ppn;
    buddy_end_ppn = ppn + n;

    /* 将可用页从 reserved 状态转换为分配器管理状态 */
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;

        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        list_init(&p->page_link);
    }

    /*
     * 每次选择：
     * 1. 起点满足对应大小的对齐要求；
     * 2. 不超过剩余页面；
     * 的最大伙伴块
     */
    while (n > 0) {
        unsigned int order = 0;

        while (order < BUDDY_MAX_ORDER) {
            size_t larger = (size_t)1 << (order + 1);

            if ((ppn & (larger - 1)) != 0 || larger > n) {
                break;
            }

            order++;
        }

        size_t count = (size_t)1 << order;

        /* 只有空闲块首页设置 PG_property */
        base->property = order;
        SetPageProperty(base);

        list_add(&buddy_free_lists[order], &base->page_link);
        buddy_nr_free += count;

        base += count;
        ppn += count;
        n -= count;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);

    if (n > buddy_nr_free ||
        n > ((size_t)1 << BUDDY_MAX_ORDER)) {
        return NULL;
    }

    /* 向上取整：例如申请 3 页，对应 order=2，即 4 页 */
    unsigned int order = 0;
    while (((size_t)1 << order) < n) {
        order++;
    }

    /* 从目标阶开始，寻找第一个非空链表。 */
    unsigned int found = order;
    while (found <= BUDDY_MAX_ORDER &&
           list_empty(&buddy_free_lists[found])) {
        found++;
    }

    if (found > BUDDY_MAX_ORDER) {
        return NULL;
    }

    struct Page *p =
        le2page(list_next(&buddy_free_lists[found]), page_link);

    assert(PageProperty(p) && p->property == found);
    assert(!PageReserved(p));
    assert((p->flags & BUDDY_ALLOCATED) == 0);

    list_del(&p->page_link);
    ClearPageProperty(p);
    list_init(&p->page_link);

    /*
     * 大块逐级拆分：
     * 左半块继续拆分，右半块放回对应阶的空闲链表
     */
    while (found > order) {
        found--;

        struct Page *right = p + ((size_t)1 << found);
        right->property = found;
        SetPageProperty(right);
        list_add(&buddy_free_lists[found], &right->page_link);
    }

    p->property = order;
    p->flags |= BUDDY_ALLOCATED;

    /* 按实际块大小扣除空闲页数 */
    buddy_nr_free -= (size_t)1 << order;
    return p;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(base != NULL && n > 0);

    size_t ppn = page2ppn(base);
    assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
    assert(!PageReserved(base) && !PageProperty(base));
    assert((base->flags & BUDDY_ALLOCATED) != 0);

    unsigned int order = base->property;
    assert(order <= BUDDY_MAX_ORDER);

    size_t released = (size_t)1 << order;

    /* 检查传入的申请页数向上取整后是否匹配实际块大小 */
    assert(n <= released && (order == 0 || n > released / 2));
    assert((ppn & (released - 1)) == 0);
    assert(released <= buddy_end_ppn - ppn);
    assert(released <=
           buddy_end_ppn - buddy_begin_ppn - buddy_nr_free);

    base->flags &= ~BUDDY_ALLOCATED;
    base->property = 0;

    /* 归还的页数只增加一次，合并不改变总空闲页数 */
    buddy_nr_free += released;

    while (order < BUDDY_MAX_ORDER) {
        size_t count = (size_t)1 << order;

        /* 非常重要。翻转对应位，找到同阶伙伴的物理页号-lzs */
        size_t buddy_ppn = ppn ^ count;

        if (buddy_ppn < buddy_begin_ppn ||
            buddy_ppn >= buddy_end_ppn ||
            count > buddy_end_ppn - buddy_ppn) {
            break;
        }

        struct Page *buddy = pages + (buddy_ppn - nbase);

        /* 伙伴必须是空闲块首页，且阶数相同 */
        if (!PageProperty(buddy) || buddy->property != order) {
            break;
        }

        assert(!PageReserved(buddy));
        assert((buddy->flags & BUDDY_ALLOCATED) == 0);

        list_del(&buddy->page_link);
        ClearPageProperty(buddy);
        buddy->property = 0;

        /* 合并后的块以两个伙伴中较低的地址为起点 */
        if (buddy_ppn < ppn) {
            base = buddy;
            ppn = buddy_ppn;
        }

        order++;
    }

    base->property = order;
    SetPageProperty(base);
    list_add(&buddy_free_lists[order], &base->page_link);
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}

/* 本阶段只检查初始化得到的空闲块。 */
static void
buddy_init_check(void) {
    size_t total = 0;
    size_t blocks = 0;

    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_entry_t *head = &buddy_free_lists[order];

        for (list_entry_t *le = list_next(head); le != head;
             le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            size_t count = (size_t)1 << order;
            size_t ppn = page2ppn(p);

            assert(PageProperty(p) && p->property == order);
            assert((ppn & (count - 1)) == 0);
            assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
            assert(count <= buddy_end_ppn - ppn);

            assert(list_next(list_prev(le)) == le);
            assert(list_prev(list_next(le)) == le);

            for (size_t i = 0; i < count; i++) {
                assert(!PageReserved(p + i));
                assert(page_ref(p + i) == 0);

                if (i != 0) {
                    assert(!PageProperty(p + i));
                }
            }

            total += count;
            blocks++;
        }
    }

    assert(total == buddy_nr_free);
    assert(total == buddy_end_ppn - buddy_begin_ppn);

    cprintf("buddy init: %lu pages in %lu blocks\n",
            (unsigned long)total, (unsigned long)blocks);
    cprintf("buddy_init_check() succeeded!\n");
}

// 增加3个函数继续用于测试-lzs
static size_t
buddy_count_blocks(unsigned int order) {
    size_t count = 0;
    list_entry_t *head = &buddy_free_lists[order];

    for (list_entry_t *le = list_next(head);
         le != head; le = list_next(le)) {
        count++;
    }

    return count;
}

static void
buddy_alloc_free_check(void) {
    size_t before = nr_free_pages();
    assert(before >= 13);

    /* 保存各阶空闲块数量，用于检查释放后的合并结果 */
    size_t blocks_before[BUDDY_MAX_ORDER + 1];
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        blocks_before[i] = buddy_count_blocks(i);
    }

    struct Page *p = alloc_pages(1);
    struct Page *q = alloc_pages(3);
    struct Page *r = alloc_pages(8);

    assert(p != NULL && q != NULL && r != NULL);
    assert(p->property == 0 && q->property == 2 && r->property == 3);
    assert(!PageProperty(p) && !PageProperty(q) && !PageProperty(r));
    assert((p->flags & BUDDY_ALLOCATED) != 0);
    assert((q->flags & BUDDY_ALLOCATED) != 0);
    assert((r->flags & BUDDY_ALLOCATED) != 0);

    /* 实际占用 1 + 4 + 8 = 13 页。 */
    assert(nr_free_pages() == before - 13);

    /* 检查对齐，以及三个实际分配区间互不重叠 */
    size_t a = page2ppn(p);
    size_t b = page2ppn(q);
    size_t c = page2ppn(r);

    assert((b & 3) == 0 && (c & 7) == 0);
    assert(a + 1 <= b || b + 4 <= a);
    assert(a + 1 <= c || c + 8 <= a);
    assert(b + 4 <= c || c + 8 <= b);

    /* 乱序释放，逐次检查空闲页数 */
    free_pages(q, 3);
    assert(nr_free_pages() == before - 9);

    free_pages(p, 1);
    assert(nr_free_pages() == before - 8);

    free_pages(r, 8);
    assert(nr_free_pages() == before);

    /* 所有页面归还后，各阶块数量应恢复 */
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        assert(buddy_count_blocks(i) == blocks_before[i]);
    }

    /* 超过最大单块大小的请求应失败，并保持计数不变 */
    assert(alloc_pages(((size_t)1 << BUDDY_MAX_ORDER) + 1) == NULL);
    assert(nr_free_pages() == before);

    cprintf("buddy_alloc_free_check() succeeded!\n");
}

// 继续增加测试函数，分别是1全部分配，2制造碎片，3全部归还 -lzs
static void
buddy_exhaustion_check(void) {
    size_t before = nr_free_pages();
    assert(before >= 4);

    /* 保存各阶块数量，最后检查合并是否恢复原状态 */
    size_t blocks_before[BUDDY_MAX_ORDER + 1];
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        blocks_before[i] = buddy_count_blocks(i);
    }

    /*
     * held 是测试持有页面的链表
     * 已分配页面不在空闲链表中，因此可以借用 page_link 记录它
     */
    list_entry_t held;
    list_init(&held);

    size_t obtained = 0;
    struct Page *p;

    /* 第一阶段：逐页申请，直到内存耗尽 */
    while ((p = alloc_page()) != NULL) {
        assert(obtained < before);
        assert(!PageReserved(p) && !PageProperty(p));
        assert(p->property == 0);
        assert((p->flags & BUDDY_ALLOCATED) != 0);

        /*
         * 测试期间借用 ref 标记已经取到的页面
         * 再次返回同一页面时，此断言应当发现问题
         */
        assert(page_ref(p) == 0);
        set_page_ref(p, 1);

        list_add(&held, &p->page_link);
        obtained++;
    }

    assert(obtained == before);
    assert(nr_free_pages() == 0);
    assert(alloc_page() == NULL);

    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        assert(list_empty(&buddy_free_lists[i]));
    }

    /* 第二阶段：只释放物理页号为偶数的页面 */
    size_t released_even = 0;
    list_entry_t *le = list_next(&held);

    while (le != &held) {
        p = le2page(le, page_link);

        /* 必须提前保存下一个节点，再删除当前节点 */
        le = list_next(le);

        if ((page2ppn(p) & 1) == 0) {
            list_del(&p->page_link);
            set_page_ref(p, 0);
            free_page(p);
            released_even++;
        }
    }

    assert(released_even >= 2);
    assert(nr_free_pages() == released_even);

    /* 偶数页的伙伴是尚未释放的奇数页，因此只能存在单页块 */
    assert(buddy_count_blocks(0) == released_even);

    for (unsigned int i = 1; i <= BUDDY_MAX_ORDER; i++) {
        assert(list_empty(&buddy_free_lists[i]));
    }

    /* 总空闲页数足够，但没有连续 2 页 */
    assert(alloc_pages(2) == NULL);
    assert(nr_free_pages() == released_even);

    /* 第三阶段：归还 held 中剩余的奇数页 */
    while (!list_empty(&held)) {
        p = le2page(list_next(&held), page_link);

        list_del(&p->page_link);
        set_page_ref(p, 0);
        free_page(p);
    }

    assert(nr_free_pages() == before);

    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        assert(buddy_count_blocks(i) == blocks_before[i]);
    }

    cprintf("buddy_exhaustion_check() succeeded! (%lu pages)\n",
            (unsigned long)obtained);
}


static void
buddy_check(void) {
    buddy_init_check();
    buddy_alloc_free_check();
    buddy_exhaustion_check();
    buddy_init_check();

    cprintf("buddy_check() succeeded!\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};