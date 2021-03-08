NULL equ 0x00
MEM_COMMIT equ 0x00001000
MEM_RESERVE equ 0x00002000
PAGE_READWRITE equ 0x04
MEM_RELEASE equ 0x00008000

    extern  VirtualAlloc
    extern  VirtualFree
    extern  GetSystemInfo

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
    global  heap_set_comparator
    global  heap_get_comparator
    global  heap_default_comparator

    struc SYSTEM_INFO
        .DUMMYUNIONNAME:              resd 1
        .dwPageSize:                  resd 1
        .lpMinimumApplicationAddress: resq 1
        .lpMaximumApplicationAddress: resq 1
        .dwActiveProcessorMask:       resq 1
        .dwNumberOfProcessors:        resd 1
        .dwProcessorType:             resd 1
        .dwAllocationGranularity:     resd 1
        .wProcessorLevel:             resw 1
        .wProcessorRevision:          resw 1
    endstruc

    section .bss

    my_system_info: resb SYSTEM_INFO_size

    section .text

; [in]  RCX - ptr to heap
; [in]  RDX - i
; [out] void
sift_down:
    sub  RSP, 40

    push R14
    push R13
    push R12

    mov  R12, RCX
    mov  R13, RDX
sift_down_label4:
    ; largest = i
    mov  R14, R13
    ; left = 2 * i + 1
    mov  RAX, R13
    shl  RAX, 1
    inc  RAX
    ; left >= size
    cmp  RAX, [R12 + 8]
    jge  sift_down_label3
    ; data[left] <= data[largest]
    lea  RCX, [R12 + RAX * 8 + 24]
    lea  RDX, [R12 + R14 * 8 + 24]
    call [R12 + 16]
    cmp  AL, 0
    je   sift_down_label1
    ; largest = left
    mov  R14, R13
    shl  R14, 1
    inc  R14
sift_down_label1:
    ; right = 2 * i + 2
    mov  RAX, R13
    shl  RAX, 1
    add  RAX, 2
    ; right >= size
    cmp  RAX, [R12 + 8]
    jge  sift_down_label2
    ; data[right] <= data[largest]
    lea  RCX, [R12 + RAX * 8 + 24]
    lea  RDX, [R12 + R14 * 8 + 24]
    call [R12 + 16]
    cmp  AL, 0
    je   sift_down_label2
    ; largest = right
    mov  R14, R13
    shl  R14, 1
    add  R14, 2
sift_down_label2:
    ; largest == i
    cmp  R14, R13
    je   sift_down_label3
    ; swap A[i] and A[largest]
    mov  RAX, [R12 + R14 * 8 + 24]
    mov  R10, [R12 + R13 * 8 + 24]
    mov  [R12 + R14 * 8 + 24], R10
    mov  [R12 + R13 * 8 + 24], RAX
    ; i = largest
    mov  R13, R14
    jmp  sift_down_label4
sift_down_label3:
    pop  R12
    pop  R13
    pop  R14

    add  RSP, 40

    ret

; [in]  RCX - ptr to heap
; [in]  RDX - i
; [out] void
sift_up:
    sub  RSP, 40

    push R13
    push R12

    mov  R12, RCX
    mov  R13, RDX
sift_up_label1:
    cmp  R13, 0
    jle  sift_up_label2
    ; parent = (i - 1) / 2
    mov  R9, R13
    dec  R9
    shr  R9, 1
    ; return if comparator(A[parent], A[i])
    lea  RCX, [R12 + R9 * 8 + 24] ; parent
    lea  RDX, [R12 + R13 * 8 + 24] ; current
    call [R12 + 16]
    cmp  AL, 1
    je   sift_up_label2

    mov  R9, R13
    dec  R9
    shr  R9, 1

    mov  RAX, [R12 + R9 * 8 + 24]
    mov  R8, [R12 + R13 * 8 + 24]
    mov  [R12 + R13 * 8 + 24], RAX
    mov  [R12 + R9 * 8 + 24], R8
    ; i = parent
    mov  R13, R9
    jmp  sift_up_label1
sift_up_label2:
    pop  R12
    pop  R13

    add  RSP, 40

    ret

; [in]  RCX - ptr to array
; [in]  RDX - size
; [out] RAX - ptr to heap
heap_build:
    push R13
    push R12

    mov  R13, RDX
    mov  R12, RCX

    mov  RCX, R13
    call heap_create

    mov  [RAX + 8], R13

    lea  RCX, [RAX + 24] ; 1st arg
    mov  RDX, R12 ; 2nd arg
    mov  R8, R13 ; 3rd arg
    mov  R13, RAX ; R13 - ptr to heap
    call memcpy

    mov  RCX, R13
    call heap_rebuild

    mov  RAX, R13

    pop  R12
    pop  R13

    ret

; [in]  RCX - ptr to heap
; [out] void
heap_rebuild:
    push R13
    push R12

    mov  R13, RCX

    mov  R12, [R13 + 8]
    shr  R12, 1
heap_build_label2:
    cmp  R12, 0
    jl   heap_build_label1

    mov  RCX, R13
    mov  RDX, R12
    call sift_down

    dec  R12
    jmp  heap_build_label2
heap_build_label1:
    pop  R12
    pop  R13

    ret

; [in]  RCX - ptr to heap
; [out] RAX - size
heap_size:
    mov  RAX, [RCX + 8]
    ret

; [in]  RCX - ptr to heap
; [out] AL - true if empty else false
heap_empty:
    cmp  qword [RCX + 8], 0
    sete AL
    ret

; [in]  RCX - ptr to heap
; [out] RAX - capacity
heap_capacity:
    mov  RAX, [RCX]
    ret

; [in]  RCX - ptr to heap
; [out] RAX - key
heap_top:
    mov  RAX, [RCX + 24]
    ret

; [in]  RCX - ptr to heap
; [out] void
heap_pop:
    ; size <= 0
    cmp  qword [RCX + 8], 0
    jle  heap_pop_label1
    ; size--
    mov  R8, [RCX + 8]
    dec  R8
    mov  [RCX + 8], R8
    ; A[0] = A[size - 1]
    mov  R9, [RCX + R8 * 8 + 24]
    mov  [RCX + 24], R9

    mov  RDX, 0
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
    mov  [RCX + R9 * 8 + 24], RDX
    inc  R9
    mov  [RCX + 8], R9

    mov  R10, RCX

    dec  R9
    mov  RDX, R9
    call sift_up

    mov  RAX, R10

    ret

; [in]  RCX - capacity
; [out] RAX - ptr to heap
heap_create:
    push R12
    mov  R12, RCX ; save capacity

    sub  RSP, 40

    lea  RCX, [REL my_system_info + SYSTEM_INFO]
    call GetSystemInfo

    ; 2nd argument
    add  R12, 3
    shl  R12, 3

    mov  RAX, R12
    xor  RDX, RDX
    mov  R9D, [REL my_system_info + SYSTEM_INFO + SYSTEM_INFO.dwPageSize]
    div  R9
    
    mov  EAX, [REL my_system_info + SYSTEM_INFO + SYSTEM_INFO.dwPageSize]
    sub  RAX, RDX
    add  R12, RAX

    mov  RDX, R12

    shr  R12, 3
    sub  R12, 3
    ; ~2nd argument

    mov  RCX, NULL ; 1st argument
    mov  R8, MEM_COMMIT | MEM_RESERVE ; 3rd argument
    mov  R9, PAGE_READWRITE ; 4th argument
    call VirtualAlloc
    add  RSP, 40

    mov  [RAX], R12 ; load capacity
    ; no need to load size because memory
    ; allocated by this function is
    ; automatically initialized to zero
    lea  R12, [REL heap_default_comparator]
    mov  [RAX + 16], R12

    pop  R12

    ret

; [in]  RCX - dest
; [in]  RDX - src
; [in]  R8 - count
; [out] void
memcpy:
    ; count <= 0
    cmp  R8, 0
    jle  memcpy_label2
    ; swap R8 and RCX
    mov  R9, RCX
    mov  RCX, R8
    mov  R8, R9
    ; offset
    mov  R10, 0
memcpy_label1:
    mov  R9, [RDX + R10 * 8]
    mov  [R8 + R10 * 8], R9

    inc  R10

    loop memcpy_label1
memcpy_label2:
    ret

; [in]  RCX - ptr to heap
; [in]  RDX - new capacity
; [out] RAX - ptr to new heap
heap_reserve:
    mov  R8, [RCX] ; capacity
    cmp  RDX, R8
    jle  heap_reserve_label1

    push R12

    mov  R12, RCX ; ptr to heap

    mov  RCX, RDX
    call heap_create

    mov  R8, [R12 + 8] ; size
    add  R8, 2

    lea  RCX, [RAX + 8]
    lea  RDX, [R12 + 8]
    call memcpy

    mov  RCX, R12
    mov  R12, RAX ; save RAX
    call heap_destroy
    mov  RAX, R12 ; load RAX

    pop  R12

    ret
heap_reserve_label1:
    mov  RAX, RCX

    ret

; [in]  RCX - ptr to heap
; [out] void
heap_destroy:
    sub  RSP, 40

    mov  RDX, 0
    mov  R8, MEM_RELEASE
    call VirtualFree

    add  RSP, 40
    ret

; [in]  RCX - ptr to heap
; [in]  RDX - ptr to comparator
; [out] void
heap_set_comparator:
    mov  [RCX + 16], RDX
    call heap_rebuild
    ret

; [in]  RCX - ptr to heap
; [out] RAX - ptr to comparator
heap_get_comparator:
    mov  RAX, [RCX + 16]
    ret

; [in]  RCX - ptr to lhs
; [in]  RDX - ptr to rhs
; [out] RAX - true / false
heap_default_comparator:
    mov  R8, [RCX]
    cmp  R8, [RDX]
    seta AL
    ret
