;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Defines utilities for printing and debugging ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

    ; Exports
    global print_buffer
    global display_memory
    global puts
    global putc
    global puti
    global putf
    global printf

; prints a string of a known length
; print_buffer(char*, long)
print_buffer:
    mov rax, 1          ; syscall for write
    mov rdi, 1          ; stdout
    mov rsi, [rsp+8]    ; buffer
    mov rdx, [rsp+16]   ; number of bytes
    syscall
    ret

; display memory in hex
; display_memory(long, char*)
display_memory:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rsp+24]   ; Pointer
    mov rcx, [rsp+16]   ; Length
    xor rdx, rdx        ; Number of bytes

.loop:

    cmp rcx, 0x0
    jz .write
    
    mov dil, [rax]
    test rdx, 0x1
    jz .extract_lower
    jmp .extract_upper

.extract_lower:
    and dil, 0x0F
    jmp .convert
.extract_upper:
    and dil, 0xF0
    shr dil, 0x4
    dec rcx
    inc rax
.convert:
    cmp dil, 0xA
    js .convert_to_digit
    jmp .convert_to_letter
.convert_to_digit:
    add dil, 0x30
    jmp .put_byte
.convert_to_letter:
    add dil, 0x37
.put_byte:
    inc rdx
    dec rsp
    mov [rsp], dil
    jmp .loop
.write:
    mov rax, rsp
    push rdx
    push rax
    call print_buffer
.done:
    ; Clear and return
    mov rsp, rbp
    pop rbp
    ret

; prints a NULL terminated string
; puts(char*)
puts:
    ; Establish function frame
    push rbp
    mov rbp, rsp

    mov rsi, [rsp+16] ; Load The Argument from the stack
    mov rdx, rsi ; Serves as a pointer to the current character

.loop:
    ; compute the length of the string
    ; result in rdx register
    cmp byte [rdx], 0x0
    jz .write
    inc rdx
    jmp .loop

.write:
    ; Write syscall
    sub rdx, rsi  ; Compute the length of the string
    mov rax, 1    ; Syscall code for write
    mov rdi, 1    ; Stdout
    syscall

.done:
    ; Clear frame & return
    mov rsp, rbp
    pop rbp
    ret

; putc(char c)
putc:
    mov rsi, rsp
    add rsi, 0x8
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall
    ret

; prints 64 bit signed integer
; puti(long)
puti:
    ; Function frame
    push rbp         
    mov rbp, rsp    

    mov rax, [rsp+16]
    xor rdx, rdx
    xor rsi, rsi

    dec rsp
    mov [rsp], byte 0x0
    
    cmp rax, 0x0
    js .signed
    jmp .init
.signed:
    mov rsi, '-'
    neg rax
.init:
    xor rdi, rdi
.loop:
    cmp rax, 0xA
    js .put_digit
    sub rax, 0xA
    inc rdi
    jmp .loop
.put_digit:
    add rax, 0x30
    dec rsp
    mov [rsp], byte al
    inc rdx
    cmp rdi, 0x0
    jz .sign
    mov rax, rdi
    jmp .init
.sign:
    cmp rsi, 0x0
    jz .done
    dec rsp
    mov [rsp], byte sil
    inc rdx
    jmp .done
.done:
    mov rax, rsp
    push rdx
    push rax
    call print_buffer

    mov rsp, rbp
    pop rbp
    ret

; prints 64 bits signed float (double precision) 
; with six digits after decimal point
; putf(double)
putf:
    
    push rbp
    mov rbp, rsp

    movsd xmm0, [rbp+16]  ; Load argument

    ; Get absolute value & sign
    movsd xmm2, xmm0
    
    mov rax, 0x7FFFFFFFFFFFFFFF   ; Absolute value
    movq xmm1, rax
    andpd xmm0, xmm1      

    mov rax, 0x8000000000000000   ; Sign 
    movq xmm1, rax
    andpd xmm2, xmm1     

    ; Array of two bytes
    sub rsp, 0x2
    mov word [rbp-2], 0x002E ; Equivelant to ".", 0    
    
    ; compute integer part
    cvtsd2si rax, xmm0
    cvtsi2sd xmm1, rax
    ucomisd xmm0, xmm1
    jb .dec
    jmp .addsign
    
.dec:
    dec rax
.addsign:

    ; mov rcx, rax
    movq rdx, xmm2
    cmp rdx, 0x0
    jz .enddec
    
    push rax       ; Save RAX

    dec rsp                 ; putc
    mov byte [rsp], '-'     ;  (
    call putc               ;    '\n'
    inc rsp                 ;  )

    pop rax       ; Load RAX
    
.enddec:

    ; display integer part
    push rax
    call puti

    ; floating point
    mov rax, rbp         ; puts 
    sub rax, 0x2         ; (
    push rax             ;    str
    call puts            ; )
    add rsp, 0x8         ; clear arguments

    ; float part
    pop rax
    cvtsi2sd xmm1, rax
    subsd xmm0, xmm1
    mov rdx, 0xF4240  
    cvtsi2sd xmm1, rdx
    mulsd xmm0, xmm1
    roundsd xmm0, xmm0, 0x01
    cvtsd2si rax, xmm0

    cmp rax, 0x0
    jz .print_float_part
    
    ; Leading zeros
    mov rdi, rax
    imul rdi, 0xA
    xor rcx, rcx
.leading_zeros:

    cmp rdi, rdx
    jnb .print_leading_zeros
    imul rdi, 0xA
    inc rcx

    dec rsp
    mov byte [rsp], '0'

    jmp .leading_zeros

.print_leading_zeros:

    mov rsi, rsp      ; Call function
    push rax
    push rcx          ; print_buffer (
    push rsi          ;     rsi, rcx
    call print_buffer ; )

    add rsp, 0x10  ; Clear aguments
    pop rax
    ; add rsp, rcx

.print_float_part:
    push rax
    call puti

.done:
    mov rsp, rbp
    pop rbp
    ret

; print formatted string
; Supports long, double and NULL terminated string
; printf(char*,...)
printf:
    ; function frame
    push rbp
    mov rbp, rsp

    sub rsp, 0x16         ; Make room for two varibles of 8 bytes each
    mov rax, [rbp+16]     ; Load first argument from the stack
    mov [rbp-16], rax     ; Local variable holding the pointer
    mov QWORD [rbp-8], 24 ; Local variable Keeps track of next argument to load
    
.loop:

    cmp byte [rax], 0x0
    jz .handle_last

    cmp byte [rax], '%'
    jz .handle_param

    inc rax

    jmp .loop

.handle_param:

    sub rax, QWORD [rbp-16] ; Compute the strings length
    push rax                ; print_buffer(
    push QWORD [rbp-16]     ;   char* str, long length
    call print_buffer       ; )

    add rsp, 0x8            ; Clear arguments
    pop rax

    inc rax                 ; Update pointer to point on the next character after %
    add rax, QWORD [rbp-16]
    mov QWORD [rbp-16], rax

    cmp byte [rax], '%'      
    jz .escape_percent
    jmp .fmt_begin

.fmt_begin:

    mov rdi, [rbp-8]       ; Load the next argument to format
    mov rdx, [rbp+rdi]

    push rdx               ; Function argument

    ; Call the right formatting function
    ; if (char == 'd') puti(arg)
    ; else if (char == 'f') putf(arg)
    ; else if (char == 's') puts(arg)
    cmp byte [rax], 'd'
    jz .fmt_int

    cmp byte [rax], 'f'
    jz .fmt_float

    cmp byte [rax], 's'
    jz .fmt_str

.fmt_int:
    call puti
    jmp .fmt_end

.fmt_float:
    call putf
    jmp .fmt_end

.fmt_str:
    call puts
    jmp .fmt_end

.fmt_end:

    add rsp, 0x8      ; Clear putx argument

    mov rdi, [rbp-8]  ; Update the pointer to the next argument to load
    add rdi, 0x8
    mov [rbp-8], rdi

    inc QWORD [rbp-16]      ; Update the pointer to the next character
    mov rax, QWORD[rbp-16]

    jmp .loop

.escape_percent:     ; %% = %
    inc rax
    jmp .loop

.handle_last:
    sub rax, QWORD [rbp-16]
    push rax
    push QWORD [rbp-16]
    call print_buffer
.done:
    mov rsp, rbp
    pop rbp
    ret