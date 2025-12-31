section .data
    features_filename db "data/data.txt", 0
    labels_filename db "data/labels.txt", 0
    dimensions_str db "- Number of rows = %d, Number of columns = %d.", 0xA, 0
    header_str db "- First five rows : ", 0xA, 0
    labels_header_str db "- First five labels : ", 0xA, 0
    start_algo_str db "- Running logistic regression with %d epochs...", 0xA, 0
    data dq 7.25, 2.64, 0.32, 5.5, 16.45, 2.888, 0.01, 2.1, 0.7, 0.4, 0.2, 4.4, 2.7, 3.3, 2.3
    labels dq 1.0, 0.0, 0.0, 1.0, 1.0
    one_float dq 0.9999999
    lr dq 0.1

section .bss
    buffer resb 1024
    buflen equ $-buffer

section .text

    ; Memory
    extern mmap
    extern realloc

    ; Printing functions
    extern print_buffer
    extern display_memory
    extern puts
    extern putc
    extern puti
    extern putf
    extern printf

    ; Working with vector and matrices
    extern display_matrix

    extern gtv

    extern addvs
    extern mulvs
    extern divvs
    extern divsv

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

    extern transpose
    extern expv

    ; I/O
    extern fopen
    extern fread
    extern fclose

    ; Utils
    extern parse_float

    ; Logistic regression functions
    extern accuracy
    extern load_matrix
    extern sigmoid
    extern logistic_regression
    extern inference

    global _start

main:

    ; Stack frame
    mov rbp, rsp

    ; Local Variables
    ; Pointer to bias : rbp-0x40
    ; Pointer to weights : rbp-0x38
    ; Number of columns : rbp-0x30
    ; Number of labels : rbp-0x28
    ; Pointer to data : rbp-0x20
    ; Number of Rows : rbp-0x18
    ; Number of cols : rbp-0x10
    ; Pointer to features : rbp-0x8
    sub rsp, 0x40

    ;;;;;;;;;;; Load Data From Files ;;;;;;;;;;; 

    ; Load Features
    mov rax, rbp
    mov rdx, rbp
    mov rdi, rbp

    sub rax, 0x18
    sub rdx, 0x10
    sub rdi, 0x8

    push rdi
    push rdx
    push rax
    push features_filename
    call load_matrix
    add rsp, 0x20

    ; Print dimensions
    push QWORD [rbp-0x10]
    push QWORD [rbp-0x18]
    push dimensions_str
    call printf
    add rsp, 0x18

    ; Print first five rows
    push header_str
    call puts
    add rsp, 0x8

    mov rsi, 1019
    imul rsi, 0x20
    add rsi, [rbp-0x8]

    push rsi
    push QWORD [rbp-0x10]
    push 0x5
    call display_matrix
    add rsp, 0x18

    ; Load Labels
    mov rax, rbp
    mov rdx, rbp
    mov rdi, rbp

    sub rax, 0x30
    sub rdx, 0x28
    sub rdi, 0x20

    push rdi
    push rdx
    push rax
    push labels_filename
    call load_matrix
    add rsp, 0x20

    ; Print dimensions
    push QWORD [rbp-0x28]
    push QWORD [rbp-0x30]
    push dimensions_str
    call printf
    add rsp, 0x18

    ; Print first five labels
    push labels_header_str
    call puts
    add rsp, 0x8

    push QWORD [rbp-0x20]
    push 0x1
    push 0x5
    call display_matrix
    add rsp, 0x18

    ; Run Algorithm
    push 0x64
    push start_algo_str
    call printf
    add rsp, 0x10

    mov rax, rbp
    sub rax, 0x40

    mov rdx, rbp
    sub rdx, 0x38

    ; jmp .exit

    push rax
    push rdx
    push 0x64
    push QWORD [lr]
    push QWORD [rbp-0x20]
    push QWORD [rbp-0x8]
    push QWORD [rbp-0x10]
    push 1024
    call logistic_regression
    add rsp, 0x40


.exit:
    ; System call for sys_exit (syscall number 60 in x86-64 Linux ABI)
    mov rax, 60
    xor rdi, rdi                ; Exit code 0
    syscall                     ; Invoke the system call


_start:
    call main                   ; Call main