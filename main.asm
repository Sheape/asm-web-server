;; Globals
global _start

;; Magic numbers
%define SYS_EXIT 1
%define SYS_WRITE 4
%define SYS_SOCKET 359
%define SYS_BIND 361
%define SYS_LISTEN 363
%define SYS_ACCEPT 364
%define SYS_CLOSE 6
%define SYS_OPEN 5
%define SYS_READ 3

%define STDOUT 1
%define STDERR 2

;; Socket info
%define AF_INET 2
%define SOCK_STREAM 1
%define PORT 0x391B
%define IN_ADDR 0
%define MAX_CONNECTIONS 5

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

%macro open 1
    mov eax, SYS_OPEN
    mov ebx, %1
    xor ecx, ecx
    syscall
%endmacro

%macro read 3
    mov eax, SYS_READ
    mov ebx, %1
    mov ecx, %2
    mov edx, %3
    syscall
%endmacro

;; Main
section .text
_start:
    write STDOUT, creating_socket_msg, creating_socket_msg_len
    create_socket AF_INET, SOCK_STREAM, 0
    mov [sockfd], eax
    test eax, eax
    jl _throw_cannot_create_socket

    write STDOUT, binding_msg, binding_msg_len
    bind_socket [sockfd], sockaddr_in, sockaddr_in_len
    test eax, eax
    jl _throw_failed_binding_socket

    write STDOUT, listening_msg, listening_msg_len
    listen [sockfd], MAX_CONNECTIONS
    test eax, eax
    jl _throw_failed_to_listen_to_socket

_accept:
    write STDOUT, accepting_msg, accepting_msg_len
    accept [sockfd], client_addr, client_addr_len, 0
    mov [connfd], eax
    test eax, eax
    jl _throw_failed_to_accept_conn

    open index_filename
    mov [fd_in], eax
    test eax, eax
    jl _throw_cannot_open_file

    read [fd_in], html_content, html_content_len

    write [connfd], response, response_len
    write [connfd], html_content, html_content_len
    write STDOUT, response, response_len
    write STDOUT, html_content, html_content_len

    close [fd_in]
    jmp _accept

_throw_cannot_create_socket:
    write STDERR, err_failed_to_create_socket, err_failed_to_create_socket_len
    jmp _exit

_throw_failed_binding_socket:
    write STDERR, err_failed_to_bind_socket, err_failed_to_bind_socket_len
    jmp _close_socket

_throw_failed_to_listen_to_socket:
    write STDERR, err_failed_to_listen_to_socket, err_failed_to_listen_to_socket_len
    jmp _close_socket

_throw_failed_to_accept_conn:
    write STDERR, err_failed_to_accept_conn, err_failed_to_accept_conn_len
    jmp _close_socket

_throw_cannot_open_file:
    write STDERR, err_cannot_open_file, err_cannot_open_file_len

_close_connection:
    close [connfd]

_close_socket:
    close [sockfd]

_exit:
    mov eax, SYS_EXIT
    xor ebx, ebx
    syscall

section .bss
sockfd:
    resd 1

connfd:
    resd 1

fd_in:
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


section .bss
html_content:
    resb 10485760
html_content_len equ $ - html_content

section .rodata
;; Data
index_filename:
    dd "index.html"

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
response_len equ $ - response

;; Errors
err_failed_to_create_socket:
    db "[ERROR] Failed to create socket.", 10
err_failed_to_create_socket_len equ $ - err_failed_to_create_socket

err_failed_to_bind_socket:
    db "[ERROR] Failed to bind socket.", 10
err_failed_to_bind_socket_len equ $ - err_failed_to_bind_socket

err_failed_to_listen_to_socket:
    db "[ERROR] Failed to listen to socket.", 10
err_failed_to_listen_to_socket_len equ $ - err_failed_to_listen_to_socket

err_failed_to_accept_conn:
    db "[ERROR] Failed to listen to incoming connections.", 10
err_failed_to_accept_conn_len equ $ - err_failed_to_accept_conn

err_cannot_open_file:
    db "[ERROR] Cannot open file.", 10
err_cannot_open_file_len equ $ - err_cannot_open_file
