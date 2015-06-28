[bits 16]
[org 7c00h]
cli
jmp 0:SOC
SOC:
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
	;EOI:
	mov al,20h
	out 20h,al
	int 19h