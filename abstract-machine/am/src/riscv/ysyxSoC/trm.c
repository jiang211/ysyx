#include <am.h>
#include <klib-macros.h>
#include <riscv/riscv.h>
#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT (DEVICE_BASE + 0x000003f8)
extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

extern char _sdata;
extern char _edata;
extern char _sidata;
extern char _etext;

volatile void memcpy(void *dest, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;
    while (n--) *d++ = *s++;
}


void _trm_init() {
  memcpy(&_sdata, &_sidata, &_edata - &_sdata);
  int ret = main(mainargs);
  halt(ret);
}
