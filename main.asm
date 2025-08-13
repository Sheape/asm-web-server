;; Globals
global _start

;; Magic numbers
SYS_EXIT equ 1
SYS_WRITE equ 4
SYS_SOCKET equ 359
SYS_BIND equ 361
SYS_LISTEN equ 363
SYS_ACCEPT equ 364
SYS_CLOSE equ 6

STDOUT equ 1
STDERR equ 2

;; Socket info
AF_INET equ 2
SOCK_STREAM equ 1
PORT equ 0x391B
IN_ADDR equ 0
MAX_CONNECTIONS equ 5

;; Macros
%macro syscall 0
    int 0x80
%endmacro

;; void write(int fd, char* buf, size_t buf_len)
%macro write 3
    mov eax, SYS_WRITE
    mov ebx, %1
    mov ecx, %2
    mov edx, %3
    syscall
%endmacro

;; int create_socket(int domain, int type, int protocol)
%macro create_socket 3
    mov eax, SYS_SOCKET
    mov ebx, %1
    mov ecx, %2
    mov edx, %3
    syscall
%endmacro

;; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
%macro bind_socket 3
    mov eax, SYS_BIND
    mov ebx, %1
    mov ecx, %2
    mov edx, %3
    syscall
%endmacro

;; int listen(int sockfd, int backlog);
%macro listen 2
    mov eax, SYS_LISTEN
    mov ebx, %1
    mov ecx, %2
    syscall
%endmacro

%macro accept 4
    mov eax, SYS_ACCEPT
    mov ebx, %1
    mov ecx, %2
    mov edx, %3
    mov esi, %4
    syscall
%endmacro

%macro close 1
    mov eax, SYS_CLOSE
    mov ebx, %1
    syscall
%endmacro

;; Main
section .text
_start:
    write STDOUT, creating_socket_msg, creating_socket_msg_len
    create_socket AF_INET, SOCK_STREAM, 0
    mov [sockfd], eax
    write STDOUT, binding_msg, binding_msg_len
    bind_socket [sockfd], sockaddr_in, sockaddr_in_len
    write STDOUT, listening_msg, listening_msg_len
    listen [sockfd], MAX_CONNECTIONS
    write STDOUT, accepting_msg, accepting_msg_len
    accept [sockfd], client_addr, client_addr_len, 0
    mov [connfd], eax
    write [connfd], response, response_len
    write STDOUT, response, response_len

_exit:
    close [connfd]
    close [sockfd]

    mov eax, SYS_EXIT
    xor ebx, ebx
    syscall

section .bss
sockfd:
    resd 1

connfd:
    resd 1


section .data
; struct sockaddr_in {
;     sa_family_t     sin_family;     /* AF_INET */ (16 bits)
;     in_port_t       sin_port;       /* Port number */ (16 bits)
;     struct in_addr  sin_addr;       /* IPv4 address */ (32 bits)
; };
sockaddr_in:
    dw AF_INET
    dw PORT
    dd IN_ADDR
    dq 0
sockaddr_in_len equ 64

client_addr:
    dw AF_INET
    dw PORT
    dd IN_ADDR
    dq 0
client_addr_len:
    dd $ - client_addr

section .rodata
;; Logging/printable text
creating_socket_msg:
    db "[INFO] Creating socket...", 10
creating_socket_msg_len equ $ - creating_socket_msg

binding_msg:
    db "[INFO] Binding socket...", 10
binding_msg_len equ $ - binding_msg

listening_msg:
    db "[INFO] Listening to clients...", 10
listening_msg_len equ $ - listening_msg

accepting_msg:
    db "[INFO] Accepting connections...", 10
accepting_msg_len equ $ - accepting_msg

response:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: text/html; charset=utf-8", 13, 10
    db 13, 10
    db "<html><h1>WASSUP!! This is a basic HTTP response from a web server written in x86 assembly.</h1></html>", 10
response_len equ $ - response
