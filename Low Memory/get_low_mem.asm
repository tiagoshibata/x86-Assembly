; Methods to get limits of low memory

; CMOS:
mov al, 16h	; Registrador 16h = byte alto
out 70h, al
in al, 71h
mov ah, al
mov al, 15h	; byte baixo
out 70h, al
in al, 71h

; int 12h:
int 12h
jc .failed
	; ax = Kb de 0..EBDA
.failed:

; BDA (13h) -> semelhante a int 12h:
mov ax, [413h]

; BDA (0Eh) -> segmento da EBDA:
mov ax, [40Eh]


; Assume 40Eh has EBDA segment:
mov ax, [40Eh]
mov ds, ax	; lds ax, [40Eh - 2] ?
mov cx, 400h	; 1 KiB
; Busca
; Ou entre E0000 e FFFFF
mov ax, 0E000h
mov ds, ax
mov cx, 0FFFFFh - 0E0000h
; Busca
