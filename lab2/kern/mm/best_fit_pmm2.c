#include <pmm.h>
#include <list.h>
#include <string.h>
#include <best_fit_pmm.h>
#include <stdio.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// LAB2 EXERCISE 1: YOUR CODE
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;

    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0; // 清除标志位和属性
        set_page_ref(p, 0);         // 将引用计数设置为0
    }

    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    cprintf("[DEBUG] best_fit_init_memmap: nr_free=%d, base=%p, size=%d\n",
            nr_free, base, n);

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base->property <= page->property) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
                break;
            }
        }
    }

    // 打印链表状态
    cputs("[DEBUG] free_list after init:");
    list_entry_t* le_debug = &free_list;
    while ((le_debug = list_next(le_debug)) != &free_list) {
        struct Page* pg = le2page(le_debug, page_link);
        cprintf("  [addr=%p, size=%d]\n", pg, pg->property);
    }
}

static struct Page *
best_fit_alloc_pages(size_t n) {
    cprintf("  [nr_free1=%d]\n", nr_free);
    assert(n > 0);
    if (n > nr_free) {
        cprintf("[DEBUG] best_fit_alloc_pages: request %d > nr_free %d\n", n, nr_free);
        return NULL;
    }
    cputs("[DEBUG] exam free_list:");
    list_entry_t* le_debug = &free_list;
    while ((le_debug = list_next(le_debug)) != &free_list) {
        struct Page* pg = le2page(le_debug, page_link);
        cprintf("  [addr=%p, size=%d]\n", pg, pg->property);
    }
    struct Page *page = NULL;
    size_t min_size = nr_free + 1;
    list_entry_t *le = &free_list;

    // 遍历空闲链表寻找最小适配块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);     
        cprintf("[DEBUG] num of propert:  %d \n",p->property);
        if (p->property >= n) {
            page = p;
            min_size = p->property;
            break;
        }
    }

    if (page == NULL) {
        cputs("[DEBUG] best_fit_alloc_pages: no suitable block found");
        return NULL;
    }

    cprintf("[DEBUG] best_fit_alloc_pages: alloc %d pages at %p (block size=%d)\n",
            n, page, page->property);
    list_entry_t* prev = list_prev(&(page->page_link));
    list_del(&(page->page_link));
    if (page->property > n) {
        struct Page *p = page + n;
        p->property = page->property - n;
        SetPageProperty(p);
        if(list_empty(&free_list)){
         list_add(&free_list, &(p->page_link));
    }
        else{

        // 插入剩余部分
        list_entry_t *le_2 = &free_list;
        while ((le_2 = list_next(le_2)) != &free_list) {
            struct Page* page_2 = le2page(le_2, page_link);
            if (p->property <= page_2->property) {
                list_add_before(le_2, &(p->page_link));
                break;
            } else if (list_next(le_2) == &free_list) {
                list_add(le_2, &(p->page_link));
                break;
            }
        }
    }
    }

    nr_free -= n;
    cprintf("  [nr_free2=%d]\n", nr_free);
    ClearPageProperty(page);

    // 打印分配后链表状态
    cputs("[DEBUG] free_list after alloc:");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page* pg = le2page(le, page_link);
        cprintf("  [addr=%p, size=%d]\n", pg, pg->property);
    }

    return page;
}


static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    cprintf("[DEBUG] >>> best_fit_free_pages(base=%p, n=%d) begin\n", base, n);

    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    cprintf("[DEBUG]   set base->property=%d, nr_free=%d\n", n, nr_free);
    // 打印释放前链表状态
    cputs("[DEBUG]   free_list before free:");
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *pg = le2page(le, page_link);
        cprintf("  [addr=%p, size=%d]\n", pg, pg->property);
    }
    // 尝试与前面的块合并
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base > page) {
            if (page + page->property == base) {
                cprintf("============[addr12345678=%p\n", page);
                cprintf("============[addr12345678=%p\n", base);
                cprintf("[DEBUG]   merge backward: [%p,%d] + [%p,%d]\n",
                        page, page->property, base, base->property);
                page->property += base->property;
                ClearPageProperty(base);
                list_del(&(page->page_link));
                base = page;
                break;
            }
        }
    }

    // 尝试与后面的块合并
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base < page) {
            if (base + base->property == page) {
                cprintf("[DEBUG]   merge forward: [%p,%d] + [%p,%d]\n",
                        base, base->property, page, page->property);
                base->property += page->property;
                ClearPageProperty(page);
                list_del(&(page->page_link));
                break;
            }
        }
    }

    // 插入base到链表中（保持按大小排序）
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
        cprintf("[DEBUG]   free_list empty, insert [%p,%d]\n", base, base->property);
    } else {
        list_entry_t *le_2 = &free_list;
        bool inserted = 0;
        while ((le_2 = list_next(le_2)) != &free_list) {
            struct Page *page_2 = le2page(le_2, page_link);
            if (base->property <= page_2->property) {
                list_add_before(le_2, &(base->page_link));
                cprintf("[DEBUG]   insert [%p,%d] before [%p,%d]\n",
                        base, base->property, page_2, page_2->property);
                inserted = 1;
                break;
            } else if (list_next(le_2) == &free_list) {
                list_add(le_2, &(base->page_link));
                cprintf("[DEBUG]   insert [%p,%d] at tail\n", base, base->property);
                inserted = 1;
                break;
            }
        }
        if (!inserted) {
            cprintf("[DEBUG]   insert [%p,%d] not triggered (unexpected)\n", base, base->property);
        }
    }

    // 打印释放后链表状态
    cputs("[DEBUG]   free_list after free:");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *pg = le2page(le, page_link);
        cprintf("  [addr=%p, size=%d]\n", pg, pg->property);
    }

    cprintf("[DEBUG] <<< best_fit_free_pages(base=%p, n=%d) end\n", base, n);
}


static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    // 分配 3 页
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    cprintf("After initial alloc_page(): p0=%p, p1=%p, p2=%p\n", p0, p1, p2);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    // 保存 free_list 状态
    list_entry_t free_list_store = free_list;

    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    // 释放 3 页
    free_page(p0);
    free_page(p1);
    free_page(p2);

    cputs("After freeing p0, p1, p2:");
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    assert(nr_free == 3);

    // 再次分配 3 页
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    cprintf("After realloc_page(): p0=%p, p1=%p, p2=%p\n", p0, p1, p2);
    assert(alloc_page() == NULL);

    // 释放 p0，检查 free_list
    free_page(p0);
    cputs("After free_page(p0):");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);
    assert(nr_free == 0);

    // 恢复原 free_list
    free_list = free_list_store;
    nr_free = nr_free_store;
    list_entry_t *le22 = &free_list;
    while ((le22 = list_next(le22)) != &free_list) {
        struct Page *p = le2page(le22 ,page_link);
        cprintf("  [add11111r=%p, size=%u]\n", p, p->property);
    }
    free_page(p);
    free_page(p1);
    free_page(p2);
    cputs("After freeing2 p0, p1, p2:");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

}

static void
best_fit_check(void) {
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    cputs("zdm_begin:");
    

    // 检查 free list 是否有效
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    cputs("Starting best_fit_check, initial free list:");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    cprintf("After alloc_pages(5), p0=%p\n", p0);
    le = &free_list;
    cputs("Free list state:");
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
    free_pages(p0 + 4, 1);

    cputs("After free_pages(p0+1,2) and free_pages(p0+4,1):");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 1) && p0[1].property == 2);

    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
    assert(alloc_pages(2) != NULL);      // best fit feature
    assert(p0 + 4 == p1);

    cprintf("After alloc_pages(1), p1=%p\n", p1);
    le = &free_list;
    cputs("Free list state:");
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    p2 = p0 + 1;
    free_pages(p0, 5);
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    cputs("Final free list state:");
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("  [addr=%p, size=%u]\n", p, p->property);
    }

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}


const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};

