    global heap_build
    global heap_push
    global heap_pop
    global heap_top

    section .text

; RCX - ptr to heap
; RDX - length
; R8  - i
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

; RCX - ptr to heap
; RDX - i
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

; RCX - ptr to heap
; RDX - length
heap_build:
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

    ret

; RCX - ptr to heap
heap_top:
    mov  RAX, [RCX]
    ret

; RCX - ptr to heap
; RDX - ptr to length
heap_pop:
    mov  R8, [RDX]
    dec  R8
    mov  R9, [RCX + R8 * 8]
    mov  [RCX], R9
    mov  [RDX], R8

    mov  RDX, R8
    mov  R8, 0
    call sift_down

    ret

; RCX - ptr to heap
; RDX - ptr to length
; R8  - key
heap_push:
    mov  R9, [RDX]
    mov  [RCX + R9 * 8], R8
    inc  R9
    mov  [RDX], R9

    dec  R9
    mov  RDX, R9
    call sift_up

    ret
