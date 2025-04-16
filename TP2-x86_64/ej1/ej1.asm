
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

    ; Guardar registros importantes
    push r12                ; Guardamos r12 (lo vamos a usar para guardar list)
    mov r12, rdi            ; r12 = list
    mov r13, rsi            ; r13 = type
    mov r14, rdx            ; r14 = hash

    ; Comprobar si list o hash son NULL
    test r12, r12
    jz .return_null_clean
    test r14, r14
    jz .return_null_clean

    ; Inicializar total_len con strlen(hash)
    mov rdi, r14
    call strlen
    mov r8, rax             ; r8 = total_len

    ; Iterar sobre los nodos para sumar longitudes
    mov rbx, [r12]          ; rbx = list->first
.len_loop:
    test rbx, rbx
    jz .len_done

    movzx r9, byte [rbx + 8]    ; r9 = current->type (uint8_t extendido)
    cmp r9, r13
    jne .len_next

    mov r10, [rbx + 16]         ; r10 = current->hash
    test r10, r10
    jz .len_next
    mov rdi, r10
    call strlen
    add r8, rax

.len_next:
    mov rbx, [rbx]              ; rbx = current->next
    jmp .len_loop

.len_done:
    ; Reservar memoria para result (total_len + 1)
    mov rdi, r8
    inc rdi
    call malloc
    test rax, rax
    jz .return_null_clean
    mov r15, rax                ; r15 = result

    ; Inicializar result con '\0'
    mov byte [r15], 0

    ; strcpy(result, hash)
    mov rdi, r14
    mov rsi, r15
    call strcpy

    ; Segunda iteración: concatenar hashes
    mov rbx, [r12]              ; rbx = list->first
.concat_loop:
    test rbx, rbx
    jz .concat_done

    movzx r9, byte [rbx + 8]
    cmp r9, r13
    jne .concat_next

    mov r10, [rbx + 16]
    test r10, r10
    jz .concat_next
    mov rdi, r10
    mov rsi, r15
    call strcat

.concat_next:
    mov rbx, [rbx]
    jmp .concat_loop

.concat_done:
    mov rax, r15                ; devolver result
    pop r12
    ret

.return_null_clean:
    xor rax, rax
    pop r12
    ret
    
