; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

extern malloc
extern free
extern strlen
extern strcat

string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je .return_null

    mov rdx, rax
    mov qword [rdx], 0
    mov qword [rdx + 8], 0
    mov rax, rdx
    ret

.return_null:
    mov rax, 0
    ret

string_proc_node_create_asm:
    ; rdi = type (uint8_t)
    ; rsi = hash (char*)
    mov rdx, rdi
    mov rcx, rsi

    mov rdi, 32
    call malloc
    test rax, rax
    je .return_null

    mov r8, rax

    mov byte [r8 + 16], dl     ; node->type (offset 16)
    mov [r8 + 24], rcx         ; node->hash (offset 24)
    mov qword [r8], 0          ; node->next (offset 0)
    mov qword [r8 + 8], 0      ; node->previous (offset 8)

    mov rax, r8
    ret

.return_null:
    mov rax, 0
    ret

string_proc_list_add_node_asm:
    ; rdi = list
    ; sil = type
    ; rdx = hash
    test rdi, rdi
    je .ret

    movzx rsi, sil
    mov rdi, rsi
    mov rsi, rdx
    call string_proc_node_create_asm
    test rax, rax
    je .ret

    mov rcx, rdi
    mov r8, rax

    mov rax, [rcx]
    test rax, rax
    jne .not_empty

    mov [rcx], r8
    mov [rcx + 8], r8
    jmp .ret

.not_empty:
    mov rax, [rcx + 8]
    mov [rax], r8              ; last->next = node (offset 0)
    mov [r8 + 8], rax          ; node->previous = last (offset 8)
    mov [rcx + 8], r8          ; list->last = node

.ret:
    ret

string_proc_list_concat_asm:
    ; rdi = list
    ; sil = type
    push rbx
    push r12
    push r13

    xor r13, r13
    mov r12, [rdi]

.loop_len:
    test r12, r12
    je .alloc_concat

    mov al, [r12 + 16]
    cmp al, sil
    jne .next_len

    mov rbx, [r12 + 24]
    mov rdi, rbx
    call strlen
    add r13, rax

.next_len:
    mov r12, [r12]
    jmp .loop_len

.alloc_concat:
    mov rdi, r13
    add rdi, 1
    call malloc
    test rax, rax
    je .error

    mov r13, rax
    mov byte [r13], 0

    mov r12, [rdi]

.loop_concat:
    test r12, r12
    je .done

    mov al, [r12 + 16]
    cmp al, sil
    jne .next_concat

    mov rsi, [r12 + 24]
    mov rdi, r13
    call strcat

.next_concat:
    mov r12, [r12]
    jmp .loop_concat

.done:
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    ret

.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret