;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Define Logisitc Regression Main Functions ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    one_float dq 1.0

section .text

    ; Imports
    extern gtvs
    extern eqvv
    extern vhsum
    extern mmap
    extern puti
    extern putf

    ; Exports
    global accuracy


; Computes the accuracy 
; accuracy(long size, double* target, double* pred, double threshold, double* out)
accuracy:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Memory allocation
    sub rsp, 0x8

    mov rax, [rbp+16]
    imul rax, 0x8

    push rsp
    push rax
    call mmap
    add rsp, 0x10

    ; Thresholding
    push QWORD [rbp-8]
    push QWORD [rbp+40]
    push QWORD [rbp+32]
    push QWORD [rbp+16]
    call gtvs
    add rsp, 0x20

    ; Eq
    push QWORD [rbp-8]
    push QWORD [rbp-8]
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call eqvv
    add rsp, 0x20

    ; Sum
    push QWORD [rbp+48]
    push QWORD [rbp-8]
    push QWORD [rbp+16]
    call vhsum
    add rsp, 0x18

    mov rax, [rbp+48]
    movq xmm0, [rax]    
    cvtsi2sd xmm1, [rbp+16]
    divsd xmm0, xmm1
    movq [rax], xmm0

.done:
    ; Clear stack & return
    mov rsp, rbp
    pop rbp
    ret