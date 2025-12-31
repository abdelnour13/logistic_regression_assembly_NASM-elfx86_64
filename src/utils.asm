
section .data
    one_double dq 1.0
    negative_double dq -1.0

section .text

    ; Exports
    global parse_float
    global exit


; Converts Null terminated string into a float
; parse_float(char* str, double* ret)
parse_float:
    ; Establish function stack
    push rbp
    mov rbp, rsp
.part1:
    ; Zero rcx and rdi registers
    mov rax, [rbp+16]
    xor rcx, rcx
    xor rdi, rdi
    movq xmm3, [one_double]

.check_sign:

    cmp byte [rax], 0x0
    jz .part3

    cmp byte [rax], '-'
    jz .set_sign

    cmp byte [rax], '+'
    jz .advance

    jmp .loop1

.set_sign:
    movq xmm3, [negative_double]
.advance:
    inc rax
.loop1:

    ; If all bytes are read convert the integer value in rcx to 64bit floating point
    cmp byte [rax], 0x0          
    jz .part3       

    ; Read the current byte           
    mov dil, byte [rax]

    ; Counters/Pointers inc/dec
    inc rax

    ; If the character '.' is encountred then handle fraction value 
    cmp dil, '.'
    jz .part2

    ; Add the digit to the current value
    imul rcx, 0xA
    add rcx, rdi
    sub rcx, 0x30

    jmp .loop1
.part2:
    ; Convert signed integer to signed double precision float
    cvtsi2sd xmm0, rcx
    xor rcx, rcx
    mov rsi, 0x1       ; This will be equal to 10^number of digits after fraction
.loop2:

    ; If all digits are read then add the fraction to the integer part stored in xmm0
    cmp byte [rax], 0x0
    jz .part4

    ; Add the digit to the current value of rcx
    mov dil, byte [rax]
    imul rcx, 0xA
    add rcx, rdi
    sub rcx, 0x30

    ; Counters/Pointers inc/dec
    inc rax

    ; rsi update
    imul rsi, 0xA

    jmp .loop2
.part3:
    cvtsi2sd xmm0, rcx
    jmp .return
.part4:
    cvtsi2sd xmm1, rcx
    cvtsi2sd xmm2, rsi
    divsd xmm1, xmm2
    addsd xmm0, xmm1 
    mulsd xmm0, xmm3
.return:
    mov rax, [rbp+24]
    movq [rax], xmm0
.done:
    ; Clear function stack and return
    mov rsp, rbp
    pop rbp
    ret

exit:
    mov rax, 60
    mov rdi, [rsp+0x8]          ; Exit code
    syscall                     ; Invoke the system call
    ret