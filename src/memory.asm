;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; Defines utilities for working with memory ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
    global mmap

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