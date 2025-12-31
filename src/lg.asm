;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Define Logisitc Regression Main Functions ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    one_float dq 1.0
    negative_float dq -1.0

section .text

    ; Imports
    extern mmap
    extern realloc
    extern free

    extern gtvs
    extern eqvv
    extern vhsum

    extern mulvs
    extern addvs
    extern divsv
    extern expv
    extern matmul
    extern subvv
    extern transpose

    extern parse_float
    extern fopen
    extern fread
    extern fclose

    ; Exports
    global accuracy
    global load_matrix
    global sigmoid
    global logistic_regression
    global inference


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

; load data
; Load data from a txt file into a matrix
; load_matrix(char* filename, long* nrows, long* ncols, double** ptr)
load_matrix:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Local Variables
    ; Total elements so far : rbp-0x89
    ; Number of cols : rbp-0x81
    ; Number of rows : rbp-0x79
    ; Flags - byte : rbp-0x71
    ; a - double : rbp-0x70
    ; Buffer of 16 bytes : rbp-0x68
    ; Number of bytes read : rbp-0x58
    ; Buffer of 64 bytes : rbp-0x50
    ; File descriptor : rbp-0x10
    ; mmap Buffer : rbp-0x8
    sub rsp, 0x89

    ; bit 1 : first file read ?
    ; bit 2 : file read result was 0 (0 bytes read EOF) ?
    mov byte [rbp-0x71], 0x01

    ; Init counters
    mov QWORD [rbp-0x81], 0x0
    mov QWORD [rbp-0x79], 0x0
    mov QWORD [rbp-0x89], 0x0

    ; Init pointer with NULL
    mov QWORD [rbp-0x8], 0x0

.open:

    ; Open file
    mov rax, rbp
    sub rax, 0x10                  ; &fd

    push rax                       ; fopen(
    push QWORD [rbp+16]            ;    filename,
    call fopen                     ;    &fd
    add rsp, 0x10                  ; )

    mov rsi, rbp
    sub rsi, 0x68                  
    mov rdi, rsi                   ; Second buffer (buff2) 

    mov rsi, rbp
    sub rsi, 0x68                  ; Buffer to read (buff2)

.read_file:

    push rsi

    mov rax, rbp
    sub rax, 0x50                  ; Buffer to read (buff1)

    mov rsi, rbp
    sub rsi, 0x58                  ; Number of read bytes (&bytes_read)

    push rsi                       ; fread(
    push 0x40                      ;    fd,
    push rax                       ;    buffer,
    push QWORD [rbp-0x10]          ;    buflen
    call fread                     ;    &bytes_read
    add rsp, 0x20                  ; )

    pop rsi

    cmp QWORD [rbp-0x58], 0x0      ; if (read_bytes == 0) goto set_and_parse;
    jz .set_and_parse              

    mov rax, rbp
    sub rax, 0x50                  ; Buffer to read (buff1)

    test byte [rbp-0x71], 0x01
    jz .copy_data
    
    inc QWORD [rbp-0x81]            ; ncols++;
    inc QWORD [rbp-0x79]            ; nrows++;

    jmp .copy_data

.set_and_parse:

    or byte [rbp-0x71], 0x2
    jmp .parse_float

.copy_data:

    cmp QWORD [rbp-0x58], 0x0      ; if (read_bytes == 0) {
    jz .read_file                  ;     goto read_file;
    dec QWORD [rbp-0x58]           ; }

    cmp byte [rax], ','            ; if (curr_byte == ',') goto increment_columns_count;
    jz .increment_columns_count    

    cmp byte [rax], 0xA            ; if (curr_byte == '\n') goto increment_columns_count;
    jz .increment_rows_count

    mov dl, byte [rax]             ; // copy data
    mov byte [rsi], dl             ; buff1[i1] := buff2[i2]

    inc rax                        ; buff1++;
    inc rsi                        ; buff2++

    jmp .copy_data

.increment_columns_count:
    test byte [rbp-0x71], 0x01     ; if (first_file_read) {
    jz .parse_float                ;  ncols++;
    inc QWORD [rbp-0x81]           ;  goto parse_float;
    jmp .parse_float               ; } else goto parse_float;

.increment_rows_count:

    and byte [rbp-0x71], 0xFE      ; set first bit (first file read) to zero
    inc QWORD [rbp-0x79]           ; nrows++;

    push rax
    push rsi
    push rdi

    mov rax, rbp                   ; Resize buffer
    sub rax, 0x8

    mov rdx, QWORD [rbp-0x89]      ; New size
    mov rdi, 0x8
    imul rdi, [rbp-0x81]
    add rdx, rdi

    push rdx
    push QWORD [rbp-0x89]          ; Resize
    push rax
    call realloc
    add rsp, 0x18

    pop rdi
    pop rsi
    pop rax

    jmp .parse_float

.parse_float:

    mov byte [rsi], 0x0            ; buff1[i1] := '\0';

    mov rdi, rbp
    sub rdi, 0x68                  ; Buffer to read (buff2)

    mov rcx, rbp
    sub rcx, 0x70                  ; &bytes_read

    push rax                       ; Save necessary registers in the stack
    push rsi

    push rcx                       ; parse_float(
    push rdi                       ;    buff1,
    call parse_float               ;    &double
                                   ; )
    
    pop rdi                        ; Load from the stack
    pop rcx
    pop rsi
    pop rax

    mov rsi, rdi                   ; reset index
    inc rax                        ; buff2++;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    push rsi
    push rax
    push rdi

    cmp QWORD [rbp-0x8], 0x0       ; if (ptr == NULL)
    jz .allocate_first_element     ; goto allocate_first_element;
    jmp .resize_buffer             ; else goto resize_buffer

.allocate_first_element:

    ; Allocate memory for a single double
    mov rax, rbp
    sub rax, 0x8

    push rax
    push 0x8
    call mmap
    add rsp, 0x10

    jmp .insert_element

.resize_buffer:        

    test byte [rbp-0x71], 0x01
    jnz .insert_element

    mov rax, rbp
    sub rax, 0x8

    mov rdx, QWORD [rbp-0x89]
    add rdx, 0x8

    push rdx
    push QWORD [rbp-0x89]
    push rax
    call realloc
    add rsp, 0x18

.insert_element:

    mov rax, [rbp-0x70]
    mov rdx, [rbp-0x8]
    add rdx, [rbp-0x89]

    mov QWORD [rdx], rax

    add QWORD [rbp-0x89], 0x8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.check_if_should_break:

    pop rdi
    pop rax
    pop rsi

    test byte [rbp-0x71], 0x02     ; if (last_read) {
    jnz .return                    ;    goto done;
    jmp .copy_data                 ; } else goto copy_data;

.return:

    mov rax, [rbp+24]

    cmp rax, 0x0
    jz .ncols

    mov rdx, [rbp-0x79]
    mov [rax], rdx

.ncols:

    mov rax, [rbp+32]

    cmp rax, 0x0
    jz .data

    mov rdx, [rbp-0x81]
    mov [rax], rdx

.data:

    mov rax, [rbp+40]
    mov rdx, [rbp-0x8]
    mov [rax], rdx

.close:

    push QWORD [rbp-0x10]
    call fclose
    add rsp, 0x8

.done:

    ; Clear frame and return
    mov rsp, rbp
    pop rbp
    ret

; Computes 1 / (1 + np.exp(-x))
; sigmoid(long size, double* v, double* out)
sigmoid:

    ; function frame
    push rbp
    mov rbp, rsp

    ; Compute -x
    push QWORD [rbp+32]
    push QWORD [negative_float]
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call mulvs
    add rsp, 0x20

    ; Compute exp(-x)
    push QWORD [rbp+32]
    push QWORD [rbp+32]
    push QWORD [rbp+16]
    call expv
    add rsp, 0x18

    ; Compute 1 + exp(-x)
    push QWORD [rbp+32]
    push QWORD [one_float]
    push QWORD [rbp+32]
    push QWORD [rbp+16]
    call addvs
    add rsp, 0x20

    ; Compute 1 / (1 + exp(-x))
    push QWORD [rbp+32]
    push QWORD [one_float]
    push QWORD [rbp+32]
    push QWORD [rbp+16]
    call divsv
    add rsp, 0x20

.done:
    ; clear stack frame & return
    mov rsp, rbp
    pop rbp
    ret


; Train a Logestic Regression 
; logistic_regression(
;    long nrows, long ncols, double* data, double* labels, double lr, long epochs
;    double** w, double* b
; )
logistic_regression:

    ; Function frame
    push rbp
    mov rbp, rsp

    ; Local Variables :
    ; - 8 bytes float 1 / nrows : rbp-0x38
    ; - 8 bytes float db : rbp-0x30
    ; - Temp buffer3 of nrows * ncols : rbp-0x28
    ; - Temp buffer2 of ncols : rbp-0x20
    ; - Temp buffer1 of nrows : rbp-0x18
    ; - Bias : rbp-0x10
    ; - Weight : rbp-0x8
    sub rsp, 0x38

    xor rax, rax           ; bias <- 0
    mov [rbp-0x10], rax

    movq xmm0, [one_float]         ; Initi with lr / nrows
    mov rax, [rbp+16]
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1
    mulsd xmm0, [rbp+48]
    movq [rbp-0x38], xmm0

    ; Allocate memory for weight
    mov rax, rbp           ; &w
    sub rax, 0x8

    mov rdx, [rbp+24]      ; Number of bytes to allocate ncols * sizeof(double)
    imul rdx, 0x8

    ; Allocate memory for weight vector
    push rax
    push rdx
    call mmap
    add rsp, 0x10

    ; Allocate memory tempbuf1
    mov rax, rbp           
    sub rax, 0x18

    mov rdx, [rbp+16]      ; Number of bytes to allocate nrows * sizeof(double)
    imul rdx, 0x8

    push rax
    push rdx
    call mmap
    add rsp, 0x10

    ; Allocate memory tempbuf2
    mov rax, rbp           
    sub rax, 0x20

    mov rdx, [rbp+24]      ; Number of bytes to allocate ncols * sizeof(double)
    imul rdx, 0x8

    push rax
    push rdx
    call mmap
    add rsp, 0x10

    ; Allocate memory tempbuf3
    mov rax, rbp           
    sub rax, 0x28

    mov rdx, [rbp+24]      ; Number of bytes to allocate nrows * ncols * sizeof(double)
    imul rdx, [rbp+16]
    imul rdx, 0x8

    push rax
    push rdx
    call mmap
    add rsp, 0x10

    ; Transpose data
    push QWORD [rbp-0x28]
    push QWORD [rbp+32]
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call transpose
    add rsp, 0x20

.loop:

    cmp QWORD [rbp+56], 0x0
    jz .return
    dec QWORD [rbp+56]

    ; y_hat = sigmoid(X @ W + b)
    push QWORD [rbp-0x18]
    push QWORD [rbp-0x8]
    push QWORD [rbp+32]
    push 0x1
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call matmul
    add rsp, 0x30

    push QWORD [rbp-0x18]
    push QWORD [rbp-0x10]
    push QWORD [rbp-0x18]
    push QWORD [rbp+16]
    call addvs
    add rsp, 0x20

    push QWORD [rbp-0x18]
    push QWORD [rbp-0x18]
    push QWORD [rbp+16]
    call sigmoid
    add rsp, 0x18

    ; Compute dz = y_hat - y
    push QWORD [rbp-0x18]
    push QWORD [rbp+40]
    push QWORD [rbp-0x18]
    push QWORD [rbp+16]
    call subvv
    add rsp, 0x20

    ; Compute lr * dw = lr * (X.T @ dz) / nrows
    push QWORD [rbp-0x20]
    push QWORD [rbp-0x18]
    push QWORD [rbp-0x28]
    push QWORD 0x1
    push QWORD [rbp+16]
    push QWORD [rbp+24]
    call matmul
    add rsp, 0x30

    push QWORD [rbp-0x20]
    push QWORD [rbp-0x38]
    push QWORD [rbp-0x20]
    push QWORD [rbp+16]
    call mulvs
    add rsp, 0x20

    ; Compute lr * db = lr * sum(dz) / nrows
    mov rax, rbp
    sub rax, 0x30

    push QWORD rax
    push QWORD [rbp-0x18]
    push QWORD [rbp+16]
    call vhsum
    add rsp, 0x18

    movq xmm0, [rbp-0x30]
    mulsd xmm0, [rbp-0x38]
    movq [rbp-0x30], xmm0

    ; update

    ; w -= lr * dw
    push QWORD [rbp-0x8]
    push QWORD [rbp-0x20]
    push QWORD [rbp-0x8]
    push QWORD [rbp+24]
    call subvv
    add rsp, 0x20

    ; b -= lr * db
    movq xmm0, [rbp-0x30]
    movq xmm1, [rbp-0x10]
    subsd xmm1, xmm0
    movq [rbp-0x10], xmm1

    jmp .loop

.return:

    mov rax, [rbp+64]
    mov rdx, [rbp-0x8]
    mov [rax], rdx

    mov rax, [rbp+72]
    mov rdx, [rbp-0x10]
    mov [rax], rdx

.free:

    ; Free temp buffer3
    mov rdx, [rbp+24]
    imul rdx, [rbp+16]
    imul rdx, 0x8

    push rdx
    push QWORD [rbp-0x28]
    call free
    add rsp, 0x10

    ; Free temp buffer2
    mov rdx, [rbp+24]
    imul rdx, 0x8

    push rdx
    push QWORD [rbp-0x20]
    call free
    add rsp, 0x10

    ; Free temp buffer1
    mov rdx, [rbp+16]
    imul rdx, 0x8

    push rdx
    push QWORD [rbp-0x18]
    call free
    add rsp, 0x10

.done:
    ; Clear stack & return
    mov rsp, rbp
    pop rbp
    ret

; inference (long nrows, long ncols, double* data, double* w, double b, double** out)
inference:

    ; stack frame
    push rbp
    mov rbp, rsp

    ; One variable pointer to buffer of nrows
    sub rsp, 0x8

    ; Allocate memory for output buffer
    mov rax, [rbp+16]
    imul rax, 0x8

    push rsp
    push rax
    call mmap
    add rsp, 0x10

    ; Inference
    push QWORD [rbp-0x8]
    push QWORD [rbp+40]
    push QWORD [rbp+32]
    push 0x1
    push QWORD [rbp+24]
    push QWORD [rbp+16]
    call matmul
    add rsp, 0x30

    push QWORD [rbp-0x8]
    push QWORD [rbp+48]
    push QWORD [rbp-0x8]
    push QWORD [rbp+16]
    call addvs
    add rsp, 0x20

    push QWORD [rbp-0x8]
    push QWORD [rbp-0x8]
    push QWORD [rbp+16]
    call sigmoid
    add rsp, 0x18

.return:
    mov rax, [rbp+56]
    mov rdx, [rsp]
    mov [rax], rdx

.done:
    mov rsp, rbp
    pop rbp
    ret