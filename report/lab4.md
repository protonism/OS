# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 4: 进程管理 |
| **小组成员** | 2413073-唐涵城、2413576-林泽森、2413523-尤祺乐 |
| **完成日期** | |

### 小组分工

| 成员 | 负责的模块 |
|------|----------------|
| 2413576-林泽森 | 模块一：`page_insert()`、`page_remove()` 及其辅助函数；Lab2 内存初始化与 Best-Fit 依赖的迁移和接口核对；必要的启动适配；Challenge 2 第一问；报告中的环境、整体逻辑和本模块内容 |
| 2413073-唐涵城 | 负责模块二（进程创建及初始化），实现 PCB 初始化、内核线程创建和初始执行现场构造，以及 `idleproc`、`initproc` 的初始化。撰写报告第 4.2 节并解答 Challenge 2 第二问。 |
| 2413523-尤祺乐 | 负责模块三（进程调度与上下文切换），实现 `cpu_idle()`、`schedule()`、`proc_run()` 和 `switch_to()`。撰写报告第 4.3 节并解答 Challenge 1。 |

---

## 一、实验目的

1. 了解虚拟内存管理的基本结构，掌握虚拟地址空间、物理页和多级页表之间的关系。
2. 实现物理页映射的建立、更新和撤销，保持页表项、引用计数与 TLB 状态一致。
3. 在保留此前物理内存管理与中断处理成果的基础上，接入 Lab4 的虚拟内存、进程创建和调度框架。
4. 理解内核线程创建、执行和上下文切换的整体过程。
5. 比较 Sv32、Sv39、Sv48 的分页结构，解释 `get_pte()` 中逐层处理页表的相似代码。

---

## 二、实验环境

### 2.1 软件与代码环境

| 项目 | 内容 |
|------|------|
| 宿主机与运行方式 | macOS；在 Docker 容器中使用交叉工具链和 QEMU |
| 容器 | `amd64-ubuntu22.04` |
| 架构 | RISC-V 64（Sv39） |
| 模拟器 | QEMU 7.0.0，`/usr/local/bin/qemu-system-riscv64` |
| 固件 | OpenSBI v1.0（QEMU `-bios default`） |
| 交叉编译器 | `riscv64-unknown-elf-gcc` 15.1.0，位于 `/opt/riscv/bin/` |
| 主要编译选项 | `-mcmodel=medany -std=gnu99 -O2 -Wall -g -Wno-unused` |
| 其他编译选项 | `-fno-builtin -nostdinc -fno-stack-protector -ffunction-sections -fdata-sections` |
| 工程结构 | `code/` 保存实验代码，`report/` 保存实验报告 |
| 容器内代码目录 | `/workspaces/jun/OS/exp/lab4/OS/code` |
| 开发分支 | `lab4`，从此前 Lab3 的进展建立，并合入 `lab4_new` 框架 |

### 2.2 启动方式适配

当前容器使用的 QEMU、OpenSBI 和 GCC 版本已核对。Lab4 继续沿用此前实验的启动适配，在 Makefile 的 `qemu`、`debug` 目标以及 `tools/grade.sh` 中统一使用：

```sh
-kernel bin/ucore.img
```

`kern/init/entry.S` 保留低地址恒等映射。写入 `satp` 后，在跳转到内核高地址之前，PC 仍位于 `0x802000xx`。该地址的根页表索引为 2，因此索引 2 保留 `0x80000000` 开始的 1 GiB 恒等映射；索引 511 保留内核高地址到同一物理范围的映射。

当前根页表相关内容为：

```asm
    .zero 8 * 2
    .quad (0x80000 << 10) | 0xcf # VRWXAD
    .zero 8 * 508
    .quad (0x80000 << 10) | 0xcf # VRWXAD
```

原有的 HartID、DTB 地址保存及栈地址设置也继续保留。以上是当前启动代码的配置说明，不作为最新页操作版本已经完成整核运行的证明。

### 2.3 依赖迁移与接口衔接

在现有 Lab3 工程的 `code/` 内合入 Lab4 框架，保留既有目录结构。前置工作包括：

- 保留 `page_init()`，继续从设备树读取内存范围，初始化物理页描述符和空闲页链表。
- 保留 `best_fit_pmm.c`、`best_fit_pmm.h` 和 `best_fit_pmm_manager`，管理器选择、声明和定义保持一致。
- 在 `pmm.h`、`mmu.h`、`memlayout.h` 中接入 Lab4 的页表接口、地址转换辅助函数和新增字段；页表全局名称统一为 `boot_pgdir_va`、`boot_pgdir_pa`。
- 在 Makefile 中接入进程、调度等新增源码目录，并迁入 Lab4 评分与注入工具。
- `readline()` 采用 Lab4 的 `kern/libs/readline.c`；SBI 调用采用 Lab4 的头文件内联实现。旧源码保留作参考，并从当前构建中排除，避免重复定义。
- 保留 Lab3 的中断和异常处理，接入 Lab4 的 `forkrets` 入口。此前用于演示的固定时长关机改为可选配置，正常 Lab4 运行不启用。
- 保留原骨架的说明与练习标记。合并时遗漏或缩写的注释已按原文补回。

---

## 三、实验整体逻辑分析

### 3.1 内核初始化与线程执行链路

Lab4 骨架组织的初始化顺序如下：

```text
kern_init()
  -> memset(edata, 0, end - edata)  清零 BSS
  -> dtb_init()                    读取设备树中的物理内存信息
  -> cons_init()                   初始化控制台
  -> print_kerninfo()              输出内核符号信息
  -> pmm_init()                    物理内存与页表基础检查，初始化内核堆
  -> pic_init() / idt_init()        中断相关初始化
  -> vmm_init()                    虚拟内存管理初始化
  -> proc_init()                   进程模块入口
  -> clock_init()                  设置定时器事件
  -> intr_enable()                 开启中断
  -> cpu_idle()                    进入空闲线程执行入口
```

指导书规划的后续执行链为：

```text
cpu_idle() -> schedule() -> proc_run() -> switch_to()
```

上述内容说明骨架的调用关系。进程创建和调度模块的具体实现与运行验证由对应部分补充，不据此认定这些模块已经完成。

### 3.2 本部分的物理内存与页操作链路

指导书中本实验采用预映射方式。`get_pte(..., 1)` 根据需要申请的是页表页，与访问触发缺页后再分配目标数据页的按需分页不同；本部分没有实现缺页换入或页面置换。

`pmm_init()` 先选择 Best-Fit 管理器，再执行 `page_init()` 和分配器检查；随后取得启动根页表的虚拟、物理地址，调用 `check_pgdir()`、`check_boot_pgdir()`，最后执行 `kmalloc_init()`。

本部分建立映射时的调用关系为：

```text
page_insert(pgdir, page, la, perm)
  -> get_pte(pgdir, la, 1)          查找或创建下级页表
  -> 增加目标数据页引用
  -> 判断旧映射是否存在、是否指向同一物理页
  -> 必要时清理旧映射
  -> 写入新的 PTE 和权限
  -> tlb_invalidate(pgdir, la)
```

撤销映射时的调用关系为：

```text
page_remove(pgdir, la)
  -> get_pte(pgdir, la, 0)          只查找，不分配页表
  -> page_remove_pte(pgdir, la, ptep)
     -> 清零有效 PTE
     -> 使对应 TLB 翻译失效
     -> 减少数据页引用，引用为零时释放
```

### 3.3 工作迭代

| 迭代 | 时间 | 主要工作 | 当前记录 |
|------|------|----------|----------|
| 1 | 2026-11-17 | 建立 Lab4 起点，将新增框架合入既有 `code/`，衔接接口和构建配置，保留此前实现 | 起点提交为 `705543f lab4初始化` |
| 2 | 2026-11-17 | 按逐步指导手动实现 `page_remove_pte()`、`page_remove()`、`page_insert()` | 完成源码实现与静态核对 |
| 3 | 2026-11-17 | 补充 `get_pte()` 的分配失败回滚、非叶项更新后的全量刷新和 TLB 汇编的编译器约束 | 完成源码实现与静态核对 |
| 4 | 2026-11-17 | 修正非叶项 `PTE_U` 设置，并将自检中叶项、非叶项的权限检查分开 | 最新源码已核对，最终版本运行结果留待填写 |

---

## 四、实验内容与实现

### 4.1 功能模块一：虚拟内存页操作

**负责人：** 2413576-林泽森。

代码主要位于 [pmm.c](../code/kern/mm/pmm.c)，相关接口位于 [pmm.h](../code/kern/mm/pmm.h)。本部分在现有 Sv39 页表框架上，实现普通 4 KiB 数据页映射的建立、更新和撤销。

**Spec：**

```text
1. page_insert(pgdir, page, la, perm)：
   定位最终 PTE，必要时申请下级页表；失败返回 -E_NO_MEM。
   新建映射时增加目标数据页引用。
   同页同地址重复插入时引用计数不变，但必须更新权限。
   替换其他物理页时撤销旧引用，旧页引用为零时回收。
   写入新 PTE 后刷新对应地址的 TLB。
2. page_remove(pgdir, la)：
   只查找已有 PTE，不申请页表；不存在有效映射时返回。
   删除有效映射时清除 PTE、刷新 TLB，并减少物理页引用。
   支持重复删除，不重复减引用或释放物理页。
3. get_pte()：
   若本次新建第一张下级页表后，第二张申请失败，
   恢复原根页表项，回收本次新建的空表；保留原有页表。
   非叶项仅设置必要的有效位；页表结构更新后全量刷新 TLB。
4. 保留原有框架注释、接口和检查逻辑，按当前 RV64 环境进行必要适配。
```

**Prompt：**

```text
以 lab4/OS/code 中已经合入 Lab3 成果的工程为基础，阅读 Lab4 指导书，
逐步指导实现 page_insert()、page_remove()，不要直接修改源码。
保留原有注释和框架，解释引用计数、同页重复映射、旧映射替换、
重复删除和 TLB 刷新的处理顺序。
检查 get_pte() 两级申请过程的失败回滚，以及非叶页表项的合法标志。
核对当前文件中的修改，指出具体位置和修改范围。
```

#### 4.1.1 物理页初始化与 Best-Fit 依赖

`page_init()` 沿用此前实现：先设置 `va_pa_offset`，从 DTB 获取物理内存范围，再按页对齐安排 `Page` 描述符数组。描述符数组位于内核映像末尾之后，需要显式初始化，不能仅依赖 BSS 清零。

其中 `npage` 表示物理内存末端的绝对页号，`pages[0]` 对应 `DRAM_BASE`。因此描述符数量为 `npage - nbase`。计算描述符数组实际占用的物理地址时使用 `PADDR(pages)`，而 `page2pa(pages)` 表示第一个描述符所描述的物理页地址，两者用途不同。

空闲内存从描述符数组末端向上按页对齐后开始，通过 `init_memmap()` 注册给物理页管理器。当前 `struct Page` 的空间使用 `sizeof(struct Page)` 计算，可以覆盖 Lab4 新增字段带来的大小变化。

Best-Fit 保留在 [best_fit_pmm.c](../code/kern/mm/best_fit_pmm.c) 中，选择条件为：

```c
if (p->property >= n &&
    (page == NULL || p->property < page->property)) {
    page = p;
}
```

分配时扫描空闲块，选择满足页数要求且大小最小的块；分割后将剩余部分插回原位置。空闲链表按地址排列，释放时依次检查低地址和高地址相邻块并合并。`alloc_pages()`、`free_pages()`、`nr_free_pages()` 的中断保护包装继续保留。

#### 4.1.2 page_remove_pte、page_remove 与 page_insert

**实现：**

以下代码摘自当前文件，保留其注释：

```c
static void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep)
{
    /* 无有效映射时，不修改引用计数。 */
    if (!(*ptep & PTE_V)) {
        return;
    }

    struct Page *page = pte2page(*ptep);

    /* 先撤销映射、刷新 TLB，再允许物理页被重新使用。 */
    *ptep = 0;
    tlb_invalidate(pgdir, la);

    if (page_ref_dec(page) == 0) {
        free_page(page);
    }
}

// get_pte第三个参数为0表示只查找 -lzs
void
page_remove(pde_t *pgdir, uintptr_t la)
{
    pte_t *ptep = get_pte(pgdir, la, 0);

    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep);
    }
}

// 实现page_insert -lzs
int
page_insert(pde_t *pgdir, struct Page *page,
            uintptr_t la, uint32_t perm)
{
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }

    page_ref_inc(page);

    if (*ptep & PTE_V) {
        struct Page *old_page = pte2page(*ptep);

        if (old_page == page) {
            /* 同页同地址重复映射，抵消刚才增加的引用。 */
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }

    *ptep = pte_create(page2ppn(page), perm | PTE_V);
    tlb_invalidate(pgdir, la);

    return 0;
}
```

**说明：**

`page_remove_pte()` 先检查 `PTE_V`。只有有效映射才需要取得原物理页、清零 PTE、刷新翻译并减少引用。先撤销映射和刷新 TLB，再允许物理页被分配器重新使用，可以避免旧翻译继续访问已经回收的页。

`page_remove()` 使用 `get_pte(pgdir, la, 0)`。最后一个参数为 0，因此删除一个不存在的映射不会额外申请页表；重复删除也不会再次减少引用计数。

`page_insert()` 在成功取得 PTE 后才增加目标页引用。若旧映射已经指向同一物理页，抵消本次增加的引用，并继续写入新权限；若旧映射指向其他页，则调用辅助函数清理旧映射。新 PTE 根据本次 `perm` 重建，避免旧权限残留。

本接口中的数据页由调用者提供；若申请下级页表失败，`page_insert()` 返回错误，目标数据页的引用保持不变，其后续处理由调用者负责。

#### 4.1.3 get_pte 的两级分配与失败回滚

**实现：**

```c
// get_pte - get pte and return the kernel virtual address of this pte for la
//        - if the PT contians this pte didn't exist, alloc a page for PT
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
    // 补上 get_pte() 的分配失败回滚 -lzs
    pde_t saved_pdep1 = *pdep1;
    struct Page *new_middle = NULL;
    if (!(*pdep1 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        // 补上 get_pte() 的分配失败回滚 -lzs
        new_middle = page;
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        // 指向下级页表属于非叶项，U位为0 -lzs
        *pdep1 = ptd_create(page2ppn(page));
        // 全量刷新 -lzs
        flush_tlb();
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        // 修改第二个分配分支中的失败处理 -lzs
        if (!create || (page = alloc_page()) == NULL) {
            if (new_middle != NULL) {
                *pdep1 = saved_pdep1;
                flush_tlb();

                set_page_ref(new_middle, 0);
                free_page(new_middle);
            }
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        // 指向下级页表属于非叶项，U位为0 -lzs
        *pdep0 = ptd_create(page2ppn(page));
        // 全量刷新 -lzs
        flush_tlb();
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

`saved_pdep1` 保存调用前的根项内容，`new_middle` 仅记录本次调用新建的第一张下级页表。如果第二次申请失败，先恢复根项并全量刷新，再将新表引用置零、交回分配器。若第一张下级表原本就存在，`new_middle` 为 `NULL`，失败路径不会回收它。

两处 `memset()` 清零新页表，防止旧内存内容被识别成有效 PTE。这里设置的引用属于页表页；目标数据页的映射引用仍由 `page_insert()` 维护。

#### 4.1.4 TLB 刷新与编译器约束

**实现：**

```c
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    // 完善 TLB 刷新的编译器约束 -lzs
    asm volatile("sfence.vma %0, zero"
             :
             : "r"(la)
             : "memory");
}
```

`tlb_invalidate()` 通过 `la` 操作数请求对应虚拟页的翻译失效，两个页操作接口在更新最终 PTE 后调用它。当前实现没有根据 `pgdir` 判断是否为活动页表，保留原骨架的调用方式。

`get_pte()` 更新指向下级表的非叶项，或者在失败路径恢复根项时，调用 `flush_tlb()`：

```c
static inline void flush_tlb(void) {
    asm volatile("sfence.vma" ::: "memory");
}
```

两处下级表创建后的 `flush_tlb()` 都是全量刷新，与 `pdep1`、`pdep0` 所处层级不同无关。这里的全量范围为当前 hart 的地址翻译缓存。`sfence.vma` 负责地址翻译同步，`"memory"` 约束编译器对相关内存操作的重排。

#### 4.1.5 非叶项权限与自检断言修正

原骨架在两处非叶项中设置 `PTE_U | PTE_V`。对照 RISC-V 规范，非叶项的 `U`、`A`、`D` 位应清零，因此改用现有 `ptd_create(page2ppn(page))`，仅设置必要的有效位。

自检中同时保留最终 PTE 的用户、写权限检查，并将根非叶项的检查修改为：

```c
assert(*ptep & PTE_U);
assert(*ptep & PTE_W);
assert(boot_pgdir_va[0] & PTE_V);
assert((boot_pgdir_va[0] &
    (PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D)) == 0);
assert(page_ref(p2) == 1);
```

最终映射项的 `PTE_U` 仍由调用者传入的 `perm` 决定。非叶项只负责指向下级页表，不能把最终映射的用户权限设置规则直接用于它。

这项修正依据规范与静态检查完成，尚未将其认定为此前临时启动异常的已证实根因。

#### 4.1.6 预期行为

| 场景 | 预期结果 |
|------|----------|
| 在新地址建立映射 | 目标数据页引用加 1，PTE 指向目标页并具有指定权限 |
| 同页同地址重复插入 | 引用计数不变，权限按本次参数更新 |
| 同页映射到第二个地址 | 增加一条映射引用 |
| 新页替换旧页 | 新页加引用，旧页减引用；旧页引用为零时释放 |
| 删除有效映射 | PTE 清零，旧页减引用，相关翻译失效 |
| 删除未映射地址或重复删除 | 不申请页表，不重复减引用或释放 |
| 第一张下级表申请失败 | 返回 `-E_NO_MEM`，原映射和数据页引用不变 |
| 新建第一张表后第二次申请失败 | 恢复原根项，回收本次新建空表，数据页引用不变 |

---

### 4.2 功能模块二：进程创建及初始化

**负责人：** 2413073-唐涵城。

**Spec**

在 RISC-V 内核中实现 `alloc_proc()`、`copy_thread()`、`copy_mm()`、`do_fork()`、`kernel_thread()` 和 `proc_init()`。为新内核线程准备独立的 PCB、内核栈和初始寄存器现场，共用启动页表。资源准备完成后分配 PID、登记线程并置为可运行。启动时用 `idleproc` 表示已有的执行流，再创建等待调度的 `initproc`。 [proc.c](../code/kern/process/proc.c)

**Prompt（根据实现整理）**

> 请结合现有的进程链表、PID 散列表和 RISC-V 陷阱返回代码，实现内核线程创建和进程管理初始化。说明新线程的栈、`context` 和 `trapframe` 如何设置，首次调度后如何进入指定函数，以及创建失败时如何回收已经申请的资源。

**实现**

1. **初始化 PCB 和启动线程。** `alloc_proc()` 用 `kmalloc()` 分配 PCB 并整体清零，设置 `state = PROC_UNINIT`、`pid = -1`、`pgdir = boot_pgdir_pa`，再初始化进程链表和散列表所用的两个节点。内核线程的 `mm` 初始为 `NULL`。 `proc_init()` 初始化全局进程链表和各散列桶，将正在运行的启动执行流设为 `current = idleproc`。其 PID 为 0，沿用 `bootstack`，状态为 `PROC_RUNNABLE`，并通过 `need_resched = 1` 请求首次调度。随后调用 `kernel_thread(init_main, "Hello world!!", 0)`，根据返回的 PID 找到 `initproc`，命名为 `init` 并断言其 PID 为 1。
2. **准备并登记新线程。** `do_fork()` 先检查进程数量上限，再分配 PCB、记录父进程 `current`，并通过 `setup_kstack()` 申请 `KSTACKPAGE` 个连续页作为内核栈。本实验中 `KSTACKPAGE = 2`，每个新线程的栈为 8 KiB。 `copy_mm()` 断言父线程的 `mm == NULL`，子线程沿用 PCB 中初始化的 `mm` 和 `pgdir`。完成 `copy_thread()` 后，临时关闭本地中断，依次分配 PID、加入 `proc_list` 和 PID 散列表、递增 `nr_process`。恢复原中断状态后调用 `wakeup_proc()`，将线程由 `PROC_UNINIT` 置为 `PROC_RUNNABLE`，并向调用者返回新线程的 PID。 [proc.c](../code/kern/process/proc.c) · [memlayout.h](../code/kern/mm/memlayout.h) · [sched.c](../code/kern/schedule/sched.c)
3. **构造首次执行现场。** `kernel_thread()` 将入口函数 `fn` 和参数 `arg` 分别写入临时陷阱帧的 `s0`、`s1`，将 `epc` 指向 `kernel_thread_entry`，再以 `clone_flags | CLONE_VM` 和栈参数 0 调用 `do_fork()`。初始 `sstatus` 设置 `SPP`、`SPIE` 并清除 `SIE`，使恢复现场期间保持关中断，执行 `sret` 后进入 S 态并开启 S 态全局中断。 [RISC-V 特权架构规范](https://github.com/riscv/riscv-isa-manual/blob/main/src/priv/supervisor.adoc#supervisor-status-sstatus-register)

`copy_thread()` 将临时陷阱帧复制到新线程自己的内核栈，并构造供 `switch_to()` 恢复的调度上下文。关键代码如下。

```c
proc->tf = (struct trapframe *)
    (proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
*(proc->tf) = *tf;
proc->tf->gpr.a0 = 0;
proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
proc->context.ra = (uintptr_t)forkret;
proc->context.sp = (uintptr_t)proc->tf;
```

`context.ra`、`context.sp` 决定第一次切换时的返回地址和栈指针。 `switch_to()` 恢复上下文后通过 `ret` 进入 `forkret()`，后者将 `current->tf` 交给 `forkrets`，复用 `__trapret` 恢复通用寄存器、`sstatus` 和 `sepc`。随后 `sret` 跳到 `kernel_thread_entry`。陷阱帧中的 `a0 = 0` 对应子进程的 fork 返回值约定，内核线程的汇编入口会将 `s1` 搬到 `a0`，再用 `jalr s0` 调用 `fn(arg)`。 [trapentry.S](../code/kern/trap/trapentry.S) · [entry.S](../code/kern/process/entry.S)

**说明与真实问题**

- `kernel_thread()` 的临时陷阱帧位于创建者的栈上，函数返回后该空间可以被覆盖。 `copy_thread()` 在登记线程之前将其完整复制到子线程自己的栈，使首次恢复使用的陷阱帧在随后调度时仍然有效。
- 达到进程数量上限时，`do_fork()` 返回 `-E_NO_FREE_PROC`。PCB 分配失败直接返回 `-E_NO_MEM`，内核栈分配失败则先释放 PCB。 `copy_mm()` 返回错误时，清理路径先释放内核栈，再释放 PCB。这些失败路径均在分配 PID 和登记进程之前。
- 在 QEMU 中运行注入测试，串口输出 `[Test Process Create] PASS` 和 `[Test Schedule] PASS`，并打印了 `initproc` 的 PID、名称和传入参数。测试断言覆盖了启动线程、父子关系和新线程的初始上下文。 `init_main()` 返回后，汇编入口调用当前框架的 `do_exit()`，随后触发 panic。 [test_lab4.c](../code/tools/test_lab4.c) · [proc.c](../code/kern/process/proc.c)

---

### 4.3 功能模块三：进程调度与上下文切换

**负责人：** 2413523-尤祺乐

**Spec：** 需要实现以下函数：

```c
void cpu_idle(void);(kern/process/proc.c)
void schedule(void);(kern/schedule/sched.c)
void proc_run(struct proc_struct *proc);(kern/process/proc.c)
void switch_to(struct context *from, struct context *to);(kern/process/switch.S)
```

其中，`cpu_idle()`函数需要持续等待，当需要重新调度时，调用`schedule()`函数进行进程调度；`schedule()`函数需要从进程链表`proc_list`中按一定策略寻找下一个可运行的线程，并调用`proc_run()`函数以运行该线程；`proc_run()`函数需要切换当前线程与页表，并调用`switch_to()`函数切换上下文；`switch_to()`函数需要保存旧线程的相关寄存器，并加载新线程的相关寄存器。

**Prompt：**

| 函数 | prompt |
| --- | --- |
| `switch_to()` | 请你实现位于kern/process/proc.c声明的void switch_to(struct context *from, struct context *to);函数，这个函数应该定义在kern/process/switch.S，作用是保存from的上下文，包括ra、sp、s0-s11等必要的寄存器，然后恢复to的上下文。为了支持不同位数，请考虑使用libs/riscv.h中定义的LOAD STORE REGBYTES等宏编写 |
| `proc_run()` | 请你在kern/process/proc.c的末尾实现void proc_run(struct proc_struct *proc);函数，这个函数的作用是将进程从current切换到proc，需要更新current，切换页表并调用switch_to()函数更新上下文，并使用local_intr_save()与local_intr_restore()宏在关键区域打断中断，注意libs/riscv.h中的lsatp()是Sv32遗留，无法表达Sv39的satp，请参考kern/mm/pmm.c中的enable_paging()的写法，可以使用SATP_MODE_SV39宏 |
| `schedule()` | 请你在kern/schedule/sched.c的末尾实现函数void schedule(void);该函数应该首先令current->need_resched为0，然后在proc_list链表中查找下一个处于PROC_RUNNABLE状态的线程或进程，查找策略如下：“1、当前是idleproc，从链表头开始查找；2、当前不是idleproc，从当前进程的下一个位置开始查找”。如果找到了这样的进程，调用proc_run()以切换到对应进程，如果没有这样的进程则回到idleproc进程。需要用local_intr_save()与local_intr_restore()宏在关键区域打断中断 |
| `cpu_idle()` | 请你在kern/process/proc.c实现void cpu_idle(void);函数，该函数作为空闲线程的执行主体应该持续等待调度需求，当need_resched == 1时，调用schedule()函数进行调度 |

**实现：**

**`switch_to()`：**

```asm
//LAB4 function3 2413523

#include <riscv.h>

/*
 * void switch_to(struct context *from, struct context *to);
 *
 * a0 = from, a1 = to
 *
 * struct context 的布局（见 proc.h）：
 *   ra, sp, s0, s1, ..., s11   （共 14 个字段）
 *
 * 使用 riscv.h 中的 STORE/LOAD/REGBYTES 宏，
 * 因此同一份代码同时适用于 RV32 和 RV64。
 *
 * switch_to 不通过普通函数调用返回：它保存当前线程的 callee-saved
 * 寄存器到 from，再从 to 恢复这些寄存器，最后 ret 跳到 to->ra。
 * 一个新线程首次被调度时，to->ra 指向 forkret，to->sp 指向它的 trapframe。
 */
    .text
    .globl switch_to
    .align 2
switch_to:
    # ---- 保存 from 的上下文 ----
    STORE ra,  0*REGBYTES(a0)
    STORE sp,  1*REGBYTES(a0)
    STORE s0,  2*REGBYTES(a0)
    STORE s1,  3*REGBYTES(a0)
    STORE s2,  4*REGBYTES(a0)
    STORE s3,  5*REGBYTES(a0)
    STORE s4,  6*REGBYTES(a0)
    STORE s5,  7*REGBYTES(a0)
    STORE s6,  8*REGBYTES(a0)
    STORE s7,  9*REGBYTES(a0)
    STORE s8, 10*REGBYTES(a0)
    STORE s9, 11*REGBYTES(a0)
    STORE s10, 12*REGBYTES(a0)
    STORE s11, 13*REGBYTES(a0)

    # ---- 恢复 to 的上下文 ----
    LOAD ra,  0*REGBYTES(a1)
    LOAD sp,  1*REGBYTES(a1)
    LOAD s0,  2*REGBYTES(a1)
    LOAD s1,  3*REGBYTES(a1)
    LOAD s2,  4*REGBYTES(a1)
    LOAD s3,  5*REGBYTES(a1)
    LOAD s4,  6*REGBYTES(a1)
    LOAD s5,  7*REGBYTES(a1)
    LOAD s6,  8*REGBYTES(a1)
    LOAD s7,  9*REGBYTES(a1)
    LOAD s8, 10*REGBYTES(a1)
    LOAD s9, 11*REGBYTES(a1)
    LOAD s10, 12*REGBYTES(a1)
    LOAD s11, 13*REGBYTES(a1)

    # 转到 to 上次切出时的返回地址（新线程为 forkret）
    ret
```

**`proc_run()`：**

```c
// proc_run - 把 CPU 从当前进程切换到 proc 进程上运行
//   1. 更新 current 指针
//   2. 切换页表（写 satp）
//   3. 调用 switch_to 保存旧上下文、恢复新上下文
// 整个过程在关中断的状态下完成
void proc_run(struct proc_struct *proc){
    if (proc == current) return;

    bool intr_flag;
    struct proc_struct *prev = current, *next = proc;

    local_intr_save(intr_flag);
    {
        current = proc;

        // 切换页表。next->pgdir 中保存的是页目录的物理地址。
        // 注意：这里不能使用 riscv.h 中的 lsatp()，它是 Sv32 的遗留写法，
        // 无法表达 Sv39 的 satp；因此参照 pmm.c 中 enable_paging() 的做法，
        // 用 SATP_MODE_SV39（8）构造 satp 的 MODE 字段（位于最高位）。
        write_csr(satp, ((uint64_t)SATP_MODE_SV39 << 60) |
                        (next->pgdir >> RISCV_PGSHIFT));
        flush_tlb(); // 写 satp 不会自动刷新 TLB，需显式 sfence.vma

        switch_to(&(prev->context), &(next->context));
    }
    local_intr_restore(intr_flag);
}
```

**`schedule()`：**

```c
// schedule - 从 proc_list 中挑选一个 PROC_RUNNABLE 的进程投入运行
//   1. 当前是 idleproc：从链表头开始查找
//   2. 当前不是 idleproc：从当前进程的下一个位置开始查找（可回绕）
//   找不到可运行进程时，回到 idleproc
void schedule(void){
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;

    local_intr_save(intr_flag);
    {
        current->need_resched = 0;

        // 查找起点：idleproc 从链表头开始；否则从当前进程的下一个位置开始
        last = (current == idleproc) ? &proc_list : &(current->list_link);
        le = last;
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
                    break;
                }
            }
        } while (le != last);

        // 没有找到可运行进程，则回到 idleproc
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc;
        }

        next->runs++;
        if (next != current) {
            proc_run(next);
        }
    }
    local_intr_restore(intr_flag);
}
```

**`cpu_idle()`:**

```c
// cpu_idle - idle 线程的执行主体
// 循环检查当前进程是否被要求重新调度，若有则调用 schedule() 切换出去；
// 没有可运行进程时 schedule() 会选回 idleproc，从而回到这里继续等待。
void cpu_idle(void){
    while (1) {
        if (current->need_resched) {
            schedule();
        }
    }
}
```

---

### 4.4 Challenge 1：中断保存与恢复

**负责人：** 2413523-尤祺乐

**分析：** `local_intr_save(x)`宏可以视作`x = __intr_save();`，外层的循环只是一种常见的宏编写技巧，使得宏可以被视作一个语句块。宏的作用就是调用`__intr_save()`函数，该函数检查`sstatus`的`SIE`位。如果`SIE`位为1，说明中断打开，则调用`intr_disable()`清除`SIE`位，并返回1；反之，则中断已经关闭，返回0。函数的返回值会赋给宏的参数，作为调用宏之前中断的开关标记。总而言之，`local_intr_save(x)`宏的作用是通过修改`SIE`位以确保中断是关闭的，并返回调用宏前中断的开关情况，调用者需要记录这一标记并维护。

`local_intr_restore(x)`宏可以视作`__intr_restore(x);`。宏的作用就是调用`__intr_restore()`函数，该函数接受此前由调用者维护的标记作为参数，如果标记为0，说明在尝试关闭中断之前中断已经关闭，无需恢复，直接返回；反之，则说明尝试关闭中断之前中断是打开状态，则调用`intr_enable()`函数，通过写入`SIE`位打开中断以恢复中断原有的状态。总而言之，`local_intr_restore(x)`宏的作用是将中断开关情况恢复到调用`local_intr_save(x)`宏之前。

一段代码块需要临时关闭中断时，只需声明一个`bool`变量作为标记，并在代码块前调用`local_intr_save(x)`宏，代码块后调用`local_intr_restore(x)`宏即可。

---

### 4.5 Challenge 2 第一问：分页模式与两段相似代码

**负责人：** 2413576-林泽森。

**Spec：** 比较 Sv32、Sv39、Sv48，并结合当前 `get_pte()` 的页表遍历过程，解释两段相似代码分别处理什么，以及它们相似的原因。

**Prompt：**

```text
结合当前 Sv39 的 get_pte() 实现，比较 Sv32、Sv39、Sv48 的级数、
索引位数、页表项大小和基本页大小；说明两段相似代码各自负责进入哪一层，
并区分页表页的分配与目标数据页映射的建立。
```

**分析：**

| 比较项 | Sv32 | Sv39 | Sv48 |
|--------|------|------|------|
| 适用架构 | RV32 | RV64 | RV64 |
| 有效虚拟地址位数 | 32 | 39 | 48 |
| 页表级数 | 2 | 3 | 4 |
| 每级索引位数 | 10 | 9 | 9 |
| PTE 大小 | 4 字节 | 8 字节 | 8 字节 |
| 每张页表项数 | 1024 | 512 | 512 |
| 基本页大小 | 4 KiB | 4 KiB | 4 KiB |
| 地址拆分 | `10 + 10 + 12` | `9 + 9 + 9 + 12` | `9 + 9 + 9 + 9 + 12` |

Sv39 和 Sv48 的地址由 64 位寄存器承载，高位分别需要符合第 38 位和第 47 位的符号扩展要求。页表级数增加可以扩展虚拟地址空间，同时增加页表遍历和页表存储的潜在开销。

一张页表占一页。Sv32 每项 4 字节，因此一页可以放 `4096 / 4 = 1024` 项，每级需要 10 位索引；Sv39、Sv48 每项 8 字节，因此一页可以放 `4096 / 8 = 512` 项，每级需要 9 位索引。

当前代码中，三个索引与地址字段的对应关系为：

```text
根页表 L2
  -> PDX1(la) = VPN[2]，地址位 38:30
     第一段代码：必要时申请并建立 L1 页表
  -> PDX0(la) = VPN[1]，地址位 29:21
     第二段代码：必要时申请并建立 L0 页表
  -> PTX(la) = VPN[0]，地址位 20:12
     返回 L0 中最终 PTE 的地址
```

两段代码执行相同的步骤：检查当前项是否有效；若无效且允许创建，则申请一页作为下级页表，设置页表页引用、清零内容，将该页的物理页号写入上级项，再继续向下一层查找。它们处理的层级和使用的索引不同，但每层页表都采用相同的组织方式，因此代码形式相似。

对于普通 4 KiB 页映射，在根页表已存在的前提下，Sv32 需要进入一层下级表，Sv39 需要两层，Sv48 需要三层，因此当前 Sv39 实现中出现两段相似代码。若使用上级叶项表示大页，页表遍历会提前终止；本题解释的是当前函数使用的普通 4 KiB 路径。

`get_pte()` 申请的是页表页，返回最终 PTE 的地址；它并不分配目标数据页。目标数据页由 `page_insert()` 的调用者提供，映射引用由 `page_insert()` 增加。这也解释了为什么 `get_pte()` 中的 `set_page_ref(page, 1)` 与 `page_insert()` 中的数据页引用增减属于不同对象。

---

### 4.6 Challenge 2 第二问：查找与分配是否拆分

**负责人：** 2413073-唐涵城。

**分析**

在本实验中，我倾向于保留 `get_pte(pgdir, la, create)` 的统一实现。查找和创建都要沿 Sv39 的三级页表逐层定位。 `create = 0` 时，`get_page()` 和 `page_remove()` 只沿现有路径查找，缺少下级表就返回 `NULL`。如果下级表齐全，函数会返回末级 PTE 的地址，该项是否形成有效映射仍需检查 `PTE_V`。 `page_insert()` 传入 `create = 1`，遇到缺失的下级表时就地分配并继续遍历。最终的数据页映射由 `page_insert()` 写入。 [pmm.c](../code/kern/mm/pmm.c)

统一实现只需走一遍页表，并且可以在同一次调用中处理创建失败。例如，本次新建 L1 页表后若申请 L0 页表失败，`get_pte()` 会恢复原根项，刷新地址翻译缓存，再回收本次新建的 L1 页表。 `page_insert()` 此时返回 `-E_NO_MEM`，也还未增加目标数据页的引用计数。如果拆成“先查找，失败后从根重新遍历并分配”两个步骤，缺表路径会重复走过已有的上层页表。

拆分的价值主要在接口层。调用点增多时，可以用 `lookup_pte()` 表达只读查找，用 `ensure_pte()` 明确表示这次调用可能分配内存并修改页表。两个入口仍可复用同一套逐级遍历，创建入口负责分配及回滚。这样既能从调用处看出是否有副作用，也能集中维护索引计算、下级页表初始化和失败处理。就当前调用规模而言，现有的 `create` 参数已经足以表达这两种用途。

---

## 五、测试与验证

### 5.1 源码静态核对

| 检查项 | 当前核对结果 |
|--------|--------------|
| 引用计数 | 首次映射增加引用；同页同地址插入抵消新增引用；撤销有效映射时减少引用 |
| 删除的幂等性 | `get_pte(..., 0)` 不创建页表；辅助函数检查有效位 |
| 替换映射与权限 | 清理旧映射后重建 PTE，权限使用本次 `perm` |
| 失败清理 | 记录原根项和本次新建页表，第二次申请失败时回滚 |
| 非叶项合法性 | 两处使用 `ptd_create()`；自检区分最终 PTE 权限与非叶项保留位 |
| TLB 调用 | 最终 PTE 更新后按地址失效；下级页表建立或回滚后全量刷新 |
| 线程登记 | PCB、内核栈和初始现场准备完毕后，在本地关中断区间内分配 PID 并登记，随后置为可运行 |
| 首次调度 | `context.ra` 指向 `forkret`，`context.sp` 指向新线程栈上的陷阱帧，`sret` 进入 `kernel_thread_entry` |
| 后续切换 | `switch_to()` 按 `struct context` 的字段顺序保存和恢复 `ra`、`sp` 及 `s0`–`s11` |
| 注释与练习标记 | 原框架注释已保留，当前仍保留 `LAB4 function1 YOUR CODE` 标记 |
| 差异格式 | `git diff --check` 未报告空白格式问题 |

### 5.2 最终版本编译

在当前源码的独立副本中，使用 `riscv64-unknown-elf-gcc` 15.1.0，从 `code/` 目录执行 `make -j4`。编译和链接成功，生成 ELF 文件 `bin/kernel`，再经 `objcopy` 生成 QEMU 启动镜像 `bin/ucore.img`。 [Makefile](../code/Makefile)

注入评分测试后，镜像同样构建成功。编译器对 `test_lab4_thread()` 报出 `-Wreturn-type` 警告。该测试线程声明为 `int`，其末尾在循环中持续调用 `schedule()`。

### 5.3 内存模块运行测试

启动时，`check_alloc_page()`、`check_pgdir()` 和 `check_boot_pgdir()` 均通过。其中，`check_pgdir()` 核对了目标物理页、引用计数及页表项标志。 `check_boot_pgdir()` 将同一物理页映射到两个虚拟地址，并验证从其中一个地址写入的内容可以从另一个地址读到。 [pmm.c](../code/kern/mm/pmm.c)

注入的 `test_lab4_pmm_basic()` 检查了新建映射、替换旧页后的权限和引用计数、重复映射同一页以及重复删除。QEMU 串口输出 `[Test PMM] PASS`。 [test_lab4.c](../code/tools/test_lab4.c)

在临时副本中另建一张空根页表，分别令第一次和第二次下级页表页申请失败。两次调用 `page_insert()` 均返回 `-E_NO_MEM`。测试断言根项、目标数据页引用和空闲页数与调用前一致，并确认查不到该地址的末级 PTE。第二种情况验证了新建 L1 页表后申请 L0 页表失败时的回滚。

### 5.4 进程创建与失败清理验证

`test_lab4_process_create()` 在 `proc_init()` 结束时检查 `current == idleproc`、PID 0 和启动栈 `bootstack`，以及 `initproc` 的 PID 1、就绪态、父进程关系和非零初始上下文入口与栈指针。两者的 `mm` 均为 `NULL`。QEMU 串口输出 `[Test Process Create] PASS`。 [test_lab4.c](../code/tools/test_lab4.c)

在同一份故障注入构建中，分别设置进程数上限和三个失败点，逐项核对返回值、释放调用次数、空闲页数、进程计数、链表首尾和 PID 查询结果。四个场景均通过。

| 场景 | 返回值 | 回收结果 |
|------|--------|----------|
| 进程数达到 `MAX_PROCESS` | `-E_NO_FREE_PROC` | 在分配资源前返回 |
| PCB 分配失败 | `-E_NO_MEM` | 在申请内核栈前返回 |
| 内核栈分配失败 | `-E_NO_MEM` | 调用 `kfree()` 释放已分配的 PCB |
| 强制 `copy_mm()` 返回错误 | `-E_NO_MEM` | 调用 `put_kstack()` 回收栈页，再调用 `kfree()` 释放 PCB |

正式实现的 `copy_mm()` 在父线程的 `mm == NULL` 时直接返回成功。表中最后一项通过故障注入验证 `do_fork()` 的清理路径。 [proc.c](../code/kern/process/proc.c)

### 5.5 多线程调度与上下文切换验证

`test_lab4_schedule()` 在 `init_main()` 入口创建两个测试线程，向同一个入口函数传入不同的参数。两个线程记录各自的执行标志，并主动调用 `schedule()` 让出 CPU。`initproc` 多次发起调度后恢复执行，断言两个标志均已置位。该用例验证了新线程从初始现场进入指定函数、参数传递以及发起调度的线程恢复执行。日志中的 `[Test Schedule] PASS` 与后续 `init_main()` 的输出见 5.7。 [test_lab4.c](../code/tools/test_lab4.c) · [switch.S](../code/kern/process/switch.S)

### 5.6 官方评分与完整回归

原有 `make grade` 评分记录如下。

```text
  -check PMM:                                OK
  -check Process Create:                     OK
  -check Schedule:                           OK
Total Score: 30/30
```

复核环境限制了 QEMU 的 GDB TCP 监听，评分脚本在此环境中未能采集串口输出。复核时使用仓库的 `tools/inject.py` 在源码副本中注入同一组测试，构建后由 QEMU 7.0.0 直接启动镜像。串口输出包含三个 `PASS` 标记及评分脚本检查的三条 `init_main()` 消息。 [inject.py](../code/tools/inject.py) · [grade.sh](../code/tools/grade.sh)

### 5.7 串口日志

```text
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
[Test PMM] PASS
check_vma_struct() succeeded!
check_vmm() succeeded.
[Test Process Create] PASS
++ setup timer interrupts
[Test Schedule] PASS
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:209:
    process exit!!.
```

三项测试输出完成后，`init_main()` 返回，`kernel_thread_entry` 调用当前框架中仍以 panic 实现的 `do_exit()`，内核随后进入调试监视器。 [entry.S](../code/kern/process/entry.S) · [proc.c](../code/kern/process/proc.c)

---

## 六、实验总结与收获

### 6.1 分工总结

**林泽森：** 本部分完成了物理内存依赖核对、`page_insert()`、`page_remove()` 及其辅助函数，并补充下级页表申请失败时的回滚。实现过程中重点区分了数据页和页表页的引用，理解了同页同地址重复映射应保持引用不变但仍需更新权限，以及删除操作不应创建页表。通过对照 Sv39 规范，进一步区分了最终映射项的权限位与非叶项的保留位，并认识到源码静态检查、编译成功和实际运行验证是不同层次的结论。

**唐涵城：** 完成了 PCB 初始化、内核线程创建和 `idleproc`、`initproc` 的初始化。通过跟踪首次调度，理解了 `context` 提供切换入口，而 `trapframe` 提供执行线程函数所需的寄存器现场。将 PID 分配和登记放在资源准备之后，使创建失败时可以按已取得的资源逐步回收。结合 Challenge 2 第二问，分析了页表查找和分配共用遍历逻辑的利弊。

**尤祺乐：** 本部分完成了进程调度的功能，结合进程链表和实验中的轮转策略，理解了调度器如何选择下一个可运行线程。通过实现 `proc_run()` 和 `switch_to()`，掌握了更新 `current`、装载 Sv39 页表和恢复寄存器的顺序。Challenge 1 中的中断保存与恢复也用于保护调度和切换的关键区域。

### 6.2 主要问题与解决

| 问题 | 现象或发现方式 | 处理 |
|------|----------------|------|
| 合入骨架后存在两套同名接口来源 | 目录对比发现旧 `libs/readline.c` 与新实现并存，旧 `libs/sbi.c` 与新内联头文件并存 | 在构建中选择 Lab4 的实现，排除旧源码，保留历史文件作参考 |
| GCC 15 的地址类型检查 | 框架 `kmalloc.c` 将整数地址直接传给接收指针的 `kva2page()`，编译报类型转换错误 | 显式转换为 `(void *)kva`，保持接口不变 |
| 测试回调返回类型不一致 | 框架线程测试回调为 `void (*)(void *)`，与 `kernel_thread()` 所需类型不一致 | 只将测试回调声明改为 `int` 返回类型，测试断言保持不变 |
| 回滚函数名拼写错误 | 曾将 `flush_tlb()` 写成 `lush_tlb()`，GCC 报隐式函数声明错误 | 对照函数定义修正拼写 |
| 初次指导沿用了骨架非叶项的 `PTE_U` | 后续规范核对发现非叶项保留位要求未落实 | 两处改用 `ptd_create()`，保留创建和回滚后的全量刷新 |
| 修改自检时遗留冲突断言 | 非叶项清零保留位后，旧的根项 `PTE_U=1` 断言仍保留；最终 PTE 的用户权限检查一度遗漏 | 分开检查最终 PTE 的 `U/W` 与根非叶项的 `V` 和保留位，移除矛盾断言 |
| 合并时遗漏或缩写框架注释 | 初始化调用旁说明和 `pmm_init()` 完整说明未原样保留 | 逐项按原文补回，保留说明细节，不改变代码逻辑 |
| 新线程需要可恢复的初始现场 | 首次调度前尚无通过 `switch_to()` 保存的现场 | 令初始 `context.ra` 指向 `forkret`，同时在新栈上构造陷阱帧，复用 `sret` 路径进入线程入口 |
| 进程切换时的 Sv39 页表装载 | 旧 `lsatp()` 封装使用 Sv32 的编码方式 | 按 Sv39 的 `MODE` 和根页表物理页号构造 `satp`，写入后执行 `sfence.vma` |

### 6.3 本部分知识点与 OS 原理的对应

| 实验知识点 | 对应的 OS 原理 | 本实验中的体现 |
|------------|----------------|----------------|
| 多级页表 | 分层组织虚拟地址到物理地址的映射，按需建立稀疏结构 | `get_pte()` 按三个索引查找，必要时分配下级表 |
| 引用计数 | 通过引用关系管理共享资源的生命周期 | 多个映射可指向同一数据页，最后一条映射撤销后回收 |
| 地址翻译缓存一致性 | 修改内存中的页表不能自动替代翻译缓存同步 | PTE 更新后执行 `sfence.vma` |
| 资源分配失败清理 | 多阶段操作失败后回到一致状态 | 下级页表分配失败时回收本次新建的空表，线程创建失败时按已取得的资源回收内核栈和 PCB |
| 页表项权限与类型 | 映射权限和页表结构信息需要按项的类型解释 | 最终 PTE 使用调用者权限，非叶项清零 `U/A/D` 保留位 |
| 进程控制块 | 内核用 PCB 统一保存线程身份、状态和资源信息 | `proc_struct` 记录 PID、父进程、内核栈、页表和调度上下文 |
| 上下文切换与陷阱返回 | 调度点的保存和恢复遵循调用约定，陷阱返回恢复指令地址及特权状态 | `switch_to()` 恢复调度上下文，新线程通过 `forkret()` 与 `sret` 恢复初始现场 |
| 调度策略与空闲线程 | 调度器选择就绪线程，空闲线程承接无任务可运行时的执行流 | 从当前线程之后循环查找 `PROC_RUNNABLE`，找不到时选择 `idleproc` |
| 中断保护 | 临时屏蔽本地中断，避免当前 hart 的中断处理打断关键操作 | PID 分配、进程登记和上下文切换使用 `local_intr_save()` 与 `local_intr_restore()` |

### 6.4 尚未涉及的重要 OS 原理知识点

- **用户进程与地址空间隔离。** 本实验的内核线程共享启动页表。独立用户地址空间的建立、程序装载和系统调用属于后续阶段。 [proc.c](../code/kern/process/proc.c)
- **退出、等待与资源回收。** 完整的退出流程还需记录退出状态、唤醒等待的父进程，并回收线程的地址空间、内核栈和 PCB。当前 `do_exit()` 是框架中的占位实现。 [proc.c](../code/kern/process/proc.c)
- **缺页处理与页面置换。** 本实验通过显式调用建立页映射。访问触发的按需分配、页换入和换出需要后续的缺页处理与置换机制。 [pmm.c](../code/kern/mm/pmm.c) · [trap.c](../code/kern/trap/trap.c)
- **时间片抢占。** 调度测试以线程主动调用 `schedule()` 验证切换，时钟中断处理目前负责重设定时器和计数。由时钟驱动的时间片管理和抢占调度属于后续内容。 [trap.c](../code/kern/trap/trap.c) · [test_lab4.c](../code/tools/test_lab4.c)

### 6.5 实验总结

本实验把页映射、内核线程创建和调度接入同一条内核启动路径。内存管理先提供页表、物理页和内核堆，进程管理据此为线程分配内核栈并构造初始现场，调度器再将就绪线程切换到 CPU 上运行。映射变更需要同步更新页表项、数据页引用和翻译缓存。线程进入可运行状态之前，内核栈、初始现场与进程登记都应准备完毕。

启动自检和注入测试验证了映射操作、线程初始化与多线程切换。故障注入覆盖了创建过程中的几个中间状态，验证了部分资源已经申请时，内核仍能正确回滚。

---
