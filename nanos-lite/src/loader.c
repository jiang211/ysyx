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
    
    /*
    FILE *fp;
    fp = fopen(filename, "rb");
    
	
    Elf32_Ehdr edhr;
	//读取elf头
    assert(fread(&edhr, sizeof(Elf32_Ehdr), 1, fp)==1);
  
    assert(*(uint32_t *)edhr.e_ident == 0x464c457f); //moshu elf

    fseek(fp, edhr.e_phoff, SEEK_SET);
    
    Elf32_Phdr phdr;
    
    // 遍历程序头表
    for (int i = 0; i < edhr.e_phnum; i++) {
      
        assert(fread(&phdr, sizeof(Elf32_Phdr), 1, fp) <= 0);
        
        // 检查是否为可加载段
        if (phdr.p_type == PT_LOAD) {
            void *mem = malloc(phdr.p_memsz);
            fseek(fp, phdr.p_offset, SEEK_SET);
            
            ramdisk_write(mem, phdr.p_vaddr, phdr.p_memsz);
            // 清零剩余内存
            memset(mem + phdr.p_filesz, 0, phdr.p_memsz - phdr.p_filesz);

            free(mem);
        }
    }
    fclose(fp);
    return edhr.e_entry;
    */
   Elf32_Ehdr ehdr;
   ramdisk_read(&ehdr, 0, sizeof(Elf_Ehdr));
   Elf_Phdr phdr[ehdr.e_phnum];
   ramdisk_read(phdr, ehdr.e_ehsize, sizeof(Elf_Phdr)*ehdr.e_phnum);
   for (int i = 0; i < ehdr.e_phnum; i++) {
       if (phdr[i].p_type == PT_LOAD) {
           ramdisk_read((void*)phdr[i].p_vaddr, phdr[i].p_offset, phdr[i].p_memsz);
           memset((void*)(phdr[i].p_vaddr+phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);
       }
   }
   return ehdr.e_entry;

}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", (void *)entry);
  ((void(*)())entry) ();
}

