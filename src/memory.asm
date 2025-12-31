;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; Defines utilities for working with memory ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    realloc_msg db "Rallocating failed", 0xA, 0x0

section .text
    extern puts
    global mmap
    global realloc

; Allocate memory
; mmap(long size, long* addr)
mmap:

    xor rdi, rdi        ; addr ; 0 means let os chose
    mov rsi, [rsp+8]    ; Size in bytes
    mov rdx, 3          ; READ & WRITE
    mov r10, 34         ; flags 
    mov r8, -1          ; fd 
    xor r9, r9          ; offset

    mov rax, 9          ; syscall number for mmap (x86-64 Linux)
    syscall             ; Pointer to new memory in RAX, or error in RAX if negative

    ; Return address
    test rax, rax               
    ja .write_address            
    mov QWORD [rsp+16], 0x0   ; NULL
    jmp .return

.write_address:
    mov rdi, [rsp+16]
    mov [rdi], rax
.return:
    ret

; Resize pointer to a new length
; realloc(long* ptr, long curr_size, long new_size)
realloc:

    mov rax, QWORD [rsp+8]
    mov rdi, QWORD [rax]
    add rdi, QWORD [rsp+16] ; Pointer to the memory to check if free

    mov rsi, QWORD [rsp+24]
    sub rsi, QWORD [rsp+16] ; Actual memory that needs to be actually allocated

    ; mmap syscall providing the address
    mov rdx, 3          ; READ & WRITE
    mov r10, 34         ; flags 
    mov r8, -1          ; fd 
    xor r9, r9          ; offset
    mov rax, 9          ; syscall number for mmap (x86-64 Linux)
    syscall

    test rax, rax
    ja .return

    push realloc_msg
    call puts
    add rsp, 0x8

    ; Else need to allocate new memeory & copy data
    sub rsp, 0x8
    push rsp
    push QWORD [rsp+24]
    call mmap
    add rsp, 0x10

    mov rax, [rsp+16]    ; Current size
    mov rdx, [rsp]       ; New Pointer

    mov rsi, [rsp+8]     ; Old Pointer
    mov rsi, [rsi]

.loop:

    cmp rax, 0x0

    cmp rax, 0x0
    jz .write_new_address

    mov dl, byte [rsi]
    mov byte [rdx], dl

    inc rsi
    inc rdi
    dec rax

    jmp .loop

.write_new_address:
    mov rsi, [rsp+8]
    mov rax, [rsp]
    mov [rsi], rax

.return:
    ret