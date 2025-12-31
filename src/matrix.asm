;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Defines utilities for working with matrices and vectors ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    zero_float dq 0.0
    one_float  dq 1.0
    e          dq 2.7182818284
    sign_mask  dq 0x8000000000000000

section .text

    extern printf
    extern putc
    extern mmap
    extern free

    global display_matrix

    global gtvs
    global mulvs
    global addvs
    global divvs

    global divsv
    global expv

    global addvv
    global subvv
    global xorvv
    global eqvv
    global mulvv
    global sqrtv

    global matmul
    global vdotproduct

    global vhsum
    global sum_0
    global mean_0
    global std_0
    global std_0

    global transpose

; Displays a matrix
; display_matrix(long nrows, long ncols, double* buff)
display_matrix:

    ; Stack Frame
    push rbp
    mov rbp, rsp

    sub rsp, 0x1C      ; Make room for four variables 3 of 8 bytes each and array of 4 bytes

    mov rax, [rbp+16]  ; First Argument : Number of rows
    mov [rbp-28], rax   

    mov rax, [rbp+32]  ; Third Argument : Pointer to data
    mov [rbp-12], rax  

    mov DWORD [rbp-4], 0x00206625 ;  EQUIV to "%f "

.outerloop:

    cmp QWORD [rbp-28], 0x0  ; if (nrows == 0) {
    jz .done                 ;    goto done
    dec QWORD [rbp-28]       ; } else  { nrows-- }

    mov rax, [rbp+24]        ; Second Argument : Number of columns
    mov [rbp-20], rax 

.innerloop:

    cmp QWORD [rbp-20], 0x0  ; if (ncols == 0) {
    jz .rowend               ;    goto rowend
    dec QWORD [rbp-20]       ; } else { ncols-- }

    mov rax, [rbp-12]   ; printf
    push QWORD [rax]    ; (
    mov rax, rbp        ;   
    sub rax, 0x4        ;   "%f ",
    push rax            ;   data[row][col]
    call printf         ;    
    add rsp, 0x8        ; )

    add QWORD[rbp-12], 0x8  ; data++

    jmp .innerloop

.rowend:
    dec rsp               ; putc(
    mov byte [rsp], 0xA   ;     '\n'
    call putc             ; )
    inc rsp               ;
    jmp .outerloop        ; goto outerloop

.done:
    mov rsp, rbp
    pop rbp
    ret

; Return ones if a number is greater than a threshold else zeros
; gtv(long size, double* v, double threshold, double* out)
gtvs:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    vbroadcastsd ymm0, [rbp+32]
    mov rsi, [rbp+40]

    vbroadcastsd ymm2, [one_float]

.loop:

    cmp rax, 0x0             ;  if(size == 0) {
    jz .done                 ;     goto done;
                             ;  } else if (size < 4) {
    cmp rax, 0x4             ;     goto lt4elm;
    js .lt4elm               ;  } else {
                             ;     rax -= 4
    sub rax, 0x4             ;  }

    vmovupd ymm1, [rdi]
    vcmpnlepd ymm1, ymm0
    vandpd ymm1, ymm2
    vmovupd [rsi], ymm1

    add rdi, 0x20
    add rsi, 0x20

    jmp .loop

.lt4elm:

    cmp rax, 0x1
    jz .last_elm
    sub rax, 0x2

    movupd xmm1, [rdi]
    cmpnlepd xmm1, xmm0
    andpd xmm1, xmm2
    movupd [rsi], xmm1

    cmp rax, 0x0
    jz .done

    add rdi, 0x10
    add rsi, 0x10

.last_elm:

    movq xmm1, [rdi]
    cmpnlesd xmm1, xmm0
    andpd xmm1, xmm2
    movq [rsi], xmm1

.done:
    mov rsp, rbp
    pop rbp
    ret


; Division of a vector with a scalar
; divvs(long size, double* v1, double scalar, double* out)
divvs:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    vbroadcastsd ymm0, [rbp+32]
    mov rsi, [rbp+40]

.loop:

    cmp rax, 0x0             ;  if(size == 0) {
    jz .done                 ;     goto done;
                             ;  } else if (size < 4) {
    cmp rax, 0x4             ;     goto lt4elm;
    js .lt4elm               ;  } else {
                             ;     rax -= 4
    sub rax, 0x4             ;  }

    vmovupd ymm1, [rdi]
    vdivpd ymm1, ymm0
    vmovupd [rsi], ymm1

    add rdi, 0x20
    add rsi, 0x20

    jmp .loop

.lt4elm:

    cmp rax, 0x1
    jz .last_elm
    sub rax, 0x2

    movupd xmm1, [rdi]
    divpd xmm1, xmm0
    movupd [rsi], xmm1

    cmp rax, 0x0
    jz .done

    add rdi, 0x10
    add rsi, 0x10

.last_elm:

    movq xmm1, [rdi]
    divsd xmm1, xmm0
    movq [rdi], xmm1

.done:
    mov rsp, rbp
    pop rbp
    ret    

; Divison of a scalar and a vector
; divsv(long size, double* v1, double scalar, double* out)
divsv:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    vbroadcastsd ymm0, [rbp+32]
    mov rsi, [rbp+40]

.loop:

    cmp rax, 0x0             ;  if(size == 0) {
    jz .done                 ;     goto done;
                             ;  } else if (size < 4) {
    cmp rax, 0x4             ;     goto lt4elm;
    js .lt4elm               ;  } else {
                             ;     rax -= 4
    sub rax, 0x4             ;  }

    vmovupd ymm1, [rdi]

    vdivpd ymm1, ymm0, ymm1
    vmovupd [rsi], ymm1

    add rdi, 0x20
    add rsi, 0x20

    jmp .loop

.lt4elm:

    cmp rax, 0x1
    jz .last_elm
    sub rax, 0x2

    movupd xmm1, [rdi]
    vdivpd xmm1, xmm0, xmm1
    movupd [rsi], xmm1

    cmp rax, 0x0
    jz .done

    add rdi, 0x10
    add rsi, 0x10

.last_elm:

    movq xmm1, [rdi]
    vdivsd xmm1, xmm0, xmm1
    movq [rdi], xmm1

.done:
    mov rsp, rbp
    pop rbp
    ret  


; computes exp ^ x TODO: search for better approximation
; expsv(long size, double* v1, double* out)
expv:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    mov rsi, [rbp+32]

    vbroadcastsd ymm0, [one_float]
    vbroadcastsd ymm1, [e]            ; Vector of e
    vbroadcastsd ymm2, [zero_float]   ; Vector of zeros
    vbroadcastsd ymm9, [sign_mask]

.loop:

    cmp rax, 0x0             
    jz .done                 
                             
    cmp rax, 0x4             
    ja .morethan4

    cmp rax, 0x1
    jz .one_elm
    jmp .two_elm
                             
.morethan4:
    vmovupd ymm3, [rdi]
    mov rdx, 0x4
    jmp .init
.two_elm:
    movupd xmm3, [rdi]
    mov rdx, 0x2
    jmp .init
.one_elm:
    movq xmm3, [rdi]
    mov rdx, 0x1

.init:

    ; Save sign & compute absolute value
    vcmpgtpd ymm10, ymm3, ymm2
    vandnpd ymm3, ymm9, ymm3

    vbroadcastsd ymm7, [one_float]    ; Vector of ones
    vroundpd ymm4, ymm3, 0x01         ; ymm4 has integer part
    vsubpd ymm3, ymm4                 ; ymm3 has float part

;;;;;;;; Exponential Of Integer Part ;;;;;;;;

.innerloop1:

    ; Get Mask
    vcmpgtpd ymm5, ymm4, ymm2 
    
    ; Check if all not greater than zero
    vextractf128 xmm6, ymm5, 0x1
    vextractf128 xmm8, ymm5, 0x0
    
    haddpd xmm6, xmm6
    haddpd xmm8, xmm8

    addpd xmm6, xmm8

    movq rcx, xmm6
    cmp rcx, 0x0
    jz .endloop1

    vsubpd ymm4, ymm0

    ; Multiply
    vandnpd ymm8, ymm5, ymm7
    vmulpd ymm7, ymm1
    vandpd ymm7, ymm5
    vaddpd ymm7, ymm8

    jmp .innerloop1

.endloop1:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; Exponential Of Float Part ;;;;;;;;;

.init_counter:

    mov rcx, 0x15
    vbroadcastsd ymm4, [one_float]

.innerloop2:

    cmp rcx, 0x0
    jz .endloop2

    cvtsi2sd xmm5, rcx
    vbroadcastsd ymm5, xmm5

    vdivpd ymm5, ymm3, ymm5 
    vmulpd ymm4, ymm5       
    vaddpd ymm4, ymm0       

    dec rcx

    jmp .innerloop2

.endloop2:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; e ^ (n + f) = (e^n) * (e^f) ;;;;;;;;;;

    vmulpd ymm7, ymm4
    vdivpd ymm3, ymm0, ymm7

    ; vcmpeqpd ymm10, ymm2

    vandpd ymm7, ymm10
    vandnpd ymm3, ymm10, ymm3
    vaddpd ymm7, ymm3

    cmp rdx, 0x4
    jnz .lt4
    vmovupd [rsi], ymm7
    jmp .update

.lt4:
    cmp rdx, 0x2
    jnz .lt2
    movupd [rsi], xmm7
    jmp .update

.lt2:
    movq [rsi], xmm7
    jmp .update

.update:

    sub rax, rdx
    imul rdx, 0x8

    add rdi, rdx
    add rsi, rdx

    jmp .loop

.done:
    mov rsp, rbp
    pop rbp
    ret  

; Addition of a vector with a scalar
; addvs(long size, double* v1, double scalar, double* out)
addvs:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    vbroadcastsd ymm0, [rbp+32]
    mov rsi, [rbp+40]

.loop:

    cmp rax, 0x0             ;  if(size == 0) {
    jz .done                 ;     goto done;
                             ;  } else if (size < 4) {
    cmp rax, 0x4             ;     goto lt4elm;
    js .lt4elm               ;  } else {
                             ;     rax -= 4
    sub rax, 0x4             ;  }

    vmovupd ymm1, [rdi]
    vaddpd ymm1, ymm0
    vmovupd [rsi], ymm1

    add rdi, 0x20
    add rsi, 0x20

    jmp .loop

.lt4elm:

    cmp rax, 0x1
    jz .last_elm
    sub rax, 0x2

    movupd xmm1, [rdi]
    addpd xmm1, xmm0
    movupd [rsi], xmm1

    cmp rax, 0x0
    jz .done

    add rdi, 0x10
    add rsi, 0x10

.last_elm:

    movq xmm1, [rdi]
    addsd xmm1, xmm0
    movq [rdi], xmm1

.done:
    mov rsp, rbp
    pop rbp
    ret

; Multiplication of a vector with a scalar
; mulvs(long size, double* v1, double scalar, double* out)
mulvs:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Load Arguments
    mov rax, [rbp+16]
    mov rdi, [rbp+24]
    vbroadcastsd ymm0, [rbp+32]
    mov rsi, [rbp+40]

.loop:

    cmp rax, 0x0             ;  if(size == 0) {
    jz .done                 ;     goto done;
                             ;  } else if (size < 4) {
    cmp rax, 0x4             ;     goto lt4elm;
    js .lt4elm               ;  } else {
                             ;     rax -= 4
    sub rax, 0x4             ;  }

    vmovupd ymm1, [rdi]
    vmulpd ymm1, ymm0
    vmovupd [rsi], ymm1

    add rdi, 0x20
    add rsi, 0x20

    jmp .loop

.lt4elm:

    cmp rax, 0x1
    jz .last_elm
    sub rax, 0x2

    movupd xmm1, [rdi]
    mulpd xmm1, xmm0
    movupd [rsi], xmm1

    cmp rax, 0x0
    jz .done

    add rdi, 0x10
    add rsi, 0x10

.last_elm:

    movq xmm1, [rdi]
    mulsd xmm1, xmm0
    movq [rdi], xmm1

.done:
    mov rsp, rbp
    pop rbp
    ret


; Multiply two vectors element by element
; mulvv(long size, double* v1, double* v2, double* out)
mulvv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vmovupd ymm1, [rdx]
    vmulpd  ymm0, ymm1
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    movupd xmm1, [rdx]
    mulpd xmm0, xmm1
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    movq xmm1, [rdx]
    mulsd xmm0, xmm1
    movq [rax], xmm0

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; Add two vectors element by element
; addvv(long size, double* v1, double* v2, double* out)
addvv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vmovupd ymm1, [rdx]
    vaddpd  ymm0, ymm1
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    movupd xmm1, [rdx]
    addpd xmm0, xmm1
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    movq xmm1, [rdx]
    addsd xmm0, xmm1
    movq [rax], xmm0

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; Substract two vectors element by element
; vsub(long size, double* v1, double* v2, double* out)
subvv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vmovupd ymm1, [rdx]
    vsubpd  ymm0, ymm1
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    movupd xmm1, [rdx]
    subpd xmm0, xmm1
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    movq xmm1, [rdx]
    subsd xmm0, xmm1
    movq [rax], xmm0

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; xor two vectors element by element
; vxor(long size, double* v1, double* v2, double* out)
xorvv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vmovupd ymm1, [rdx]
    vxorpd  ymm0, ymm1
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    movupd xmm1, [rdx]
    xorpd xmm0, xmm1
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    movq xmm1, [rdx]
    xorpd xmm0, xmm1
    movq [rax], xmm0

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; Return ones if arr1[i] == arr2[i] else zeros
; eqvv(long size, double* v1, double* v2, double* out)
eqvv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

    vbroadcastsd ymm2, [one_float]

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vmovupd ymm1, [rdx]
    vcmpeqpd ymm0, ymm1
    vandpd ymm0, ymm2
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    movupd xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    andpd xmm0, xmm2
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    movq xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    andpd xmm0, xmm2
    movq [rax], xmm0

.done:
    mov rsp, rbp
    pop rbp
    ret

; Add two vectors element by element
; addvv(long size, double* v1, double* out)
sqrtv:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+32] ; Pointer to write the return
    mov rsi, [rbp+24] ; Pointer to the vector
    mov rcx, [rbp+16] ; Length of vector

.loop:

    cmp rcx, 0x0
    jz .done

    vmovupd ymm0, [rsi]
    vsqrtpd  ymm0, ymm0
    vmovupd [rax], ymm0

    sub rcx, 0x4
    add rax, 0x20
    add rsi, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm0, [rsi]
    sqrtpd xmm0, xmm0
    movupd [rax], xmm0

    sub rcx, 0x2
    add rax, 0x10
    add rsi, 0x10

    cmp rcx, 0x0
    jz .done

.add_last_elm:

    movq xmm0, [rsi]
    sqrtsd xmm0, xmm0
    movq [rax], xmm0

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; Matrix multiplication of two matrices
; matmul(long a, long b, long c, double* m1, double* m2, double* out)
; m1 : axb, m2 : cxb
; Equiv : m1 @ m2.T
matmul:

    ; Stack frame
    push rbp
    mov rbp, rsp

.outerloop:

    cmp QWORD [rbp+16], 0x0  ; if (a == 0 )
    jz .done                 ; { goto done; }
    dec QWORD [rbp+16]       ; then { a--; }

    mov rax, [rbp+32]     ; Load c into rax
    mov rsi, [rbp+48]     ; Load m2 into rsi

.innerloop:

    cmp rax, 0x0          ; if (c == 0)
    jz .inc               ; { goto inc; }
    dec rax               ; then { c--; }               

    push rax              ; Save RAX

    push QWORD [rbp+56]   ; vdotproduct(
    push rsi              ;    b,
    push QWORD [rbp+40]   ;    &m[i],
    push QWORD [rbp+24]   ;    &m[j],
    call vdotproduct      ;    &out[i * nrows + j]
    add rsp, 0x10         ; )
    pop rsi
    add rsp, 0x8

    pop rax               ; Load RAX

    mov rdx, [rbp+24]
    imul rdx, 0x8
    add rsi, rdx          ; m2 += b * sizeof(double)

    add QWORD [rbp+56], 0x8  ; out += sizeof(double)

    jmp .innerloop

.inc:
    mov rdx, [rbp+24]
    imul rdx, 0x8
    add [rbp+40], rdx     ; m1 += b * sizeof(double)
    jmp .outerloop

.done:
    ; Clear frame & return
    mov rsp, rbp
    pop rbp
    ret

; Dot product of two vectors
; vdotproduct(long size, double* v1, double* v2, double* out)
vdotproduct:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Load arguments
    mov rax, [rbp+40] ; Pointer to write the return
    mov rdx, [rbp+32] ; Pointer to second vector
    mov rsi, [rbp+24] ; Pointer to first vector
    mov rcx, [rbp+16] ; Length of vector

    vxorpd ymm0, ymm0 ; Zero all ymm0 register


.loop:

    cmp rcx, 0x0
    jz .return

    cmp rcx, 0x4
    js .add_last_two_elm

    vmovupd ymm1, [rsi]
    vmovupd ymm2, [rdx]
    vmulpd  ymm1, ymm2
    vaddpd  ymm0, ymm1

    sub rcx, 0x4
    add rsi, 0x20
    add rdx, 0x20

    jmp .loop

.add_last_two_elm:

    cmp rcx, 0x1
    jz .add_last_elm

    movupd xmm1, [rsi]
    movupd xmm2, [rdx]
    mulpd xmm1, xmm2
    addpd xmm0, xmm1   ; xmm0 is the lower part of ymm0 so this adds directly to the lowest 128 bits of ymm0

    sub rcx, 0x2
    add rsi, 0x10
    add rdx, 0x10

    cmp rcx, 0x0
    jz .return

.add_last_elm:

    movq xmm1, [rsi]
    movq xmm2, [rdx]
    mulsd xmm1, xmm2
    addsd xmm0, xmm1

.return:

    vextractf128 xmm1, ymm0, 0x1 ; Move higher 128 bits of ymm0 to xmm1
    haddpd xmm0, xmm0 ; Add the two elements in xmm0 register
    haddpd xmm1, xmm1 ; Add the two elements in xmm1 register
    addsd xmm0, xmm1 
    movq [rax], xmm0  ; Write the value in the address reserved for return

.done:
    ; Clear function frame & return
    mov rsp, rbp
    pop rbp
    ret

; compute sum of all elements
; vhsum(long size, double* v, double* out)
vhsum:

    ; Stack frame
    push rbp
    mov rbp, rsp

    vxorpd ymm0, ymm0 ; ymm0 := [0, 0, 0, 0]

    mov rax, [rbp+24]
    mov rdx, [rbp+32]

.loop:

    cmp QWORD [rbp+16], 0x0   ; if (nrows == 0 ) {
    jz .return                ;   goto done;
                              ; }
    cmp QWORD [rbp+16], 0x4   ; else if (nrows < 4) {
    js .lt4elm                ;   goto lt4elm;
                              ; }
    sub QWORD [rbp+16], 0x4   ; else { nrows -= 4 }

    vmovupd ymm1, [rax]
    vaddpd  ymm0, ymm1

    add rax, 0x20

    jmp .loop 

.lt4elm:

    cmp QWORD [rbp+16], 0x1
    jz .last_elm
    sub QWORD [rbp+16], 0x2

    movupd xmm1, [rax]
    addpd xmm0, xmm1

    cmp QWORD [rbp+16], 0x0
    jz .return
    add rax, 0x10

.last_elm:

    movq xmm1, [rax]
    addsd xmm0, xmm1

.return:

    vextractf128 xmm1, ymm0, 0x1 
    haddpd xmm0, xmm0 
    haddpd xmm1, xmm1
    addsd xmm0, xmm1 
    movq [rdx], xmm0  

.done:
    mov rsp, rbp
    pop rbp
    ret

; Reduce to sum of columns
; sum_0(long nrows, long ncols, double* v, double* out)
sum_0:

    ; stack frame
    push rbp
    mov rbp, rsp

    ; Zero output
    push QWORD [rbp+40]  ; vxor(
    push QWORD [rbp+40]  ;  ncols,
    push QWORD [rbp+40]  ;  out,
    push QWORD [rbp+24]  ;  out,
    call xorvv           ;  out
    add rsp, 0x20        ; )

.loop:

    cmp QWORD [rbp+16], 0x0  ; if(nrows == 0) {
    jz .done                 ;   goto done;
    dec QWORD [rbp+16]       ; } else { nrows--; }

    push QWORD [rbp+40]  ; vadd(
    push QWORD [rbp+40]  ;  nrows,
    push QWORD [rbp+32]  ;  v,
    push QWORD [rbp+24]  ;  out
    call addvv           ;  out
    add rsp, 0x20        ; )

    mov rax, [rbp+24]     ;
    imul rax, 0x8        ; v += nrows * sizeof(double)
    add [rbp+32], rax    ;

    jmp .loop

.done:
    ; Return & clear frame
    mov rsp, rbp
    pop rbp
    ret

; Compute the mean and std row wise
; mean_0(long nrows, long ncols, double* data, double* out)
mean_0:

    ; Stack frame
    push rbp
    mov rbp, rsp

    ; Sum
    push QWORD [rbp+40]   ;  sum_0(
    push QWORD [rbp+32]   ;    nrows,
    push QWORD [rbp+24]   ;    ncols,
    push QWORD [rbp+16]   ;    data,
    call sum_0            ;    out
    add rsp, 0x20         ;  )

    ; Division
    cvtsi2sd xmm0, [rbp+16] ;
    sub rsp, 0x8            ;  a = (double) nrows;
    movq [rbp-8], xmm0      ;

    push QWORD [rbp+40]     ; divvs(
    push QWORD [rbp-8]      ;   ncols,
    push QWORD [rbp+40]     ;   out, scalar,
    push QWORD [rbp+24]     ;   out
    call divvs              ; )

.done:
    ; Clear and return
    mov rsp, rbp
    pop rbp
    ret


; Computes the standard diviation row wise
; std_0(long nrows, long ncols, double* data, double* out)
var_0:

    ; stack frame
    push rbp
    mov rbp, rsp

    ; Make four local variables of 8 bytes each
    ; One holds the float value of number of rows
    ; The two other holds pointer to two memory addresses
    sub rsp, 0x20

    cvtsi2sd xmm0, [rbp+16]    ; a = (double) nrows;
    movq [rbp-8], xmm0  

    mov rax, [rbp+16]
    imul rax, [rbp+24]
    mov [rbp-32], rax          ; d = nrows * ncols

    ;;;;;;;;;;;;;;;;;;;; Allocate an array of ncols doubles ;;;;;;;;;;;;;;;;;;;

    mov rax, [rbp+24]  ; rax = ncols * sizeof(double)
    imul rax, 0x8

    mov rdi, rbp       ; rdi = &b;
    sub rdi, 0x10

    push rdi           ; mmap(
    push rax           ;   rax, /* ncols * sizeof(double) */
    call mmap          ;   rdi /* &b */
    add rsp, 0x10      ; )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;; Allocate an array with the same size as the input ;;;;;;;;;;;;;;

    mov rax, [rbp+16]
    imul rax, [rbp+24]
    imul rax, 0x8

    mov rdi, rbp
    sub rdi, 0x18

    push rdi
    push rax
    call mmap
    add rsp, 0x10

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Compute mu ** 2
    push QWORD [rbp-16]      ;  mean_0(
    push QWORD [rbp+32]      ;    nrows, 
    push QWORD [rbp+24]      ;    ncols,
    push QWORD [rbp+16]      ;    data
    call mean_0              ;    b
    add rsp, 0x20            ;  )

    push QWORD [rbp-16]      ; mulvv(
    push QWORD [rbp-16]      ;   ncols,
    push QWORD [rbp-16]      ;   b,
    push QWORD [rbp+24]      ;   b
    call mulvv               ;   b
    add rsp, 0x20            ; )

    ; Compute sum_of_squares / N
    push QWORD [rbp-24]      ; mulvv(
    push QWORD [rbp+32]      ;   total_size,
    push QWORD [rbp+32]      ;   data
    push QWORD [rbp-32]      ;   data
    call mulvv               ;   c
    add rsp, 0x20            ; )

    push QWORD [rbp+40]      ; sum_0(
    push QWORD [rbp-24]      ;   nrows,
    push QWORD [rbp+24]      ;   ncols,
    push QWORD [rbp+16]      ;   c,
    call sum_0               ;   out
    add rsp, 0x20            ; )

    push QWORD [rbp+40]      ; divvs(
    push QWORD [rbp-8]       ;   ncols,
    push QWORD [rbp+40]      ;   out,
    push QWORD [rbp+24]      ;   a,
    call divvs               ;   out
    add rsp, 0x20            ; )

    ; Compute variance
    ; var = sum_of_squares / N - mu ** 2
    push QWORD [rbp+40]
    push QWORD [rbp-16]
    push QWORD [rbp+40]
    push QWORD [rbp+24]
    call subvv
    add rsp, 0x20

    ;;;;;;;;;;;;;;;;;;;;;; Free Memory ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Free first buffer
    mov rax, [rbp+24]  
    imul rax, 0x8

    push rax           
    push QWORD [rbp-0x10]           
    call free          
    add rsp, 0x10  

    ; Free second buffer
    mov rax, [rbp+16]
    imul rax, [rbp+24]
    imul rax, 0x8

    push rax           
    push QWORD [rbp-0x18]           
    call free          
    add rsp, 0x10     

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.done:
    mov rsp, rbp
    pop rbp
    ret

; Computes the standard diviation row wise
; std_0(long nrows, long ncols, double* data, double* out)
std_0:

    ; function frame
    push rbp
    mov rbp, rsp

    push QWORD [rbp+40]
    push QWORD [rbp+32]
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call var_0
    add rsp, 0x20

    push QWORD [rbp+40]
    push QWORD [rbp+40]
    push QWORD [rbp+24]
    call sqrtv
    add rsp, 0x20

.done:
    mov rsp, rbp
    pop rbp
    ret

; transpose(long nrows, long ncols, double* m, double* out)
transpose:

    ; function frame
    push rbp
    mov rbp, rsp

    mov rdi, QWORD [rbp+16]

.outerloop:

    cmp rdi, 0x0
    jz .done
    dec rdi

    mov rcx, [rbp+24]

.innerloop:

    cmp rcx, 0x0
    jz .outerloop
    dec rcx

    ; i * ncols + j
    mov rax, rdi
    imul rax, QWORD [rbp+24]
    add rax, rcx
    imul rax, 0x8

    ; j * nrows + i
    mov rdx, rcx
    imul rdx, QWORD [rbp+16]
    add rdx, rdi
    imul rdx, 0x8

    ; m2[j][i] = m1[i][j]
    mov rsi, QWORD [rbp+32]
    add rsi, rax

    mov rax, [rsi]

    mov rsi, QWORD [rbp+40]
    add rsi, rdx

    mov [rsi], rax

    jmp .innerloop

.done:
    mov rsp, rbp
    pop rbp
    ret