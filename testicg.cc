// 纯裸机环境，不依赖任何标准库
typedef long long int64_t;
typedef unsigned long long uint64_t;

// --- 硬件外设接口 (MMIO) ---
#define UART_ADDR  0x40600004ULL
#define TIMER_ADDR 0x20003000ULL

// 串口输出字符
static inline void putchar(char c) {
    *(volatile unsigned char *)(UART_ADDR) = (unsigned char)c;
}

// 串口输出字符串
static inline void puts(const char *s) {
    while (*s) putchar(*s++);
}

// 串口输出 64 位无符号整数 (替代 std::cout)
static inline void put_u64(uint64_t x) {
    if (x == 0) {
        putchar('0');
        return;
    }
    char buf[25];
    int pos = 0;
    do {
        buf[pos++] = '0' + (x % 10);
        x /= 10;
    } while (x);
    while (pos--) putchar(buf[pos]);
}

// 读取系统计时器 (微秒)
static inline uint64_t uptime_us() {
    return *(volatile uint64_t *)(TIMER_ADDR);
}

class ICG_PRNG {
private:
    int64_t state;
    int64_t p;
    int64_t a;
    int64_t c;

    // 核心高负载函数：密集产出 div, mul, rem, sub 指令
    int64_t extEuclideanInverse(int64_t n, int64_t m) {
        if (n == 0) return 0; 

        int64_t t = 0;
        int64_t newt = 1;
        int64_t r = m;
        int64_t newr = n;

        while (newr != 0) {
            int64_t quotient = r / newr;
            int64_t temp_t = t - quotient * newt;
            t = newt;
            newt = temp_t;
            int64_t temp_r = r % newr;
            r = newr;
            newr = temp_r;
        }

        if (t < 0) {
            t += m;
        }
        return t;
    }

public:
    ICG_PRNG(int64_t seed) {
        p = 2147483647LL; 
        a = 9102LL;       
        c = 2110582212LL; 
        
        state = seed % p;
        if (state < 0) {
            state += p;
        }
    }

    uint64_t next_uint32() {
        int64_t inv = extEuclideanInverse(state, p);
        state = (a * inv + c) % p;
        return (uint64_t)state;
    }

    uint64_t next_uint64() {
        uint64_t high = next_uint32();
        uint64_t low = next_uint32();
        return (high << 32) | low;
    }
};

int main() {
    puts("--- ICG PRNG Bare-metal Benchmark ---\n");
    
    // 初始化种子 114514
    ICG_PRNG rng(114514LL);
    
    uint64_t random_val = 0;
    uint64_t iterations = 1145; 
    
    // 1. 记录开始时间
    uint64_t start_time = uptime_us();
    
    // 2. 核心高负载循环
    for(uint64_t i = 0; i < iterations; i++) {
        random_val = rng.next_uint64();
    }
    
    // 3. 记录结束时间
    uint64_t end_time = uptime_us();
    uint64_t dt_us = end_time - start_time;
    
    // 4. 计算 it/s (每秒迭代次数)
    // 公式: (iterations / dt_us) * 1000000 
    // 防止整数截断，先乘后除
    uint64_t it_per_s = 0;
    if (dt_us > 0) {
        it_per_s = (iterations * 1000000ULL) / dt_us;
    }
    
    // 打印最终结果和性能指标
    puts("Seed            : 114514\n");
    puts("Iterations      : "); put_u64(iterations); puts("\n");
    puts("Final    Result : "); put_u64(random_val); puts("\n");
    puts("Expected Result : 5022853189604196808\n");
    
    if(random_val == 5022853189604196808ULL) {
        puts("---  Test Passed  ---\n");
    } else {
        puts("---     Wrong     ---\n");
    }

    puts("Time Elapsed(us): "); put_u64(dt_us); puts("\n");
    puts("Performance     : "); put_u64(it_per_s); puts(" it/s\n");
    puts("-------------------------------------\n");

    return 0;
}