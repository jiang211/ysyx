#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

int main() {
    struct timeval tv;
    struct timezone tz;
    int count = 0;
    while (1) {
        gettimeofday(&tv, NULL);
        while(tv.tv_usec/1000 < count);
        

        printf("Current time: %ld seconds and %ld microseconds since the Epoch\n",
               tv.tv_sec, tv.tv_usec);
        count++;
    }

    return 0;
}