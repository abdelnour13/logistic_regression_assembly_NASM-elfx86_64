;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; Utilities For Working with files ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    file_open_error_msg db "Error when opening the file : %s",0xA, 0x0

section .text

    extern printf

    global fopen
    global fread
    global fclose

; Open's a file in read mode
; fopen(char* filname, long* fd)
fopen:

    push rbp
    mov rbp, rsp

    mov rax, 2  ; Syscall for opening a file
    mov rdi, [rsp+16]  ; Filename
    mov rsi, 0 ; O_READONLY
    mov rdx, 0 ; Permissions (applies only when creating a file)
    syscall

    cmp rax, 0x0
    js .print_error
    jmp .return

.print_error:

    push rax

    push QWORD [rsp+16]
    push file_open_error_msg
    call printf
    add rsp, 0x10

    pop rax

.return:
    mov rdi, [rsp+24]
    mov QWORD [rdi], rax
.done:
    mov rsp, rbp
    pop rbp
    ret

; Read N bytes from a file and put into the buffer
; Returns the number of bytes read
; fread(long fd, char* buffer, long buflen, long* bytes_read)
fread:

    mov rdi, [rsp+8] ; File descriptor
    mov rsi, [rsp+16] ; Buffer
    mov rdx, [rsp+24] ; Length
    mov rax, 0 ; Syscall for read
    syscall

    mov rdi, [rsp+32]
    mov [rdi], rax

.done:
    ret

; Close the file
; close(long fd)
fclose:

    mov rax, 3
    mov rdi, [rsp+8]
    syscall

    ret