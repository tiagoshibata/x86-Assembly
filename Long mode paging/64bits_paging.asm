;http://ftp.x.org/pub/current/src/driver/
;http://www.computer-engineering.org/
;http://www.win.tue.nl/~aeb/linux/kbd/scancodes.html
;|---------------------------------|
;|=================================|
;|=================================|
;|-----> REATIVAR TECLADO!!! <-----|
;|=================================|
;|=================================|
;|---------------------------------|
;PCID

;call KBC.wait_input
;mov al,0AEh;ativa teclado
;out 64h,al

%define MEMBASE 7c00h
[bits 16]
[org MEMBASE]

call KBC.wait_input
mov al,0ADh;desativa teclado
out 64h,al

cli
cld

;seta 40x25:
mov ax,3
int 10h

;Limpa tela: (DF=0)
push dword 0B800h
pop es
xor di,di
;background (preto), fonte (cinza):
mov ax,0000_0110b << 8
mov cx,2000
rep stosw


jmp 0:SOF

errors:
db 'CPU não suporta 64 bits.'
.show:
mov si,msg.error
.loop:
	lodsb;al=[ds:si], DF ? si-- : si++
	stosw;[es:di]=ax, di = DF ? DI - 2 : DI + 2
	cmp al,'.'
loopnz .loop
	
xor ah,ah
int 16h;espera tecla

int 19h;reinicia

test_A20:
	not cx
	mov al,[es:10h]
	mov ah,al
	not al
	.loop:
		xchg al,[0]
		cmp ah,[es:10h]
		xchg al,[0]
	loopne .loop
	je A20_on;stack abandonada
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

[bits 16]

SOF:

mov cx,cs;cs=0
mov ds,cx
mov ss,cx
mov sp,7c00h

not cx
mov es,cx

call test_A20;cx = !timeout = FFFF

A20_setup:
;FAST A20:
in al,92h
or al,2
out 92h,al
call test_A20

;FAST Keyboard A20 Enable Command:
mov al,0DDh
out 64h,al
call test_A20

;BIOS:
mov ax,2401h
int 15h
jnc A20_on

;Complete A20 Setup:

call KBC.wait_input
mov al,0D0h;requerir leitura do KBC
out 64h,al

;lê buffer de entrada e guarda em ah
call KBC.wait_output
in al,60h
mov ah,al

call KBC.wait_input
mov al,0D1h;requerir escrita no KBC
out 64h,al

;seta A20
call KBC.wait_input
mov al,ah
or al,2;seta bit 1
out 60h,al

call test_A20
jmp A20_setup

A20_on:


;Se CPUID não é suportado, não é 64 bits
pushfd;push de todas as flags
pop eax
mov ecx, eax;salva valores
xor eax, 0x200000;inverte bit
push eax
popfd
pushfd;guarda e retira flags
pop eax
push ecx
popfd;retorna flags originais
cmp eax,ecx;mudou flag?
je errors.show;não, não tem CPUID

;Suporta funções acima de 80000001h?
mov eax,80000000h
mov ebx,eax
inc bl
cpuid
cmp eax,ebx;possui funções acima de 80000001h?
jb errors.show;jmp below


test_64:
;suporta >0x80000001
mov eax,0x80000001
cpuid
test edx,1 << 29;64 bits
jz errors.show

lgdt [GDT.p]

; ;Página de 1Gb:
; ;PML4E:
; mov dword [0], 1000h | 0000_00_000111b
; mov dword [4], 0_00000000000b << (52 - 32);se IA32_EFER.NXE == 1, execute-disable, senão reservado,
; ;ignorados, endereço físico de PDPTE (1000h), ignorados, reservado, ignorado, acessado, cache disable e write-through, usuário e supervisor, RW,
; ;presente


; mov dword [1000h],(1 << 7) | 111b
; mov dword [1000h + 4],0
; ;63 - Execute Disable, 62:52 - Ignorados, 51:30 - Endereço físico da página, 29:13 - Reservados, 12 - PAT, 11:9 - Ignorados, 8 - Global,
; ;7 - Page Size (1Gb), 6 - Dirty, 5 - Acessed, 4 - Cache Disable, 3 - Write-Through, 2 - User/Supervisor, 1 - Read/W, 0 - presente



; Página de 2 Mb:
;PML4 aponta para PDPTE
mov dword [0], 1000h | 000000000111b; page-directory-pointer table, 4 ignorados, reservado, ignorado, acessado, cache disable, write-through,
									; user/supervisor (se 0, não pode ser acessada com CPL=3), R/W, P
mov dword [4], 0					; M até 51 = reservado, 52:62=ignorados, 63=XD (Execute Disable)
;PDPTE para Page Directory:
mov dword [1000h], (1 << 7) | 111b;2000h | 000100111b	; ponteiro p/ Page Directory, ignorado, Page Size (1 para 1Gb), ignor, acessado, cache disable, write-through,
										; user/supervisor, R/W, P
mov dword [1000h + 4], 0					; 51:M reservado, 62:52 ignor, 63=XD
;Page Directory:
mov dword [2000h], 0h | 00000011100111b		; endereço físico, 20:13 reservados, 12=PAT?, 11:9 ignor, global?, Page Size (1=1Mb), dirty (escrita),
											; Accessed, cache disable, write-through, User/Supervisor, R/W, P
mov dword [2000h + 4], 0					;51:M=reservados, 62:52=ignor, 63=XD


xor eax,eax
mov cr3,eax; (ignr) Com PCIDE: 11:0 = PCIDE, M-1:12 = PML4, 63:M = 0. M = MAXPHYADDR
;Sem PCIDE: 2:0 ignorados, 3 page-level write-through, 4 page-level cache-disable 11:5 ignorados, M-1:12 PML4, 63:M reservados

mov ecx,0xC0000080
rdmsr
or eax,1 << 8;LME (Long Mode Paging)
wrmsr

mov eax,cr4
or eax,1 << 5;PAE
mov cr4,eax

xchg bx,bx

mov eax,cr0
or eax,1 << 31 | 1 << 0;PG (Paging)
mov cr0,eax


jmp 8:long_mode

[bits 64]
long_mode:

mov ax, 16
mov ds, ax

mov rax,cr4
or eax,1 << 17
mov cr4,rax;PCIDE

xor rax,rax;Limpa PML4E, DF=0
mov rdi,8
mov rcx,(4096 - 8) / 8
rep stosq

;Limpa PDPTE
mov rdi,4096 + 8
mov rcx,(4096 - 8) / 8
rep stosq

mov byte [7C00h], 23
mov al, [7C00h]

hlt

physical_address_width	db 0
linear_address_width	db 0

msg:
	.error db 'Erro',0


align 8, db 0

GDT:

dq 0 ;null-selector

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
db 1010_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-31 -> bits 24-31 do endereço base
db 0

;dados (32 bits):
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
db 1001_0011b;setado em ORDEM CONTRÁRIA!

;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> System Bit: se 0, o descriptor é de 16 bytes ao invés de 8
;bit 53 -> Long Mode
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) se setado, segmento *= 4K
db 1010_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-31 -> bits 24-31 do endereço base
db 0

.p:
	dw GDT.p - GDT - 1;tamanho do GDT
	dq GDT;ponteiro

times 510-($-$$) db 0
dw 0AA55h