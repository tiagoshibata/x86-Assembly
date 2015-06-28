%define PIT_CHANNEL_0	0
%define PIT_CHANNEL_1	(1 << 6)
%define PIT_CHANNEL_2	(2 << 6)
%define PIT_READ_BACK	(3 << 6)
%define PIT_LATCH	0
%define PIT_ACS_LOBYTE	(1 << 4)
%define PIT_ACS_HYBYTE	(2 << 4)
%define PIT_ACS_2BYTES	(3 << 4)
%define MODE(x)		(x + x)
; seta Square Wave Generator
mov al, MODE(3) | PIT_ACS_2BYTES | PIT_CHANNEL_2
out 43h, al

; ativa frequencia
mov ax, 100
; test ax, ax
; jnz .ok
; 	dec ax
; .ok:
out 42h, al
mov al, ah
out 42h, al

; ativa PC Speaker por PIT
in al, 61h
or al, 3
out 61h, al

cli
hlt
jmp $-1
