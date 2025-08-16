; ---------- GLOBALS ---------- ;
global _start

extern int_to_str

; ---------- CONSTANTS ---------- ;
%define SYS_EXIT 1
%define SYS_WRITE 4
%define SYS_SOCKET 359
%define SYS_BIND 361
%define SYS_LISTEN 363
%define SYS_ACCEPT 364
%define SYS_CLOSE 6
%define SYS_OPEN 5
%define SYS_READ 3

; ---------- File Descriptors ---------- ;
%define STDOUT 1
%define STDERR 2

; ---------- Socket Info ---------- ;
%define AF_INET 2
%define SOCK_STREAM 1
%define PORT 0x55A4     ; Port 42069
%define IN_ADDR 0
%define MAX_CONNECTIONS 5

; ---------- ASCII Characters/ANSI codes ---------- ;
%define NEWLINE 10
%define CR 13
%define ANSI_BLUE 27, "[0;34m"
%define ANSI_RED 27, "[0;31m"
%define ANSI_RESET 27, "[0m"

; ---------- Log Prefixes ---------- ;
%define PREFIX_DEBUG ANSI_BLUE, "[DEBUG] ", ANSI_RESET
%define PREFIX_INFO ANSI_BLUE, "[INFO] ", ANSI_RESET
%define PREFIX_ERROR ANSI_RED, "[ERROR] ", ANSI_RESET

; ---------- MACROS ---------- ;
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

; ---------- MAIN ---------- ;
section .text
_start:
    write STDOUT, creating_socket_msg, creating_socket_msg_len
    create_socket AF_INET, SOCK_STREAM, 0
    mov [sockfd], eax
    test eax, eax
    jl .throw_cannot_create_socket

    write STDOUT, binding_msg, binding_msg_len
    bind_socket [sockfd], sockaddr_in, sockaddr_in_len
    test eax, eax
    jl .throw_failed_binding_socket

    write STDOUT, listening_msg, listening_msg_len
    listen [sockfd], MAX_CONNECTIONS
    test eax, eax
    jl .throw_failed_to_listen_to_socket

.next_request:
    write STDOUT, accepting_msg, accepting_msg_len
    accept [sockfd], client_addr, client_addr_len, 0
    mov [connfd], eax
    test eax, eax
    jl .throw_failed_to_accept_conn

    open index_filename
    mov [fd_in], eax
    test eax, eax
    jl .throw_cannot_open_file

.read:
    read [fd_in], html_content, html_content_len
    push eax
    mov ebx, header_content_length
    push ebx
    call int_to_str
    mov edi, eax

    write [connfd], response, response_len
    write [connfd], header_content_length, edi
    write [connfd], header_separator, header_separator_len
    write [connfd], html_content, html_content_len
    write STDOUT, response, response_len
    write STDOUT, header_content_length, edi
    write STDOUT, header_separator, header_separator_len
    write STDOUT, html_content, html_content_len

    close [fd_in]
    jmp .next_request

.throw_cannot_create_socket:
    write STDERR, err_failed_to_create_socket, err_failed_to_create_socket_len
    jmp .exit

.throw_failed_binding_socket:
    write STDERR, err_failed_to_bind_socket, err_failed_to_bind_socket_len
    jmp .close_socket

.throw_failed_to_listen_to_socket:
    write STDERR, err_failed_to_listen_to_socket, err_failed_to_listen_to_socket_len
    jmp .close_socket

.throw_failed_to_accept_conn:
    write STDERR, err_failed_to_accept_conn, err_failed_to_accept_conn_len
    jmp .close_socket

.throw_cannot_open_file:
    write STDERR, err_cannot_open_file, err_cannot_open_file_len

.close_connection:
    close [connfd]

.close_socket:
    close [sockfd]

.exit:
    mov eax, SYS_EXIT
    xor ebx, ebx
    syscall

; ---------- RESERVED STATIC MEMORY ---------- ;
section .bss
sockfd resd 1
connfd resd 1
fd_in resd 1

html_content resb 10485760 ;; 10MB file size limit
html_content_len equ $ - html_content

header_content_length resb 12
header_content_length_len equ $ - header_content_length

; ---------- DATA SECTION ---------- ;
section .data
client_addr:
    dw AF_INET
    dw PORT
    dd IN_ADDR
    dq 0           ; Empty Padding
client_addr_len dd $ - client_addr

; ---------- READ-ONLY DATA SECTION ---------- ;
section .rodata
; struct sockaddr_in {
;     sa_family_t     sin_family;     /* AF_INET */ (16 bits)
;     in_port_t       sin_port;       /* Port number */ (16 bits)
;     struct in_addr  sin_addr;       /* IPv4 address */ (32 bits)
; };
sockaddr_in:
    dw AF_INET
    dw PORT
    dd IN_ADDR
    dq 0           ; Empty Padding
sockaddr_in_len equ 64

index_filename:
    dd "index.html"

; ---------- Printable Messages ---------- ;
; ---------- HTTP Protocol Request/Response ---------- ;
response:
    db "HTTP/1.1 200 OK", CR, NEWLINE
    db "Content-Type: text/html; charset=utf-8", CR, NEWLINE
    db "Content-Length: "
response_len equ $ - response

header_separator db CR, NEWLINE, CR, NEWLINE
header_separator_len equ 4

; ---------- Debug Messages ---------- ;
creating_socket_msg db PREFIX_DEBUG, "Creating socket...", NEWLINE
creating_socket_msg_len equ $ - creating_socket_msg

binding_msg db PREFIX_DEBUG, "Binding socket...", NEWLINE
binding_msg_len equ $ - binding_msg

listening_msg db PREFIX_DEBUG, "Listening to clients...", NEWLINE
listening_msg_len equ $ - listening_msg

accepting_msg db PREFIX_DEBUG, "Accepting connections...", NEWLINE
accepting_msg_len equ $ - accepting_msg

; ---------- Error Messages ---------- ;
err_failed_to_create_socket db PREFIX_ERROR, "Failed to create socket.", NEWLINE
err_failed_to_create_socket_len equ $ - err_failed_to_create_socket

err_failed_to_bind_socket db PREFIX_ERROR, "Failed to bind socket.", NEWLINE
err_failed_to_bind_socket_len equ $ - err_failed_to_bind_socket

err_failed_to_listen_to_socket db PREFIX_ERROR, "Failed to listen to socket.", NEWLINE
err_failed_to_listen_to_socket_len equ $ - err_failed_to_listen_to_socket

err_failed_to_accept_conn db PREFIX_ERROR, "Failed to listen to incoming connections.", NEWLINE
err_failed_to_accept_conn_len equ $ - err_failed_to_accept_conn

err_cannot_open_file db PREFIX_ERROR, "Cannot open file.", NEWLINE
err_cannot_open_file_len equ $ - err_cannot_open_file
