#include <errno.h>
#define __LIBRARY__
#include <unistd.h>
#include <stdio.h>

_syscall2(int, whoami, char *, name, unsigned int, size);

int main(int argc, char *argv[]) {
    char name[30] = {0};

    // 调用库函数 API
    whoami(name, 30);
    printf("%s\n", name);

    return 0;
}