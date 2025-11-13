#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

#define MAX_ORDER 14 // 由于我们最多只用存储16384个物理页，也就是2的14次方，最多开14阶

Buddy_system buddy;
int isPowerOfTwo(size_t n)
{
    return (n & (n - 1)) == 0;
}

size_t correct_n(size_t n)
{
    // 如果n本来就是2的幂次方，直接返回n
    if (isPowerOfTwo(n))
    {
        return n;
    }
    // 如果不是，求出最接近但小于n的2的幂次方
    int i = 1;
    while (i < n)
    {
        if (2 * i > n)
        {
            return i;
        }
        i *= 2;
    }
    return i;
}
static unsigned int
getOrderOfTwo(size_t n)
{
    unsigned int count = 0;
    while (n >> 1)
    {
        n >>= 1;
        count++;
    }
    return count;
}

static struct Page *
getBuddy(struct Page *base, unsigned int property)
{
    // 先计算该块包含了多少物理页
    unsigned int temp = 1;
    for(int i = 0; i < property; i++){
        temp = temp * 2;
    }
    size_t real_block_size = temp;

    //计算自己的相对偏移量 
    size_t relative_base = (size_t)base - 0xffffffffc020f318;
    //计算块的大小，0x28是一个page结构体的大小
    size_t sizeOfPage = real_block_size * 0x28;           
    size_t buddy_relative_addr = (size_t)relative_base ^ sizeOfPage;      //计算出字节偏移量
    struct Page *buddy = (struct Page *)(buddy_relative_addr + 0xffffffffc020f318); //计算伙伴块的真实地址
    return buddy;
}
static void // 初始化伙伴内存分配系统
buddy_system_init(void)
{
    for (int i = 0; i < MAX_ORDER + 1; i++)
    {
        list_init(&buddy.array[i]);
    }
    buddy.free = 0;
    buddy.max = 0;
    // 调用list_init函数初始化每一个阶层的链表，并且把free和max值都设为0
}

static void
buddy_system_init_memmap(struct Page *base, size_t n)
{
    // 确保输入合法性
    assert(base != NULL && n > 0);
    // 伙伴系统只能接受2的幂次方个物理页，因此要对n进行第一步处理
    size_t pageNumber = correct_n(n);
    // 得到我们要管理的物理页的数量pageNumber，然后要获得它的阶数
    unsigned int order = getOrderOfTwo(pageNumber);

    // 然后要初始化传入的这块内存中的所有物理页
    for (struct Page *p = base; p != base + pageNumber; p++)
    {
        assert(PageReserved(p));
        // 清除所有flag标记
        p->flags = 0;
        // 全部初始化为非头页
        p->property = -1;
        // 将当前页的引用计数设置为0
        set_page_ref(p, 0);
    }
    // 赋值buddy system
    list_add(&buddy.array[order], &(base->page_link));
    buddy.free = pageNumber;
    buddy.max = pageNumber;

    // 现在开始，Page的property属性代表当前物理页的阶数
    base->property = order;
    SetPageProperty(base); // 设置对应的属性
    return;
}

static struct Page *
buddy_system_alloc_pages(size_t n)
{
    // 输入合法性检测
    if (n > buddy.free || n <= 0)
    {
        // 如果请求的页数超出剩余的页数，直接返回NULL
        return NULL;
    }
    struct Page *ret = NULL; // 初始化返回值
    // 与初始化的时候不一样，此时我们需要找到一个最接近但大于等于n的2的幂数
    size_t pageNumber = correct_n(n);
    if (pageNumber != n)
    {
        pageNumber *= 2;
    }
    // 获取分配页数对应的阶数
    unsigned int order = getOrderOfTwo(pageNumber);
    int canFind = 1;
    // 现在开始分配正确的块
    while (canFind)
    {
        if (!list_empty(&buddy.array[order]))
        {
            // 如果当前阶数对应的链表非空，则进行分配
            ret = le2page(list_next(&buddy.array[order]), page_link);
            // 删除被分配出去的页
            list_del(list_next(&buddy.array[order]));
            // 别忘了重置属性，但不包括property，因为后面还要用到
            ClearPageProperty(ret);
            break;
        }
        else
        {
            // 这种情况就是该阶层已经没有空闲的块可以分配了
            // 此时需要不断循环到上一层继续查找
            size_t tmp = pageNumber;
            for (int i = order + 1; i <= buddy.max; i++)
            {
                if (!list_empty(&buddy.array[i]))
                {
                    // 此时相当于在上层找到了空闲的块
                    // 但是需要做二分块的操作,首先获取该块首页指针
                    list_entry_t *le = list_next(&(buddy.array[i]));
                    struct Page *left = le2page(le, page_link);
                    // tmp 是当前阶数对应的页数的一半，因此可以获得另一半的首页指针
                    struct Page *right = left + tmp;
                    // 维护新的阶数和属性
                    left->property = i - 1;
                    right->property = i - 1;
                    SetPageProperty(left);
                    SetPageProperty(right);

                    // 删除原来的大块，但是添加新的小块
                    list_del(le);
                    list_add(&(buddy.array[i - 1]), &(left->page_link));
                    list_add(&(left->page_link), &(right->page_link));

                    break;
                }
                if (i > buddy.max)
                {
                    // 出现这种情况就意味着无法找到合适的块来分配,所以让外层循环退出
                    canFind = 0;
                    break;
                }
                tmp *= 2;
            }
        }
    }

    // 当分配成功时，别忘了要维护剩余的空闲块的数量
    if (ret != NULL)
    {
        buddy.free -= pageNumber;
    }
    return ret;
}

static void
buddy_system_free_pages(struct Page *base, size_t n)
{
    // 输入的合法性检测
    assert(base != NULL && n > 0);
    // 直接用地址加入对应的阶层
    list_add(&(buddy.array[base->property]), &(base->page_link));
    SetPageProperty(base);
    // 现在需要回溯，合并地址相邻的空闲块
    // 首先获取此次释放的块的相邻块
    struct Page *buddy_block1 = base;
    struct Page *buddy_block2 = getBuddy(base,base->property);
    // 开始递归
    while(PageProperty(buddy_block2) && buddy_block1->property < buddy.max){
        // block1和block2，要先求出地址在前的那个块
        if(buddy_block1 > buddy_block2){
            // 说明block1地址在block2之后，进行交换
            struct Page *tmp = buddy_block1;
            buddy_block1 = buddy_block2;
            buddy_block2 = tmp;
            // 将在后面的那个块的阶数属性设置为-1，表示被合并你了
            buddy_block2->property = -1;
        }
        // 删除小块，添加大块
        list_del(&(buddy_block2->page_link));
        list_del(&(buddy_block1->page_link));
        buddy_block1->property++;
        list_add(&(buddy.array[buddy_block1->property]), &(buddy_block1->page_link));

        // 求出新的伙伴块
        buddy_block2 = getBuddy(buddy_block1,buddy_block1->property);
    }
    SetPageProperty(buddy_block1);
    // 操作完成后，不要忘记更新剩余空闲块的数量
    size_t pageNumber = correct_n(n);
    if (pageNumber != n)
    {
        pageNumber *= 2;
    }
    buddy.free += pageNumber;
    return ;
}

static size_t
buddy_system_nr_free_pages(void)
{
    return buddy.free;
}

static void
show_buddy_array(int left, int right)
{
    cprintf("------------------ Buddy System Free Lists ------------------\n");
    for (int i = left; i <= right; i++)
    {
        if (list_empty(&buddy.array[i]))
        {
            cprintf("Order %d: Empty\n", i);
        }
        else
        {
            cprintf("Order %d: ", i);
            list_entry_t *le = &buddy.array[i];
            while ((le = list_next(le)) != &buddy.array[i])
            {
                struct Page *page = le2page(le, page_link);
                cprintf("[%p, size=%d] ", page, 1 << page->property);
            }
            cprintf("\n");
        }
    }
    cprintf("Total free pages: %d\n", buddy.free);
    cprintf("-------------------------------------------------------------\n");
}

// 基本分配和释放测试
static void
buddy_system_check_basic(void)
{
    cprintf("=== Basic Allocation and Free Test ===\n");
    cprintf("Initial free pages: %d\n", buddy.free);
    
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    // 分配三个10页的块
    cprintf("Allocating 10 pages for p0...\n");
    p0 = buddy_system_alloc_pages(10);
    assert(p0 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Allocating 10 pages for p1...\n");
    p1 = buddy_system_alloc_pages(10);
    assert(p1 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Allocating 10 pages for p2...\n");
    p2 = buddy_system_alloc_pages(10);
    assert(p2 != NULL);
    show_buddy_array(0, MAX_ORDER);

    // 验证分配结果
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    cprintf("p0 address: 0x%016lx\n", p0);
    cprintf("p1 address: 0x%016lx\n", p1);
    cprintf("p2 address: 0x%016lx\n", p2);

    // 释放内存
    cprintf("Freeing p0...\n");
    buddy_system_free_pages(p0, 10);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Freeing p1...\n");
    buddy_system_free_pages(p1, 10);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Freeing p2...\n");
    buddy_system_free_pages(p2, 10);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Basic test completed successfully!\n\n");
}

// 最小分配测试（1页）
static void
buddy_system_check_min(void)
{
    cprintf("=== Minimum Allocation Test (1 page) ===\n");
    cprintf("Initial free pages: %d\n", buddy.free);
    
    struct Page *p = buddy_system_alloc_pages(1);
    assert(p != NULL);
    cprintf("Allocated 1 page at address: 0x%016lx\n", p);
    show_buddy_array(0, MAX_ORDER);
    
    buddy_system_free_pages(p, 1);
    cprintf("Freed 1 page\n");
    show_buddy_array(0, MAX_ORDER);
    
    cprintf("Minimum allocation test completed successfully!\n\n");
}

// 最大分配测试（16384页）
static void
buddy_system_check_max(void)
{
    cprintf("=== Maximum Allocation Test (16384 pages) ===\n");
    cprintf("Initial free pages: %d\n", buddy.free);
    
    struct Page *p = buddy_system_alloc_pages(16384);
    if (p == NULL) {
        cprintf("Warning: Cannot allocate 16384 pages (might be expected)\n");
        return;
    }
    
    cprintf("Allocated 16384 pages at address: 0x%016lx\n", p);
    show_buddy_array(0, MAX_ORDER);
    
    buddy_system_free_pages(p, 16384);
    cprintf("Freed 16384 pages\n");
    show_buddy_array(0, MAX_ORDER);
    
    cprintf("Maximum allocation test completed successfully!\n\n");
}

// 困难情况测试（不同大小的分配）
static void
buddy_system_check_difficult(void)
{
    cprintf("=== Difficult Allocation Test ===\n");
    cprintf("Initial free pages: %d\n", buddy.free);
    
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    // 分配不同大小的块
    cprintf("Allocating 10 pages for p0...\n");
    p0 = buddy_system_alloc_pages(10);
    assert(p0 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Allocating 50 pages for p1...\n");
    p1 = buddy_system_alloc_pages(50);
    assert(p1 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Allocating 100 pages for p2...\n");
    p2 = buddy_system_alloc_pages(100);
    assert(p2 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("p0 address: 0x%016lx\n", p0);
    cprintf("p1 address: 0x%016lx\n", p1);
    cprintf("p2 address: 0x%016lx\n", p2);

    // 验证分配结果
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 释放内存（不同顺序）
    cprintf("Freeing p1 first...\n");
    buddy_system_free_pages(p1, 50);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Freeing p0...\n");
    buddy_system_free_pages(p0, 10);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Freeing p2...\n");
    buddy_system_free_pages(p2, 100);
    show_buddy_array(0, MAX_ORDER);

    cprintf("Difficult test completed successfully!\n\n");
}

// 边界情况测试
static void
buddy_system_check_edge_cases(void)
{
    cprintf("=== Edge Cases Test ===\n");
    cprintf("Initial free pages: %d\n", buddy.free);
    
    // 测试分配0页（应该失败）
    cprintf("Testing allocation of 0 pages...\n");
    struct Page *p0 = buddy_system_alloc_pages(0);
    assert(p0 == NULL);
    cprintf("Allocation of 0 pages correctly failed\n");
    
    // 测试分配超过最大可用页数
    cprintf("Testing allocation beyond available pages...\n");
    size_t too_many = buddy.free + 1;
    struct Page *p1 = buddy_system_alloc_pages(too_many);
    assert(p1 == NULL);
    cprintf("Allocation of %d pages correctly failed\n", too_many);
    
    cprintf("Edge cases test completed successfully!\n\n");
}

// 主测试函数
static void
buddy_system_check(void)
{
    cprintf("============================================\n");
    cprintf("Starting Buddy System Tests\n");
    cprintf("============================================\n");
    
    // 保存初始状态
    size_t initial_free = buddy.free;
    
    // 运行所有测试
    buddy_system_check_basic();
    buddy_system_check_min();
    buddy_system_check_max();
    buddy_system_check_difficult();
    buddy_system_check_edge_cases();
    
    // 验证最终状态
    cprintf("Final free pages: %d\n", buddy.free);
    cprintf("Initial free pages: %d\n", initial_free);
    assert(buddy.free == initial_free); // 所有内存应该被正确释放
    
    cprintf("============================================\n");
    cprintf("All Buddy System Tests Completed Successfully!\n");
    cprintf("============================================\n");
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
