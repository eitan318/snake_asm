.intel_syntax noprefix
.global _start
_start:

.equ LISTENING_BACKLOG, 0
.equ PORT_BIG_ENDI, 0x5000
.equ ADDR_BIG_ENDI, 0x00000000
.equ MAX_RECV, 1024
.equ MAX_FILE, 1024
.equ HTTP_OK_LEN, 19
.equ HTTP_GET_PREFIX_LEN, 4
.equ HTTP_POST_PREFIX_LEN, 5
.equ HTTP_POST_POSTFIX_LEN, 4

# /usr/include/x86_64-linux-gnu/

.equ O_RDONLY, 0
.equ O_WRONLY, 0x1
.equ O_CREAT, 0x40
.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ SYS_SOCKET, 41
.equ SYS_BIND, 49
.equ SYS_LISTEN, 50
.equ SYS_ACCEPT, 43
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_OPEN, 2
.equ SYS_CLOSE, 3
.equ SYS_FORK, 57 
.equ SYS_EXIT, 60


call main

# exit(0)
mov rax, SYS_EXIT 
mov rdi, 0
syscall


#
# http server
#
main:
        push rbp
        mov rbp, rsp

        # create main socket
        mov rax, SYS_SOCKET
        mov rdi, AF_INET 
        mov rsi, SOCK_STREAM
        mov rdx, 0
        syscall                         # rax = main sock fd

        mov r14, rax                    # r14 = main sock fd

        .equ SOCKADDR_LEN, 16
        sub rsp, SOCKADDR_LEN                           # struct sockaddr_in {
        mov [rbp-16], word ptr AF_INET                  #       sa_family_t     sin_family;     /* AF_INET */
        mov [rbp-14], word ptr PORT_BIG_ENDI            #       in_port_t       sin_port;       /* Port number */
        mov [rbp-12], dword ptr ADDR_BIG_ENDI           #       struct in_addr  sin_addr;       /*IPv4 address */
        mov [rbp-8], qword ptr 0                        #       char[8]         padding; }

        # bind ip and port to main sock
        mov rax, SYS_BIND
        mov rdi, r14                     
        lea rsi, [rbp - SOCKADDR_LEN]
        mov rdx, SOCKADDR_LEN
        syscall

        # listen on main sock
        mov rax, SYS_LISTEN
        mov rdi, r14                    # rdi = main sock fd
        mov rsi, LISTENING_BACKLOG
        syscall

.listen_loop:
        # accept client
        mov rax, SYS_ACCEPT
        mov rdi, r14                    # rdi = main sock fd
        xor rsi, rsi                    # sock in kernel
        xor rdx, rdx                    # sock in kernel
        syscall                         # rax = client sock fd 

        mov r13, rax                    # r13 = client sock fd

        mov rax, SYS_FORK
        syscall                         # rax = 0 -> child, chiled_fd -> parent 

        cmp rax, 0
        je .child_proc

        # fallthrow if parent (main) proc

        # close client sock
        mov rax, SYS_CLOSE 
        mov rdi, r13                    # client sock fd
        syscall

        jmp .listen_loop                        # keep listening

.child_proc:
        # here is child (client handler) proc

        # close main sock
        mov rax, SYS_CLOSE 
        mov rdi, r14                    # main sock fd
        syscall
         
        # read request from client sock
        mov rax, SYS_READ 
        mov rdi, r13                    # rdi = client sock fd 
        lea rsi, client_msg
        mov rdx, MAX_RECV 
        syscall                         # rax = client request len

        mov r12, rax                    # r12 = client request len

        cmp byte ptr [client_msg], 'G'
        je .http_get

        .http_post:
        # find header postfix start
        lea rax, client_msg
        push rax
        lea rax, header_postfix
        push rax
        call find_substr                # rax = header postfix start
        add rsp, 16

        mov r14, rax                    # r14 = headerr postfix start

        # null-terminate the path
        lea rax, [client_msg + HTTP_POST_PREFIX_LEN] 
        push rax
        lea rax, space_str
        push rax 
        call find_substr                # rax = next ' ' addr
        add rsp, 16
        mov byte ptr [rax], 0           # null-terminate       

        # open requested file
        lea rdi, [client_msg + HTTP_POST_PREFIX_LEN]          
        mov rax, SYS_OPEN
        mov rsi, O_WRONLY | O_CREAT
        mov rdx, 0x1ff 
        syscall                         # rax requested file fd

        mov r15, rax                    # r15 = requested file fd

        # write to requested file
        mov rsi, r14 
        add rsi, HTTP_POST_POSTFIX_LEN  # rsi = request data start
        mov rax, SYS_WRITE
        lea rdx, client_msg 
        add rdx, r12                    # rdx = request end = (request start) + (request size)
        sub rdx, rsi                    # rdx = request data size = (request end) - (request data start)
        mov rdi, r15                    # requested file fd
        syscall                         # rax = amout written to requested file

        # close requested file 
        mov rax, SYS_CLOSE 
        mov rdi, r15                    # requested file fd
        syscall

        # write http ok to sock
        mov rax, SYS_WRITE
        mov rdi, r13                    # client sock fd
        lea rsi, http_ok
        mov rdx, HTTP_OK_LEN 
        syscall

        jmp .done_main

        .http_get:
        # null-terminate the path
        lea rax, [client_msg + HTTP_POST_PREFIX_LEN] 
        push rax
        lea rax, space_str
        push rax
        call find_substr                # rax = next ' ' addr
        add rsp, 16
        mov byte ptr [rax], 0           # null-terminate       

        # open requested file
        lea rdi, [client_msg + HTTP_GET_PREFIX_LEN]          
        mov rax, SYS_OPEN
        mov rsi, O_RDONLY
        syscall                         # rax requested file fd

        mov r15, rax                    # r15 = requested file fd

        # read requested file
        mov rax, SYS_READ
        mov rdi, r15                    # requested file fd
        lea rsi, file_buf
        mov rdx, MAX_FILE
        syscall                         # rax = amout read from requested file

        mov rbx, rax                    # rbx = amout read from requested file

        #close requested file 
        mov rax, SYS_CLOSE 
        mov rdi, r15                    # requested file fd
        syscall

        # write http ok to sock
        mov rax, SYS_WRITE
        mov rdi, r13                    # client sock fd
        lea rsi, http_ok
        mov rdx, HTTP_OK_LEN 
        syscall

        # write file content to sock
        mov rax, SYS_WRITE
        mov rdi, r13                    # client sock fd
        lea rsi, file_buf
        mov rdx, rbx                    # amount read from requested file 
        syscall

.done_main:
        mov rsp, rbp
        pop rbp
        ret

#
# (cdcle) get_next_space(str, substr)
#
find_substr:
        push rbp
        mov rbp, rsp

        mov rax, [rbp+24]               # str*
.pass:
        mov rcx, [rbp+16]               # substr*
        push rax
.check_match:
        mov dl, byte ptr [rax] 
        cmp dl,  0
        je .not_found                   # if *str reached \0 it was not found at all

        cmp byte ptr [rcx], 0           # if *substr reached \0 it is equal to *str
        je .found_match

        cmp dl, [rcx]
        jne .mismatch                   # if a char is different, current check is wrong

        inc rcx                         # inc curr tmp substr ptr
        inc rax                         # inc curr tmp str ptr
        jmp .check_match

.found_match:
        pop rax                         # return curr str ptr 
        jmp .done_fsbstr

.mismatch:
        pop rax
        inc rax                         # inc curr str ptr
        jmp .pass

.not_found:
        pop rax
        mov rax, -1                     # ret -1

.done_fsbstr:
        mov rsp, rbp
        pop rbp
        ret



.section .data
http_ok:                .asciz "HTTP/1.0 200 OK\r\n\r\n"
header_postfix:         .asciz "\r\n\r\n"
space_str:              .asciz " "

.section .bss
file_buf: .skip MAX_FILE
client_msg: .skip MAX_RECV
