#include <stdio.h>
#include <stdint.h>
#include <sys/mman.h>

int main(int argc, char** argv) {
    printf("Hello world (%s)!\n", argv[0]);
    fflush(stdout);

    uint64_t* p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    printf("alloc = %p\n", p);
    printf("%16llx\n", *p);
    fflush(stdout);

    *p = 0x1122334455667788;
    printf("%16llx\n", *p);
    fflush(stdout);

    munmap(p, 4096);
    printf("%16llx\n", *p);
    fflush(stdout);

    uint64_t* q = mmap(p, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    printf("alloc = %p\n", q);
    printf("%16llx\n", *q);
    fflush(stdout);

    return 0;
}
