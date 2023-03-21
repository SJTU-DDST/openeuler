#include<linux/myhash.h>

__u64 newhash(__u64 key, __u64 len){
    __u64 seed = 0xc70f6907UL;
  // 'm' and 'r' are mixing constants generated offline.
  // They're not really 'magic', they just happen to work well.

    __u64 m = 0x5bd1e995;
    __u64 r = 24;

    // Initialize the hash to a 'random' value

    __u64 h = seed ^ len;

    // Mix 4 bytes at a time into the hash

    const unsigned char *data = (const unsigned char *)key;

    while (len >= 4) {
        unsigned int k = *(unsigned int *)data;

        k *= m;
        k ^= k >> r;
        k *= m;

        h *= m;
        h ^= k;

        data += 4;
        len -= 4;
    }

    // Handle the last few bytes of the input array

    switch (len) {
        case 3:
        h ^= data[2] << 16;
        break;
        case 2:
        h ^= data[1] << 8;
        break;
        case 1:
        h ^= data[0];
        h *= m;
        break;
    };

    // Do a few final mixes of the hash to ensure the last few
    // bytes are well-incorporated.

    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;

    return h;
}

int getindex(__u64 hash){
    return (int)((hash & HASH_MASK) >> 16);
}