#ifndef _MYHASH_H
#define _MYHASH_H

#define HASH_MASK 0x0000000001ff0000Ull

#include <linux/types.h>

__u64 newhash(__u64 key, __u64 len);

int getindex(__u64 hash);


#endif