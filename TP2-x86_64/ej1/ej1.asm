
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
    test rdi, rdi
    jz .return_null
    test rdx, rdx
    jz .return_null

    ; Guardar punteros originales en registros seguros
    mov r12, rdi        ; r12 = list
    mov r13, rsi        ; r13 = type
    mov r14, rdx        ; r14 = hash

    ; Inicializar 'total_len' con la longitud de 'hash'
    mov rdi, r14        ; rdi = hash
    call strlen
    mov r8, rax         ; r8 = total_len = strlen(hash)

    ; Iterar sobre la lista y acumular longitudes
    mov rbx, [r12]      ; rbx = list->first
.next_node:
    test rbx, rbx
    jz .done_iterating
    movzx r9, byte [rbx + 8]  ; r9 = current->type (uint8_t)
    cmp r9, r13
    jne .next_node_continue

    mov r10, [rbx + 16]   ; r10 = current->hash
    test r10, r10
    jz .next_node_continue
    mov rdi, r10
    call strlen
    add r8, rax           ; total_len += strlen(current->hash)

.next_node_continue:
    mov rbx, [rbx]        ; avanzar al siguiente nodo
    jmp .next_node

.done_iterating:
    ; Reservar memoria para total_len + 1
    mov rdi, r8
    inc rdi
    call malloc
    test rax, rax
    jz .return_null

    ; Guardar puntero a result en r15
    mov r15, rax

    ; Inicializar result con cadena vacía
    mov byte [r15], 0

    ; Copiar hash en result: strcpy(result, hash)
    mov rdi, r15
    mov rsi, r14
    call strcpy

    ; Iterar sobre la lista y concatenar los hashes
    mov rbx, [r12]         ; rbx = list->first
.next_concat:
    test rbx, rbx
    jz .done_concat
    movzx r9, byte [rbx + 8]  ; r9 = current->type
    cmp r9, r13
    jne .next_concat_continue

    mov r10, [rbx + 16]    ; r10 = current->hash
    test r10, r10
    jz .next_concat_continue
    mov rdi, r15           ; rdi = result
    mov rsi, r10           ; rsi = current->hash
    call strcat

.next_concat_continue:
    mov rbx, [rbx]         ; avanzar al siguiente nodo
    jmp .next_concat

.done_concat:
    mov rax, r15           ; devolver result
    ret

.return_null:
    xor rax, rax
    ret

    