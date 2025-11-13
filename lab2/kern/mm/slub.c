#define _GNU_SOURCE
#include "slub.h"
#include "defs.h"
#include "pmm.h"
#include "memlayout.h"
#include "list.h"
#include "mmu.h"
#include "default_pmm.h"
#include "stdio.h" 
#include "string.h" 
/* compatibility: use PAGE_SIZE if code expects it */
#ifndef PAGE_SIZE
#define PAGE_SIZE PGSIZE
#endif

/* ---------- Locking: default to no-op for now ----------
   Replace these with your kernel spinlock API when available.
   Example replacement (when you have spinlock.h):
       #include <kern/sync/spinlock.h>
       typedef spinlock_t slub_lock_t;
       static inline void slub_lock_init(slub_lock_t *l) { initlock(l, "slub"); }
       static inline void slub_lock(slub_lock_t *l) { acquire(l); }
       static inline void slub_unlock(slub_lock_t *l) { release(l); }

   Or use local interrupt disable/enable if that's the chosen strategy.
*/
typedef int slub_lock_t;
static inline void slub_lock_init(slub_lock_t *l) { (void)l; }
static inline void slub_lock(slub_lock_t *l) { (void)l; } /* no-op */
static inline void slub_unlock(slub_lock_t *l) { (void)l; }

/* ---------- pmm adapter: allocate/free pages and return KVA ----------
   Uses alloc_pages/free_pages (which deal with struct Page *).
   Convert struct Page * -> physical address via page2pa,
   then to KVA via va_pa_offset (as pmm.c sets).
*/
static void *host_alloc_pages(int n)
{
    struct Page *pg = alloc_pages((size_t)n);
    if (!pg) return NULL;
    uintptr_t pa = page2pa(pg);
    void *kva = (void *)(pa + va_pa_offset);
    /* zero page(s) for debugging/safety */
    memset(kva, 0, (size_t)n * PAGE_SIZE);
    return kva;
}

static void host_free_pages(void *kva, int n)
{
    if (!kva) return;
    uintptr_t pa = (uintptr_t)kva - va_pa_offset;
    struct Page *pg = pa2page(pa);
    free_pages(pg, (size_t)n);
}

/* ---------- SLUB structures ---------- */

struct slab {
    struct slab *next;      /* next slab in list (partial/full) */
    unsigned free_count;    /* number of free objects */
    void *page;             /* KVA of slab base (where header is) */
    void *free_list;        /* pointer to first free obj (singly-linked) */
    unsigned obj_size;      /* object size for this slab */
    unsigned nr_objs;       /* total objects in this slab */
    int npages;             /* number of pages for this slab */
};

struct slab_cache {
    unsigned obj_size;      /* size of objects in this cache */
    struct slab *partial;   /* slabs with some free objects */
    struct slab *full;      /* slabs with no free objects */
    slub_lock_t lock;
    unsigned nr_slabs;
    unsigned nr_allocs;
    unsigned nr_frees;
};

/* config (same as slub.h) */
#define SLUB_MIN_SHIFT 3   /* 8 bytes */
#define SLUB_MAX_SHIFT 10  /* 1024 bytes */
#define SLUB_MIN_OBJECT (1 << SLUB_MIN_SHIFT)
#define SLUB_MAX_OBJECT (1 << SLUB_MAX_SHIFT)
#define SLUB_MAX_CLASSES (SLUB_MAX_SHIFT - SLUB_MIN_SHIFT + 1)

static struct slab_cache caches[SLUB_MAX_CLASSES];

/* helpers */
static inline unsigned size_to_index(size_t size)
{
    if (size == 0) return 0;
    unsigned s = SLUB_MIN_SHIFT;
    while ((1u << s) < size && s <= SLUB_MAX_SHIFT) s++;
    if (s > SLUB_MAX_SHIFT) return (unsigned)-1;
    return s - SLUB_MIN_SHIFT;
}

static inline size_t index_to_size(unsigned idx)
{
    return (size_t)1 << (idx + SLUB_MIN_SHIFT);
}

/* Align pointer down to page boundary */
static inline void *page_align_down(void *p)
{
    uintptr_t v = (uintptr_t)p;
    return (void*)(v & ~(PAGE_SIZE - 1));
}

/* slab header placed at beginning of slab memory (page-aligned) */
#define SLAB_HEADER(ptr) ((struct slab *)(ptr))

/* Create new slab for cache (npages typically 1) */
static struct slab *slab_create(struct slab_cache *cache, int npages)
{
    void *page = host_alloc_pages(npages);
    if (!page) return NULL;

    struct slab *s = SLAB_HEADER(page);
    size_t obj_size = cache->obj_size;
    size_t header_sz = sizeof(struct slab);

    /* compute base of object area after header, align to obj_size */
    uintptr_t base = (uintptr_t)page + ((header_sz + (uintptr_t)(obj_size - 1)) & ~((uintptr_t)(obj_size - 1)));
    size_t usable = (size_t)npages * PAGE_SIZE - (base - (uintptr_t)page);
    unsigned nr = (unsigned)(usable / obj_size);
    if (nr == 0) {
        host_free_pages(page, npages);
        return NULL;
    }

    s->next = NULL;
    s->free_count = nr;
    s->page = page;
    s->obj_size = (unsigned)obj_size;
    s->nr_objs = nr;
    s->npages = npages;

    /* init free list */
    for (unsigned i = 0; i < nr; i++) {
        void *obj = (void *)((uintptr_t)base + i * obj_size);
        void **slot = (void **)obj;
        if (i == nr - 1) *slot = NULL;
        else *slot = (void *)((uintptr_t)obj + obj_size);
    }
    s->free_list = (void *)base;
    return s;
}

/* allocate obj from slab */
static void *slab_alloc_obj(struct slab *s)
{
    if (!s->free_list) return NULL;
    void *obj = s->free_list;
    s->free_list = *(void **)obj;
    s->free_count--;
    return obj;
}

/* free obj back to slab */
static void slab_free_obj(struct slab *s, void *obj)
{
    *(void **)obj = s->free_list;
    s->free_list = obj;
    s->free_count++;
}

/* remove slab from singly-linked list (head may change) */
static void slab_remove_from_list(struct slab **head, struct slab *s)
{
    struct slab *prev = NULL, *cur = *head;
    while (cur) {
        if (cur == s) {
            if (prev) prev->next = cur->next;
            else *head = cur->next;
            cur->next = NULL;
            return;
        }
        prev = cur;
        cur = cur->next;
    }
}

/* add slab to head of list */
static void slab_add_head(struct slab **head, struct slab *s)
{
    s->next = *head;
    *head = s;
}

/* Find slab header from pointer: align down to page start */
static struct slab *slab_from_ptr(void *ptr)
{
    void *page = page_align_down(ptr);
    struct slab *s = SLAB_HEADER(page);
    if (s->nr_objs == 0 || s->obj_size == 0) {
        return NULL;
    }
    return s;
}

/* create caches */
int slub_init(void)
{
    for (unsigned i = 0; i < SLUB_MAX_CLASSES; i++) {
        caches[i].obj_size = (unsigned)index_to_size(i);
        caches[i].partial = NULL;
        caches[i].full = NULL;
        slub_lock_init(&caches[i].lock);
        caches[i].nr_slabs = 0;
        caches[i].nr_allocs = 0;
        caches[i].nr_frees = 0;
    }
    return 0;
}

/* public page-level alloc wrappers */
void *kmalloc_pages(int npages)
{
    return host_alloc_pages(npages);
}
void kfree_pages(void *ptr, int npages)
{
    host_free_pages(ptr, npages);
}

/* public kmalloc / kfree */
void *kmalloc(size_t size)
{
    if (size == 0) size = 1;
    if (size > SLUB_MAX_OBJECT) {
        /* large alloc: allocate enough pages */
        int npages = (int)((size + PAGE_SIZE - 1) / PAGE_SIZE);
        void *p = host_alloc_pages(npages);
        if (!p) return NULL;
        struct slab *s = SLAB_HEADER(p);
        s->page = p;
        s->npages = npages;
        s->nr_objs = 0xFFFFFFFF; /* marker for large alloc */
        return (void *)((uintptr_t)p + sizeof(struct slab)); /* return after header */
    }

    unsigned idx = size_to_index(size);
    if (idx == (unsigned)-1) return NULL;
    struct slab_cache *cache = &caches[idx];

    slub_lock(&cache->lock);

    struct slab *s = cache->partial;
    if (!s) {
        /* create new slab (1 page) */
        s = slab_create(cache, 1);
        if (!s) {
            slub_unlock(&cache->lock);
            return NULL;
        }
        cache->nr_slabs++;
        slab_add_head(&cache->partial, s);
    }

    /* allocate object */
    void *obj = slab_alloc_obj(s);
    if (!obj) {
        /* shouldn't happen: just in case, try next slab or create new */
        slab_remove_from_list(&cache->partial, s);
        slab_add_head(&cache->full, s);
        slub_unlock(&cache->lock);
        return kmalloc(size); /* retry */
    }

    cache->nr_allocs++;

    /* if slab becomes full, move to full list */
    if (s->free_count == 0) {
        slab_remove_from_list(&cache->partial, s);
        slab_add_head(&cache->full, s);
    }

    slub_unlock(&cache->lock);

    return obj;
}

void kfree(void *ptr)
{
    if (!ptr) return;

    void *page = page_align_down(ptr);
    struct slab *s = SLAB_HEADER(page);

    /* detect large alloc marker */
    if (s->nr_objs == 0xFFFFFFFFu) {
        int npages = s->npages;
        void *base = s->page;
        host_free_pages(base, npages);
        return;
    }

    unsigned obj_size = s->obj_size;
    if (obj_size == 0 || s->nr_objs == 0) {
        /* invalid free (not from slub) */
        return;
    }

    unsigned idx = size_to_index(obj_size);
    if (idx == (unsigned)-1) return;
    struct slab_cache *cache = &caches[idx];

    slub_lock(&cache->lock);

    /* if slab was full, move it to partial first */
    if (s->free_count == 0) {
        slab_remove_from_list(&cache->full, s);
        slab_add_head(&cache->partial, s);
    }

    slab_free_obj(s, ptr);
    cache->nr_frees++;

    /* If slab becomes completely free, free the slab pages back to pmm */
    if (s->free_count == s->nr_objs) {
        slab_remove_from_list(&cache->partial, s);
        cache->nr_slabs--;
        host_free_pages(s->page, s->npages);
    }

    slub_unlock(&cache->lock);
}

/* diagnostic */
void slub_print_stats(void)
{
    cprintf("SLUB statistics:\n");
    for (unsigned i = 0; i < SLUB_MAX_CLASSES; i++) {
        struct slab_cache *c = &caches[i];
        if (c->nr_slabs == 0 && c->nr_allocs == 0 && c->nr_frees == 0) continue;
        cprintf(" size=%4u, slabs=%3u, allocs=%6u, frees=%6u\n",
               (unsigned)c->obj_size, c->nr_slabs, c->nr_allocs, c->nr_frees);
    }
}

