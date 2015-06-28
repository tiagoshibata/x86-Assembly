%define MEM_BASE 7c00h
[bits 16]     ;real-mode
[org MEM_BASE]   ;offset de boot
cli
;seta 80x25:
mov ax,03h
int 10h
;Esconde cursor:
inc ah;ah=1
mov cx,0010_0000b << 4 | 0000b;Opções (esconder cursor), linha inicial, linha final
int 10h
;Limpa tela:
push dword 0B800h
pop es
xor edi,edi
;background, fonte, char, background, fonte, char:
mov eax,1111_0000_0000_0000_1111_0000_0000_0000b
mov cx,1000
rep stosd
loop .loop
hlt
times 510 - ($ - $$) db 0
dw 0AA55h