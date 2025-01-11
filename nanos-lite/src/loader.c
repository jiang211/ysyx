#include <proc.h>
#include <elf.h>
#include <stdio.h>
#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif
size_t ramdisk_write(const void *buf, size_t offset, size_t len);
size_t get_ramdisk_size();
size_t ramdisk_read(void *buf, size_t offset, size_t len);
static uintptr_t loader(PCB *pcb, const char *filename) {
    
    
   Elf32_Ehdr ehdr;
   ramdisk_read(&ehdr, 0, sizeof(Elf32_Ehdr));
   assert(*(uint32_t *)ehdr.e_ident == 0x464c457f); 
   Elf_Phdr phdr[ehdr.e_phnum];//
   ramdisk_read(phdr, ehdr.e_ehsize, sizeof(Elf_Phdr)*ehdr.e_phnum);
   for (int i = 0; i < ehdr.e_phnum; i++) {
       if (phdr[i].p_type == PT_LOAD) {
           ramdisk_read((void*)phdr[i].p_vaddr, phdr[i].p_offset, phdr[i].p_memsz);
           memset((void*)(phdr[i].p_vaddr+phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);
       }
   }
   return ehdr.e_entry;

}
/*
static uintptr_t loader(PCB *pcb, const char *filename) {
    
  int fd = fs_open(filename, 0, 0);
  assert(fd);
   Elf32_Ehdr ehdr;
   fs_read(fd, &ehdr, sizeof(Elf32_Ehdr));
   assert(*(uint32_t *)ehdr.e_ident == 0x464c457f); 
   Elf_Phdr phdr;
   for (int i = 0; i < ehdr.e_phnum; i++) {
       fs_lseek(fd, ehdr.e_phoff + ehdr.e_phentsize*i, SEEK_SET);
       fs_read (fd, &phdr, sizeof(Elf_Phdr));
       if (phdr[i].p_type == PT_LOAD) {
           fs_lseek(fd, ehdr.phdr.p_offset, SEEK_SET);
           fs_read (fd, (char *)elf_phdr.p_vaddr, elf_phdr.p_memsz);
           ramdisk_read((void*)phdr[i].p_vaddr, phdr[i].p_offset, phdr[i].p_memsz);
           memset((void*)(phdr[i].p_vaddr+phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);
       }
   }
   return ehdr.e_entry;

}
*/
void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", (void*)entry);
  ((void(*)())entry) ();
}

