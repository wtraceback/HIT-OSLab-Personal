#include <stdio.h>
#include <unistd.h>         // fork wait
#include <time.h>
#include <sys/times.h>
#include <sys/types.h>      // typedef int pid_t;
#include <stdlib.h>         // exit

#define HZ	100

void cpuio_bound(int last, int cpu_time, int io_time);

/*
* 要求：
* 1. 所有子进程都并行运行，每个子进程的实际运行时间一般不超过 30 秒；
* 2. 父进程向标准输出打印所有子进程的 id，并在所有子进程都退出后才退出；
*/
int main(int argc, char * argv[])
{
    // 创建 10 个进程
    pid_t proc_id_arr[10];      // 10 个子进程的 PID
    int i;
    for (i = 0; i < 10; i++) {
        proc_id_arr[i] = fork();

        if (proc_id_arr[i] < 0) {  // 创建子进程失败
            printf("Failed to fork child process %d!\n", i + 1);
            exit(-1);       // 非常重要，必须得退出
        } else if (proc_id_arr[i] == 0) {   // 子进程
            cpuio_bound(20, 2 * i, (20 - 2 * i));
            exit(0);        // 非常重要，必须得退出子进程
        } else {    // 父进程
            ;
            // 父进程继续循环 fork
        }
    }

    // 打印所有子进程的 PID
    for (i = 0; i < 10; i++) {
        printf("Child PID: %d\n", proc_id_arr[i]);
    }

    // 等待所有子进程完成后再退出父进程
    wait(&i);

    return 0;
}

/*
 * 此函数按照参数占用CPU和I/O时间
 * last: 函数实际占用CPU和I/O的总时间，不含在就绪队列中的时间，>=0是必须的
 * cpu_time: 一次连续占用CPU的时间，>=0是必须的
 * io_time: 一次I/O消耗的时间，>=0是必须的
 * 如果last > cpu_time + io_time，则往复多次占用CPU和I/O
 * 所有时间的单位为秒
 */
void cpuio_bound(int last, int cpu_time, int io_time)
{
    struct tms start_time, current_time;
    clock_t utime, stime;
    int sleep_time;

    while (last > 0)
    {
        /* CPU Burst */
        times(&start_time);
        /* 其实只有t.tms_utime才是真正的CPU时间。但我们是在模拟一个
         * 只在用户状态运行的CPU大户，就像“for(;;);”。所以把t.tms_stime
         * 加上很合理。*/
        do
        {
            times(&current_time);
            utime = current_time.tms_utime - start_time.tms_utime;
            stime = current_time.tms_stime - start_time.tms_stime;
        } while ( ( (utime + stime) / HZ )  < cpu_time );
        last -= cpu_time;

        if (last <= 0 )
            break;

        /* IO Burst */
        /* 用sleep(1)模拟1秒钟的I/O操作 */
        sleep_time=0;
        while (sleep_time < io_time)
        {
            sleep(1);
            sleep_time++;
        }
        last -= sleep_time;
    }
}
