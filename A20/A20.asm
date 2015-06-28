%define DISABLED 0
%define ENABLED 1
%define COMPLETE_IMAGE 1
%define A20_startup_status DISABLED

;http://www.bioscentral.com/misc/bda.htm#
;http://www.nondot.org/sabre/os/files/Booting/BIOS_SEG.txt
;http://www.vesa.org/wp-content/uploads/2010/12/thanksdport.htm
;http://www.vesa.org/wp-content/uploads/2010/12/thankspublic.htm
;http://www.petesqbsite.com/sections/tutorials/zines/qbtm/1-svga.html
;http://www.petesqbsite.com/sections/tutorials/graphics.shtml
;http://www.petesqbsite.com/sections/tutorials/tutorials/vesasp12.txt
;http://www.gamedev.net/page/resources/_/technical/graphics-programming-and-theory/graphics-programming-black-book-r1698

%macro def_str 0
	%strlen __strsize pstring
	dw __strsize ;n�mero de chars
	db pstring   ;string
%endmacro

%macro BIOS_disable_A20 0
	mov ax,2400h
	int 15h
%endmacro

%macro FAST_A20 0
	;FAST A20 System Line:
	in al,92h
	or al,2
	out 92h,al
	call test_A20
	mov si,fastA20
	je EOF
%endmacro

%macro FAST_KEYBOARD 0
	;FAST Keyboard A20 Enable Command:
	mov al,0DDh
	out 64h,al
	mov si,fastkbc
	call test_A20
	je EOF
%endmacro

%macro BIOS_A20_COMMAND 0
	;BIOS:
	mov ax,2401h
	int 15h
	mov si,BIOS_enable
	jnc EOF
%endmacro

%macro COMPLETE_A20_SETUP 0
	;Complete A20 Setup:
	call KBC.wait_input
	mov al,0ADh;desativa teclado
	out 64h,al

	call KBC.wait_input
	mov al,0D0h;requerir leitura do KBC
	out 64h,al

	call KBC.wait_output
	;l� buffer de entrada e guarda em ah
	in al,60h
	mov ah,al

	call KBC.wait_input
	mov al,0D1h;requerir escrita no KBC
	out 64h,al

	call KBC.wait_input
	;seta A20
	mov al,ah
	or al,2;seta bit 1
	out 60h,al

	call KBC.wait_input
	mov al,0AEh;ativa teclado
	out 64h,al

	call test_A20
	mov si,complete_setup
	je EOF
%endmacro

[bits 16]
[org 7c00h]

cli
; %if (A20_startup_status == DISABLED)
	; BIOS_disable_A20
; %else
	; in al,92h
	; or al,2
	; out 92h,al
; %endif
xor di,di
jmp 0:SOF

test_A20:
	push 0FFFFh
	pop es
	mov al,[es:10h]
	mov ah,al
	not al
	mov cx,20
	.loop:
		xchg al,[0]
		cmp ah,[es:10h]
		xchg al,[0]
		je A20_on
	loop .loop
	ret


print:
mov cx,[si];n�mero de chars
inc si
inc si;pular n�mero de chars

;push dword 0B800h
;pop es

mov ax,0B800h
mov es,ax

mov ah,0000_1111b;preto e branco
cld
_loop:
	movsb;[es:edi] = [ds:esi], DF ? si-- di-- : si++ di++
	inc di
	loop _loop
ret

KBC:
 .wait_input:;espera buffer de entrada no teclado do KBC estar vazio (pode escrever!).
	 in      al,64h
	 test    al,2
	 jnz     .wait_input
	 ret

 .wait_output:;espera dados no buffer (pode ler!).
	 in      al,64h
	 test    al,1
	 jz      .wait_output
	 ret

SOF:

;seta 80x25:
mov ax,03
int 10h
; ;Esconde cursor:
; inc ah;ah=1
; mov cx,0010_0000b << 4 | 0000b;Op��es (esconder cursor), linha inicial, linha final
; int 10h
; ;Limpa tela:
; push dword 0B800h
; pop es
; xor edi,edi
; ;background, fonte, char, background, fonte, char:
; mov eax,1111_0000_0000_0000_1111_0000_0000_0000b
; mov cx,1000
; rep stosd

mov si,init
call print

call test_A20

mov si,off
call print
jmp continue

A20_on:
mov si,on
jmp EOF

continue:

push .bios
FAST_A20
.bios:

BIOS_disable_A20

push .FAST_KBC
BIOS_A20_COMMAND
.FAST_KBC:

BIOS_disable_A20

push .COMPLETE
FAST_KEYBOARD
.COMPLETE:

BIOS_disable_A20

push .END
COMPLETE_A20_SETUP
.END:

A20_failed:
mov si,fail
call print
jmp reboot

EOF:
call print
hlt
;ret

reboot:

xor ah,ah
int 16h

int 19h

%define pstring '  A20 ativado  '
on: def_str

%define pstring '  A20 desativado  '
off: def_str

%define pstring '  Fim do programa'
fail: def_str

%define pstring 'Iniciando teste da linha A20...     '
init: def_str

%define pstring '  Ativando linha A20...  '
loading: def_str

%define pstring '  FAST A20 System Gate -> On'
fastA20: def_str

%define pstring '  FAST Keyboard A20 Enable Command -> On'
fastkbc: def_str

%define pstring '  BIOS 15h/2401h OK'
BIOS_enable: def_str

%define pstring '  Complete Setup OK'
complete_setup: def_str

; times 510 - ($ - $$) db 0

; dw 0AA55h

; %if (COMPLETE_IMAGE == 1)
	; times (720 * 1024) - ($ - $$) db 0 ;720 Kb
; %endif
