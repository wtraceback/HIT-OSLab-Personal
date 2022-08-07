#include <asm/segment.h>                // get_fs_byte
#include <errno.h>                      // EINVAL
#include <string.h>                     // strcpy strlen

char _myname[24];       // 23 个字符 + '\0' = 24 操作系统内核在运行的时候就预留出空间存储名字

int sys_iam(const char* name) {
    char temp[30];

    int i = 0;
    // 获取用户态内存中的字符串
    for (i = 0; i < 30; i++) {
        // 从用户态内存中获取输入的字符串
        temp[i] = get_fs_byte(name + i);

        // 如果识别到字符串的末尾，则结束循环
        if (temp[i] == '\0') {
            break;
        }
    }

    int len = strlen(temp);

    if (len > 23) {         // 等于 23 则说明有 23 个字符以及一个空字符
        return -(EINVAL);   // 置 errno 为 EINVAL ，返回 ­-1 ，具体见 _syscalln 的宏展开
    }

    strcpy(_myname, temp);

    return len;
}

int sys_whoami(char* name, unsigned int size) {
    int len = strlen(_myname) + 1;      // 包含字符串末尾的空字符 \0

    if (size < len) {
        return -(EINVAL);
    }

    // 把内核态内存中的 _myname 保存的字符串输出到用户态内存的 name 中
    int i = 0;
    for (i = 0; i < len; i++) {
        put_fs_byte(_myname[i], (name + i));
    }

    return len - 1;
}