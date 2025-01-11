#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

int main() {
    struct timeval tv, tv_start, tv_end;
    long long elapsed;  // 用于存储已经过去的时间（微秒）

    while (1) {
        // 获取当前时间作为开始时间
        gettimeofday(&tv_start, NULL);

        // 打印当前时间
        printf("Current time: %ld seconds and %ld microseconds since the Epoch\n",
               tv_start.tv_sec, tv_start.tv_usec);

        // 忙等待直到0.5秒过去
        do {
            gettimeofday(&tv_end, NULL);
            elapsed = (tv_end.tv_sec - tv_start.tv_sec) * 1000000LL + (tv_end.tv_usec - tv_start.tv_usec);
        } while (elapsed < 500000);

        // 此时已经过去了大约0.5秒
    }

    return 0;
}