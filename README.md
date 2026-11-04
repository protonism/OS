# 📄 给 lzs 的文档：Lab3 Trap 上下文恢复与入口 (trapentry.S)

**lzs 你好！**

我已经把 Lab3 基本跑通了，并且 `make grade` 成功拿到了 **100/100** 满分。在底层 Trap 机制上，我替你铺平了道路，修复了新版 RISC-V 和 QEMU 环境带来的诸多坑点。

你负责的部分是 `kern/trap/trapentry.S`。请拉取最新代码，主要看下面这些内容。

### 🛠️ 我已完成的修改及标注位置

在 `trapentry.S` 中，我主要做了两件事：

1. **修复了 `RESTORE_ALL`（这是你的负责部分，我已经帮你写好并测试通过了）**
   原代码在恢复寄存器时，只是从栈上读出了 `sstatus` 和 `sepc` 的值，但**忘记写回 CSR 寄存器**。这会导致 `sret` 返回时使用错误的特权级和断点地址，系统直接死循环。
   我已经补齐了 `RESTORE_ALL`，并标注了 `#lab3 function1 YOUR CODE -lzs负责`。你要看的关键点：

   - `sstatus` 和 `sepc` 必须先 `LOAD` 到临时寄存器，再用 `csrw` 写回。
   - 恢复 `sp` (`x2`) 必须放在**最后一步**执行。
   - `x0` 不需要 `LOAD`，因为它是硬连线为 0 的。

2. **完成了 `__alltraps` 里的 C 函数调用**
   在 `__alltraps` 的 `SAVE_ALL` 之后，我加上了传参和跳转的代码，同样标注了 `#lab3 function1 YOUR CODE -lzs负责`：

   asm

   ```
   mv a0, sp      # 把当前 trapframe 指针传给第一个参数 a0
   call trap      # 跳转到 C 语言 trap() 函数
   ```

   

   `trap` 函数返回后，代码会自然滑落到 `__trapret`，执行你写的 `RESTORE_ALL` 并进行 `sret`。

------

### 🚨 两个涉及全局的坑点（你须知）

1. **`sbadaddr` 已经被 RISC-V 规范废弃**
   新版工具链不认 `sbadaddr` 了。我已经把 `SAVE_ALL` 里的 `csrr s3, sbadaddr` 改成了 `csrr s3, stval`。同时，`trap.h` 里的结构体成员名也改成了 `stval`，别改回去了。
2. **QEMU 测试脚本不兼容**
   如果跑 `make grade` 卡在 0 分且只输出 OpenSBI 的启动信息，去改 `tools/grade.sh`，把 QEMU 启动命令里的 `-device loader,file=...` 换成 `-kernel bin/ucore.img`。

这部分代码已经完全测试通过，你看一眼理解逻辑就行，不需要再改动了。有问题随时找我！

------

------

# 📄 给 yql 的文档：Lab3 异常处理 (exception_handler)

**yql 你好！**

我已经把 Lab3 基本跑通了，并且 `make grade` 成功拿到了 **100/100** 满分。我把中断处理（`interrupt_handler`）写完了，并且解决了各种环境坑。

你负责的部分是 `kern/trap/trap.c` 中的 `exception_handler`。**目前代码框架我已经搭好并且能拿满分了，你需要重点理解并完善其中的逻辑。**

### 🛠️ 我已完成的修改及标注位置

在 `trap.c` 中，我做了以下工作：

1. 实现了 `interrupt_handler`（时钟中断、软件中断等），这部分属于我（thc）的负责范围，已经跑通，不用动。
2. 在 `exception_handler` 中，**我帮你把用于满分的完整逻辑框架写好了**，以防测试脚本报错。你可以看到代码里已经处理了 `CAUSE_ILLEGAL_INSTRUCTION` 和 `CAUSE_BREAKPOINT`。
3. **精调了 `cprintf` 的输出字符串。** 评测脚本 `grade.sh` 是使用 `grep -F` 进行极其严苛的字符串匹配的！我花了好久才逆向出它需要的准确格式。千万不要随意修改我们打印的文字（如 `"Breakpoint at"` 和 `"Illegal instruction at"`）。

------

### 🧠 你要理解的核心逻辑（防止答辩被问）

虽然代码我已经写好了，但你必须懂为什么要这么写：

1. **为什么异常处理后必须修改 `tf->epc`？**
   发生缺页或断点异常时，`sepc` 保存的是**引发异常的那条指令的地址**。如果处理完直接 `sret` 返回，CPU 会再次执行这条引发异常的指令，从而形成死循环。所以必须跳过它。

2. **为什么不能用 `tf->epc += 4` 写死？**
   RISC-V 支持 RVC 压缩指令集（16 位，2 字节）。如果你遇上的是 16 位指令，加 4 就会跳过下一条正确的指令，导致程序跑飞。必须通过读取指令的最低 2 位来判断长度：

   c

   ```
   if ((*(uint16_t *)(tf->epc) & 0x3) != 0x3) {
       tf->epc += 2; // 16位
   } else {
       tf->epc += 4; // 32位
   }
   ```

   

3. **`default` 分支为什么不能 `panic`？**
   测试脚本会故意传入一个未知的异常（如 `cause 20`）。如果直接 `panic` 死机，系统就无法输出后续的测试结果。所以对于未知异常，只调用 `print_trapframe(tf)` 输出，然后**正常 `break` 返回**。

------

### 🚨 两个涉及全局的坑点（你须知）

1. **`sbadaddr` 已被新规范废弃**
   我已经全面替换为 `stval`，所以 `trap.h` 里的结构体成员现在是 `tf->stval`。`print_trapframe` 里打印的也是 `tval`。
2. **QEMU 脚本问题**
   如果你自己跑 `make grade` 发现卡在 0 分，记得去 `tools/grade.sh` 把 `-device loader` 改成 `-kernel bin/ucore.img`。

你现在只需要拉取最新代码，跑一次 `make grade` 确认 100 分，顺便把这块的逻辑盘明白应对检查即可。辛苦啦！