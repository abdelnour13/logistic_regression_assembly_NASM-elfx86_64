section .data
    filename db "data.txt", 0
    float_value dq 5.5
    data  dq 11.5, -1.0, 4.4, 0.6, 7.0, 8.0, -5.0, 1.0, 2.1, 1.02, 5.1, 1.088, 3.6, 4.0, 2.0
    data2 dq 11.5, -1.0, 5.6, 7.1, 7.0, 8.0, -5.0, 0.5, 1.1, 1.00, 5.0, 1.0, 3.6, 4.0, 1.5
    sucess_msg db "Memeory allocated with sucess", 0xA, 0
    failed_msg db "Failed to allocate memory", 0xA, 0
    threshold dq 3.5

section .bss
    buffer resb 1024
    buflen equ $-buffer

section .text

    ; Memory
    extern mmap

    ; Printing functions
    extern print_buffer
    extern display_memory
    extern puts
    extern putc
    extern puti
    extern printf

    ; Working with vector and matrices
    extern display_matrix

    extern gtv

    extern addvs
    extern mulvs
    extern divvs

    extern addvv
    extern subvv
    extern xorvv
    extern eqvv
    extern mulvv

    extern matmul
    extern vdotproduct

    extern vhsum
    extern sum_0
    extern mean_0
    extern std_0

    extern vlogpd

    global _start

_start:
    
    mov rbp, rsp
    sub rsp, 0x8

    push rsp
    push 0x78
    call mmap
    add rsp, 0x10

    push data
    push 0xF
    push 0x1
    call display_matrix
    add rsp, 0x18

    push QWORD [rsp]
    push data2
    push data
    push 0xF
    call eqvv
    add rsp, 0x20
    
    push QWORD [rsp]
    push 0xF
    push 0x1
    call display_matrix
    add rsp, 0x18
    
.exit:
    ; System call for sys_exit (syscall number 60 in x86-64 Linux ABI)
    mov rax, 60
    xor rdi, rdi                ; Exit code 0
    syscall                     ; Invoke the system call