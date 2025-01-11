#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

int main() {
    struct timeval tv;
    struct timezone tz;
    int count = 0;
    long long start_time, current_time;

    // 获取初始时间
    gettimeofday(&tv, NULL);
    start_time = tv.tv_sec * 1000 + tv.tv_usec / 1000;  // 转换为毫秒

    while (1) {
        // 获取当前时间
        gettimeofday(&tv, NULL);
        current_time = tv.tv_sec * 1000 + tv.tv_usec / 1000;  // 转换为毫秒

        // 检查是否已经过去0.5秒（500毫秒）
        if (current_time - start_time >= 500) {
            // 打印当前时间
            printf("Current time: %ld seconds and %ld microseconds since the Epoch\n",
                   tv.tv_sec, tv.tv_usec);

            // 重置计时器
            start_time = current_time;
            count++;  // 增加计数器，用于其他可能的逻辑
        }
    }

    return 0;
}