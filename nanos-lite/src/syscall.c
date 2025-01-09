#include <common.h>
#include <am.h>
#include <klib.h>
#include "syscall.h"
void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  printf("a[0] = %d\n", a[0]);
  switch (a[0]) {
    case 0:halt(c->GPRx);break;
    case 1:yield();break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
