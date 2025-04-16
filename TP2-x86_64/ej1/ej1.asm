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
    test rdi, rdi
    je .end

    push rdi
    movzx rsi, sil
    call string_proc_node_create_asm

    test rax, rax
    je .restore_and_end

    pop rdi
    push rax

    mov rcx, [rdi]
    test rcx, rcx
    jne .append_to_end

    mov rcx, [rsp]
    mov [rdi], rcx
    mov [rdi + 8], rcx
    jmp .done

.append_to_end:
    mov rcx, [rdi + 8]
    mov rbx, [rsp]

    mov [rcx], rbx
    mov [rbx + 8], rcx
    mov [rdi + 8], rbx

.done:
    add rsp, 8
    ret

.restore_and_end:
    add rsp, 8
.end:
    ret

string_proc_list_concat_asm:
    push r12
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx

    test r12, r12
    jz .return_null_clean
    test r14, r14
    jz .return_null_clean

    mov rdi, r14
    call strlen
    mov r8, rax

    mov rbx, [r12]
.len_loop:
    test rbx, rbx
    jz .len_done

    movzx r9, byte [rbx + 8]
    cmp r9, r13
    jne .len_next

    mov r10, [rbx + 16]
    test r10, r10
    jz .len_next
    mov rdi, r10
    call strlen
    add r8, rax

.len_next:
    mov rbx, [rbx]
    jmp .len_loop

.len_done:
    mov rdi, r8
    inc rdi
    call malloc
    test rax, rax
    jz .return_null_clean
    mov r15, rax

    mov byte [r15], 0

    ; strcpy(result, hash)
    mov rdi, r15      ; destino
    mov rsi, r14      ; origen
    call strcpy

    mov rbx, [r12]
.concat_loop:
    test rbx, rbx
    jz .concat_done

    movzx r9, byte [rbx + 8]
    cmp r9, r13
    jne .concat_next

    mov r10, [rbx + 16]
    test r10, r10
    jz .concat_next
    mov rdi, r15      ; destino
    mov rsi, r10      ; origen
    call strcat

.concat_next:
    mov rbx, [rbx]
    jmp .concat_loop

.concat_done:
    mov rax, r15
    pop r12
    ret

.return_null_clean:
    xor rax, rax
    pop r12
    ret

    