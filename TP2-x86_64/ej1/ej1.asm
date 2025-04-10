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

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
    ; reservar memoria para la lista
    mov rdi, 16                ; asumimos que string_proc_list tiene 2 punteros: 2*8 = 16 bytes
    call malloc
    test rax, rax              ; verificar si malloc devolvió NULL
    je .return_null

    ; rax contiene el puntero a la lista, lo guardamos para retornar
    mov rdx, rax               ; rdx = list

    ; inicializar first = NULL
    mov qword [rdx], 0         ; offset 0 -> list->first

    ; inicializar last = NULL
    mov qword [rdx + 8], 0     ; offset 8 -> list->last

    mov rax, rdx               ; retornar el puntero a la lista
    ret

.return_null:
    mov rax, 0
    ret

string_proc_node_create_asm:
    ; argumentos:
    ; rdi = type (uint8_t)
    ; rsi = hash (char*)

    ; reservar memoria para el nodo
    mov rdx, rdi            ; guardar 'type' en rdx
    mov rcx, rsi            ; guardar 'hash' en rcx

    mov rdi, 32             ; sizeof(string_proc_node)
    call malloc
    test rax, rax
    je .return_null

    ; rax contiene el puntero al nodo
    mov r8, rax             ; r8 = node

    ; node->type = type
    mov byte [r8], dl       ; offset 0

    ; node->hash = hash
    mov [r8 + 8], rcx       ; offset 8

    ; node->previous = NULL
    mov qword [r8 + 16], 0  ; offset 16

    ; node->next = NULL
    mov qword [r8 + 24], 0  ; offset 24

    mov rax, r8             ; return node
    ret

.return_null:
    mov rax, 0
    ret

string_proc_list_add_node_asm:
    ; rdi = list
    ; sil = type (uint8_t)
    ; rdx = hash (char*)

    test rdi, rdi
    je .ret

    ; llamar a string_proc_node_create(type, hash)
    movzx rsi, sil        ; mover type (sil) a rsi (extiende a 64 bits)
    mov rdi, rsi          ; arg1: type
    mov rsi, rdx          ; arg2: hash
    call string_proc_node_create_asm
    test rax, rax
    je .ret               ; si node es NULL, retornar

    ; rdi todavía contiene list
    mov rcx, rdi          ; rcx = list
    mov r8, rax           ; r8 = node

    ; if (list->first == NULL)
    mov rax, [rcx]        ; rax = list->first
    test rax, rax
    jne .not_empty

    ; lista vacía: list->first = node, list->last = node
    mov [rcx], r8         ; list->first = node
    mov [rcx + 8], r8     ; list->last = node
    jmp .ret

.not_empty:
    ; list->last->next = node
    mov rax, [rcx + 8]     ; rax = list->last
    mov [rax + 24], r8     ; last->next = node

    ; node->previous = list->last
    mov [r8 + 16], rax     ; node->previous = last

    ; list->last = node
    mov [rcx + 8], r8

.ret:
    ret

extern strlen
extern strcat

string_proc_list_concat_asm:
    ; rdi = list
    ; sil = type

    test rdi, rdi
    je .return_null

    push rbx                   ; guardamos registros de uso
    push r12
    push r13

    mov r12, rdi               ; r12 = list
    movzx r13, sil             ; r13 = tipo a buscar
    xor rbx, rbx               ; rbx = total_length = 0

    ; === Loop para calcular total_length ===
    mov rdi, [r12]             ; rdi = current = list->first
.loop_count:
    test rdi, rdi
    je .alloc_result

    mov al, [rdi]              ; current->type
    cmp al, r13b
    jne .next_count

    mov rsi, [rdi + 8]         ; rsi = current->hash
    mov rdi, rsi
    call strlen
    add rbx, rax               ; total_length += strlen(current->hash)

.next_count:
    mov rdi, [rdi + 24]        ; current = current->next
    jmp .loop_count

.alloc_result:
    ; reservar total_length + 1
    mov rdi, rbx
    add rdi, 1
    call malloc
    test rax, rax
    je .fail

    ; rax = result
    mov r13, rax               ; r13 = result
    mov byte [r13], 0          ; result[0] = '\0'

    ; === Segundo loop para concatenar ===
    mov rdi, [r12]             ; current = list->first
.loop_concat:
    test rdi, rdi
    je .done

    mov al, [rdi]
    cmp al, sil
    jne .next_concat

    mov rsi, [rdi + 8]         ; current->hash
    mov rdi, r13               ; rdi = result
    call strcat

.next_concat:
    mov rdi, [rdi + 24]        ; current = current->next
    jmp .loop_concat

.done:
    mov rax, r13               ; return result
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

.return_null:
    xor rax, rax
    ret

