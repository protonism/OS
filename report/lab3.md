# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 3: 中断与时钟 |
| **小组成员** | 2413073-唐涵城、2413576-林泽森、2413523-尤祺乐 |
| **完成日期** | 2026-11-05 |

### 小组分工

| 成员 | 负责的模块 |
|------|----------------|
| 2413576-林泽森 | Trap 底层：`RESTORE_ALL`、`__alltraps`；第 153 页 stvec 模式编码、四字节对齐与向后兼容扩展思考；验证寄存器恢复、栈恢复、C 函数传参和 Trap 返回，与 C 侧联合验证断点返回 |
| 2413073-唐涵城 | 中断与时钟：`interrupt_handler()`；Lab2 缺失代码迁移；时钟计数、周期输出及关机逻辑；第 171 页 `do { … } while (0)` 思考题；验证时钟持续触发、每次重设事件、计数及关机，检查内存分配接口的中断保护 |
| 2413523-尤祺乐 | 异常与集成：`exception_handler()`；非法指令和断点的输出及 EPC 更新；代码合并与完整回归；验证非法指令返回、配合断点验证、补充 16/32 位断点场景、执行完整评分与兜底分支检查；汇总最终报告 |

---

## 一、实验目的

1. 理解 RISC-V S 模式下的 trap 机制，掌握 `stvec`、`sstatus`、`sepc`、`scause`、`stval` 等 CSR 的作用。
2. 掌握 trapframe 的布局，以及 `SAVE_ALL` / `RESTORE_ALL` 保存和恢复通用寄存器、CSR、栈指针的流程。
3. 实现 `interrupt_handler()`，完成时钟中断计数、每次中断重新设置下一次事件、周期输出和关机。
4. 实现 `exception_handler()`，处理非法指令和断点异常，正确更新 `sepc`，并保留未知异常的兜底输出。
5. 将 Lab2 的 `page_init()`、Best-Fit 分配器和启动适配迁移到 lab3 骨架，保证物理内存管理仍然可用，且分配接口的中断保护不被破坏。
6. 理解 `stvec` 的模式编码与对齐要求，以及 `local_intr_save/restore` 宏使用 `do { … } while (0)` 的原因。

---

## 二、实验环境

### 2.1 软件与代码环境

| 项目 | 内容 |
|------|------|
| 架构 | RISC-V 64（Sv39） |
| 模拟器 | QEMU 7.0.0，`/opt/qemu/bin/qemu-system-riscv64` |
| 固件 | OpenSBI v1.0（QEMU `-bios default`） |
| 交叉编译器 | `riscv64-unknown-elf-gcc` 15.1.0 |
| 汇编器 | GNU binutils 2.45（`riscv64-unknown-elf-as`） |
| 调试器 | `riscv64-unknown-elf-gdb` |
| 编译选项 | `-std=gnu99 -Wall -Werror -O2 -g` |

### 2.2 启动方式适配

lab3 骨架和 lab2 一样，直接使用 `-device loader,file=bin/ucore.img,addr=0x80200000` 时，新版 OpenSBI 读不到下一阶段入口，内核不会执行。因此把 `qemu`、`debug`、`test` 目标以及 `tools/grade.sh` 中的启动方式统一改为：

```sh
-kernel bin/ucore.img
```

同时，`kern/init/entry.S` 保留 lab2 修复的低地址恒等映射。写入 `satp` 后 CPU 仍按物理地址 `0x802000xx` 取指，该地址作为虚拟地址时 VPN2 = 2，所以根页表索引 2 必须放置 `0x80000000` 的恒等映射，否则 `sfence.vma` 后会触发指令页错误。

---

## 三、实验整体逻辑分析

### 3.1 启动与中断初始化链路

```text
kern_init()
  -> memset(edata, end)          清零 BSS
  -> dtb_init()                  从设备树读取物理内存范围
  -> cons_init()                 初始化控制台
  -> idt_init()                  sscratch = 0；stvec = &__alltraps
  -> pmm_init()                  lab2 迁移的 page_init + Best-Fit
  -> clock_init()                sie.STIE = 1；设置首个定时器事件；ticks = 0
  -> intr_enable()               sstatus.SIE = 1
  -> while (1)                   等待中断
```

### 3.2 一次时钟中断的处理链路

```text
时钟中断
  -> __alltraps: SAVE_ALL，构造 36*8 字节的 trapframe
  -> trap(tf): 按 scause 最高位区分中断/异常
  -> trap_dispatch()
  -> interrupt_handler(): clock_set_next_event()、ticks++、周期输出、关机判断
  -> __trapret: RESTORE_ALL，恢复 sstatus/sepc/通用寄存器/sp
  -> sret 返回被打断的指令
```

### 3.3 工作迭代

| 迭代 | 时间 | 主要工作 | 结果 |
|------|------|----------|------|
| 1 | 2026-11-03 | 初始化 lab3 分支，迁移 Lab2 的 `page_init()`、Best-Fit、`entry.S` 恒等映射和 `-kernel` 启动参数 | `check_alloc_page() succeeded!`，Best-Fit 在 lab3 下正常工作 |
| 2 | 2026-11-03 | 停止跟踪 `code/obj`、`code/bin` 编译产物，完善 `.gitignore` | 后续编译不再污染提交 |
| 3 | 2026-11-04 | 打通 trap 入口/返回、`interrupt_handler`、`exception_handler`；修复 `sbadaddr -> stval`；按 RVC 判断指令长度；对齐评测输出字符串 | `make grade` 100/100 |
| 4 | 2026-11-05 | 按分工复核 A/B/C 模块，执行编译、正常 QEMU 启动、官方评分与报告整理 | 三项评测全部 PASS，报告完成 |

说明：为尽快打通评测，迭代 3 中先由唐涵城补齐了 trapentry 与 exception 的满分框架；随后林泽森按分工复核 `RESTORE_ALL` / `__alltraps` 与寄存器、栈、传参、返回路径，尤祺乐复核 `exception_handler` 的非法指令、断点和兜底分支并完成整体回归。

---

## 四、实验内容与实现

### 4.1 功能模块一：Trap 底层（Trap frame、入口与返回）

**负责人：** 2413576-林泽森。

#### （1）trapframe 布局

`struct trapframe` 在 `kern/trap/trap.h` 中定义，`struct pushregs` 按 RISC-V 通用寄存器编号排列：

| 偏移 | 内容 |
|------|------|
| 0 ~ 255 | `gpr.zero, ra, sp, gp, tp, t0..t6, s0..s11, a0..a7`（32 个 8 字节槽位） |
| 256 | `status`（保存 `sstatus`） |
| 264 | `epc`（保存/恢复 `sepc`） |
| 272 | `tval`（保存 `stval`，旧名 `badvaddr`） |
| 280 | `cause`（保存 `scause`） |
| 合计 | 288 字节 = 36 × 8，仍保持 16 字节栈对齐 |

#### （2）SAVE_ALL

`SAVE_ALL` 先执行 `csrw sscratch, sp` 暂存进入 trap 前的栈指针，然后 `sp -= 36 * REGBYTES` 分配 trapframe，保存 `x0, x1, x3..x31`。随后用 `csrrw s0, sscratch, x0` 取回原 `sp`，同时把 `sscratch` 清零，最后保存 `sstatus`、`sepc`、`stval`、`scause` 到偏移 32~35。

`x2`（sp）不直接保存，而是把原 `sp` 存到偏移 2；`sscratch` 清零的约定用于说明“当前已经在内核态”，lab3 还没有用户态程序，因此不需要判断 trap 来自用户态。

#### （3）RESTORE_ALL

```asm
    .macro RESTORE_ALL
    # 先恢复 CSR：sstatus、sepc
    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)
    csrw sstatus, s1
    csrw sepc, s2

    # 恢复通用寄存器，x0 硬连线为 0，不需要恢复
    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    ...
    LOAD x31, 31*REGBYTES(sp)

    # sp 必须最后恢复
    LOAD x2, 2*REGBYTES(sp)
    .endm
```

关键点：

- `sstatus` 和 `sepc` 必须先写入 CSR。`sepc` 可能被异常处理修改（例如断点/非法指令后 `epc += 2/4`），所以不能只从栈上读出来而不写回。
- `sstatus` 保存的是 trap 进入时硬件已经清掉 `SIE` 的值，因此恢复过程中不会再次响应中断；`sret` 再从 `SPIE` 恢复原来的中断使能状态。
- `sp` 最后用 `LOAD x2, 2*REGBYTES(sp)` 恢复，和 `SAVE_ALL` 中保存的原 `sp` 对应；不能既 `LOAD x2` 又 `addi sp, sp, 288`，否则会重复调整。
- `x0` 不恢复；`stval/scause` 是只读输入 CSR，不需要写回。

#### （4）__alltraps 与 C 函数传参

```asm
__alltraps:
    SAVE_ALL

    mv a0, sp       # trap(struct trapframe *tf) 的第一个参数
    call trap       # 进入 C 语言 trap()

    .globl __trapret
__trapret:
    RESTORE_ALL
    sret
```

`call trap` 会破坏 `ra`，但 `ra` 已经在 trapframe 中保存，`RESTORE_ALL` 会恢复；`trap()` 返回后自然落到 `__trapret`，执行 `sret`。

#### （5）验证

`make grade` 的 Test 1 通过（35/35）。`test_lab3_register_context` 在触发 `ebreak` 前把 26 个通用寄存器设置为 `0x105~0x11f`，trap 返回后逐一比较，能够同时验证：

- `SAVE_ALL/RESTORE_ALL` 的寄存器保存与恢复；
- 栈指针恢复（trapframe 大小 288 字节，16 字节对齐）；
- `mv a0, sp; call trap` 的 C 函数传参；
- `sstatus/sepc` 写回与 `sret` 返回；
- 断点异常处理后 `sepc` 前进，返回不会重复执行 `ebreak`。

#### （6）第 153 页扩展思考：stvec 模式编码、四字节对齐与向后兼容

RISC-V 的 `stvec` 低两位是模式字段：

- `MODE = 0`：Direct 模式，所有 trap 都跳到 `BASE`；
- `MODE = 1`：Vectored 模式，中断跳到 `BASE + 4 × cause`，异常仍然跳到 `BASE`；
- 其他编码保留。

因此 `BASE` 必须 4 字节对齐，低两位恒为 0，才能和模式字段共存。本实验的 `__alltraps` 使用 `.align(2)` 保证 4 字节对齐，`idt_init()` 直接 `write_csr(stvec, &__alltraps)`，即 Direct 模式：

```c
write_csr(sscratch, 0);
write_csr(stvec, &__alltraps);
```

Direct 模式的优点是实现简单、只需要一个入口，适合当前“先保存现场再在 C 里按 `scause` 分发”的结构；Vectored 模式可以减少 C 侧的分支，但需要为每个中断准备 4 字节对齐的入口表，异常仍要回到统一入口。二者可以共存：`SAVE_ALL`/trapframe/`trap()` 的流程不变，只在 `stvec` 的写入方式和入口表布局上不同。对旧平台保持 `MODE = 0` 即可向后兼容；如果后续要使用 Vectored 模式，需要保证 `BASE` 对齐、入口地址正确，并在 `idt_init()` 中显式设置模式位，不能依赖地址低位。

---

### 4.2 功能模块二：中断与时钟、Lab2 迁移

**负责人：** 2413073-唐涵城。

#### （1）interrupt_handler

```c
void interrupt_handler(struct trapframe *tf) {
    // 清除 scause 最高位，只保留 Cause Code
    uintptr_t code = tf->cause & ~(1UL << (sizeof(uintptr_t) * 8 - 1));

    switch (code) {
    case IRQ_S_TIMER:
        clock_set_next_event();          // 先设置下一次事件
        ticks++;
        if (ticks % TICK_NUM == 0) print_ticks();
        if (ticks >= SHUTDOWN_AFTER) sbi_shutdown();
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_S_EXT:
        break;                           // 外部中断后续实验再处理
    default:
        cprintf("Unknown interrupt: cause %d\n", (int)code);
        break;
    }
}
```

时钟分支的顺序很重要：每次进入时钟中断都调用 `clock_set_next_event()` 重新设置下一次事件，否则定时器只触发一次；然后累加 `ticks`，每 100 次输出一次，达到 `SHUTDOWN_AFTER` 后调用 `sbi_shutdown()`。

当前实现中：

```c
#define TICK_NUM 100
#define SHUTDOWN_AFTER 500   // 5 秒后关机
```

QEMU 的 timebase 是 10 MHz，`clock.c` 中 `timebase = 100000`，因此每个 tick 为 10 ms，100 ticks 约 1 秒，500 ticks 约 5 秒。

#### （2）clock 模块

```c
volatile size_t ticks;

static inline uint64_t get_cycles(void) {
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
}

static uint64_t timebase = 100000;

void clock_init(void) {
    set_csr(sie, MIP_STIP);      // 使能 S 模式定时器中断
    clock_set_next_event();      // 设置第一次事件
    ticks = 0;
    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) {
    sbi_set_timer(get_cycles() + timebase);
}
```

`clock_init()` 只负责使能 `sie.STIE`、设置第一次事件并清零计数；真正让时钟持续工作的是 `interrupt_handler()` 中的每次重新设置事件。

#### （3）Lab2 缺失代码迁移

lab3 骨架中与 Lab2 相关的缺失内容及迁移结果：

| 文件 | 迁移内容 | 说明 |
|------|----------|------|
| `kern/mm/pmm.c` | `page_init()` | 从 lab2 原样迁移：设置 `va_pa_offset`、从 DTB 取内存范围、建立 `Page` 数组、保留内核和描述符数组、注册空闲页 |
| `kern/mm/pmm.c` | `init_pmm_manager()` | 由 `default_pmm_manager` 改为 `best_fit_pmm_manager` |
| `kern/mm/best_fit_pmm.c` | `free_area`、`best_fit_init/init_memmap/alloc_pages/free_pages/nr_free_pages`、`best_fit_pmm_manager` | 使用 lab2 已测试的分配器实现；保留 lab3 骨架自带的 `basic_check/best_fit_check` 不动 |
| `kern/init/entry.S` | 低地址恒等映射 | 根页表索引 2 映射 `0x80000000-0xbfffffff`，解决写入 `satp` 后的取指问题 |
| `code/Makefile` | `-device loader` -> `-kernel` | 适配 QEMU 7 + OpenSBI |
| `code/tools/grade.sh` | `-device loader` -> `-kernel` | 让本仓库的评分脚本能在当前 QEMU 下启动内核 |

迁移时保留了 `pmm.c` 原有的中断保护包装，没有采用 lab2 中不带保护的 `alloc_pages/free_pages` 直接转发版本：

```c
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}
```

`free_pages()` 和 `nr_free_pages()` 同样被 `local_intr_save/restore` 包住。

Lab2 的 Buddy System 和 SLUB 没有迁移进 lab3 骨架：它们不是 lab3 的必要路径，lab3 骨架也没有对应源文件和 Makefile 入口；这部分仍保留在 lab2 分支。

`page_init()` 的关键不变量：

1. 先设置 `va_pa_offset = PHYSICAL_MEMORY_OFFSET`，后面的 `PADDR` 依赖它；
2. `npage = PPN(mem_base + mem_size)` 是内存末尾的绝对页号，不是页数；
3. `Page` 数组放在内核 `end` 之后按页对齐的位置，定位物理地址必须用 `PADDR(pages)`；
4. 数组位于 `.bss` 之外，`kern_init()` 的 `memset` 不会清零它，必须显式初始化并标记 `PG_reserved`；
5. 首个完整空闲页为 `ROUNDUP(page_array_end, PGSIZE)`，与 `mem_base` 取较大值后注册给 `init_memmap()`。

#### （4）内存分配接口的中断保护

`kern/sync/sync.h` 中的实现：

```c
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

`__intr_save()` 读取 `sstatus.SIE`，只有原来开启中断时才关闭并返回 1；`__intr_restore()` 只在原来开启过中断时才重新开启。因此嵌套的临界区不会提前开中断：内层保存到 0，内层恢复不动作，外层恢复才真正开中断。

当前 lab3 的时钟中断处理函数不分配内存，因此不会出现“中断处理程序与主流程同时操作空闲链表”的真实竞争；但 `alloc_pages/free_pages/nr_free_pages` 的保护仍然保留，为后续实验和中断上下文中的分配提供单核下的互斥保证。该保护只适用于单 hart；多核还需要额外的 spinlock。

#### （5）第 171 页 do { … } while (0) 思考题

`local_intr_save(x)` 使用 `do { … } while (0)`，原因主要有三点：

1. **让宏表现得像一条语句。** 调用者写 `local_intr_save(flag);` 时，末尾分号会被 `do … while (0)` 吸收，宏整体仍然是一个完整语句。
2. **保证 `if/else` 安全。** 如果写成 `#define local_intr_save(x) { x = __intr_save(); }`，那么：

   ```c
   if (cond)
       local_intr_save(flag);
   else
       ...
   ```

   展开后会变成 `if (cond) { ... }; else ...`，多出来的分号是一个空语句，`else` 失去匹配的 `if`，编译失败。`do { … } while (0)` 不会产生这个问题；如果宏内部有多条语句，裸写更会让 `if` 只保护第一条语句。
3. **只执行一次，同时保留作用域和提前退出语义。** `while (0)` 保证循环体恰好执行一次；宏内部的局部变量不会泄漏到调用者作用域；如果宏内部需要提前退出，`break` 只会跳出这个 `do … while (0)`，不会误跳出调用者所在的外层循环。它也是标准 C，不依赖 GNU 的 `({ … })` 语句表达式。

`local_intr_restore(x)` 目前写成 `#define local_intr_restore(x) __intr_restore(x);`。它只有一次函数调用，在 `pmm.c` 的花括号代码块中这样写没有问题；但这个宏自带末尾分号，如果直接放进不带花括号的 `if/else`，会展开成 `if (cond) __intr_restore(flag);; else ...`，同样会破坏 `else` 的配对。更对称、更安全的写法是：

```c
#define local_intr_restore(x) \
    do { __intr_restore(x); } while (0)
```

或者直接写成 `static inline void local_intr_restore(bool flag)`。本实验保持骨架原样，调用点都在花括号块内，因此行为正确；报告里记录这一点作为宏定义的思考。

---

### 4.3 功能模块三：异常处理

**负责人：** 2413523-尤祺乐。

根据指导书的要求，采用以下提示词以定义函数`exception_handler()`：

```text
请完成kern/trap/trap.c的exception_handler()的实现，应该根据tf->cause区分非法指令异常、断点异常以及其他异常，前两种异常需要输出指定格式的消息，你可以查找make grade对应的测试以寻找具体的格式，并根据riscv消息的格式解析指令的长度，正确更新tf->epc。最后一类异常只需要调用print_trapframe()输出栈帧。
```

完成的实现如下：

```c
// 2413523 尤祺乐 负责exception_handler()实现
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Illegal instruction at %p\n", (void *)tf->epc);
            // 低两位为 0b11 表示 32 位指令，否则为 16 位压缩指令
            if ((*(uint16_t *)tf->epc & 0x3) != 0x3) {
                tf->epc += 2;
            } else {
                tf->epc += 4;
            }
            break;

        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint at %p\n", (void *)tf->epc);
            if ((*(uint16_t *)tf->epc & 0x3) != 0x3) {
                tf->epc += 2;
            } else {
                tf->epc += 4;
            }
            break;

        default:
            print_trapframe(tf);
            break;
    }
}
```

其中，非法指令异常和断点异常的输出格式是根据`grade.sh`的脚本代码确定的，输出指定文字后，根据`tf->epc`的低2位判断指令的长度是16位或32位，并正确更新`tf->epc`，避免重复陷入同一异常导致死循环。

---

## 五、测试与验证

### 5.1 编译

```bash
cd code
make clean && make
```

编译通过，最后生成 `bin/kernel` 和 `bin/ucore.img`，无编译错误。

### 5.2 正常启动与时钟输出

```bash
timeout 12 qemu-system-riscv64 -machine virt -nographic \
    -bios default -kernel bin/ucore.img
```

实测关键输出（节选）：

```text
memory management: best_fit_pmm_manager
page_init: memory [0x0000000080000000, 0x0000000088000000), free start 0x0000000080347000, npage=557056
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
++ setup timer interrupts
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```

`100 ticks` 每秒出现一次，共 5 次，对应 ticks = 100、200、300、400、500；达到 `SHUTDOWN_AFTER = 500` 后 `sbi_shutdown()` 使 QEMU 退出（退出码 0）。这验证了：

- 时钟中断持续触发；
- 每次中断都重新设置下一次事件；
- `ticks` 正常累加；
- 周期输出和关机逻辑生效；
- lab2 迁移的 `page_init()` 和 Best-Fit 仍能通过 `check_alloc_page()`。

### 5.3 官方评分

```bash
cd code
make grade
```

实际结果：

```text
Building trap entry, register restore, and breakpoint EPC...
Running trap entry, register restore, and breakpoint EPC...
  - trap entry, register restore, and breakpoint EPC: PASS (35/35)
Building illegal instruction EPC advance and return...
Running illegal instruction EPC advance and return...
  - illegal instruction EPC advance and return: PASS (25/25)
Building re-armed supervisor timer and repeated trap return...
Running re-armed supervisor timer and repeated trap return...
  - re-armed supervisor timer and repeated trap return: PASS (40/40)
Total Score: 100/100
```

### 5.4 Trap 上下文与返回验证

Test 1 的 `test_lab3_register_context` 在 `ebreak` 前给 26 个通用寄存器赋固定值，异常返回后逐个比较并通过，说明：

- trapframe 的压栈/出栈布局与 C 结构体一致；
- 通用寄存器、`sp`、`sstatus`、`sepc` 都能恢复；
- `mv a0, sp; call trap` 传参正确；
- 断点返回地址按实际指令长度推进，返回后从 `ebreak` 的下一条指令继续执行。

### 5.5 异常处理验证

Test 2 通过（25/25）：

- 非法指令 `.word 0x0000007b` 被捕获，输出 `Illegal instruction at ...`，`epc` 前进 4 字节后正常返回；
- 软件中断直接调用 `interrupt_handler()`，输出 `Supervisor software interrupt`；
- 未知中断 cause 15 输出 `Unknown interrupt: cause 15`；
- 未知异常 cause 20 进入 `default`，`print_trapframe()` 输出 `cause    0x00000014` 后正常返回，没有 panic。

### 5.6 时钟持续触发与重设事件验证

Test 3 通过（40/40）：`test_lab3_wait_for_timer()` 等待 `ticks` 达到 200，期间至少观察到 100 ticks 的周期输出，最终输出 `ticks=200`。这说明时钟不是只触发一次，而是每次 `interrupt_handler()` 都通过 `clock_set_next_event()` 重新设置了下一次事件。

### 5.7 内存分配中断保护的检查

- `kern/mm/pmm.c` 的 `alloc_pages()`、`free_pages()`、`nr_free_pages()` 都保留了 `local_intr_save/restore` 包装；
- `local_intr_save()` 只在原来 `SIE = 1` 时关中断并返回 1，`local_intr_restore()` 只在该标志为 1 时开中断，嵌套临界区不会提前开中断；
- lab3 的时钟中断处理函数不调用分配器，因此当前没有实际的分配器并发竞争；保护代码仍然保留，作为后续实验和中断上下文分配的基础。

---

## 六、实验总结与收获

### 6.1 分工总结

**林泽森：** 通过 `RESTORE_ALL`/`__alltraps` 的实现与验证，理解了 trapframe 布局、`sscratch` 暂存栈指针、CSR 写回顺序和 `sp` 最后恢复的原因；`stvec` 的模式位与 4 字节对齐是入口地址能正确编码的前提，Direct 模式适合当前单入口分发，Vectored 模式可作为后续扩展。

**唐涵城：** 完成了 Lab2 的 `page_init()`、Best-Fit 迁移和 lab3 启动适配，实现了 `interrupt_handler()` 的时钟计数、每次重设事件、周期输出和关机；通过 `sync.h` 的 `do { … } while (0)` 分析，理解了宏的单语句语义、`if/else` 安全性和嵌套关中断标志的作用。

**尤祺乐：** 完成了 `exception_handler()` 的非法指令、断点处理和 EPC 更新，补充了 16/32 位断点场景与兜底分支验证；通过完整评分和回归，确认 trap 入口、异常返回、时钟中断和 Lab2 内存初始化的组合可以稳定运行。

### 6.2 主要问题与解决

| 问题 | 现象 | 解决 |
|------|------|------|
| `sbadaddr` 不被新工具链识别 | 汇编报 `unknown CSR 'sbadaddr'` | 使用新规范名称 `stval`，并同步修改 `trap.h` 的 `tval` 字段和 `riscv.h` 的 CSR 定义 |
| `ebreak` 被压缩成 2 字节 | 固定 `epc += 4` 会跳过下一条指令，断点测试失败 | 根据 `epc` 处指令低两位判断 16/32 位，分别加 2 或 4 |
| `-device loader` 无法启动内核 | OpenSBI 下一阶段入口为 0，内核不执行 | Makefile 和 `grade.sh` 改用 `-kernel bin/ucore.img` |
| 评测字符串严格匹配 | 输出格式不一致会判 0 分 | 保留 `Breakpoint at`、`Illegal instruction at`、`Unknown interrupt: cause 15`、`cause    0x00000014` 等格式 |
| 未知异常不能终止内核 | `panic` 会让后续测试无法继续 | `default` 只打印 trapframe 后返回 |

### 6.3 总结

本实验把 Lab2 的物理内存管理和 lab3 的 trap/时钟/异常处理串成了一条完整链路：启动时完成 `page_init()` 和 Best-Fit 初始化，`idt_init()` 安装 trap 入口，`clock_init()` 使能定时器，`intr_enable()` 打开全局中断；时钟中断经 `SAVE_ALL -> trap -> interrupt_handler -> RESTORE_ALL -> sret` 持续运行，并在 500 ticks 后关机。最终 `make grade` 三项全部通过，总分 100/100。
