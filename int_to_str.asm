; Globals
global int_to_str

section .bss
tmp_buf:
    resb 12

; Main
section .text

; char* int_to_str(int input)
;
; Parameters:
; int input - [esp + 8]
; char* buffer - [esp + 4]
;
; Returns:
; memory address to output string - eax
int_to_str:
    mov ebx, [esp + 8]
    mov edi, [esp + 4]

    mov esi, tmp_buf + 11
    test ebx, ebx
    xor bp, bp
    jg _divide

_negative:
    mov byte [tmp_buf], '-'

_divide:
    mov eax, ebx
    test eax, eax
    je _copy_to_buffer
    xor edx, edx
    mov ecx, 10
    div ecx
    mov ebx, eax

_cast:
    add dl, '0'
    dec esi
    inc bp
    mov [esi], dl
    jmp _divide

_copy_to_buffer:
    movzx ecx, bp
    cld
    rep movsb
    movzx eax, bp

_end:
    ret
