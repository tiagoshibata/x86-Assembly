;http://bochs.sourceforge.net/doc/docbook/user/internal-debugger.html
;http://www.dmtf.org/
;http://pages.cs.wisc.edu/~remzi/OSFEP/
;http://forum.osdev.org/viewtopic.php?f=1&t=18222
;http://brokenthorn.com/Resources/OSDevScanCodes.html
%define MEMBASE 7c00h
%include 'mem_position.inc'
msr:;model specific registers
	.IA32_EFER equ 0xC0000080 
%warning buggy
[bits 16]     ;real-mode
[org MEMBASE]   ;offset de boot
cli;sem int's de hardware
;FAST A20:
in al,92h
or al,2
out 92h,al

; mov ax,201h
; ;mov ah,2;função
; ;mov al,1;número de setores para escrever/ler

; mov cx,2
; ;mov ch,0;cilindro
; ;mov cl,2;setor
; xor dh,dh;cabeça
; ;dl=drive

; ;buffer (alinhado em 4kB (4096/1000h), ou seja, segmento 256 (100h), offset 0):
; mov bx,100h
; mov es,bx
; xor bx,bx

; int 13h
; xchg bx,bx

jmp 0:SOF
SOF:
push cs
pop ds
							;4 ingorados,00,atributos,1
mov [0],dword 					(0000_0011_1111b | (73000h << 12));(1000h | (0111_1100_0000b << 20));Page Directory Entry 1

;primeira PTE
mov ax,100h
mov es,ax

mov edi,73000h
mov eax,0000_0111_1111b | (0 << 12);inicio fisico
mov cx,256;Kb's para mapear
cld
id_map:
	stosd
	;add edi,4
	add eax,(4096 << 12)
loop id_map
; xor eax,eax
; mov ecx,100
; id_maping_loop:
	; mov ebx,eax
	; shl ebx,10;ebx = 1024 * eax (1000h * eax)
	; or ebx,0000_0111_1111b
	; mov dword [1000h + eax],ebx
	; add eax,4
; loop id_maping_loop
; mov dword [1000h],				(0000_0111_1111b | (0 << 12)) ;0:4kB - 1
; mov dword [1000h + (4 * 7)],	(0000_0111_1111b | ((28 * 1024) << 12));7ª entrada: 28kB:32kB - 1
lgdt [GDT.pointer]

mov eax,cr0
or eax,1<<0;seta bit PM (0, modo protegido)
mov cr0,eax

jmp 8:pmode;16 é a posição do code descriptor de código no GDT. Ainda sem IRQ's
   
[bits 32]
pmode:
; ;copia memória de 100h para 0h:
; push 16
; pop es
; xor edi,edi
; mov esi,100h
; cld
; mov ecx,8
mov ax,16
mov ds,ax
mov es,ax
mov ss,ax
mov esp,7c00h

xchg bx,bx
xor eax,eax
mov cr3,eax;endereço de Page Directory

mov eax,cr0
or eax,1<<31;seta paginação 32 bits
mov cr0,eax

xchg bx,bx
mov [0],byte 0Ah
hlt
	
;GDT:
GDT:
.start:
;8 bytes para null-descriptor
dw 0
dw 0
db 0
db 0
db 0
db 0

;data-descriptor
;quad-word=4 palavras=8 bytes
;http://www.brokenthorn.com/Resources/OSDev8.html

;código (32 bits):
dw 1111_1111_1111_1111b;bits 0-15 -> bits 0-15 do limite do segmento
dw 0;bits 16-31 -> bits 0-15 do endereço base
db 0;bits 32-39 -> bits 16-23 do endereço base

;bit 40 -> bit de acesso - setado pela CPU para 1 cada vez que o segmento é acessado. Usado pelo OS para definir se o segmento é muito acessado
;bit 41 -> acesso. 1 = leitura e escrita (segmento de dados), leitura e execução (segmento de código), 0=leitura ("") e execução ("")
;bit 42 -> direção de expansão
;bit 43 -> tipo de segmento (0=dados,1=código)
;bit 44 -> bit do descriptor - 0=do sistema,1=código/dados(programa)
;bits 45 e 46 -> privilégio (0=máx,3=mín)
;bit 47 -> bit P - setado se o segmento está na memória. Usado pelo sistema para manusear os segmetos em memória RAM e virtual.
db 1001_1111b;setado em ORDEM CONTRÁRIA!

;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> System Bit: se 0, o descriptor é de 16 bytes ao invés de 8
;bit 53 -> Long Mode
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) se setado, segmento *= 4K
db 1100_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-31 -> bits 24-31 do endereço base
db 0

;dados:

dw 1111_1111_1111_1111b;bits 0-15 -> bits 0-15 do limite do segmento
dw 0;bits 16-31 -> bits 0-15 do endereço base
db 0;bits 32-39 -> bits 16-23 do endereço base

;bit 40 -> bit de acesso - setado pela CPU para 1 cada vez que o segmento é acessado. Usado pelo OS para definir se o segmento é muito acessado
;bit 41 -> acesso. 1 = leitura e escrita (segmento de dados), leitura e execução (segmento de código), 0=leitura ("") e execução ("")
;bit 42 -> direção de expansão
;bit 43 -> tipo de segmento (0=dados,1=código)
;bit 44 -> bit do descriptor - 0=do sistema(LDT/TSS/Gate),1=código/dados(programa)
;bits 45 e 46 -> privilégio (0=máx,3=mín)
;bit 47 -> bit P - setado se o segmento está na memória. Usado pelo sistema para manusear os segmetos em memória RAM e virtual.
db 1001_0011b;setado em ORDEM CONTRÁRIA!
;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> reservado para o SO
;bit 53 -> reservado (0)
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) - 1=segmento *= 4K
db 1100_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-32 -> bits 24-32 do endereço base
db 0

.pointer:
	dw GDT.pointer - GDT.start - 1;tamanho do GDT
	dq GDT.start;ponteiro

times 510-($-$$) db 0

dw 0AA55h

; ;7c00 = 31744
; ;31744 / 1024 = 31 kB
; ;31744 + 512 = 32256
; ;32256 / 1024 = 31.5
; ;bootloader está entre 31 kB e 31.5 kB na memória RAM física
; ;Page Table Entry:
; PTE: dd 0000_0111_1111b | 0 << 11 ;0:4kB - 1
; dd 0 ;4kB:8kB - 1
; dd 0;8kB:12kB - 1
; dd 0;12kB:16kB - 1
; dd 0;16kB:20kB - 1
; dd 0;20kB:24kB - 1
; dd 0;0000_0111_1111b | (24 * 1024) << 11;24kB:28kB - 1
; dd 0;0000_0111_1111b | (28 * 1024) << 11;28kB:32kB - 1


; times 1024 - ($ - $$) db 0
