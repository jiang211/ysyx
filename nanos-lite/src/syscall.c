#include <common.h>

#include "syscall.h"

int fs_open(const char *pathname, int flags, int mode);
size_t fs_read(int fd, void *buf, size_t len);
size_t fs_write(int fd, const void *buf, size_t len);
size_t fs_lseek(int fd, size_t offset, int whence);
int fs_close(int fd);

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
    case SYS_open:fs_open((char *)a[1], (int)a[2], (int)a[3]);break;
    case SYS_close:fs_close((int)a[1]);break;
    case SYS_lseek:fs_lseek((int)a[1], (size_t)a[2], (int)a[3]);break;
    case SYS_read:fs_read((int)a[1], (void *)a[2], (size_t)a[3]);break;
    case SYS_write:fs_write((int)a[1], (void *)a[2], (size_t)a[3]);break;
    case SYS_brk :c->GPRx = 0;break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
