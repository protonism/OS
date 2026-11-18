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
