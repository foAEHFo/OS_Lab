#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>


//初始化运行队列，RR_init使用正确的成员变量赋值初始化运行队列rq，包括：
//- run_list：初始化后应为空列表。
//- proc_num：设置为0
//- max_time_slice：不需要在这里设置，该变量将由调用者分配
//提示：请参阅libs/list.h以获取链表结构的例程。
static void
RR_init(struct run_queue *rq)
{
    // LAB6: 2312141
    list_init(&rq->run_list);//初始化运行队列链表头
    rq->proc_num = 0;//将运行队列中的进程数量设置为0
}


//将进程插入运行队列尾部
//RR_enqueue将进程proc插入运行队列rq的尾部。该过程应验证/初始化proc的相关成员，然后将run_link节点放入队列中。
//该过程还应更新rq结构中的元数据。
//proc->time_slice表示为进程分配的时间片，应该设置为rq->max_time_slice。
//提示：请参阅libs/list.h以获取链表结构的例程。
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312141
    if(proc->time_slice<=0){
        proc->time_slice = rq->max_time_slice;//将进程的时间片设置为运行队列的最大时间片
    }
    list_add_before(&rq->run_list, &proc->run_link);//将进程的run_link节点插入运行队列的尾部
    rq->proc_num++;//将运行队列中的进程数量加1
}


//RR_dequeue会将进程proc从运行队列rq中移除。该过程应更新rq结构中的元数据。

static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312141
    list_del_init(&proc->run_link);//将进程的run_link节点从运行队列中移除并初始化
    rq->proc_num--;//将运行队列中的进程数量减1
}


 //RR_pick_next 从运行队列的前端选择一个元素，并返回相应的进程指针。
 //进程指针是通过宏le2proc计算的，见kern/process/proc.h中的定义。
//如果队列中没有进程，则返回NULL。
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2312141
    if (list_empty(&rq->run_list)) {
        return NULL;//如果运行队列为空，返回NULL
    }
    list_entry_t *next_entry = rq->run_list.next;//获取运行队列的第一个节点
    struct proc_struct *next_proc = le2proc(next_entry, run_link);//通过宏le2proc计算进程指针
    return next_proc;//返回下一个要运行的进程
}



 //RR_proc_tick通过当前进程的时钟滴答事件工作。你应该检查当前进程的时间片是否用尽，并更新进程结构体proc。
 //proc->time_slice表示当前进程剩余的时间片。
 //proc->need_resched是进程切换的标志变量
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312141
    proc->time_slice--;//将进程的时间片减1
    if (proc->time_slice <= 0) {
        proc->need_resched = 1;//如果时间片用尽，设置need_resched标志
    }
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",//轮转调度器
    .init = RR_init,//初始化运行队列
    .enqueue = RR_enqueue,//将进程加入运行队列
    .dequeue = RR_dequeue,//将进程从运行队列中移除
    .pick_next = RR_pick_next,//选择下一个可运行的任务
    .proc_tick = RR_proc_tick,//时间片滴答处理函数
};//调度类结构体实例
