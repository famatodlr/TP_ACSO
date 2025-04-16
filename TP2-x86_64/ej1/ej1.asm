
section .text
    global string_proc_list_create_asm
    global string_proc_node_create_asm
    global string_proc_list_add_node_asm
    global string_proc_list_concat_asm
    extern malloc
    extern strlen
    extern strcpy
    extern strcat




string_proc_list_create_asm:
    mov rdi, 16              ; malloc(sizeof(string_proc_list))
    call malloc              ; rax <- malloc result

    test rax, rax            ; check NULL
    je .return_null

    mov qword [rax], 0       ; first = NULL
    mov qword [rax + 8], 0   ; last = NULL
    ret

.return_null:
    xor rax, rax
    ret




string_proc_node_create_asm:
    ; Reservamos 32 bytes para el nodo
    mov rdx, rsi         ; guardamos hash en rdx (segundo arg) para más tarde
    movzx rcx, dil       ; extendemos type (uint8_t) en rcx

    mov rdi, 32
    call malloc          ; malloc(32), resultado en rax

    test rax, rax
    je .return_null      ; si malloc devolvió NULL, salimos

    ; Inicializar node->next = NULL
    mov qword [rax], 0

    ; node->previous = NULL
    mov qword [rax + 8], 0

    ; node->type = type (rcx lo guarda)
    mov byte [rax + 16], cl

    ; node->hash = hash (rdx)
    mov qword [rax + 24], rdx

    ret

.return_null:
    xor rax, rax
    ret





string_proc_list_add_node_asm:
    ; Si list es NULL, return
    test rdi, rdi
    je .end

    ; Guardar args porque vamos a llamar a otra función
    push rdi            ; save list
    movzx rsi, sil      ; preparar segundo arg (type) para llamada
                        ; ya tenemos rdx con hash
    call string_proc_node_create_asm

    ; Resultado está en rax → node
    test rax, rax
    je .restore_and_end

    ; Restauramos list
    pop rdi             ; rdi = list
    push rax            ; guardamos node para después

    ; Verificamos si list->first == NULL
    mov rcx, [rdi]      ; rcx = list->first
    test rcx, rcx
    jne .append_to_end  ; si no es NULL, vamos a else

    ; list->first = node
    mov rcx, [rsp]      ; rcx = node
    mov [rdi], rcx

    ; list->last = node
    mov [rdi + 8], rcx

    jmp .done

.append_to_end:
    mov rcx, [rdi + 8]  ; rcx = list->last
    mov rbx, [rsp]      ; rbx = node

    ; list->last->next = node
    mov [rcx], rbx

    ; node->previous = list->last
    mov [rbx + 8], rcx

    ; list->last = node
    mov [rdi + 8], rbx

.done:
    add rsp, 8          ; limpiar stack (node)
    ret

.restore_and_end:
    add rsp, 8          ; limpiar stack (list)
.end:
    ret






string_proc_list_concat_asm:
    ; Entradas:
    ; rdi = puntero a la lista 'string_proc_list* list'
    ; rsi = uint8_t 'type'
    ; rdx = puntero a 'char* hash'

    ; Comprobar si list o hash son NULL
    test rdi, rdi            ; Comprobar si 'list' es NULL
    jz .return_null
    test rdx, rdx            ; Comprobar si 'hash' es NULL
    jz .return_null

    ; Inicializar 'total_len' con la longitud de 'hash'
    mov rax, rdx             ; rax = puntero a 'hash'
    call strlen              ; Llamar a la función strlen
    mov r8, rax              ; r8 = longitud de 'hash'

    ; Iterar sobre los nodos de la lista y calcular el total_len
    mov rbx, [rdi]           ; rbx = puntero a la primera lista de nodos (list->first)
.next_node:
    test rbx, rbx            ; Verificar si el nodo actual es NULL
    jz .done_iterating
    mov r9, [rbx + 8]        ; r9 = type del nodo (current->type)
    cmp r9, rsi              ; Comparar tipo con el parámetro 'type'
    jne .next_node_continue   ; Si no es igual, ir al siguiente nodo

    mov r10, [rbx + 16]      ; r10 = puntero a hash (current->hash)
    test r10, r10            ; Verificar si hash del nodo es NULL
    jz .next_node_continue
    call strlen              ; Llamar a la función strlen para obtener la longitud de 'current->hash'
    add r8, rax              ; Sumar la longitud de 'current->hash' a 'total_len'

.next_node_continue:
    mov rbx, [rbx]           ; rbx = siguiente nodo (current = current->next)
    jmp .next_node

.done_iterating:
    ; Reservar memoria para la cadena resultante (total_len + 1)
    mov rdi, r8              ; rdi = total_len
    inc rdi                  ; rdi = total_len + 1 (espacio para el null terminator)
    call malloc              ; Reservar memoria para el resultado
    test rax, rax            ; Comprobar si malloc falló
    jz .return_null

    ; Inicializar la cadena resultante con una cadena vacía
    mov byte [rax], 0        ; result[0] = '\0'

    ; Copiar 'hash' en la cadena resultante
    mov rdi, rdx             ; rdi = puntero a 'hash'
    mov rsi, rax             ; rsi = puntero a la cadena resultante
    call strcpy              ; Copiar 'hash' en 'result'

    ; Iterar nuevamente sobre la lista y concatenar los hashes
    mov rbx, [rdi]           ; rbx = puntero a la primera lista de nodos (list->first)
.next_concat:
    test rbx, rbx            ; Verificar si el nodo actual es NULL
    jz .done_concat
    mov r9, [rbx + 8]        ; r9 = type del nodo (current->type)
    cmp r9, rsi              ; Comparar tipo con el parámetro 'type'
    jne .next_concat_continue ; Si no es igual, ir al siguiente nodo

    mov r10, [rbx + 16]      ; r10 = puntero a hash (current->hash)
    test r10, r10            ; Verificar si hash del nodo es NULL
    jz .next_concat_continue
    mov rdi, r10             ; rdi = puntero a 'current->hash'
    mov rsi, rax             ; rsi = puntero a la cadena resultante
    call strcat              ; Concatenar 'current->hash' en 'result'

.next_concat_continue:
    mov rbx, [rbx]           ; rbx = siguiente nodo (current = current->next)
    jmp .next_concat

.done_concat:
    ; Regresar el puntero a la cadena resultante
    mov rax, rsi             ; Retornar puntero a la cadena resultante
    ret

.return_null:
    xor rax, rax             ; Retornar NULL
    ret
