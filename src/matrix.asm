;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Defines utilities for working with matrices and vectors ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    one_float dq 1.0

section .text

    extern printf
    extern putc
    extern mmap

    global display_matrix

    global gtvs
    global mulvs
    global addvs
    global divvs

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

    global vlogpd

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


; Addition of a vector with a scalar
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

    ; Make room for two variables of 8 bytes each
    sub rsp, 0x10

    mov rax, rbp

.outerloop:

    cmp QWORD [rbp+16], 0x0  ; if (a == 0 )
    jz .done                 ; { goto done; }
    dec QWORD [rbp+16]       ; then { a--; }

    mov rax, [rbp+32]     ; Load c into rax
    mov rsi, [rbp+48]     ; Load m2 into rsi

.innerloop:

    cmp rax, 0x0          ; if (c == 0)
    jz .inc               ; {  goto outerloop; }
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

    vmovupd ymm1, [rsi]
    vmovupd ymm2, [rdx]
    vmulpd  ymm1, ymm2
    vaddpd  ymm0, ymm1

    sub rcx, 0x4
    add rsi, 0x20
    add rdx, 0x20

    cmp rcx, 0x4
    js .add_last_two_elm

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

; Computes log of a double using trapez approximation
; log(double* values, double* out)
vlogpd:

    ; Stack frame
    push rbp
    mov rbp, rsp

    ; First argument, an array of four double precision 
    mov rdx, [rbp+16]       
    vmovupd ymm0, [rdx]  

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;; inverse arguments less than 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    vmovupd ymm1, ymm0          ; Copy arguments to ymm1 and ymm0
    vmovupd ymm2, ymm0

    mov rax, 0x3FF0000000000000 ; Put ones in ymm3 and ymm4
    push rax
    vbroadcastsd  ymm3, [rsp]
    vmovupd ymm4, ymm3

    vcmpgtpd ymm3, ymm0         ; Compute mask where it is all ones for elements less than one

    vandpd ymm0, ymm3           ; ymm1 will have elements that are greater than 1
    vsubpd ymm1, ymm0           

    vdivpd ymm4, ymm2           ; ymm4 will have inverse of elements that are less than one
    vandpd ymm4, ymm3           ; other elements are zeroed

    vaddpd ymm4, ymm1           ; ymm0 now have the desired values
    vmovupd ymm0, ymm4        

    ; Save sign for later

    vbroadcastsd ymm1, [rsp] ; ymm1 := 1
    vxorpd ymm7, ymm7 ; ymm2 := 0
    vsubpd ymm7, ymm1 ; ymm2 := ymm2 - ymm1
    vandpd ymm7, ymm3 ; ymm1 has -1 if less than 1 else 0

    vmovupd ymm4, ymm1
    vandpd  ymm4, ymm3 ; ymm4 has 1 if less than 1 else 0
    vsubpd  ymm1, ymm4 ; ymm1 has 0 if less than 1 else 1

    vaddpd ymm7, ymm1

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov rax, [rbp+24]       ; Second Argument to the pointer used to return the value

    ; Compute Steps
    mov rdx, 0x3FF0000000000000  ; Move the value 1 to all parts of ymm1
    push rdx
    vbroadcastsd ymm1, [rsp]

    vmovupd ymm2, ymm0 
    vsubpd ymm2, ymm1            ; ymm2 := values - 1

    mov rdx, 0x40C3880000000000  ; Move value 10^4 to all parts of ymm1
    push rdx
    vbroadcastsd ymm1, [rsp]

    vdivpd ymm2, ymm1            ; ymm2 := (values - 1) / 10^4

    ; Copy constants
    mov rdx, 0x3FE0000000000000  ; Move 0.5 to all parts of ymm1
    push rdx
    vbroadcastsd ymm1, [rsp]

    add rsp, 0x20 ; Free local constants

    mov rdx, 0x3FF0000000000000  ; Move 1 to all parts of ymm3
    push rdx
    vbroadcastsd ymm3, [rsp]

    vxorpd ymm4, ymm4 ; Zero register ymm4 ; will be used to store the results

    mov rcx, 0x2710   ; Put 10^4 in rcx

.loop:

    cmp rcx, 0x0                ; if (rcx == 0) {
    jz .return                  ;   goto return;
    dec rcx                     ; } else { rcx--; }

    vbroadcastsd ymm5, [rsp]    ; ymm5 := 1
    vdivpd ymm5, ymm3           ; ymm5 := 1/ymm3 := 1/x0

    vaddpd ymm3, ymm2           ; ymm3 := ymm3 + ymm2 = x0+dx
    vbroadcastsd ymm6, [rsp]    ; ymm5 := 1
    vdivpd ymm6, ymm3           ; ymm5 := 1/ymm3 := 1/(x0+dx)

    vaddpd ymm6, ymm5           ; ymm6 := ymm6 + ymm5 := (1/x0) + (1/(x0+dx))
    vmulpd ymm6, ymm2           ; ymm6 := ymm6 * ymm2 := dx * ((1/x0) + (1/(x0+dx)))
    vmulpd ymm6, ymm1           ; ymm6 := ymm6 * ymm1 := 0.5 * dx * ((1/x0) + (1/(x0+dx)))

    vaddpd ymm4, ymm6           ; xmm4 += xmm5

    jmp .loop

.return:
    vmulpd ymm4, ymm7
    vmovupd [rax], ymm4
.done:
    mov rsp, rbp
    pop rbp
    ret