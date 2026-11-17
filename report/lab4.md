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
| 2413073-唐涵城 | |
| 2413523-尤祺乐 | |

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

**负责人：**

**Spec：**

**Prompt：**

**实现：**

**说明与真实问题：**

---

### 4.3 功能模块三：进程调度与上下文切换

**负责人：**

**Spec：**

**Prompt：**

**实现：**

**说明与真实问题：**

---

### 4.4 Challenge 1：中断保存与恢复

**负责人：**

**分析：**

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

**负责人：**

**分析：**

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
| 注释与练习标记 | 原框架注释已保留，当前仍保留 `LAB4 function1 YOUR CODE` 标记 |
| 差异格式 | `git diff --check` 未报告空白格式问题 |

以上为源码检查结论，不替代运行测试。

### 5.2 最终版本编译

### 5.3 内存模块运行测试

### 5.4 进程创建与失败清理验证

### 5.5 多线程调度与上下文切换验证

### 5.6 官方评分与完整回归

### 5.7 日志与截图

---

## 六、实验总结与收获

### 6.1 分工总结

**林泽森：** 本部分完成了物理内存依赖核对、`page_insert()`、`page_remove()` 及其辅助函数，并补充下级页表申请失败时的回滚。实现过程中重点区分了数据页和页表页的引用，理解了同页同地址重复映射应保持引用不变但仍需更新权限，以及删除操作不应创建页表。通过对照 Sv39 规范，进一步区分了最终映射项的权限位与非叶项的保留位，并认识到源码静态检查、编译成功和实际运行验证是不同层次的结论。

**唐涵城：**

**尤祺乐：**

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

上述记录包含源码、编译阶段已发现的问题；不将尚未定位的临时启动异常归因于某一项，也不据此宣称最新版本已经通过完整测试。

### 6.3 本部分知识点与 OS 原理的对应

| 实验知识点 | 对应的 OS 原理 | 本实验中的体现 |
|------------|----------------|----------------|
| 多级页表 | 分层组织虚拟地址到物理地址的映射，按需建立稀疏结构 | `get_pte()` 按三个索引查找，必要时分配下级表 |
| 引用计数 | 通过引用关系管理共享资源的生命周期 | 多个映射可指向同一数据页，最后一条映射撤销后回收 |
| 地址翻译缓存一致性 | 修改内存中的页表不能自动替代翻译缓存同步 | PTE 更新后执行 `sfence.vma` |
| 资源分配失败清理 | 多阶段操作失败后回到一致状态 | 第二次页表申请失败时恢复根项并回收新建空表 |
| 页表项权限与类型 | 映射权限和页表结构信息需要按项的类型解释 | 最终 PTE 使用调用者权限，非叶项清零 `U/A/D` 保留位 |

### 6.4 尚未涉及的重要 OS 原理知识点

### 6.5 实验总结

---
