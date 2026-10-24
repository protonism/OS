// 添加slub头文件 -lzs
#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

#define SLUB_ALIGNMENT 16
#define SLUB_SMALL_MAX 2048

void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *ptr);
void slub_check(void);

#endif