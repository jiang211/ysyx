/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif
#define MROM_base 0x20000000
#define MROM_size 0x00001000
#define SRAM_base 0x0f000000
#define SRAM_size 0x01000000
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }
uint8_t* guest_to_host_mrom(paddr_t paddr) { return pmem + paddr - MROM_base; }
uint8_t* guest_to_host_sram(paddr_t paddr) { return pmem + paddr - SRAM_base + MROM_size; }
static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static word_t mrom_read(paddr_t addr, int len) {
  printf("ret = %08x\n",host_read(guest_to_host_mrom(addr), len));
  word_t ret = host_read(guest_to_host_mrom(addr), len);
  return ret;
}

static word_t sram_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host_sram(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}



static void sram_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host_sram(addr), len, data);
}


static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
#ifdef CONFIG_IMTRACE
  printf("read at"FMT_PADDR "\n",addr);
#endif
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  if(addr >= MROM_base && addr < MROM_base + MROM_size){return mrom_read(addr,len);}
  if(addr >= SRAM_base && addr < SRAM_base + SRAM_size){return sram_read(addr,len);}
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  printf("write at " FMT_PADDR " len=%d, data=" FMT_WORD "\n", addr, len, data);
#ifdef CONFIG_IMTRACE
   printf("write at " FMT_PADDR " len=%d, data=" FMT_WORD "\n", addr, len, data);
#endif
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  if(addr >= SRAM_base && addr < SRAM_base + SRAM_size){sram_write(addr,len,data);return;}
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  
  out_of_bound(addr);
}
