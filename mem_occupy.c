#include<stdio.h>  
#include<sys/mman.h>  
#include<stdlib.h>  
#include<unistd.h>  
  
//要占用100M内存，以字节为单位  
const int alloc_size = 1024*1024*1024;  
  
int main(){  
        char *mem = malloc(alloc_size);  
    //使用mlock锁定内存  
        if(mlock(mem,alloc_size) == -1){  
                perror("mlock");  
                return -1;  
        }  
    //typedef unsigned int size_t  
        size_t i;  
    //获得每一个内存页的大小，一般为4K  
        size_t page_size = getpagesize();  
        for(i=0;i<alloc_size;i+=page_size){  
            mem[i] = 0;  
        }  
          
        printf("i = %zd\n",i);  
        while(1){  
            sleep(5);  
        }  
        
        return 1;  
}  
