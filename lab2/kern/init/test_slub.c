#include "defs.h"
#include "pmm.h"
#include "memlayout.h"
#include "slub.h"
#include "stdio.h"  
#include "list.h"

/* 测试 SLUB 分配器 */
void test_slub(void) {
    cprintf("===== SLUB TEST START =====\n");

    /* 初始化 SLUB 内存分配器 */
    slub_init();

    /* 分配不同大小的内存块 */
    void *p1 = kmalloc(16);
    void *p2 = kmalloc(32);
    void *p3 = kmalloc(64);

    cprintf("Allocated 16 bytes at %p\n", p1);
    cprintf("Allocated 32 bytes at %p\n", p2);
    cprintf("Allocated 64 bytes at %p\n", p3);

    /* 打印当前 SLUB 内存统计 */
    slub_print_stats();

    /* 释放内存 */
    kfree(p2);
    cprintf("Freed 32 bytes at %p\n", p2);
    kfree(p1);
    cprintf("Freed 16 bytes at %p\n", p1);
    kfree(p3);
    cprintf("Freed 64 bytes at %p\n", p3);

    /* 再次打印 SLUB 内存统计，验证释放是否正确 */
    slub_print_stats();

    cprintf("===== SLUB TEST END =====\n");
}

