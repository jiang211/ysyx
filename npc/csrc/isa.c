#include <paddr.h>
//#include <isa.h>
#include <common.h>


static const uint32_t img [] = {
  0x70010117,  // auipc t0,0
  0x04812683,  // sb  zero,16(t0)
  0x04012603,  // lbu a0,16(t0)
  0x00012503,  // lbu a0,16(t0)
  0xffd68293,  // lbu a0,16(t0)
  0x03012683,
  0x00812083,
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

static void restart() {  
  /* Set the initial program counter. */
  cpu.pc = 0x30000000;
  printf("Reset PC: 0x%08x\n", cpu.pc);
  /* The zero register is always 0. */
  cpu.gpr[0] = 0;
  cpu.csr[1] = 0x1800;
}


void init_isa() {
  /* Load build-in image. */
  memcpy(guest_to_host(0x30000000), img, sizeof(img));
  /* Initialize this vertual computer system. */
  restart();
}
