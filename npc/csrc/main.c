#include <common.h>

void init_monitor(int argc, char** argv);
void init_verilator(int argc, char** argv, char** env);
void init_module();
void delete_module();
void engine_start();
int is_exit_status_bad();


int main(int argc, char** argv, char** env) {
  
  init_monitor(argc, argv);

  init_verilator(argc, argv, env);

  printf("1\n");
  init_module();  

  printf("2\n");
  engine_start();

  printf("3\n");
  // Return good completion status
  delete_module();
  return is_exit_status_bad();

}

