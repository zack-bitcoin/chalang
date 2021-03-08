
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int op_gas = 10000;
int ram_current = 0;
int ram_most = 0;
int ram_limit = 10000;
int many_funs = 0;
int fun_limit = 100;
int hash_size = 32;
int state_height = 200000;
int state_slash = 0;

struct element {
  int type;//int, binary, or stack. 1, 2, 3.
  int integer;
  char *
};

struct element * vars[10000];

//need database for vars, funs.
//need stack and altstack.


int print_chars(){
  int c = getchar();
  if(10 == c){
    return(0);
  };
  printf("%i\n", c);
  return(print_chars());
};

int main(int argc, char * argv[]){
  if(argc > 1){ op_gas = atoi(argv[1]); };
  if(argc > 2){ ram_limit = atoi(argv[2]); };
  if(argc > 3){ fun_limit = atoi(argv[3]); };
  if(argc > 4){ state_height = atoi(argv[4]); };

  print_chars();
  return(0);
};
