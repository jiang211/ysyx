#include <common.h>

#include "syscall.h"

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;
  printf(" syscall_ID  =%x\n", a[0] );
  #ifdef CONFIG_STRACE
  printf(" syscall_ID  =   0x%x \n", a[0] );
#endif
  switch (a[0]) {
    case 0:halt(c->GPRx);break;
    case 1:yield();break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
