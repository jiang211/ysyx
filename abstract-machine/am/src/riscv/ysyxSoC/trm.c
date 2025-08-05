#include <am.h>
#include <klib-macros.h>
#include <riscv/riscv.h>
#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT (DEVICE_BASE + 0x000003f8)

#define UART_BASE 0x10000000L
#define UART_TX   0
#define UART_FC   2
#define UART_LC   3
#define UART_LS   5
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

void init_uart(){
  *(volatile char *)(UART_BASE + UART_LC) = 0b10000011;    // 1停止位，无校验位，禁止中断，开始写divisor
  *(volatile char *)(UART_BASE + UART_TX) = 0x1E;    // 
  *(volatile char *)(UART_BASE + UART_LC) = 0b00000011; 
}

void putch(char ch) {
  *(volatile char *)(UART_BASE + UART_TX) = ch;
  uint8_t TX_ISEMPTY = *(volatile char *)(UART_BASE + UART_LS);
    while ((TX_ISEMPTY & 0x40) != 0x40) { //等待uart数据发送完成
        TX_ISEMPTY = *(volatile char *)(UART_BASE + UART_LS);
    }
    while(((*(volatile char *)(UART_BASE + UART_LS))&0x20) != 0x20); //等待传输FIFO为空
    *(volatile char *)(UART_BASE + UART_FC) = 0b11000100; //清空缓存区
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

extern char _sdata;
extern char _edata;
extern char _sidata;
extern char _etext;

volatile void _memcpy(void *dest, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;
    while (n--) *d++ = *s++;
}


void _trm_init() {
  init_uart();
  _memcpy(&_sdata, &_sidata, &_edata - &_sdata);
  int ret = main(mainargs);
  halt(ret);
}
