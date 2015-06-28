;http://en.wikipedia.org/wiki/X86
%macro set_bit 2
	%strlen __strl		%1
	%define __bit_set	1 << %2
	%define __index		0
	%rep __strl
		%substr char	%1 __index
		db char | __bit_set
		%define __index __index + 1
	%endrep
%endmacro
[bits 16]
[org 7c00h]
cli
jmp 0:SOC

SOC:

;http://www.brokenthorn.com/Resources/OSDevPic.html
;http://ftp.utcluj.ro/pub/users/nedevschi/PMP/WLab/dmaintr/8259pic.txt
; 8259A Software Port Map
; Port Address	Description
; 0x20	Primary PIC Command and Status Register
; 0x21	Primary PIC Interrupt Mask Register and Data Register
; 0xA0	Secondary (Slave) PIC Command and Status Register
; 0xA1	Secondary (Slave) PIC Interrupt Mask Register and Data Register

;Initialization Control Word (ICW) 1:
;inicializa PIC (Programmable Interrupt Controller)
; Bit 0 - 1 se for enviar ICW 4
; Bit 1 - 0 para + que 1 PIC (cascade mode) (2 em 8086) 1 para single-mode
; Bit 2 - 0 em 8086
; Bit 3 - Edge triggered (0)/Level triggered (1).
; Bit 4 - bit de inicialização (1 para inicializar PIC)
; Bits 5...7 - 0 em 8086
mov al,000_1_0_0_0_1b;11h
;envia para PIC master e slave:
out 20h,al
out 0A0h,al

;ICW 2 (nescessário na inicialização, seta posição da IVT):
;bits:0-2: endereço A10-A20 da IVT
;3-7:endereço da IVT
;IRQ's até 31 são excessões da CPU, então mapeamos para 32-47 IRQ's de hardware.
;As primeiras 8 para Master (início em 32) e últimas para Slave (40 -> 48)
mov al,32
out 21h,al
mov al,40
out 0A1h,al

;ICW 3 (nescessário para Cascading (+ que 1 PIC), envia qual IRQ deve ser usada para comunicação entre PIC's):
;Master: qual IRQ se conecta com Slave
;Slave: 0-2: qual IRQ o PIC Master usa para se conectar
;       3-7: reservados (0)
;IRQ 2 é usada em 8086 (setar bit 2 em Master, usa número em Slave):
mov al,1 << 2
out 21h,al
mov al,2
out 0A1h,al

;ICW 4 (requer se setado bit 0 da ICW 1):
;bit 0: 1 se 8086
;1: controlador executa End of Interrupt (EOI) automaticamente
;2: se em modo buffered, 1 para buffer master e 0 para slave
;3: buffered mode
;4: Special Fully Nested Mode, para sistemas antigos com vários PIC's. 0 para 8086
;5-7: reservados (0)
mov al,101b
out 21h,al
mov al,1
out 0A1h,al

;Operation Command Word 1 (OCW): Ativa IRQ do teclado:
mov al,1111_1101b
out 21h,al
mov al,1111_1111b
out 0A1h,al

xor ax,ax
mov ds,ax

mov word [33 * 4], K_handler;offset
mov word [33 * 4 + 2], ax;0 = segmento

cld
push 0B800h
pop es
xor di,di

sti

freeze: hlt
jmp freeze

K_handler:
	wait_keyboard:
		in al,64h
		test al,1
		jz wait_keyboard
	in al,60h
	;escreve em hexadecimal:
	mov cx,2
	xor bh,bh
	mov ah,0000_1111b
	write:
		rol al,4
		push ax
		and al,1111b
		mov bl,al
		mov al,[bx + hex_chars]
		stosw
		pop ax
	loop write
	mov al,'|'
	stosw
	jmp ret_irq
	
ret_irq:
	mov al,20h
	out 20h,al
	iret

hex_chars				db '0123456789ABCDEF'

;scancodes utilizados:			NÃO UTILIZADOS: 0, 54, 55, 56, 59, 5A, 5B (apenas escaped), 5C (apenas escaped), 5D (apenas escaped),
;								5E (apenas escaped), 5F (apenas escaped), 60, 61, 62, 63 (apenas escaped), 64, 65 (apenas escaped), 66 (apenas escaped)
;								67 (apenas escaped), 68 (apenas escaped), 69 (apenas escaped), 6A (apenas escaped), 6B (apenas escaped),
;								6C (apenas escaped), 6D (apenas escaped), 6E, 6F, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 7A,7B, 7C, 7D, 7E, 7F, 80
;1 Esc         2 1           3 2      4 3      5 4      6 5      7 6      8 7      9 8      A 9      B 0      C -            D =           E Backspace
;F TAB         10 Q          11 W     12 E     13 R     14 T     15 Y     16 U     17 I     18 O     19 P     1A [           1B ]          1C ENTER
;1D CTRL E     1E A          1F S     20 D     21 F     22 G     23 H     24 J     25 K     26 L     27 ;     28 '           29 `          2A SHIFT E 
;2B \          2C Z          2D X     2E C     2F V     30 B     31 N     32 M     33 ,     34 .     35 /     36 SHIFT D     37 KP*        38 ALT E
;39 ESPAÇO     3A CAPS LOCK  3B F1    3C F2    3D F3    3E F4    3F F5    40 F6    41 F7    42 F8    43 F9    44 F10         45 NUM LOCK   46 SCROLL Lk
;47 KP7        48 KP8        49 KP9   4A KP-   4B KP4   4C KP5   4D KP6   4E KP+   4F KP1   50 KP2   51 KP3   52 KP0         53 KP.        54 ---------
;55 -----      56 -----      57 F11   58 F12   59 ----- 5A ----- 5B ----- 5C -----
;							  ESC		 backspace/tab				enter/Ctrl E			Shift E		  Shift D
; KB_scancodes			db 0, 1, '1234567890-=', 2, 3, 'qwertyuiop[]', 4, 5, "asdfghjkl;'`", 6, '\zxcvbnm,./', 7
						; set_bit('*', 7);Keypad
					; ;Alt E	Caps Lock F1..F10						Num Lock (20)/Scroll Lock
						; db 8, ' ', 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
						; set_bit('789-456+1', 7);Keypad
						
; KB_escaped_scancodes	db 

times 510 - ($ - $$) db 0
dw 0AA55h