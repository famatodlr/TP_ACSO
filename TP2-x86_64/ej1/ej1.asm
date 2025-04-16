

string_proc_list_create_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     edi, 16
        call    malloc
        mov     [rbp-8], rax
        cmp     qword [rbp-8], 0
        jne     .L2
        mov     eax, 0
        jmp     .L3
.L2:
        mov     rax, [rbp-8]
        mov     qword [rax], 0
        mov     rax, [rbp-8]
        mov     qword [rax+8], 0
        mov     rax, [rbp-8]
.L3:
        leave
        ret

string_proc_node_create_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32
        mov     eax, edi
        mov     [rbp-32], rsi
        mov     byte [rbp-20], al
        mov     edi, 32
        call    malloc
        mov     [rbp-8], rax
        cmp     qword [rbp-8], 0
        jne     .L5
        mov     eax, 0
        jmp     .L6
.L5:
        mov     rax, [rbp-8]
        mov     qword [rax], 0
        mov     rax, [rbp-8]
        mov     qword [rax+8], 0
        mov     rax, [rbp-8]
        mov     rdx, [rbp-32]
        mov     qword [rax+24], rdx
        mov     rax, [rbp-8]
        movzx   edx, byte [rbp-20]
        mov     byte [rax+16], dl
        mov     rax, [rbp-8]
.L6:
        leave
        ret

string_proc_list_add_node_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 48
        mov     [rbp-24], rdi
        mov     eax, esi
        mov     [rbp-40], rdx
        mov     byte [rbp-28], al
        cmp     qword [rbp-24], 0
        je      .L12
        movzx   eax, byte [rbp-28]
        mov     rdx, [rbp-40]
        mov     rsi, rdx
        mov     edi, eax
        call    string_proc_node_create
        mov     [rbp-8], rax
        cmp     qword [rbp-8], 0
        je      .L13
        mov     rax, [rbp-24]
        mov     rax, [rax]
        test    rax, rax
        jne     .L11
        mov     rax, [rbp-24]
        mov     rdx, [rbp-8]
        mov     [rax], rdx
        mov     rax, [rbp-24]
        mov     rdx, [rbp-8]
        mov     [rax+8], rdx
        jmp     .L7
.L11:
        mov     rax, [rbp-24]
        mov     rax, [rax+8]
        mov     rdx, [rbp-8]
        mov     [rax], rdx
        mov     rax, [rbp-24]
        mov     rdx, [rax+8]
        mov     rax, [rbp-8]
        mov     [rax+8], rdx
        mov     rax, [rbp-24]
        mov     rdx, [rbp-8]
        mov     [rax+8], rdx
        jmp     .L7
.L12:
        nop
        jmp     .L7
.L13:
        nop
.L7:
        leave
        ret

string_proc_list_concat_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 64
        mov     [rbp-40], rdi
        mov     eax, esi
        mov     [rbp-56], rdx
        mov     byte [rbp-44], al
        cmp     qword [rbp-40], 0
        je      .L15
        cmp     qword [rbp-56], 0
        jne     .L16
.L15:
        mov     eax, 0
        jmp     .L17
.L16:
        mov     rax, [rbp-56]
        mov     rdi, rax
        call    strlen
        mov     [rbp-8], rax
        mov     rax, [rbp-40]
        mov     rax, [rax]
        mov     [rbp-16], rax
        jmp     .L18
.L20:
        mov     rax, [rbp-16]
        movzx   eax, byte [rax+16]
        cmp     byte [rbp-44], al
        jne     .L19
        mov     rax, [rbp-16]
        mov     rax, [rax+24]
        test    rax, rax
        je      .L19
        mov     rax, [rbp-16]
        mov     rax, [rax+24]
        mov     rdi, rax
        call    strlen
        add     [rbp-8], rax
.L19:
        mov     rax, [rbp-16]
        mov     rax, [rax]
        mov     [rbp-16], rax
.L18:
        cmp     qword [rbp-16], 0
        jne     .L20
        mov     rax, [rbp-8]
        add     rax, 1
        mov     rdi, rax
        call    malloc
        mov     [rbp-24], rax
        cmp     qword [rbp-24], 0
        jne     .L21
        mov     eax, 0
        jmp     .L17
.L21:
        mov     rax, [rbp-24]
        mov     byte [rax], 0
        mov     rdx, [rbp-56]
        mov     rax, [rbp-24]
        mov     rsi, rdx
        mov     rdi, rax
        call    strcat
        mov     rax, [rbp-40]
        mov     rax, [rax]
        mov     [rbp-16], rax
        jmp     .L22
.L24:
        mov     rax, [rbp-16]
        movzx   eax, byte [rax+16]
        cmp     byte [rbp-44], al
        jne     .L23
        mov     rax, [rbp-16]
        mov     rax, [rax+24]
        test    rax, rax
        je      .L23
        mov     rax, [rbp-16]
        mov     rdx, [rax+24]
        mov     rax, [rbp-24]
        mov     rsi, rdx
        mov     rdi, rax
        call    strcat
.L23:
        mov     rax, [rbp-16]
        mov     rax, [rax]
        mov     [rbp-16], rax
.L22:
        cmp     qword [rbp-16], 0
        jne     .L24
        mov     rax, [rbp-24]
.L17:
        leave
        ret

