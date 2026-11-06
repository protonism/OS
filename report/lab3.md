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

### 4.1 功能模块一：Trap 底层（RESTORE_ALL 与 __alltraps）

**负责人：** 2413576-林泽森。

本实验完成了 `kern/trap/trapentry.S` 中标注 `#lab3 function1` 的两处代码：`RESTORE_ALL` 宏和 `__alltraps` 中调用 `trap()` 的部分。`SAVE_ALL`、trapframe 布局和 `stvec` 初始化由骨架提供。

**Spec：**

```text
文件：kern/trap/trapentry.S
1. RESTORE_ALL：从 trapframe 偏移 32/33 读取 sstatus/sepc，并 csrw 写回；
   恢复 x1、x3~x31；x0 不恢复；sp 最后从偏移 2 恢复。
2. __alltraps：SAVE_ALL 之后 mv a0, sp; call trap；
   trap() 返回后自然落到 __trapret，执行 RESTORE_ALL 和 sret。
3. 不修改 SAVE_ALL 和 trapframe 布局；__alltraps 保持 4 字节对齐。
```

**Prompt：**

```text
请完成 kern/trap/trapentry.S 中 lab3 function1 的两处代码。第一处是 RESTORE_ALL：从 trapframe 中恢复 sstatus 和 sepc 并写回 CSR，恢复 x1、x3~x31，x0 不需要恢复，sp 必须最后从偏移 2 恢复；第二处是 __alltraps：在 SAVE_ALL 之后把 sp 作为 trapframe 指针传给 trap()，即 mv a0, sp; call trap。不要修改 SAVE_ALL 和 trapframe 布局，并解释 CSR 写回顺序和 sp 恢复顺序。
```

**实现：**

```asm
    .macro RESTORE_ALL
    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)
    csrw sstatus, s1
    csrw sepc, s2

    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    ...                       # x4~x31 按同样方式恢复
    LOAD x31, 31*REGBYTES(sp)

    LOAD x2, 2*REGBYTES(sp)   # sp 最后恢复
    .endm

__alltraps:
    SAVE_ALL
    mv a0, sp
    call trap
__trapret:
    RESTORE_ALL
    sret
```

**说明与真实问题：**

- `sstatus` 和 `sepc` 不能只从 trapframe `LOAD`，必须 `csrw` 写回 CSR，否则 `sret` 使用的是旧值。
- `sp` 必须最后恢复；不能再额外 `addi sp, sp, 288`，否则会重复调整栈指针。
- 原骨架的 `csrr s3, sbadaddr` 在当前 binutils 2.45 下报 `unknown CSR 'sbadaddr'`，改为 `csrr s3, stval`，同时把 `trap.h` 的字段改名为 `tval`。
- `call trap` 会破坏 `ra`，但 `ra` 已保存在 trapframe 中，`RESTORE_ALL` 会恢复。
- Test 1 通过（35/35），验证 26 个通用寄存器、sp、C 函数传参和断点返回。

第 153 页的思考题简要回答：`stvec` 低两位是 MODE，0 为 Direct、1 为 Vectored；`BASE` 必须 4 字节对齐，因此 `__alltraps` 用 `.align(2)`，`idt_init()` 写入 `&__alltraps` 就是 Direct 模式。扩展到 Vectored 时只要保证入口表 4 字节对齐、中断入口地址为 `BASE + 4 * cause`，异常仍然回到 `BASE`，旧平台继续用 Direct 即可保持兼容。

---

### 4.2 功能模块二：中断与时钟（interrupt_handler）

**负责人：** 2413073-唐涵城。

本实验完成了 `kern/trap/trap.c` 中标注 `//lab3 function2` 的 `interrupt_handler()`。`clock.c` 的 `clock_init()` 和 `clock_set_next_event()` 由骨架提供；Lab2 部分只迁移了 `page_init()` 和 Best-Fit，并把 `init_pmm_manager()` 切换到 `best_fit_pmm_manager`，保证 `pmm_init()` 能正常完成。

**Spec：**

```text
文件：kern/trap/trap.c
1. interrupt_handler(tf)：先清除 scause 最高位，只保留 cause code；
2. IRQ_S_TIMER：每次调用 clock_set_next_event()，ticks++，
   每 100 次调用 print_ticks()，达到 500 次调用 sbi_shutdown()；
3. IRQ_S_SOFT：输出 Supervisor software interrupt；
   其他：输出 Unknown interrupt: cause N；
4. 输出字符串要和 tools/grade.sh 的 grep 目标一致。
```

**Prompt：**

```text
请完成 kern/trap/trap.c 中 lab3 function2 的 interrupt_handler()：先清除 scause 的最高位，再按中断类型分发；时钟中断每次都要调用 clock_set_next_event() 重新设置下一次事件，ticks++，每 100 次打印一次，达到 500 次调用 sbi_shutdown()；软件中断输出 Supervisor software interrupt，未知中断输出 Unknown interrupt: cause N。不要修改 SAVE_ALL/trapframe，输出字符串要匹配 tools/grade.sh。
```

**实现：**

```c
void interrupt_handler(struct trapframe *tf) {
    uintptr_t code = tf->cause & ~(1UL << (sizeof(uintptr_t) * 8 - 1));

    switch (code) {
    case IRQ_S_TIMER:
        clock_set_next_event();
        ticks++;
        if (ticks % TICK_NUM == 0) print_ticks();
        if (ticks >= SHUTDOWN_AFTER) sbi_shutdown();
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_S_EXT:
        break;
    default:
        cprintf("Unknown interrupt: cause %d\n", (int)code);
        break;
    }
}
```

**说明与真实问题：**

- 真实时钟中断的 `scause` 最高位是 1（例如 `0x8000000000000005`），不能直接 `switch (tf->cause)`，否则会进入 `default`；要先 `tf->cause & ~(1UL << 63)`。
- 定时器事件只设置一次的话，时钟只会触发一次，`ticks` 停在 1；所以每次 `IRQ_S_TIMER` 都要调用 `clock_set_next_event()`。
- `SHUTDOWN_AFTER = 500`，QEMU 的 timebase 是 10 MHz、`timebase = 100000`，所以 500 ticks 约 5 秒，正常输出 5 次 `100 ticks` 后关机。
- 评测脚本用 `grep -F` 精确匹配 `100 ticks`、`Supervisor software interrupt`、`Unknown interrupt: cause 15` 等字符串，输出格式不能随意改。
- Lab2 迁移部分：`page_init()` 从 lab2 原样迁入；`best_fit_pmm.c` 补 `free_area` 和分配器函数；`entry.S` 补低地址恒等映射；Makefile 和 `grade.sh` 使用 `-kernel`。`pmm.c` 的 `local_intr_save/restore` 包装保持不变，分配接口仍有中断保护。

第 171 页的思考题简要回答：`local_intr_save` 用 `do { … } while (0)` 把宏变成一条完整语句，调用者可以正常写分号；在 `if/else` 中不会因为多出的花括号分号破坏 `else` 的配对，`while (0)` 保证只执行一次，还允许宏内部 `break`。`local_intr_restore` 目前是带末尾分号的普通宏，在花括号块里没问题，但放进不带花括号的 `if/else` 会多出一个空语句，建议也改成 `do { … } while (0)`。`__intr_save/__intr_restore` 用 bool 标志保存原来的 `SIE`，嵌套时内层恢复不会提前开中断，外层恢复才真正打开。

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
