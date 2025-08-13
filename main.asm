;; Magic numbers
SYS_EXIT equ 1
SYS_WRITE equ 4

STDOUT equ 1
STDERR equ 2

;; Macros
%macro syscall 0
    int 0x80
%endmacro

;; Globals
global _start

;; Main
section .text
_start:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, creating_socket_msg
    mov edx, creating_socket_msg_len
    syscall

    mov eax, SYS_EXIT
    xor ebx, ebx
    syscall

section .data
;; Data
sockfd:
    dd 0

;; Logging/printable text
creating_socket_msg:
    db "Hello World", 0
creating_socket_msg_len equ $ - creating_socket_msg
