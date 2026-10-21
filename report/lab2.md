# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 2: 物理内存和页表 |
| **小组成员** | 2413073-唐涵城、2413576-林泽森、2413523-尤祺乐 |
| **完成日期** | 2026-10-23 |

### 小组分工

| 成员 | 负责的模块 |
|------|----------------|
| 2413073-唐涵城 | 物理内存初始化、First-Fit 分析、Best-Fit 实现与接入、启动环境适配、物理内存范围获取 Challenge 思考题 |
| 2413576-林泽森 | Buddy System 设计、实现、接入与独立测试；Best-Fit 尾插修复与回归；官方评分复验 | 
| 2413523-尤祺乐 | QEMU 与内核双 GDB 调试、页表查询和 TLB 分析；协助最终报告整合 | 

---

## 一、实验目的

1. 理解 Sv39 启动页表，以及虚拟地址、物理地址、物理页号和页描述符之间的关系。
2. 掌握从设备树获取物理内存范围、建立 Page 数组、保留内核占用空间和注册空闲页的流程。
3. 理解 First-Fit 与 Best-Fit 的连续页分配、空闲块切分和回收合并。
4. 实现 Buddy System，掌握按阶管理、请求取整、伙伴定位、逐级拆分与递归合并。
5. 分别设计实现提示词和测试提示词，通过实际编译、QEMU 运行及边界检查验证生成代码。
6. 完成 QEMU 分支任务，观察模拟器中的地址翻译与 TLB 过程；本项实际记录由尤祺乐补充。

---

## 二、实验环境

### 2.1 软件与代码环境

| 项目 | 内容 |
|------|------|
| 架构 | RISC-V 64（Sv39） |
| 模拟器 | QEMU 7.0.0，/opt/qemu/bin/qemu-system-riscv64 |
| 固件 | OpenSBI v1.0（QEMU -bios default） |
| 交叉编译器 | riscv64-unknown-elf-gcc 15.1.0 |
| 编译选项 | -std=gnu99 -Wall -Werror -O2，并保留 -g 调试信息 |


### 2.2 实验环境适配

**负责人：** 2413073-唐涵城。


**（1）`-device loader` 不会设置内核入口。**
原 `Makefile` 的 `qemu`/`debug`/`test` 目标以及 `tools/grade.sh` 使用：

```sh
-device loader,file=bin/ucore.img,addr=0x80200000
```

该选项只把镜像写入内存，不会填写 OpenSBI 的 `fw_dynamic_info`。新版 OpenSBI 读到的下一阶段入口为 `0`，于是跳转到 `0x0`，内核不会执行。解决办法是改用：

```sh
-kernel bin/ucore.img
```

因此本实验把 `Makefile` 中三处 `-device loader,...` 改成了 `-kernel $(UCOREIMG)`；`tools/grade.sh` 未修改，评分时通过外部 QEMU wrapper 把 `-device loader` 重写为 `-kernel`（见第五部分）。

**（2）启动页表缺少低地址恒等映射。**
`kern/init/entry.S` 写入 `satp` 后，QEMU 7.0 会立即按 Sv39 翻译后续取指。此时 PC 仍是物理地址 `0x802000xx`，而原启动页表只映射了高虚拟地址 `0xffffffffc0000000`，导致紧接着的 `sfence.vma` 触发指令页错误并无限重启。

修复方式是在启动页表中增加一项恒等映射：虚拟地址 `0x80000000–0xbfffffff` 映射到物理地址 `0x80000000–0xbfffffff`。由于 `0x80200000` 作为虚拟地址时 VPN2 = 2，叶子页表项放在根页表索引 2：

```asm
boot_page_table_sv39:
    .zero 8 * 2
    .quad (0x80000 << 10) | 0xcf   # 恒等映射 0x80000000-0xbfffffff
    .zero 8 * 508
    .quad (0x80000 << 10) | 0xcf   # 0xffffffffc0000000 -> 0x80000000
```

该修改只影响启动阶段的地址映射，不改变物理内存管理的逻辑。

---

## 三、实验整体逻辑分析

### 3.1 本章节的逻辑主线

本实验围绕物理内存的发现、初始化和分配展开，整体实现链路为：

```text
pmm_init()
  -> init_pmm_manager()      选择并初始化物理内存管理器
  -> page_init()             从 DTB 探测物理内存，建立 Page 描述符
       -> init_memmap()      把空闲页面交给 pmm_manager
  -> check_alloc_page()      pmm_manager->check() 验证分配/释放
```

运行时页面分配/回收：

```text
alloc_pages(n) -> pmm_manager->alloc_pages(n)
free_pages(base, n) -> pmm_manager->free_pages(base, n)
```

唐涵城阶段完成的内容：

1. 实现 `kern/mm/pmm.c` 中的 `page_init()`：物理内存探测、`Page` 描述符初始化、保留区处理、空闲区注册。
2. 理解 First-Fit：`default_pmm.c` 中 `default_init`、`default_init_memmap`、`default_alloc_pages`、`default_free_pages`。
3. 在 `kern/mm/best_fit_pmm.c` 中实现完整 Best-Fit 分配器并注册 `best_fit_pmm_manager`。
4. 在 `init_pmm_manager()` 中把当前管理器切换为 Best-Fit。

在此基础上，林泽森补充 Buddy System，并保留默认 Best-Fit 配置。两种分配器共享 page_init() 提供的可用页区间，通过同一 pmm_manager 接口提供服务。

### 3.2 功能的逐步实现

1. **启动与映射适配。** 保证 OpenSBI 能进入内核，开启 Sv39 后继续取指并跳转到高地址内核。
2. **物理内存初始化。** 从 DTB 获取范围，建立 Page 数组，排除 OpenSBI、内核及描述符数组占用。
3. **First-Fit 分析与 Best-Fit 实现。** 理解参考算法，再完成最小满足块选择、切分、释放合并和管理器注册。
4. **接入 Buddy System。** 将空闲区按物理页号对齐划分为 2 的幂次块，提供另一种分配与合并方式。
5. **独立测试和回归。** Buddy 运行自设计检查；Best-Fit 运行原检查、尾插回归和官方评分。
6. **QEMU 分支调试。** 尤祺乐在可运行内核上完成两个 GDB 的联合观察，该任务不依赖 Buddy 的完成情况。

---

## 四、实验内容与实现

### 4.1 功能模块一：物理内存初始化

**负责人：** 2413073-唐涵城。

#### 模块功能描述

**需要实现/修改的函数：**

```c
static void page_init(void);
```

page_init() 由 pmm_init() 调用，将设备树内存信息转换为 Page 描述符布局和初始完整空闲页区间。以下分析、代码和最终提示词主要保留唐涵城原稿。

#### 物理内存探测流程

1. QEMU 启动后先运行 OpenSBI，把设备树（DTB）的物理地址放在 `a1` 寄存器中传入内核。
2. `kern/init/entry.S` 把 `a0`（HartID）和 `a1`（DTB 物理地址）分别保存到 `boot_hartid`、`boot_dtb`。
3. `kern_init()` 调用 `dtb_init()`。`dtb_init()` 把 DTB 物理地址加上 `PHYSICAL_MEMORY_OFFSET` 得到虚拟地址，校验魔数 `0xd00dfeed`，遍历 FDT 结构，找到名字以 `memory` 开头的节点，读取其 `reg` 属性（两个大端 64 位单元：base 和 size）。
4. 解析结果保存到静态变量，通过 `get_memory_base()` / `get_memory_size()` 提供给 PMM。

QEMU 默认配置下的输出：

```text
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
```

即物理内存范围为 `[0x80000000, 0x88000000)`。

#### page_init() 的设计与实现

`page_init()` 位于 `kern/mm/pmm.c`，由 `pmm_init()` 在 `init_pmm_manager()` 之后调用。核心步骤如下。

##### （1）设置虚实映射偏移

```c
va_pa_offset = PHYSICAL_MEMORY_OFFSET;
```

`PADDR(kva) = kva - va_pa_offset`。后面的 `PADDR` 依赖该全局变量，因此必须最先设置。内核链接在虚拟地址 `KERNBASE = 0xFFFFFFFFC0200000`，实际加载在物理地址 `0x80200000`，偏移量为 `0xFFFFFFFF40000000`。

##### （2）校验 DTB 信息

```c
uint64_t mem_base = get_memory_base();
uint64_t mem_size = get_memory_size();
if (mem_base == 0 || mem_size == 0) {
    panic("page_init: invalid DTB memory info");
}
if (mem_base < DRAM_BASE) {
    panic("page_init: memory base below DRAM_BASE");
}
if (mem_size > (uint64_t)-1 - mem_base) {
    panic("page_init: physical memory range overflows");
}
uint64_t mem_end = mem_base + mem_size;
```

设备树信息无效（base/size 为 0、base 低于 DRAM 起始地址、base+size 溢出）时直接 `panic`，终止初始化。

##### （3）计算 `npage`

```c
npage = PPN(mem_end);   // PPN(x) = x >> PGSHIFT
```

`npage` 表示物理内存末尾的**绝对页号**，不是页数。QEMU 默认配置下：

```text
mem_end = 0x88000000
npage   = 0x88000 = 557056
nbase   = DRAM_BASE / PGSIZE = 0x80000 = 524288
```

`pages[]` 只描述 `[DRAM_BASE, mem_end)` 之间的页面，索引关系为：

```c
pages[PPN(pa) - nbase]
```

因此描述符数组只需要 `npage - nbase = 0x8000 = 32768` 项。

##### （4）确定描述符数组位置

```c
extern char end[];
pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
```

`end` 是链接脚本 `tools/kernel.ld` 在 `.bss` 末尾提供的符号。描述符数组紧接内核镜像之后，并按 4 KiB 对齐。

注意：描述符数组位于 `.bss` 之外，`kern_init()` 中的 `memset(edata, 0, end - edata)` 不会清零它，因此必须显式初始化每个描述符。

`sizeof(struct Page) = 40` 字节，32768 个描述符共 `0x140000` 字节（320 页）。QEMU 下：

```text
pages 物理地址 = 0x80207000
描述符数组结束 = 0x80207000 + 0x140000 = 0x80347000
```

##### （5）保留所有描述符对应的页面

```c
uintptr_t page_array_pa = PADDR((uintptr_t)pages);
uintptr_t page_array_end =
    page_array_pa + sizeof(struct Page) * (npage - nbase);
if (page_array_end > mem_end) {
    panic("page_init: Page array exceeds physical memory");
}

for (size_t i = 0; i < npage - nbase; i++) {
    pages[i].flags = 0;
    pages[i].property = 0;
    set_page_ref(&pages[i], 0);
    SetPageReserved(&pages[i]);
}
```

这里先把 `[nbase, npage)` 对应的**全部**描述符标记为 reserved，原因有三点：

- `init_memmap()` 内部会断言交给它的每个空闲页都满足 `PageReserved(p)`；
- 内核 `end` 所在页的物理地址小于描述符数组，必须保持 reserved；
- 描述符数组自身占用的页面也必须保持 reserved。

随后 `init_memmap()` 会把它管理的空闲区页面的 flags/property/ref 清零并建立空闲块。

> 常见陷阱：定位描述符数组必须使用 `PADDR((uintptr_t)pages)`。`page2pa(pages)` 返回的是 `DRAM_BASE`，因为 `pages[0]` 描述的是物理页 `nbase`，而不是数组本身。

##### （6）计算首个空闲页并注册

```c
uintptr_t freemem = ROUNDUP(page_array_end, PGSIZE);
if (freemem < mem_base) {
    freemem = ROUNDUP(mem_base, PGSIZE);
}

if (PPN(freemem) >= npage) {
    panic("page_init: no complete free page left");
}
init_memmap(pa2page(freemem), npage - PPN(freemem));
```

- `freemem` 跳过内核镜像、描述符数组，并向上取整到页边界。
- `npage - PPN(freemem)` 只统计完整页面；如果 `PPN(freemem) >= npage`，说明没有完整空闲页，此时不得调用 `init_memmap()`，直接终止。
- OpenSBI（`0x80000000–0x80200000`）、内核镜像、描述符数组都位于 `freemem` 之前，不会进入空闲链表。

最终注册的空闲区为 `[0x80347000, 0x88000000)`，共 `31929` 个页面。

#### page_init() 完整代码

```c
static void page_init(void) {
    extern char end[];

    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    if (mem_base == 0 || mem_size == 0) {
        panic("page_init: invalid DTB memory info");
    }
    if (mem_base < DRAM_BASE) {
        panic("page_init: memory base below DRAM_BASE");
    }
    if (mem_size > (uint64_t)-1 - mem_base) {
        panic("page_init: physical memory range overflows");
    }
    uint64_t mem_end = mem_base + mem_size;

    npage = PPN(mem_end);
    if (npage <= nbase) {
        panic("page_init: npage <= nbase");
    }

    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
    uintptr_t page_array_end =
        page_array_pa + sizeof(struct Page) * (npage - nbase);
    if (page_array_end > mem_end) {
        panic("page_init: Page array exceeds physical memory");
    }

    for (size_t i = 0; i < npage - nbase; i++) {
        pages[i].flags = 0;
        pages[i].property = 0;
        set_page_ref(&pages[i], 0);
        SetPageReserved(&pages[i]);
    }

    uintptr_t freemem = ROUNDUP(page_array_end, PGSIZE);
    if (freemem < mem_base) {
        freemem = ROUNDUP(mem_base, PGSIZE);
    }

    cprintf("page_init: memory [0x%016lx, 0x%016lx), free start 0x%016lx, "
            "npage=%lu\n",
            (unsigned long)mem_base, (unsigned long)mem_end,
            (unsigned long)freemem, (unsigned long)npage);

    if (PPN(freemem) >= npage) {
        panic("page_init: no complete free page left");
    }
    init_memmap(pa2page(freemem), npage - PPN(freemem));
}
```

#### 最终提示词（page_init，保留唐涵城原稿）

```text
请阅读以下文件：
- kern/mm/pmm.c / pmm.h / memlayout.h / mmu.h
- kern/driver/dtb.c / dtb.h
- kern/init/entry.S / init.c
- tools/kernel.ld
- tools/test_lab2.c（测试约定，不能修改）

在 kern/mm/pmm.c 的 //lab2 function1 YOUR CODE 处实现 static void page_init(void)，
要求：
1. 设置 va_pa_offset = PHYSICAL_MEMORY_OFFSET；
2. 用 get_memory_base()/get_memory_size() 获取物理内存范围，信息无效时 panic；
3. npage 必须等于 PPN(mem_base + mem_size)，nbase = DRAM_BASE/PGSIZE；
4. pages 放在 ROUNDUP(end, PGSIZE)，并正确处理“虚拟地址/物理地址/页号/描述符地址”的转换；
5. 将 [nbase, npage) 的全部 Page 描述符显式初始化并标记 reserved；
6. 首个空闲页要跳过内核镜像和描述符数组，按页对齐；
7. 只有存在完整空闲页时才调用 init_memmap()，否则终止初始化；
8. 代码必须能通过 -std=gnu99 -Wall -Werror 编译，并满足 tools/test_lab2.c 中
   test_page_init() 的全部检查。
请解释每个地址变量的含义，并指出 page2pa(pages) 与 PADDR(pages) 的区别。
```


### 4.2 练习：理解 First-Fit 连续物理内存分配算法

**负责人：** 2413073-唐涵城。


First-Fit 的实现位于 `kern/mm/default_pmm.c`，使用一个按页地址升序排列的空闲块链表和总空闲页数 `nr_free`：

```c
static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
```

#### （1）`default_init()`：初始化空闲链表

```c
static void default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
```

把链表头初始化为空（`prev = next = self`），空闲页计数清零。

#### （2）`default_init_memmap(base, n)`：建立初始空闲块

```c
for (p = base; p != base + n; p++) {
    assert(PageReserved(p));
    p->flags = p->property = 0;
    set_page_ref(p, 0);
}
base->property = n;
SetPageProperty(base);
nr_free += n;
/* 按地址升序插入 free_list */
```

- 对空闲区每一页，断言它此前是 reserved（来自 `page_init()` 的保留），然后清零标志、属性和引用计数。
- 整个连续区间作为**一个**空闲块，只有块首页（`base`）设置 `PG_property`，`property = n` 表示块长。
- 按页地址升序插入链表，`nr_free` 增加 `n`。

#### （3）`default_alloc_pages(n)`：分配连续页

```c
if (n > nr_free) return NULL;
/* 从链表头开始，找到第一个 property >= n 的块 */
page = ...;
if (page != NULL) {
    prev = list_prev(&page->page_link);
    list_del(&page->page_link);
    if (page->property > n) {
        struct Page *p = page + n;
        p->property = page->property - n;
        SetPageProperty(p);
        list_add(prev, &p->page_link);   // 剩余块插回原位置
    }
    nr_free -= n;
    ClearPageProperty(page);
}
return page;
```

- First-Fit 从链表头开始扫描，返回**第一个**足够大的空闲块。
- 如果块大于请求，切分出后半部分作为新的空闲块头，插回原块位置以保持地址有序。
- 被分配块的首页清除 `PG_property`，`nr_free -= n`。

#### （4）`default_free_pages(base, n)`：回收并合并

```c
/* 1. 检查每一页都是已分配状态，清零 flags 和 ref */
assert(!PageReserved(p) && !PageProperty(p));
p->flags = 0;
set_page_ref(p, 0);

/* 2. 以 base 为块首页，property = n，nr_free += n */
base->property = n;
SetPageProperty(base);
nr_free += n;

/* 3. 按地址升序插入 free_list */

/* 4. 与低地址相邻块合并 */
if (prev != &free_list && prev + prev->property == base) {
    prev->property += base->property;
    ClearPageProperty(base);
    list_del(&base->page_link);
    base = prev;
}

/* 5. 与高地址相邻块合并 */
if (next != &free_list && base + base->property == next) {
    base->property += next->property;
    ClearPageProperty(next);
    list_del(&next->page_link);
}
```

释放时先校验页面确实是已分配状态，再按地址有序插入，并分别与低、高地址的物理相邻空闲块合并。由于链表按地址排序，`list_prev`/`list_next` 是地址顺序上相邻的空闲块，仍需验证物理连续；找到相邻块后的合并是 O(1)，有序插入本身仍可能需要线性扫描。及时合并可以避免外部碎片累积。

#### （5）First-Fit 的不变量

- 链表中只有空闲块首页，按页地址升序；
- 块首页满足 `PageProperty(head) == 1` 且 `head->property` 为块页数；
- 非首页的 `PG_property == 0`；
- 所有块 `property` 之和等于 `nr_free == nr_free_pages()`。

#### First-Fit 的改进空间

First-Fit 的基本策略比较朴素，主要有以下改进方向：

1. **查找复杂度**：每次分配都从链表头线性扫描，最坏 O(n)。可以用按块大小分级的分离空闲链表（segregated free list）、按大小排序的红黑树/AVL/treap，或线段树/位图索引，把查找降到 O(log n) 甚至 O(1)。
2. **扫描起点**：维护 next-fit 指针（rover），从上次分配位置继续扫描，避免每次都从低地址开始反复切割；但 next-fit 可能加剧碎片，需要权衡。
3. **外部碎片**：First-Fit 倾向于切碎低地址的大块。可以研究最小分裂粒度（整块分配时需记录实际大小并同步调整释放约定），或结合 Best-Fit/Worst-Fit 策略。
4. **合并策略**：当前是释放时立即合并，查找和合并都很及时；高并发场景可改为延迟合并（deferred coalescing），用位图记录相邻空闲状态，降低释放路径开销。
5. **元数据与缓存**：用位图代替链表可减少内存占用并支持快速连续页搜索；多核场景使用 per-CPU 空闲页缓存和细粒度锁，减少全局链表竞争。
6. **专用分配器**：小对象用 slab/SLUB，避免把整页切碎；大块连续分配可用 buddy system，兼顾合并效率与碎片。

### 4.3 功能模块二：Best-Fit 连续物理内存分配

**主要负责人：** 2413073-唐涵城。**后续尾插修复与回归测试：** 2413576-林泽森。

#### 模块功能描述

**需要实现/修改的函数：**

```c
static void best_fit_init(void);
static void best_fit_init_memmap(struct Page *base, size_t n);
static struct Page *best_fit_alloc_pages(size_t n);
static void best_fit_free_pages(struct Page *base, size_t n);
static size_t best_fit_nr_free_pages(void);
static void init_pmm_manager(void);
```

实现完整管理器，选择能够满足请求的最小空闲块，维护切分、回收、合并及页数统计。以下保留唐涵城的核心分析及原始提示词。

Best-Fit 位于 `kern/mm/best_fit_pmm.c`，内部状态与 First-Fit 完全一致（`free_area_t` + 按地址升序的空闲链表），区别只在**选择哪个空闲块**。

#### （1）核心分配逻辑

```c
static struct Page *best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }

    /* 扫描整个链表，选择 property >= n 且 property 最小的块 */
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n &&
            (page == NULL || p->property < page->property)) {
            page = p;
        }
    }

    if (page != NULL) {
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));  // 剩余块插回原位置
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

与 First-Fit 的差别：First-Fit 找到第一个 `property >= n` 就停止；Best-Fit 必须遍历整个链表，在所有满足条件的块中选择 `property` 最小者。这样可以在当前候选块中优先保留更大的块，但不保证整个请求序列的碎片最少。

#### （2）初始化、释放和查询

- `best_fit_init()`：`list_init(&free_list); nr_free = 0;`
- `best_fit_init_memmap()`：与 First-Fit 相同——校验 reserved、清零、建立首个空闲块、按地址有序插入。
- `best_fit_free_pages()`：与 First-Fit 相同——校验已分配状态、有序插入、与低/高地址相邻块双向合并。
- `best_fit_nr_free_pages()`：返回 `nr_free`。

#### （3）注册管理器

以下注册和切换代码保留唐涵城完成阶段的写法。最终版本由林泽森增加编译开关，并将 .check 接为 best_fit_all_check()，先运行原检查再运行尾插回归检查；原 basic_check() 和 best_fit_check() 未修改。

```c
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};
```

并在 `kern/mm/pmm.c` 的 `init_pmm_manager()` 中切换：

```c
pmm_manager = &best_fit_pmm_manager;
```

#### （4）与测试约定的对应

`basic_check()` 和 `best_fit_check()` 直接通过宏读写分配器内部状态，因此实现必须满足：

- `free_list` / `nr_free` 是可赋值左值宏（测试会保存和恢复它们）；
- 空闲链表按页地址升序，只有块首页在链表中；
- 分配后返回块首页的 `PG_property` 清零，`ref` 不变（测试断言 `page_ref == 0`）；
- 释放时向低、高两个方向合并相邻空闲块。

`best_fit_check()` 的关键判定：先释放 `p0+1`（2 页）和 `p0+4`（1 页），随后 `alloc_pages(1)` 必须返回 `p0+4` 而不是 `p0+1`。First-Fit 会返回低地址的 `p0+1`，Best-Fit 选择更小的 1 页块，因此测试能区分两种算法。

#### 最终提示词（Best-Fit，保留唐涵城原稿）

```text
请阅读 kern/mm/pmm.h 中的 struct pmm_manager、kern/mm/memlayout.h 中的
struct Page / PageProperty / PageReserved / free_area_t，以及
kern/mm/default_pmm.c 的 First-Fit 参考实现，为 kern/mm/best_fit_pmm.c
实现 Best-Fit（最佳适应）物理页分配器。

约束：
1. 不得修改 basic_check 和 best_fit_check。它们直接通过 free_list、
   nr_free 两个宏访问分配器内部状态，因此需定义 static free_area_t
   以及 #define free_list (free_area.free_list)、
   #define nr_free (free_area.nr_free)。
2. 实现 init、init_memmap、alloc_pages、free_pages、nr_free_pages，
   并定义 const struct pmm_manager best_fit_pmm_manager
   （.name = "best_fit_pmm_manager"，.check = best_fit_check）。
3. 空闲链表按页地址升序；块首页设置 PG_property 且 property = 页数；
   alloc_pages(n) 必须扫描整个链表，选择 property >= n 且 property
   最小的块；若块大于 n，把 page+n 作为新块头插回原位置以保持地址有序；
   free_pages 按地址有序插入，并与前后物理相邻块双向合并，维护 nr_free。
4. init_memmap 中每页必须满足 PageReserved，随后清零 flags/property/ref；
   free_pages 中断言 !PageReserved && !PageProperty，并清零 flags/ref。
5. 需在 -std=gnu99 -Wall -Werror -O2 下编译通过；manager 若引用后面
   定义的 static best_fit_check，请放到文件末尾或先写前向声明。
6. 请逐条推演 best_fit_check 的断言，特别是空闲块为 [p0+1,2页] 和
   [p0+4,1页] 时 alloc_pages(1) 必须返回 p0+4；free_pages(p0,5) 后
   alloc_pages(5) 必须返回 p0 且随后 alloc_page() 为 NULL；最终
   count 和 total 必须归零。给出实现、关键不变量说明和自检表。
```

#### Best-Fit 的改进空间

1. **查找复杂度**：当前每次分配都要遍历整个空闲链表，O(n)。可以把空闲块按大小组织成分离链表（size class）、红黑树/AVL/treap（以 `property` 为键，地址为次键），或用线段树维护“最小满足 n”的查询，把分配降到 O(log n) 或 O(1)。
2. **碎片问题**：Best-Fit 倾向选择刚好够用的块，切分后容易留下大量极小剩余块。可以研究最小分裂粒度（整块分配时需记录实际大小）、合并空闲块，或在不同策略之间做自适应选择；移动已分配页面以压缩内存还需要映射和页面迁移机制支持，当前实现未包含。
3. **大小类划分**：按 2 的幂或固定粒度分桶，桶内用链表；查询时从 `ceil(n)` 所在桶向上找，兼顾速度与碎片。
4. **小对象分离**：页级 Best-Fit 适合大块连续分配；小对象（几十到几百字节）交给 SLUB/Slab 对象缓存，避免每次切分整页。
5. **多核扩展性**：全局空闲链表需要锁保护。可采用 per-CPU 页缓存、每 NUMA 节点独立空闲链表、批量分配/释放，减少锁竞争。
6. **延迟合并与位图**：释放时只标记空闲，分配失败时再合并；用位图记录页状态，支持快速查找连续空闲区间。
7. **与 Buddy System 结合**：页级分配用 buddy 保证 O(log n) 合并和 2 的幂块；Best-Fit 用于处理非 2 的幂的连续请求，二者结合可兼顾效率与碎片。

#### 林泽森补充：尾插问题与回归测试

我在运行时发现，best_fit_init_memmap() 与 best_fit_free_pages() 在尾插分支中缺少 break。插入后循环继续访问刚插入的节点，可能重复插入同一节点，破坏 prev/next 链接。在低地址 2 页块、高地址 1 页块的隔离测试中，连续两次单页申请可能返回同一页，而原 best_fit_check() 仍能通过。

两处尾插分支均修改为：

```c
} else if (list_next(le) == &free_list) {
    list_add(le, &(base->page_link));
    break;
}
```

新增 best_fit_tail_check()：借出 5 页构造上述空闲块，连续申请单页，检查地址不重复、Best-Fit 优先选择 1 页块、耗尽后链表为空，以及归还后计数恢复。通过包装函数接入：

```c
static void
best_fit_all_check(void) {
    best_fit_check();
    best_fit_tail_check();
}
```

最终 .check = best_fit_all_check。框架原有两个检查函数保持原样。QEMU 实测输出 best_fit_tail_check() succeeded!，详见第五部分。

### 4.4 功能模块三：Buddy System伙伴系统分配算法

**负责人：** 2413576-林泽森。

#### 模块功能描述

**新增文件：** kern/mm/buddy_pmm.c、kern/mm/buddy_pmm.h。

**配套修改：** Makefile 增加 PMM 开关，pmm.c 引入头文件并选择管理器。参考骨架 lab2_new 保持不变。

**核心函数及检查入口：**

```c
static void buddy_init(void);
static void buddy_init_memmap(struct Page *base, size_t n);
static struct Page *buddy_alloc_pages(size_t n);
static void buddy_free_pages(struct Page *base, size_t n);
static size_t buddy_nr_free_pages(void);

static void buddy_init_check(void);
static size_t buddy_count_blocks(unsigned int order);
static void buddy_alloc_free_check(void);
static void buddy_exhaustion_check(void);
static void buddy_check(void);
```

本模块通过 struct pmm_manager 接入内核，复用唐涵城完成的 page_init()、Page 数组及地址转换接口。可用物理页被组织为大小为 1、2、4、8……页的块，申请时拆分较大块，释放时与同阶空闲伙伴递归合并。

#### 接口规格与数据结构

| 项目 | 本次实现约定 |
|------|--------------|
| 分配单位 | 物理页，每页 4096 字节 |
| 阶数 | order = k 表示块包含 2^k 页 |
| 最大阶 | BUDDY_MAX_ORDER = 15，最大单块为 32768 页，即 128 MiB；能否申请到还取决于空闲区 |
| 初始空闲区 | 当前 page_init() 一次注册一段连续区间，记录其物理页号起止范围 |
| 非 2 次幂申请 | 向上取整，例如 alloc_pages(3) 实际占用 4 页 |
| 释放约定 | 原始块首地址与原始请求页数整块归还，不支持对子区间任意释放 |
| 页数统计 | 按实际块大小增减；申请 3 页扣除 4 页，释放该块归还 4 页 |
| 伙伴基准 | 使用 page2ppn() 得到的物理页号，不混用虚拟地址、描述符地址与数组下标 |
| 分配失败 | 总量不足、无满足要求的连续块或超过最大单块大小时返回 NULL；n = 0 由断言拒绝 |

```c
#define BUDDY_MAX_ORDER 15
#define BUDDY_ALLOCATED (1UL << 2)

static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_nr_free;
static size_t buddy_begin_ppn;
static size_t buddy_end_ppn;
```

各阶分别维护一条链表，只将空闲块首页加入链表。buddy_nr_free 保存空闲页总数，两个边界变量限定可管理区间。

Page.property 在 Buddy 中保存阶数，而在 First-Fit/Best-Fit 中保存块页数。两种分配器互斥选择，不能在运行中直接把同一批链表按另一种规则解释。

| 标记 | 含义 |
|------|------|
| PG_reserved（第 0 位） | 页面保留，不能由分配器交付 |
| PG_property（第 1 位） | 当前 Page 是空闲块首页 |
| BUDDY_ALLOCATED（第 2 位，值为 4） | 当前 Page 是已分配块首页 |

实际块大小由首页的 property 恢复。释放函数检查 n 向上取整后的大小是否匹配，但没有额外保存原始 n，因此不能区分“申请 3 页”和“申请 4 页”；本实验要求调用者归还原始请求参数。

#### 核心实现与作用说明

##### （1）初始化内部状态

buddy_init() 初始化 0 至 15 阶空链表，清零页数和区间。它不负责发现内存；可用区间随后由 page_init() 经 init_memmap() 传入。

##### （2）建立初始空闲块

起点未必按大块对齐，总长度未必为 2 的幂，不能直接把整段作为一个块。buddy_init_memmap() 每次选择起点满足对齐、又不超过剩余长度的最大块，继续处理后续区间。

2^k 页块要求起始物理页号满足 ppn % (2^k) = 0，代码用位运算判断。先把可用页从 reserved 状态转换为管理状态，再把各块首页加入对应链表。

```c
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
```

最终实测 [0x80347000, 0x88000000) 共 31929 页，被划分为 10 个合法块。初始化必须完整覆盖可用区间，不能为了凑成一个 2 次幂块而丢弃头尾页面。

##### （3）请求取整与逐级拆分

找到最小阶 order，使 2^order >= n；若对应链表为空，则向更高阶寻找。取出大块后，每级保留左半块继续拆分，把右半块放回对应阶链表。

```c
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
```

例如申请 3 页需要 4 页块，若只找到 16 页块，则先拆为两个 8 页，再把左侧 8 页拆为两个 4 页，返回左侧 4 页。其余 8 页和 4 页仍为空闲块，页数只扣除实际交付的 4 页，拆分本身不丢失页面。

##### （4）释放与伙伴合并

释放时验证范围、对齐、已分配首页标记及请求大小对应关系，读取保存阶数并归还实际占用页数，再计算：

```c
size_t count = (size_t)1 << order;
size_t buddy_ppn = ppn ^ count;
```

异或只翻转物理页号的第 order 位，在同一父块的左右伙伴间切换。“相邻”不等于“伙伴”；伙伴还必须位于管理范围内，是同阶空闲块首页。

```c
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
```

合并时移除伙伴链表节点，以较低地址为新起点，order++ 后继续向上尝试。两个 4 页空闲块合成一个 8 页块，空闲总量没有增加，因此页数只在归还已分配块时增加一次。

在已知块首页的前提下，申请查找、拆分与释放合并的步数均受最大阶限制，不必扫描全部空闲块寻找伙伴。buddy_nr_free_pages() 直接返回维护的空闲页计数。

##### （5）管理器选择与接入

buddy_pmm.h 导出 buddy_pmm_manager，注册结构将六个接口绑定到本模块函数，最终 .check = buddy_check。

Makefile 增加：

```makefile
PMM ?= best_fit

ifeq ($(PMM),buddy)
CFLAGS += -DPMM_BUDDY
else ifneq ($(PMM),best_fit)
$(error PMM must be best_fit or buddy)
endif
```

pmm.c 的选择逻辑为：

```c
static void init_pmm_manager(void) {
#ifdef PMM_BUDDY
    pmm_manager = &buddy_pmm_manager;
#else
    pmm_manager = &best_fit_pmm_manager;
#endif

    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}
```

默认仍为 Best-Fit，make PMM=buddy test 才选择 Buddy。切换前执行 make clean，因为当前构建规则不会只因编译参数改变就自动重编全部目标文件。

#### 提示词与实现迭代过程


##### 第一次迭代：明确规格，完成实现和基础检查

**目标：** 从零新增 Buddy 分配器，接入已有框架并完成初始化及常规分配释放检查。

**对话提示词一：实现提示词**

```text
[角色]
你是熟悉 RISC-V ucore 物理内存管理的操作系统实验助教。
请逐项指导我修改代码，并解释每段代码的作用，由我在 WSL 编译运行。

[已有条件与可用资源]
当前代码是 lab2/OS/code，lab2_new 只读参考，不修改。
唐同学已完成 page_init()、First-Fit 分析与 Best-Fit。
请阅读 kern/mm/pmm.h、pmm.c、memlayout.h、mmu.h、default_pmm.c、
best_fit_pmm.c 和 libs/list.h，复用 struct pmm_manager、struct Page、
page2ppn()、PageReserved/PageProperty 等接口。
保持原 basic_check()、best_fit_check() 和官方评分文件不变。

[目标与接口规格]
新增 kern/mm/buddy_pmm.c、buddy_pmm.h，注册 buddy_pmm_manager，
实现 init、init_memmap、alloc_pages、free_pages、nr_free_pages 和 check。
1. 用 0 至 15 阶空闲链表管理 2 的幂次页块，property 保存阶数。
2. 初始化面对单段连续空闲区，根据绝对物理页号对齐与剩余长度划分，
   完整覆盖可用页面，不丢弃非 2 次幂尾部。
3. alloc_pages(n) 向上取整为 2 的幂，从最小可用阶取块并逐级拆分；
   空闲页数按实际交付块大小扣减，无可用块时返回 NULL。
4. 用独立 flags 位标记已分配块首页；free_pages(base,n) 按记录阶数
   整块归还，校验范围、对齐、状态与 n 对应的取整大小。
5. 用 page2ppn(base) 为基准，以 ppn XOR (1 << order) 定位伙伴；
   仅同阶空闲伙伴可合并，取较低地址继续向上尝试。
6. 保留默认 Best-Fit，增加 PMM=buddy 编译开关，不改变 Page 布局。
7. 满足 -std=gnu99 -Wall -Werror -O2。

[输出与分步验证]
先讲清接口并实现初始化，指导我运行初始化检查；
再补齐分配释放，检查申请 1、3、8 页实际占用 13 页、
区间不重叠、乱序释放后页数和各阶块数量恢复。
给出准确修改位置与命令，每一步解释作用，便于理解后继续。
```

**AI 输出**

给出按阶链表、物理页号边界和已分配首页标记，先初始化再补取整、拆分及递归合并；增加 PMM 开关、buddy_init_check() 和 buddy_alloc_free_check()，逐步运行验证。

**实际反馈与处理：**

- 初始化阶段为 31930 页、10 个块；补充分配释放及测试后为 31929 页、10 个块。内核大小改变会影响空闲区起点，判断依据是同次测试前后恢复一致，而非固定页面数。
- 明确 property 在不同分配器中的含义，统一使用物理页号计算伙伴，避免与描述符下标混用。
- 本次已记录的第一次迭代没有 Buddy 编译或断言失败；不足在于只测试少量正常请求，尚未验证完整耗尽与碎片失败路径。

**运行命令：**

```bash
make clean
make PMM=buddy test
```

**本轮结果：** 初始化与基础分配释放检查通过，释放前后页数和块数一致。

##### 第二次迭代：补充耗尽、碎片与回归验证

**目标：** 独立设计更强的测试，验证基础检查尚未覆盖的边界及恢复能力。

**对话提示词二：测试提示词**

```text
[当前反馈]
Buddy 初始化和申请释放检查已在 QEMU 通过，最新为 31929 页、10 个块。
申请 1、3、8 页并释放后恢复原状态。请保持已实现接口和测试，
继续逐段讲解新增测试的作用。

[测试任务]
针对当前实现增加 buddy_exhaustion_check()，通过真实申请和释放验证，
不只检查打印信息或手动修改计数。
1. 保存初始空闲页数与各阶块数量。
2. 连续 alloc_page() 直到失败，检查实际获得页数等于初始空闲页数，
   全部空闲链表为空，再次申请返回 NULL。
3. 检查页面不重复交付，可在测试独占的已分配页上临时用 ref 标记；
   释放前恢复为 0，解释为什么不会遗留状态。
4. 用 held 链表和已分配页的 page_link 记录页面，
   避免在小内核栈上放数万指针的大数组。
5. 只释放偶数物理页号的页面，制造总空闲量足够但没有连续 2 页的场景；
   alloc_pages(2) 必须失败，失败前后计数不变。
6. 再释放奇数页，要求空闲页数和各阶块数量恢复，验证递归合并。
7. 接入 buddy_check()：初始化检查、基础分配释放、耗尽碎片测试、
   最后再次检查结构。

[集成与证据]
测试保留在 kern/mm 下，不加入与评分注入器冲突的 kern/test。
保留官方测试，说明 grade 要用 Best-Fit、Buddy 靠独立测试验证，
以及切换配置前为什么需要 clean。
复验 Best-Fit 尾插修复；为 QEMU 7.0.0 配置外部 wrapper，
转换 -device loader 为 -kernel，按实际路径运行官方评分。
解释每项断言能发现的错误，给出预期输出，不编造未执行的结果。
```

**AI 输出**

新增耗尽与碎片检查。逐页申请时以 ref 标记检查重复返回，用 held 链表保存页面；偶数页先释放、奇数页后释放，分别检验连续块不足时拒绝请求和最终递归合并恢复。

**测试为何有效：**

- 耗尽过程把原大块真正拆成单页，可发现拆分丢页或重复交付；实际拿到的数量还要和计数及空链表状态交叉验证。
- 单页块的伙伴是一偶一奇，只释放偶数页时不能合并出 2 页块，因此能够检验错误合并或错误满足连续请求。
- 最后不仅要求页数恢复，还要求各阶块数量恢复，可发现计数看似正确但合并不完整。
- 借用的 ref 在释放前恢复，page_link 在归还前移出测试链表，最后再次检查结构。

**实际问题与处理：**

1. 基础测试不足以证明耗尽和碎片处理正确，第二轮增加上述独立测试作为主要完善。
2. 当前环境起初未配置 QEMU wrapper，按实际路径 /opt/qemu/bin/qemu-system-riscv64 创建 /tmp/qemu-lab2，验证版本后复验官方评分。
3. gmake 的 Entering/Leaving directory 和挤在一行的编译信息是正常输出，以检查项的 OK 和 20/20 判断通过。

**最终结果：**

- Buddy 的三组检查通过，31929 个页面耗尽后全部归还，恢复为 31929 页、10 个块。
- Best-Fit 尾插回归有实际通过记录，最终官方评分以 Best-Fit 配置通过 20/20。
- 本轮没有已记录的 Buddy 断言失败；没有故意执行触发 panic 的非法释放、零页请求，不将这些列为已通过的实测场景。

#### 适用范围与改进空间

当前实现针对单核、单段连续空闲区，没有多核锁、多段独立区域管理、任意子区间释放及 SLUB 接口。按 2 的幂取整可能产生内部碎片，例如申请 3 页实际占用 4 页。后续扩展时需要同步明确接口与测试。

### 4.5 Challenge：OS 如何获取可用物理内存范围

**负责人：** 2413073-唐涵城。

如果 OS 无法提前知道硬件的可用物理内存范围，可以依靠固件、引导协议或主动探测来获得：

1. **设备树（DTB/FDT）**
   RISC-V 平台通常由 OpenSBI/U-Boot 把 DTB 的物理地址放在 `a1` 中传给内核。内核解析 `/memory` 节点的 `reg` 属性，得到每段物理内存的 `(base, size)`；`/reserved-memory` 节点和 FDT 的 memory reservation block 给出保留区。本实验正是采用这种方式：`entry.S` 保存 `a1`，`dtb_init()` 解析 DTB，`page_init()` 调用 `get_memory_base()/get_memory_size()`。

2. **x86 BIOS/UEFI**
   - BIOS：通过 `int 0x15, eax = 0xE820` 获取 E820 内存图，描述可用 RAM、保留区、ACPI 区和 MMIO。
   - UEFI：调用 `GetMemoryMap()` 获得 `EFI_MEMORY_DESCRIPTOR` 数组，按类型区分 `EfiConventionalMemory`、`EfiReservedMemoryType`、`EfiMemoryMappedIO` 等。
   - ACPI 表（如 SRAT）补充 NUMA 节点与热插拔信息。

3. **引导协议/引导程序**
   Multiboot/Multiboot2 的 memory map、Linux boot protocol 的 `e820_entries`、U-Boot 的 `/memory` 节点或 `bd_info`、GRUB 传递的 memory map 等，都可以把可用内存范围交给内核。

4. **固件调用/平台寄存器**
   某些平台可通过平台专用固件接口或内存控制器寄存器查询 DRAM 大小和布局；SoC 的芯片手册也会给出固定的 DRAM 基址和容量。

5. **主动探测（无任何固件信息时的兜底）**
   在候选地址写入特征值再读回，捕获总线错误/异常，二分搜索 RAM 的上下界；或借助缓存/总线行为推断。但探测必须避开 MMIO、固件和已用区域，风险较高，现代系统通常只把它作为最后手段。

无论采用哪种方式，内核都必须把以下区域标记为保留，不能交给分配器：

- 固件（OpenSBI/BIOS/UEFI）自身；
- 内核镜像（`.text/.data/.bss`）与启动栈；
- 设备树/ACPI 表、initrd/initramfs；
- 页描述符数组、页表等内核元数据；
- MMIO、中断控制器、串口等设备地址空间；
- 固件报告的 reserved-memory 区域。

本实验的 `page_init()` 通过“只把 `[freemem, mem_end)` 交给 `init_memmap()`”实现了对 OpenSBI、内核镜像和描述符数组的保留。生产内核还应显式保留 DTB（本实验中 DTB 位于 `0x87000000` 附近，仍落在空闲区内）以及 FDT 的保留区。

### 4.6 Challenge：SLUB 任意大小内存对象分配

Buddy 提供页级块分配，未实现页内对象缓存与 SLUB 测试。

### 4.7 分支任务：GDB 调试 QEMU 页表查询与 TLB

**负责人：** 2413523-尤祺乐。

**当前状态：** 待负责人补充实际过程与结果。内核启动适配、普通 QEMU 运行和官方评分不能替代本分支的源码双重调试。

待补内容：调试版 QEMU 的准备与版本、三个终端和两个 GDB 的顺序、源码关键调用路径与分支、真实访存的虚拟/物理地址对应、页表查询单步过程、TLB 命中/未命中、分页开启前后比较、软件 TLB 与真实 CPU TLB 的区别，以及实际问题、AI 交互和截图。

<!-- 尤祺乐在此补充真实命令、寄存器/PTE 数值、源码位置及截图。 -->

---

## 五、测试与验证

### 5.1 编译验证

**原记录负责人：** 2413073-唐涵城。

```sh
cd /home/tanch/os/lab2
make
```

在 `-std=gnu99 -Wall -Werror -O2` 下编译通过，无警告无错误。

### 5.2 Best-Fit 正常启动

**原记录负责人：** 2413073-唐涵城。保留原始输出；符号地址及镜像大小会随后续代码和配置变化。

由于本机 QEMU 7.0.0 的 `-device loader` 问题，使用 `-kernel` 启动：

```sh
timeout 10 qemu-system-riscv64 -machine virt -nographic -bios default \
    -kernel bin/ucore.img -monitor none -no-reboot
```

关键输出：

```text
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d6 (virtual)
  etext  0xffffffffc02016dc (virtual)
  edata  0xffffffffc0206018 (virtual)
  end    0xffffffffc0206078 (virtual)
Kernel executable memory footprint: 24KB
memory management: best_fit_pmm_manager
page_init: memory [0x0000000080000000, 0x0000000088000000), free start 0x0000000080347000, npage=557056
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
```

`check_alloc_page() succeeded!` 说明 `best_fit_check()` 中的全部断言（空闲链表一致性、分配/切分、释放/合并、Best-Fit 选择）都已通过。

### 5.3 Best-Fit 检查与尾插回归

**原测试记录：** 2413073-唐涵城。

```sh
timeout 10 make test
```

`best_fit_check()` 的 6 个评分点全部通过：

```text
memory management: best_fit_pmm_manager
page_init: memory [0x0000000080000000, 0x0000000088000000), free start 0x0000000080347000, npage=557056
grading: 1 / 6 points
grading: 2 / 6 points
grading: 3 / 6 points
grading: 4 / 6 points
grading: 5 / 6 points
grading: 6 / 6 points
check_alloc_page() succeeded!
```

**林泽森补充的尾插回归结果：**

```text
grading: 6 / 6 points
best_fit_tail_check() succeeded!
check_alloc_page() succeeded!
```

以上来自修复两处尾插分支后运行 make clean、make test 的实际输出。最终 grade 再以 Best-Fit 复验，pmm_init() 会先执行当前管理器的 .check，再运行注入测试。

### 5.4 Buddy 独立测试

**负责人：** 2413576-林泽森。

**实际命令：**

```bash
cd /mnt/d/UniversityDocs/jun/OS/exp/lab2/OS/code
make clean
make PMM=buddy test
```

**最后一次完整测试的关键输出：**

```text
memory management: buddy_pmm_manager
page_init: memory [0x0000000080000000, 0x0000000088000000), free start 0x0000000080347000, npage=557056
buddy init: 31929 pages in 10 blocks
buddy_init_check() succeeded!
buddy_alloc_free_check() succeeded!
buddy_exhaustion_check() succeeded! (31929 pages)
buddy init: 31929 pages in 10 blocks
buddy_init_check() succeeded!
buddy_check() succeeded!
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
```

前后均为 31929 页、10 个块，耗尽阶段实际申请全部 31929 页，再全部归还。终端最后的 QEMU: Terminated 是退出模拟器后的进程结束信息，不能据此判断上述检查失败。

**测试覆盖与判定：**

| 检查函数/场景 | 核心判定 | 可发现的问题 |
|---------------|----------|--------------|
| buddy_init_check() | 首页标记与阶数匹配，块对齐、不越界，链表双向链接正确，页数求和一致 | 初始块对齐、范围、链表或计数错误 |
| 申请 1、3、8 页 | 实际扣除 13 页，分配区间对齐且不重叠 | 取整错误、重叠分配、错误计数 |
| 乱序释放 | 逐次增加实际块页数，最终页数和各阶数量恢复 | 释放大小错误、丢块、合并时重复加计数 |
| 超过最大单块的请求 | 返回 NULL，计数不变 | 请求边界或失败路径破坏状态 |
| 逐页耗尽 | 数量等于初始空闲页数，页面不重复，链表全空，再申请失败 | 拆分丢页、重复返回、耗尽行为错误 |
| 只释放偶数物理页 | 只有单页空闲块，申请 2 页失败，失败后计数不变 | 错误合并非伙伴、错误满足连续请求 |
| 再释放奇数页 | 页数及各阶数量恢复，再次结构检查通过 | 伙伴定位错误、递归合并不完整、测试遗留状态 |


### 5.5 官方评分与 QEMU wrapper

**唐涵城提供启动适配思路，林泽森在当前环境配置 wrapper 并重新验证。**

tools/grade.sh 仍使用 -device loader，因此借助外部 QEMU wrapper 将其重写为 -kernel，不修改仓库内评分脚本。与唐涵城原稿的 wrapper 思路相同，本次使用 Bash 数组保存参数边界，并固定已确认的 QEMU 路径：

```bash
cat > /tmp/qemu-lab2 <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

real_qemu="/opt/qemu/bin/qemu-system-riscv64"
args=()

while (( $# > 0 )); do
    if [[ "$1" == "-device" && $# -ge 2 &&
          "$2" == loader,file=*,addr=0x80200000 ]]; then
        image="${2#loader,file=}"
        image="${image%,addr=0x80200000}"
        args+=(-kernel "$image")
        shift 2
    else
        args+=("$1")
        shift
    fi
done

exec "$real_qemu" "${args[@]}"
EOF

chmod +x /tmp/qemu-lab2
/tmp/qemu-lab2 --version
```

版本检查实际输出 QEMU emulator version 7.0.0。随后在 OS/code 目录执行：

```bash
QEMU=/tmp/qemu-lab2 make PMM=best_fit grade
```

grade 自动清理构建，将代码复制到 /tmp/lab2_grade，注入官方测试后编译运行。最终实际结果：

```text
lab2 injection complete
  -check page init:                          OK
  -check best fit:                           OK
Total Score: 20/20
```

**官方评测通过截图：**

![官方评分通过：Page Init 与 Best-Fit 均为 OK，总分 20/20](./OS/report/images/通过测试.png)

其中：

- [Test 1] Page Init: PASS 验证 va_pa_offset、DTB 范围、npage、pages 布局、空闲页数、内核尾页及描述符数组的 reserved 状态，以及 page2pa/pa2page 往返转换。
- [Test 2] Best-Fit: PASS 验证当前 pmm_manager == &best_fit_pmm_manager。
- pmm_init() 在注入测试前还会运行 Best-Fit 原检查和新增尾插回归。Buddy 由 5.4 节独立测试验证，不能将本次 20/20 解释为官方评分覆盖 Buddy。
- lab2 injection complete、gmake 的 Entering/Leaving directory 和编译输出均正常，检查项前的短横线不表示失败。



---

## 六、实验总结与收获

### 6.1 对操作系统的理解

#### 唐涵城：原物理内存管理部分总结

以下保留其原报告总结，描述初始化、First-Fit、Best-Fit 和启动适配部分。

本阶段完成了从物理内存探测到页面分配的完整链路：

1. `page_init()` 依据 DTB 提供的内存范围，正确建立了 `Page` 描述符数组，区分了虚拟地址、物理地址、页号和描述符地址，排除了 OpenSBI、内核镜像和描述符数组占用的空间，并把完整空闲页面注册给物理内存管理器。
2. 通过阅读 `default_pmm.c`，理解了 First-Fit 的空闲链表组织、首次满足分配、剩余块切分和双向合并机制。
3. 实现了 Best-Fit 分配器：扫描整个空闲链表选择最小满足块，保持地址有序的空闲链表、页属性约定和释放合并逻辑与 First-Fit 一致，最终通过全部测试。
4. 实验还处理了 QEMU 7.0.0/OpenSBI 的启动适配问题（`-device loader` 入口问题和启动页表低地址恒等映射），对 RISC-V 启动流程、Sv39 地址转换和固件交接有了更直观的理解。

Best-Fit 相比 First-Fit 能减少大块被小块请求切碎的概率，但代价是全链表扫描 O(n) 和可能产生大量极小剩余块。工程实践中通常会结合分离空闲链表、平衡树索引、最小分裂粒度、per-CPU 缓存和 slab 分配器，在碎片率与分配延迟之间取得平衡。

#### 林泽森：Buddy System 与测试收获

通过伙伴系统，我认识到分配器要同时维护地址、大小、状态、链表和总页数的一致性。只让计数恢复还不够，必须检查分配区间不重叠、伙伴满足对齐、块回到正确阶，以及失败请求不破坏状态。

Buddy 可以直接从阶数与物理页号计算伙伴，合并无需扫描全部块；代价是取整造成内部碎片。Best-Fit 按请求页数切分，可能留下外部碎片，Buddy 则用层级限制块大小和合并方式，体现了不同策略的取舍。

**本实验知识点与 OS 原理的联系：**

| 知识点 | 实验体现 | 联系与差异 |
|--------|----------|------------|
| 物理内存发现与保留 | DTB、Page 数组、reserved 标记 | 将抽象可用内存落实到具体固件信息和内核自身占用 |
| 连续分配与外部碎片 | First-Fit/Best-Fit 链表，偶数页先释放测试 | 总空闲量足够不代表存在足够连续的物理页 |
| 伙伴系统与内部碎片 | 申请 3 页占用 4 页 | 简化查找与合并的同时可能浪费块内页面 |
| 管理元数据 | property、flags、page_link | 元数据占用也要保留，字段含义取决于当前管理器 |
| 地址转换与分配 | PADDR、page2ppn、启动页表 | 分配物理页与翻译虚拟地址有关联，但不是同一功能 |
| 正确性与测试 | 耗尽、碎片失败、无重叠、阶分布恢复 | 正常案例不能替代边界验证，官方与独立测试覆盖不同 |

**OS 原理中重要、当前已实现部分没有直接覆盖的内容：**

- 按需分页、缺页处理、页面置换和交换空间。
- 用户进程独立地址空间、写时复制和内存映射文件。
- 多核锁、并发分配、NUMA 和每 CPU 缓存。
- SLUB/Slab 对象分配与页内小对象缓存。

页表查询与 TLB 的 QEMU 源码观察由尤祺乐后续补充，当前不作为已完成实验结论。

### 6.2 AI 协作开发的经验

**林泽森：**

本次先确定接口及不变量，再按初始化、分配释放、边界测试逐步推进。每次修改后都在 WSL 实际编译运行，把终端结果反馈给 AI；页数变化时结合内核大小分析，而不是把某个固定输出当成正确性的唯一依据。

第一次迭代侧重实现，第二次侧重独立检验。Best-Fit 原有检查能通过却仍可能重复返回同一页，说明测试要针对可能出错的场景设计。Buddy 的耗尽与碎片测试进一步区分了空闲页总量正确和连续块组织正确。

提示词明确 Page 字段含义、取整方式、释放约定、代码目录和不可修改的测试，有助于避免生成结果与框架不兼容。对于日志疑问也结合最终检查判断，gmake 目录信息和手动退出 QEMU 的结束信息不代表实验失败。

**唐涵城、尤祺乐：** 如需补充个人 AI 使用经验，由本人根据实际过程填写。

---
