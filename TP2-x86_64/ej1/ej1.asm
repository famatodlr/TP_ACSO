extern malloc
extern strlen
extern strcat

string_proc_list_create_asm:
    push    rbp
    mov     edi, 16              ; Tamanho de la lista
    call    malloc
    test    rax, rax
    je      .fail                ; Si malloc falla, retorna NULL

    mov     qword [rax], 0        ; first = NULL
    mov     qword [rax+8], 0      ; last = NULL
    pop     rbp
    ret

.fail:
    xor     rax, rax
    pop     rbp
    ret


string_proc_node_create_asm:
    push    rbp
    mov     r8b, dil             ; Guardar type (uint8_t) en r8b
    mov     rdx, rsi             ; Guardar hash (char*) en rdx
    mov     edi, 32              ; Tamanho para malloc
    call    malloc
    test    rax, rax
    je      .fail                ; Si malloc falla, retorna NULL

    mov     qword [rax], 0        ; prev = NULL
    mov     qword [rax+8], 0      ; next = NULL
    mov     byte [rax+16], r8b    ; type
    mov     qword [rax+24], rdx   ; hash
    pop     rbp
    ret

.fail:
    xor     rax, rax
    pop     rbp
    ret


string_proc_list_add_node_asm:
    push    rbp
    test    rdi, rdi             ; Si lista es NULL
    je      .done

    mov     rbx, rdi             ; Lista (primer nodo de la lista)
    mov     dl, dl               ; type (uint8_t)
    mov     rsi, rsi             ; hash (char*)

    ; Llamar a string_proc_node_create_asm
    mov     edi, edx             ; pasar type en edi
    call    string_proc_node_create_asm
    test    rax, rax             ; Verificar si malloc falló
    je      .done

    mov     rcx, [rbx]           ; lista->first
    test    rcx, rcx
    je      .empty_list

    ; Si la lista no está vacía
    mov     rdx, [rbx+8]         ; lista->last
    mov     [rdx], rax           ; last->next = nuevo nodo
    mov     [rax+8], rdx         ; nuevo nodo->prev = last
    mov     [rbx+8], rax         ; lista->last = nuevo nodo
    jmp     .done

.empty_list:
    mov     [rbx], rax           ; lista->first = nuevo nodo
    mov     [rbx+8], rax         ; lista->last = nuevo nodo
.done:
    pop     rbp
    ret


string_proc_list_concat_asm:
    push    rbp
    test    rdi, rdi             ; Si lista es NULL
    je      .fail
    test    rdx, rdx             ; Si hash es NULL
    je      .fail

    mov     r8, rdi              ; lista
    mov     r9b, sil             ; type
    mov     r10, rdx             ; hash base string

    ; Llamar a strlen para el hash base
    mov     rdi, r10
    call    strlen
    mov     r11, rax
    add     r11, 1               ; Asegurarse de dejar espacio para el terminador nulo

    ; Calcular el tamaño total para la concatenación
    mov     rbx, [r8]            ; list->first
.loop_len:
    test    rbx, rbx
    je      .alloc_buffer
    movzx   eax, byte [rbx+16]   ; tipo del nodo
    cmp     al, r9b              ; compara tipo
    jne     .next_node
    mov     rdi, [rbx+24]        ; obtener el hash del nodo
    test    rdi, rdi
    je      .next_node
    call    strlen
    add     r11, rax
.next_node:
    mov     rbx, [rbx]           ; siguiente nodo
    jmp     .loop_len

.alloc_buffer:
    mov     rdi, r11             ; Asignar espacio
    call    malloc
    test    rax, rax
    je      .fail
    mov     r12, rax
    mov     byte [r12], 0        ; buffer[0] = '\0'

    ; Concatenar el hash base
    mov     rdi, r12
    mov     rsi, r10
    call    strcat

    ; Concatenar los hashes de la lista
    mov     rbx, [r8]
.loop_cat:
    test    rbx, rbx
    je      .done
    movzx   eax, byte [rbx+16]   ; obtener el tipo del nodo
    cmp     al, r9b              ; comparar tipo
    jne     .next_cat
    mov     rsi, [rbx+24]        ; obtener el hash del nodo
    test    rsi, rsi
    je      .next_cat
    mov     rdi, r12
    call    strcat
.next_cat:
    mov     rbx, [rbx]           ; siguiente nodo
    jmp     .loop_cat

.done:
    mov     rax, r12
    pop     rbp
    ret

.fail:
    xor     rax, rax
    pop     rbp
    ret

    
