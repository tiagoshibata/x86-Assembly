;http://bochs.sourceforge.net/techspec/adlib_sb.txt
%define PIT_CHANNEL_0	0
%define PIT_CHANNEL_1	(1 << 6)
%define PIT_CHANNEL_2	(2 << 6)
%define PIT_READ_BACK	(3 << 6)
%define PIT_LATCH	0
%define PIT_ACS_LOBYTE	(1 << 4)
%define PIT_ACS_HYBYTE	(2 << 4)
%define PIT_ACS_2BYTES	(3 << 4)
%define MODE(x)		(x + x)
[org 7C00h]
[bits 16]
cli
jmp 0:SOC
SOC:

; Desativa controlador primário
call KBC.wait_input
mov al, 0ADh
out 64h, al
; Desativa controlador secundário
call KBC.wait_input
mov al, 0A7h
out 64h, al
; Clear keyboard buffer:
clear_buffer:
in al, 60h	; receive a byte
in al, 64h
test al, 1	; buffer not empty?
jnz clear_buffer
; Ativa controlador primário
call KBC.wait_input
mov al, 0AEh
out 64h, al
; Seta Scancode Set 1:
call KBC.wait_input
mov al, 1
out 0F0h, al


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
mov al,000_1_0_0_0_1b
;envia para PIC master e slave:
out 20h,al
out 0A0h,al
;ICW 2:
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
mov al,1
out 21h,al
out 0A1h,al
;Operation Command Word 1 (OCW): Ativa IRQ do teclado:
mov al,1111_1101b
out 21h,al
mov al,1111_1111b
out 0A1h,al

mov word [33 * 4], K_handler	;offset
mov word [33 * 4 + 2], 0	;0 = segmento

; seta Square Wave Generator
mov al, MODE(3) | PIT_ACS_2BYTES | PIT_CHANNEL_2
out 43h, al

; ativa frequencia
mov bx, 1193180 / 1000;0FFFFh	; frequencia / 2
call set_freq

; ativa PC Speaker por PIT
in al, 61h
or al, 3
out 61h, al

sti

; lê tecla
get_key:
hlt
cmp ah, 1	; Esc
je reboot
cmp ah, 1Eh	; A
jne .notA
	sub bx, 4
.notA:
cmp ah, 1Fh	; S
jne .notS
	add bx, 4
.notS:

set_freq:
mov ax, bx
; test ax, ax
; jnz .ok
; 	dec ax
; .ok:
out 42h, al
mov al, ah
out 42h, al
jmp get_key

IDT:
dw 0
dd 0

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

K_handler:
	call KBC.wait_output
	in al, 60h
	mov ah, al
	; EOI:
	mov al,20h
	out 20h,al
iret

reboot:
	lidt [IDT]
	int 3
stop: hlt
jmp stop