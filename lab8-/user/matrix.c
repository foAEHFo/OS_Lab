#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MATSIZE     10

static int mata[MATSIZE][MATSIZE];
static int matb[MATSIZE][MATSIZE];
static int matc[MATSIZE][MATSIZE];

void
work(unsigned int times) {
    int i, j, k, size = MATSIZE;
    cprintf("0k,1!");
    for (i = 0; i < size; i ++) {
        cprintf("0k,12!");
        for (j = 0; j < size; j ++) {
            cprintf("0k,123!");
            mata[i][j] = matb[i][j] = 1;
        }
    }

    yield();

    cprintf("pid %d is running (%d times)!.\n", getpid(), times);

    while (times -- > 0) {
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
                matc[i][j] = 0;
                for (k = 0; k < size; k ++) {
                    matc[i][j] += mata[i][k] * matb[k][j];
                }
            }
        }
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
                mata[i][j] = matb[i][j] = matc[i][j];
            }
        }
    }
    cprintf("pid %d done!.\n", getpid());
    exit(0);
}

const int total = 21;

int
main(void) {
    int pids[total];
    cprintf("0k,1!");
    memset(pids, 0, sizeof(pids));
    cprintf("0k,2!");

    int i;
    for (i = 0; i < total; i ++) {
        cprintf("0k,3!");
        if ((pids[i] = fork()) == 0) {
            cprintf("0k,4!");
            srand(i * i);
            cprintf("0k,5!");
            int times = (((unsigned int)rand()) % total);
            times = (times * times + 10) * 100;
            cprintf("0k,6!");
            work(times);
            cprintf("0k,7!");
        }
        if (pids[i] < 0) {
            goto failed;
        }
    }

    cprintf("fork ok.\n");

    for (i = 0; i < total; i ++) {
        if (wait() != 0) {
            cprintf("wait failed.\n");
            goto failed;
        }
    }

    cprintf("matrix pass.\n");
    return 0;

failed:
    for (i = 0; i < total; i ++) {
        if (pids[i] > 0) {
            kill(pids[i]);
        }
    }
    panic("FAIL: T.T\n");
}

