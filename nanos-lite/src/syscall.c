#include <common.h>

#include "syscall.h"

static void sys_write(Context *c) {
  printf("1\n");
  int fd = (int)c->GPR2;
  void *buf = (void *)c->GPR3;
  size_t count = (size_t)c->GPR4;
  if(fd == 1 || fd == 2) {
    for(int i = 0; i < count; i++) {
      putch(((char *)buf)[i]);
    }
  }
  c->GPRx = count;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;
  #ifdef CONFIG_STRACE
  printf(" syscall_ID  =   0x%x \n", a[0] );
#endif
  switch (a[0]) {
    case SYS_exit:halt(c->GPR1);break;
    case SYS_yield:yield();c->GPRx = 0;break;
    case SYS_write:sys_write(c);break;
    //case SYS_brk :c->GPRx = 0;break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
