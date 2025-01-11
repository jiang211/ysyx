#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <NDL.h>

int main() {
  struct timeval tv;
  // struct timezone tz;
  int ms = 500;
  while (1) {
    while (NDL_GetTicks() < ms) {
    }
    ms += 500;
    printf("ms = %d\n", ms);
  }
}
