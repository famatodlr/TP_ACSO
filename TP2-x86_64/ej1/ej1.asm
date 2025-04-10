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
extern str_concat
extern strlen
extern strcat

string_proc_list_create_asm:
    mov rdi, 16                ; 2 punteros: 2*8 = 16 bytes
    call malloc
    test rax, rax
    je .return_null

    mov rdx, rax               ; rdx = list
    mov qword [rdx], 0         ; list->first = NULL
    mov qword [rdx + 8], 0     ; list->last = NULL
    mov rax, rdx
    ret

.return_null:
    mov rax, 0
    ret

string_proc_node_create_asm:
    ; rdi = type (uint8_t), rsi = hash (char*)
    mov rdx, rdi
    mov rcx, rsi

    mov rdi, 32               ; sizeof(string_proc_node)
    call malloc
    test rax, rax
    je .return_null

    mov r8, rax               ; r8 = node
    mov byte [r8], dl         ; node->type
    mov [r8 + 8], rcx         ; node->hash
    mov qword [r8 + 16], 0    ; node->previous = NULL
    mov qword [r8 + 24], 0    ; node->next = NULL

    mov rax, r8
    ret

.return_null:
    mov rax, 0
    ret

string_proc_list_add_node_asm:
    ; rdi = list, sil = type, rdx = hash
    test rdi, rdi
    je .ret

    movzx rsi, sil
    mov rdi, rsi              ; arg1: type
    mov rsi, rdx              ; arg2: hash
    call string_proc_node_create_asm
    test rax, rax
    je .ret

    mov rcx, rdi              ; rcx = list
    mov r8, rax               ; r8 = node

    mov rax, [rcx]            ; list->first
    test rax, rax
    jne .not_empty

    mov [rcx], r8             ; list->first = node
    mov [rcx + 8], r8         ; list->last = node
    jmp .ret

.not_empty:
    mov rax, [rcx + 8]        ; rax = list->last
    mov [rax + 24], r8        ; last->next = node
    mov [r8 + 16], rax        ; node->previous = last
    mov [rcx + 8], r8         ; list->last = node

.ret:
    ret

string_proc_list_concat_asm:
    ; rdi = list, sil = type
    push rbx
    push r12
    push r13
    push r14

    mov r14, rdi              ; guardamos puntero a la lista
    xor r13, r13              ; r13 = total_length
    mov r12, [r14]            ; r12 = current = list->first

.loop_len:
    test r12, r12
    je .alloc_concat
    mov al, [r12]             ; current->type
    cmp al, sil
    jne .next_len
    mov rbx, [r12 + 8]        ; current->hash
    mov rdi, rbx
    call strlen
    add r13, rax
.next_len:
    mov r12, [r12 + 24]
    jmp .loop_len

.alloc_concat:
    mov rdi, r13
    add rdi, 1
    call malloc
    test rax, rax
    je .error

    mov r13, rax
    mov byte [r13], 0         ; result[0] = '\0'

    mov r12, [r14]            ; current = list->first

.loop_concat:
    test r12, r12
    je .done
    mov al, [r12]
    cmp al, sil
    jne .next_concat
    mov rsi, [r12 + 8]
    mov rdi, r13
    call strcat
.next_concat:
    mov r12, [r12 + 24]
    jmp .loop_concat

.done:
    mov rax, r13
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.error:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret