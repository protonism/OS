#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 YOUR CODE
static void page_init(void) {
    extern char end[];  // tools/kernel.ld 在 .bss 末尾提供

    // 虚实映射偏移必须先设置，后面的 PADDR 依赖它
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    // 从设备树取得物理内存范围
    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    if (mem_base == 0 || mem_size == 0) {
        panic("page_init: invalid DTB memory info");
    }
    if (mem_base < DRAM_BASE) {
        panic("page_init: memory base below DRAM_BASE");
    }
    if (mem_size > (uint64_t)-1 - mem_base) {  // 防止 base + size 溢出
        panic("page_init: physical memory range overflows");
    }
    uint64_t mem_end = mem_base + mem_size;

    // npage 是内存末尾的绝对页号（不是页数）
    npage = PPN(mem_end);
    if (npage <= nbase) {
        panic("page_init: npage <= nbase");
    }

    // 描述符数组紧接内核 end 之后，按页对齐
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    // 注意：这里必须用 PADDR(pages) 定位数组物理地址；
    // page2pa(pages) 返回的是 DRAM_BASE，它是 pages[0] 所描述的物理页。
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
    uintptr_t page_array_end =
        page_array_pa + sizeof(struct Page) * (npage - nbase);
    if (page_array_end > mem_end) {
        panic("page_init: Page array exceeds physical memory");
    }

    // 先把全部描述符标记为 reserved。数组位于 .bss 之外，
    // kern_init() 的 memset(edata, end - edata) 不会清零它，必须显式初始化。
    for (size_t i = 0; i < npage - nbase; i++) {
        pages[i].flags = 0;
        pages[i].property = 0;
        set_page_ref(&pages[i], 0);
        SetPageReserved(&pages[i]);
    }

    // 首个完整空闲页：跳过描述符数组，按页向上取整
    uintptr_t freemem = ROUNDUP(page_array_end, PGSIZE);

    // 与 DTB 给出的内存起始地址求交（QEMU 下 mem_base == DRAM_BASE）
    if (freemem < mem_base) {
        freemem = ROUNDUP(mem_base, PGSIZE);
    }

    cprintf("page_init: memory [0x%016lx, 0x%016lx), free start 0x%016lx, "
            "npage=%lu\n",
            (unsigned long)mem_base, (unsigned long)mem_end,
            (unsigned long)freemem, (unsigned long)npage);

    // 只有存在完整空闲页时才注册；否则终止初始化
    if (PPN(freemem) >= npage) {
        panic("page_init: no complete free page left");
    }
    init_memmap(pa2page(freemem), npage - PPN(freemem));
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
