#ifndef SLUB_H
#define SLUB_H

#include <defs.h>


/* 配置参数 */
#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif

/* 大小分级都是2的次方 */
#define SLUB_MIN_SHIFT 3   /* 最小偏移量 8 bytes */
#define SLUB_MAX_SHIFT 10  /* 最大偏移量 1024 bytes */
#define SLUB_MIN_OBJECT (1 << SLUB_MIN_SHIFT)// 最小对象大小：8 字节
#define SLUB_MAX_OBJECT (1 << SLUB_MAX_SHIFT) // 最大对象大小：1024 字节

#define SLUB_MAX_CLASSES (SLUB_MAX_SHIFT - SLUB_MIN_SHIFT + 1)// 大小分级总数

int slub_init(void);

/* 内核分配 API */
void *kmalloc(size_t size);
void kfree(void *ptr);

/*用于测试 */
void *kmalloc_pages(int npages);
void kfree_pages(void *ptr, int npages);

/*诊断函数 */
void slub_print_stats(void);

#endif /* SLUB_H */
