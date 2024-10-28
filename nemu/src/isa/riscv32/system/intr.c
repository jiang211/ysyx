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

#include <isa.h>

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
#ifdef CONFIG_ETRACE
  printf(" mcause  =   0x%x \n", cpu.csr[2] );
  printf(" mstatus = 0x%x \n", cpu.csr[3]);
  printf(" mepc    = 0x%x \n", cpu.csr[0]   );
#endif
  cpu.csr[1] = 0x1800;
  cpu.csr[0] = epc;
  cpu.csr[2] = NO;
  return cpu.csr[3];
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
