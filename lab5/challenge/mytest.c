#include <ulib.h>
#include <stdio.h>

int num = 0;

int
main(void) {
    int pid;

    cprintf("Parent: initial num = %d\n", num);

    pid = fork();
    assert(pid >= 0);

    if (pid == 0) {
        // 子进程
        cprintf("Child: before write, num = %d\n", num);
        num = 100;
        cprintf("Child: after write, num = %d\n", num);
        exit(0);
    }

    wait();  

    cprintf("Parent: after child exit, num = %d\n", num);

    cprintf("COW test pass.\n");
    return 0;
}
