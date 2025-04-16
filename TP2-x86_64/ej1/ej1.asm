

string_proc_list_create_asm:
    push    rbp
    mov     rbp, rsp
    mov     edi, 16
    call    malloc
    test    rax, rax
    je      .fail
    mov     qword [rax], 0        ; first = NULL
    mov     qword [rax+8], 0      ; last = NULL
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rbp
    ret



string_proc_node_create_asm:
    push    rbp
    mov     rbp, rsp
    mov     eax, edi                  ; type (uint8_t)
    mov     rdx, rsi                  ; hash (char *)
    mov     edi, 32
    call    malloc
    test    rax, rax
    je      .fail
    mov     qword [rax], 0           ; prev = NULL
    mov     qword [rax+8], 0         ; next = NULL
    mov     byte [rax+16], al        ; type
    mov     qword [rax+24], rdx      ; hash
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rbp
    ret



string_proc_list_add_node_asm:
    push    rbp
    mov     rbp, rsp
    mov     rdx, rsi      ; type (uint8_t)
    mov     rcx, rdx      ; copiar type en rcx para después
    mov     rdx, rdx      ; redundante pero clara: rdx = hash
    test    rdi, rdi
    je      .done
    mov     esi, ecx
    call    string_proc_node_create
    test    rax, rax
    je      .done
    mov     rbx, rdi                  ; lista
    mov     rcx, [rbx]               ; lista->first
    test    rcx, rcx
    je      .empty_list
    ; lista no vacía
    mov     rdx, [rbx+8]             ; lista->last
    mov     [rdx], rax               ; last->next = nuevo
    mov     [rax+8], rdx             ; nuevo->prev = last
    mov     [rbx+8], rax             ; lista->last = nuevo
    jmp     .done
.empty_list:
    mov     [rbx], rax               ; lista->first = nuevo
    mov     [rbx+8], rax             ; lista->last = nuevo
.done:
    pop     rbp
    ret




string_proc_list_concat_asm:
    push    rbp
    mov     rbp, rsp
    test    rdi, rdi
    je      .fail
    test    rdx, rdx
    je      .fail

    mov     r8, rdi                  ; list
    mov     r9b, sil                 ; type
    mov     r10, rdx                 ; base string

    ; strlen(base string)
    mov     rdi, r10
    call    strlen
    mov     r11, rax                 ; total length
    add     r11, 1                   ; for null terminator

    ; recorrer la lista
    mov     rbx, [r8]                ; node = list->first
.loop_len:
    test    rbx, rbx
    je      .alloc_buffer
    movzx   eax, byte [rbx+16]       ; node->type
    cmp     al, r9b
    jne     .next_node
    mov     rdi, [rbx+24]
    test    rdi, rdi
    je      .next_node
    call    strlen
    add     r11, rax
.next_node:
    mov     rbx, [rbx]               ; node = node->next
    jmp     .loop_len

.alloc_buffer:
    mov     rdi, r11
    call    malloc
    test    rax, rax
    je      .fail
    mov     r12, rax                 ; buffer ptr
    mov     byte [r12], 0            ; inicializa string vacía

    ; strcat(base string)
    mov     rdi, r12
    mov     rsi, r10
    call    strcat

    ; repetir el loop para concatenar
    mov     rbx, [r8]
.loop_cat:
    test    rbx, rbx
    je      .done
    movzx   eax, byte [rbx+16]
    cmp     al, r9b
    jne     .next_cat
    mov     rsi, [rbx+24]
    test    rsi, rsi
    je      .next_cat
    mov     rdi, r12
    call    strcat
.next_cat:
    mov     rbx, [rbx]
    jmp     .loop_cat

.done:
    mov     rax, r12
    pop     rbp
    ret
.fail:
    xor     rax, rax
    pop     rbp
    ret

