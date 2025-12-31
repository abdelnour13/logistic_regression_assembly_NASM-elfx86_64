# Logistic Regression in Assembly

This project implements a Logistic Regression algorithm using Assembly language. It includes modules for matrix operations, memory management, and data I/O. For pure fun !

## How to run ?

1. Compile the project :

```bash
python3 compile.py
```

2. Run the excutable :

```bash
./main
```

## My Machine :

### CPU Architecture
- **Architecture:** x86_64
- **Execution Modes:** 32-bit, 64-bit
- **Byte Order:** Little Endian
- **Address Size:** 48-bit virtual, 48-bit physical

### Processor
- **CPU Model:** AMD Ryzen 5 5600H (Zen 3)
- **Vendor:** AMD
- **Cores:** 6
- **Threads:** 12 (SMT enabled)
- **Sockets:** 1

### Instruction Set Extensions
- **SIMD:** SSE, SSE2, SSE3, SSSE3, SSE4.1, SSE4.2
- **AVX:** AVX, AVX2
- **FMA:** FMA3
- **Crypto:** AES-NI, SHA
- **Other:** BMI1, BMI2, POPCNT, CLMUL

### Cache Hierarchy
- **L1 Data:** 32 KiB × 6
- **L1 Instruction:** 32 KiB × 6
- **L2:** 512 KiB × 6
- **L3:** 16 MiB (shared)

### Memory & NUMA
- **NUMA Nodes:** 1 (uniform memory access)