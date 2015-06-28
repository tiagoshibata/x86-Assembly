%define MEM_BASE			7c00h
%define BOOTING_BREAKPOINT	0
%define INT_BREAKPOINT		0

%macro BREAKPOINT 0
	xchg bx,bx
%endmacro

%macro b_int 1;int com breakpoint
	int %1
	;%if (INT_BREAKPOINT == 1)
	;	BREAKPOINT
	;%endif
%endmacro

msr:;model specific registers
	.IA32_EFER equ 0xC0000080 
[bits 16]		;real-mode
[org MEM_BASE]	;offset de boot

%if (BOOTING_BREAKPOINT == 1)
	BREAKPOINT
%endif

cli
cld;DF=0
;FAST A20:
in al,92h
or al,2
out 92h,al
jmp 0:SOF

get_next_mem_pos:
	mov edx,534D4150h;'SMAP'
	mov eax,0E820h;número da int
	mov [es:di + 20],dword 1
	mov ecx,24;pedir 24 bytes
	b_int 15h
ret

reboot:
	b_int 19h
hlt
	
SOF:

;Detecta memória com int's da BIOS:
map_mem:

xor di,di
mov sp,7c00h
xor ebx,ebx
mov ss,bx
mov ds,bx
call get_next_mem_pos
hlt
;se primeira chamada funcionou, CF=0 e eax=534D4150h
jc reboot
E820_ok:
cmp eax,534D4150h
jne reboot
test ebx,ebx
jz reboot;ebx=0? Apenas uma entrada (não suportado)
;loop para receber memória
receive_mem:
.loop:
jcxz .receive_next;nenhuma entrada? pula para próxima

cmp cl,24
jb .valid;cl < 24,não há entrada especial de mem inválida

test byte [di + 20],1;bit pata ignorar entrada setado?
jz .receive_next;pula para próxima

.valid:;entrada válida!

.test_type:
mov eax, dword [di + 16];tipo de entrada (di + 16)
;eax == 1 || eax == 3 ? continua : lê próxima entrada
cmp eax,1
je .valid_RAM
cmp eax,3
jne .receive_next

.valid_RAM:;memória válida,livre e RAM!
add di,16;seta ponteiro para próxima entrada e recebe-a

.receive_next:
test ebx,ebx
jz .end;se ebx == 0,fim do mapeamento.
call get_next_mem_pos
jnc .loop;CF ? fim da lista : continuar.

.end:
mov [temp],di
lgdt [GDT.pointer]

mov eax,cr4
or eax,1<<5;bit 5 = PAE. PAE e PG = IA-32e paging. bit 17 = PCIDE
mov cr4,eax

xor edi,edi
mov	ecx,4000h >> 2;1_0000_0000_0000b,1000h,4096 dwords = 4000h bytes (0h -> 4000h)
xor	eax,eax
rep	stosd			; clear the page tables

mov	dword [0000h],1000h + 111b ; first PDP table
mov	dword [1000h],2000h + 111b ; first page directory
mov	dword [2000h],3000h + 111b ; first page table

mov	edi,3000h		; address of first page table
mov	eax,0 + 111b
mov	ecx,256 		; number of pages to map (1 MB)
make_page_entries:
stosd;guarda em [es:edi] o valor em eax. DF=0, incrementa edi em 4.
add	edi,4;edi += 4, no total += 8.
add	eax,1000h
loop	make_page_entries

xor eax,eax
mov cr3,eax

;seta registrador model-especific
mov ecx,msr.IA32_EFER;long mode, model-especific
rdmsr;lê do registrador model-espcific
or eax,1<<8;seta bit 8 (IA32_EFER.LME) para paging em 64 bits
wrmsr;escreve no registrador mode-especific

;ativa PMode e LMode:
mov eax,cr0
or eax,1<<31 | 1<<0;seta bit PG (31, paging e LMode) e PM (0, modo protegido)
mov cr0,eax

;far jump para setar cs e ip:
jmp 8h:long_mode;8 é a posição do code descriptor de código no GDT. Ainda sem IRQ's

[bits 64]
long_mode:
BREAKPOINT
mov ax,16
mov ds,ax

; mov rsi, test_map
; mov rbp,test_map.end
; call show_mem
; hlt

mov rsi,7BFFh
xor rbp,rbp
mov bp,[temp]
call show_mem

EOF:
mov dword [0B000h + 160 * 5],'E F '
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

;código (64 bits):
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
db 1001_1011b;setado em ORDEM CONTRÁRIA!

;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> System Bit: se 0, o descriptor é de 16 bytes ao invés de 8
;bit 53 -> Long Mode
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) se setado, segmento *= 4K
db 1011_1111b;setado em ORDEM CONTRÁRIA!
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
;bit 44 -> bit do descriptor - 0=do sistema,1=código/dados(programa)
;bits 45 e 46 -> privilégio (0=máx,3=mín)
;bit 47 -> bit P - setado se o segmento está na memória. Usado pelo sistema para manusear os segmetos em memória RAM e virtual.
db 1001_0111b;setado em ORDEM CONTRÁRIA!
;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> reservado para o SO
;bit 53 -> reservado (0)
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) - 1=segmento *= 4K
db 0100_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-32 -> bits 24-32 do endereço base
db 0

;dados (64 bits):
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
db 1001_0111b;setado em ORDEM CONTRÁRIA!

;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> System Bit: se 0, o descriptor é de 16 bytes ao invés de 8
;bit 53 -> Long Mode
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) se setado, segmento *= 4K
db 1010_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-31 -> bits 24-31 do endereço base
db 0

.end:
.pointer:
	dw GDT.pointer - GDT.start - 1;tamanho do GDT
	dq GDT.start;ponteiro

	
test_map: dq 0,0xC0DE,0xDEAD,0xCAFE,0xAE,0FFFFFFFFFFFFFFFFh,0xBABACA,0FFFF0000h,0xBEEF
.end:


show_mem:	;mostra qwords. ds:rbp=fim do mapa, ds:rsi=início do mapa
	mov rdi,0B8000h;posição física na memória de vídeo
	mov rbx,rsp
.next_q:
	lodsq;rax = [ds:rsi], rsi += 8
	mov dh,' ';atributo
	mov rcx,16;número de caracteres
	.div_loop:
	rol rax,4;rotate left
	mov dl,al
	and dl,1111b
	cmp dl,9
	jg .mostra_letra
	add dl,48
	jmp .test_eax
	.mostra_letra:
	add dl,55
	.test_eax:
	mov [rdi],dx
	inc rdi
	inc rdi
	loop .div_loop
	
	mov [rdi],word 0
	inc rdi
	inc rdi
	
	cmp rsi,rbp
	jb .next_q;jump below
	
	mov rsp,rbx
ret
temp:
times 510-($-$$) db 0

dw 0AA55h