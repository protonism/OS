#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

//LAB4 function3 2413523

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


