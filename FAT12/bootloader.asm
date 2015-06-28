[org 7c00h]
cli
mov ax, 3
int 10h

xor dx, dx
mov ax, 1301h
mov bx, 0000_0111b
mov cx, strlen
mov es, dx
mov bp, message
int 10h

xor ah, ah
int 16h
ret

message db 'Press any key to exit', 0
strlen equ $ - message
