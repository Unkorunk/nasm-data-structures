NULL equ 0x00
MEM_COMMIT equ 0x00001000
MEM_RESERVE equ 0x00002000
PAGE_READWRITE equ 0x04
MEM_RELEASE equ 0x00008000

    extern  VirtualAlloc
    extern  VirtualFree

    global  heap_create
    global  heap_destroy
    global  heap_reserve
    global  heap_build
    global  heap_push
    global  heap_pop
    global  heap_top
    global  heap_capacity
    global  heap_size
    global  heap_empty

    section .text

; [in]  RCX - ptr to heap
; [in]  RDX - size
; [in]  R8  - i
; [out] void
sift_down:
    push R14
    push R13

    mov  R14, R8 ; largest

    mov  RAX, R8
    shl  RAX, 1
    cmp  RAX, RDX
    jge  sift_down_label1

    mov  R13, [RCX + R14 * 8]
    cmp  [RCX + RAX * 8], R13
    jle  sift_down_label1
    mov  R14, RAX
sift_down_label1:
    mov  RAX, R8
    shl  RAX, 1
    inc  RAX
    cmp  RAX, RDX
    jge  sift_down_label2

    mov  R13, [RCX + R14 * 8]
    cmp  [RCX + RAX * 8], R13
    jle  sift_down_label2
    mov  R14, RAX
sift_down_label2:
    cmp  R14, R8
    je   sift_down_label3
    
    mov  RAX, [RCX + R14 * 8]
    mov  R13, [RCX + R8 * 8]
    mov  [RCX + R14 * 8], R13
    mov  [RCX + R8 * 8], RAX

    mov  R8, R14
    call sift_down
sift_down_label3:
    pop  R13
    pop  R14

    ret

; [in]  RCX - ptr to heap
; [in]  RDX - i
; [out] void
sift_up:
    push R13
sift_up_label1:
    cmp  RDX, 0
    jle  sift_up_label2

    mov  R13, RDX
    shr  R13, 1
    mov  RAX, [RCX + R13 * 8]
    mov  R8, [RCX + RDX * 8]
    cmp  RAX, R8
    jge  sift_up_label2

    mov  [RCX + RDX * 8], RAX
    mov  [RCX + R13 * 8], R8

    mov  RDX, R13
    jmp  sift_up_label1
sift_up_label2:
    pop  R13

    ret

; [in]  RCX - ptr to array
; [in]  RDX - size
; [out] RAX - ptr to heap
heap_build:
    push R13
    push R14
    push R15

    ; save RCX, RDX
    mov  R13, RCX
    mov  R14, RDX

    mov  RCX, RDX
    call heap_create

    lea  RCX, [RAX + 16]
    mov  RDX, R13
    mov  R8, R14
    call memcpy

    ; load RCX, RDX
    mov  RDX, R14
    lea  RCX, [RAX + 16]

    mov  R15, RCX
    mov  R13, RDX

    mov  R14, R13
    shr  R14, 1
    inc  R14
heap_build_label1:
    dec  R14

    mov  RCX, R15
    mov  RDX, R13
    mov  R8, R14
    call sift_down

    cmp  R14, 0
    jne  heap_build_label1

    pop  R15
    pop  R14
    pop  R13

    ret

; [in]  RCX - ptr to heap
; [out] RAX - size
heap_size:
    mov  RAX, [RCX + 8]
    ret

; [in]  RCX - ptr to heap
; [out] RAX - 1 if empty else 0
heap_empty:
    cmp  qword [RCX + 8], 0
    jne  heap_empty_label1
    MOV  RAX, 1
    ret
heap_empty_label1:
    MOV  RAX, 0
    ret

; [in]  RCX - ptr to heap
; [out] RAX - capacity
heap_capacity:
    mov  RAX, [RCX]
    ret

; [in]  RCX - ptr to heap
; [out] RAX - key
heap_top:
    mov  RAX, [RCX + 16]
    ret

; [in]  RCX - ptr to heap
; [out] void
heap_pop:
    cmp  qword [RCX + 8], 0
    jle  heap_pop_label1

    mov  R8, [RCX + 8]
    dec  R8
    mov  R9, [RCX + R8 * 8 + 16]
    mov  [RCX + 16], R9
    mov  [RCX + 8], R8

    add  RCX, 16
    mov  RDX, R8
    mov  R8, 0
    call sift_down
heap_pop_label1:
    ret

; [in]  RCX - ptr to heap
; [in]  RDX - key
; [out] RAX - ptr to new heap
heap_push:
    mov  R9, [RCX + 8]
    cmp  R9, [RCX]
    jl   heap_push_label1

    push R12
    mov  R12, RDX

    inc  R9
    mov  RDX, R9
    call heap_reserve
    mov  RCX, RAX

    mov  RDX, R12
    pop  R12
heap_push_label1:
    mov  R9, [RCX + 8]
    mov  [RCX + R9 * 8 + 16], RDX
    inc  R9
    mov  [RCX + 8], R9

    push R13
    mov  R13, RCX

    add  RCX, 16
    dec  R9
    mov  RDX, R9
    call sift_up

    mov RAX, R13
    pop R13

    ret

; [in]  RCX - capacity
; [out] RAX - ptr to heap
heap_create:
    push R12

    mov  R12, RCX

    mov  R8, RCX
    add  R8, 2
    shl  R8, 3

    sub  RSP, 48
    mov  RCX, NULL
    mov  RDX, R8
    mov  R8, MEM_COMMIT | MEM_RESERVE
    mov  R9, PAGE_READWRITE
    call VirtualAlloc
    add  RSP, 48

    mov  [RAX], R12 ; capacity
    mov  qword [RAX + 8], 0 ; size

    pop  R12

    ret

; [in]  RCX - dest
; [in]  RDX - src
; [in]  R8 - count
; [out] void
memcpy:
memcpy_label1:
    cmp  R8, 0
    jle  memcpy_label2
    mov  R9, [RDX]
    mov  [RCX], R9
    dec  R8
    add  RCX, 8
    add  RDX, 8
    jmp  memcpy_label1
memcpy_label2:
    ret

; [in]  RCX - ptr to heap
; [in]  RDX - new capacity
; [out] RAX - ptr to new heap
heap_reserve:
    push R12

    mov  R8, [RCX] ; capacity
    cmp  RDX, R8
    jle  heap_reserve_label1

    mov  R12, RCX ; ptr to heap

    mov  RCX, RDX
    call heap_create

    mov  R8, [R12 + 8] ; size
    mov  [RAX + 8], R8

    lea  RCX, [RAX + 16]
    lea  RDX, [R12 + 16]
    call memcpy

    mov  RCX, R12
    mov  R12, RAX ; save RAX
    call heap_destroy
    mov  RAX, R12 ; load RAX
heap_reserve_label1:
    pop  R12

    ret

; [in]  RCX - ptr to heap
; [out] void
heap_destroy:
    sub  RSP, 48

    mov  RDX, 0
    mov  R8, MEM_RELEASE
    call VirtualFree

    add  RSP, 48
    ret
