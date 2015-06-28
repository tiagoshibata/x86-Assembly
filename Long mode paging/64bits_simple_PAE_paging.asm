;http://wiki.osdev.org/Memory_Map_%28x86%29
;http://wiki.osdev.org/Category:Power_management
;http://atschool.eduweb.co.uk/camdean/pupils/amac/vga.htm
;http://en.wikipedia.org/wiki/Global_Descriptor_Table
;http://siyobik.info/main/reference
;http://wiki.osdev.org/Entering_Long_Mode_Directly
;http://www.codeproject.com/KB/system/asm.aspx
;http://www.x86-64.org/documentation/assembly.html
;http://stanislavs.org/helppc/8259.html
;http://wiki.osdev.org/User:Stephanvanschaik/Setting_Up_Long_Mode
;http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html


;http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html
;3-22 Vol. 2A
;http://alexfru.narod.ru/elinks.html#advanced
;http://geezer.osdevbrasil.net/osd/index.htm
;http://wiki.osdev.org/Boot_sequence
;http://www.brokenthorn.com/Resources/OSDev9.html
;http://wiki.osdev.org/CMOS
;http://wiki.osdev.org/Getting_VBE_Mode_Info
;http://wiki.osdev.org/Memory_Map_%28x86%29#BIOS_Data_Area_.28BDA.29
;http://www.supernovah.com/Tutorials/index.php
;http://www.osdever.net/tutorials/index
;http://wiki.osdev.org/Floppy_Disk_Controller
;http://www.vijaymukhi.com/vmis/roll.htm
;http://www.acpi.info/
;http://www.petesqbsite.com/sections/tutorials/graphics.shtml
;http://stackoverflow.com/questions/4590078/how-can-i-write-directly-to-the-screen
;http://wiki.osdev.org/RTC
;http://wiki.osdev.org/CMOS
;http://wiki.osdev.org/Exceptions
;http://x86asm.net/articles/x86-64-tour-of-intel-manuals/
;http://www.nynaeve.net/?p=64
;http://wiki.osdev.org/ACPI
;http://wiki.osdev.org/Serial_Ports
;http://www.osdever.net/FreeVGA/vga/graphreg.htm

;128 bytes de stack para CPU

; x00000000 - 0x000003FF - Real Mode Interrupt Vector Table
; 0x00000400 - 0x000004FF - BIOS Data Area
; 0x00000500 - 0x00007BFF - Unused
; 0x00007C00 - 0x00007DFF - Our Bootloader
; 0x00007E00 - 0x0009FFFF - Unused
; 0x000A0000 - 0x000BFFFF - Video RAM (VRAM) Memory
; 0x000B0000 - 0x000B7777 - Monochrome Video Memory
; 0x000B8000 - 0x000BFFFF - Color Video Memory
; 0x000C0000 - 0x000C7FFF - Video ROM BIOS
; 0x000C8000 - 0x000EFFFF - BIOS Shadow Area
; 0x000F0000 - 0x000FFFFF - System BIOS

;interrupção: limpa IF na interrupção e seta IF no retorno (interrupt flag)
;task gate: salva estado do processador (registradores,flags...)
;trap gate: chama o procedimento sem salvar nada.

%define MEM_BASE 7c00h
msr:;model specific registers
	.IA32_EFER equ 0xC0000080

[bits 16]     ;real-mode
[org MEM_BASE]   ;offset de boot

cli;sem int's de hardware

; call KBC.wait_input
; mov al,0ADh;desativa teclado
; out 64h,al

jmp 0:SOF

errors:

.no_long_mode:
push no_long_mode_msg
push 0;CS
push .lock;IP

.show:
pop si

;seta 80x25:
mov ax,03h
int 10h

;mov ax,0B8000h
;mov es,ax;início da memória de vídeo de texto
push dword 0B8000h
pop es

xor di,di;início do segmento
mov ah,0000_1111b;preto e branco
;cld;DF=0
.loop:
	lodsb;al=[ds:si], DF ? si-- : si++
	stosw;[es:di]=ax, di = DF ? DI - 2 : DI + 2
	test al,al
	jnz .loop
ret
	
	
.no_E820:
push no_E820_msg
call .show


.lock:
	hlt
	jmp .lock

;mostra com int's da BIOS
	;mov ah,0Eh
	;mov cx,25
    ;loop_print:
        ;mov al,[bp]
		;int 10h
		;inc bp
        ;loop loop_print
	;recebe tecla:
	;xor ah,ah
	;int 16h
	;reinicia:
	;int 19h

A20_setup:
   .init:
   ;System FAST A20:
   in al,92h
   or al,2
   out 92h,al
   call .test_A20
   
   ;Fast KBC A20 Enable Command:
   mov al,0DDh
   out 64h,al
   call .test_A20
   
   ;BIOS:
   mov ax,2401h
   int 15h
   call .test_A20
   
   push A20_fail
   call errors.show
   
   jmp .init

  .test_A20:
    ;ah=al=[0:0]
	mov     al, [0]
	mov     ah, al
	;al=!al
	not     al
	mov cx,15;testar 15 vezes a porta
	.loop:
	;al=0FFFFh:10h,0FFFFh:10h=![0:0]
	xchg    al, [100000h]
	;ah(antigo [0:0]) == [0:0] ?
	cmp     ah, [0]
	xchg 	al,[100000h]
	;PUSH'S DE STACK PELO CALL SÃO ABANDONADOS AQUI!!!
	;Corrigir se stack não for modificada em 64 bits.
	je map_mem;porta ativada? mapeia memória
	loop .loop;tenta novamente
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

push dword 0
pop ss

mov sp,7c00h

push cs
pop ds

;Se CPUID não é suportado, não é 64 bits
  pushfd;push de todas as flags
  pop eax
  mov ecx, eax;salva valores
  xor eax, 0x200000;inverte bit
  push eax
  popfd
  pushfd;retira e guarda flags
  pop eax
  push ecx
  popfd;retorna flags originais
  cmp eax,ecx;mudou flag?
  je errors.no_long_mode;não, não tem CPUID

;Checa Long Mode:
mov eax,80000000h
cpuid
cmp eax,80000001h;possui funções acima de 80000001h?
jnae errors.no_long_mode;jmp not above or equal

;suporta >0x80000001
mov eax,80000001h
cpuid
test edx,1 << 29 ;bit 29 setado?
jz errors.no_long_mode ;não, não é 64 bits.

;testa PAE
;mov eax,01h
;cpuid
;test edx,1 << 6
;jz errors.no_paging

lgdt [GDT.pointer]

;Checa A20:
    call A20_setup.test_A20
	jne A20_setup.init;pula para ativação da porta A20
   
;Detecta memória com int's da BIOS:
map_mem:
memory_map equ 0;início da estrutura onde estará o mapeamento
xor ebx,ebx
mov edx,534D4150h
mov eax,0E820h;número da int
mov es,ebx;es:di=ponteiro para struct
mov di,memory_map
mov [memory_map + 20],dword 1
mov ecx,24;pedir 24 bytes
int 15h

;se primeira chamada funcionou, CF=0 e eax=534D4150h
jc errors.no_E820

E820_ok:
cmp eax,534D4150h
jne errors.no_E820
test ebx,ebx
jz errors.no_E820;ebx=0? Apenas uma entrada (não suportado)

; call KBC.wait_input
; mov al,0AEh;ativa teclado
; out 64h,al

;loop para receber memória
receive_mem:
.loop:
jcxz .receive_next;nenhuma entrada? pula para próxima. (jump cx zero)
cmp cl,20
jbe .valid;cl <= 20,não há entrada especial de mem inválida

test byte [es:di + 20],1;bit pata ignorar entrada setado?
jz .receive_next;pula para próxima

.valid:;entrada válida!
mov eax, dword [es:di + 16];tipo de entrada
;eax == 1 || eax == 3 ? continua : lê próxima entrada
cmp eax,1
je .valid_RAM
cmp eax,3
jne .receive_next

.valid_RAM:;memória válida,livre e RAM!
add di,16;seta ponteiro para próxima entrada e recebe-a
;.....


.receive_next:
test ebx,ebx
jz .end;se ebx == 0,fim do mapeamento.
mov edx,534D4150h;resetado por algumas BIOS's
mov eax,0E820h
mov cx,24
mov [es:di + 20],dword 1;otimizar!
int 15h
jnc .loop;CF ? fim da lista : continuar.

.end:


  
   
long_mode_setup:;apenas com paging desativado. SEM INT's!!!
   
   ;paging em long-mode:
   ;cro.PG=1,cr4.pae=1 e IA32_EFER.LME = 1
   ;se cr0.WP=0, segmentos supervisores (permissão < 3) podem escrever em segmentos apenas leitura.
   ;cr4.PGE=páginas globais
   ;cr4.PCIDE ativa Process Context IDentifiers
   ;cr4.SMEP setado impede que supervisores modifiquem páginas de usuários
   ;se IA32_EFER.NXE = 1, não se pode carregar instruções de páginas
   
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
	
	
	; repeat 256:
		; [es:edi] = eax
		; edi += 8
	; end_repeat

	; eax -> dword (4 bytes)  \
							; > * 256 
	; 0   -> dword (4 bytes)  /
	; ...

	; 8 * 256 bytes = 2048 bytes = 800h bytes = 2 KB
	
	;fim de PAE = 4000h + 800h = 4800h = 18432 bytes = 18 KB
	
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
	

   ;seta MSR
   mov ecx,msr.IA32_EFER;long mode, model-especific
   rdmsr;lê do registrador model-espcific
   or eax,1<<8 | 1 << 13;seta bit 8 (IA32_EFER.LME) para paging em 64 bits e 13 (LMSLE - Long Mode Segment Limit Enable)
   wrmsr;escreve no registrador mode-especific
  
   ;ativa PMode e LMode:
   mov eax,cr0
   or eax,1<<31 | 1<<0;seta bit PG (31, paging e LMode) e PM (0, modo protegido)
   mov cr0,eax
   
   ;mov ax,16
   ;mov ds,ax
   
   ;far jump para setar cs e ip:
   jmp 8h:long_mode;8 é a posição do code descriptor de código no GDT. Ainda sem IRQ's



[bits 64];Long Mode!
long_mode:
hlt
jmp $-1
;atualizar stack!


;Interrupt Descriptor Table:
; IDT:
	; ; ;Bits 39...41:
	; ; ; Interrupt Gate: formato 0D110, onde D é o nº de bits
	; ; ; 01110 - 32 bit descriptor
	; ; ; 00110 - 16 bit descriptor
	; ; ; Task Gate: 00101
	; ; ; Trap Gate: formato 0D111, onde D é o nº de bits
	; ; ; 01111 - 32 bit descriptor
	; ; ; 00111 - 16 bit descriptor
	
	; ._0:
	; dw 0;offset bits 0-15
	; dw 8;seletor de código
	; dw 1_11_01110_00000000b;presente,privilégio para acessar,01110,reservados
	; dw 0;offset bits 31-16
	
	; ;%rep 48
		; dw 0
		; dw 8
		; dw 1_11_01110_00000000b
		; dw 0
	; ;%endrep
	
	; ._49:
	; dw (MEM_BASE + ISR._49 - $$) & 0FFFFh
	; dw 8
	; dw 1_11_01110_00000000b
	; dw (MEM_BASE + ISR._49 - $$) >> 16
	
	
	; .pointer:
	; dw IDT.pointer - IDT._0 - 1;tamanho do IDT
	; dd IDT._0;ponteiro

	
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
db 1001_1011b;setado em ORDEM CONTRÁRIA!

;bits 48-51 -> bits 16-19 do limite do segmento
;bit 52 -> System Bit: se 0, o descriptor é de 16 bytes ao invés de 8
;bit 53 -> Long Mode
;bit 54 -> tipo de segmento (0=16 bits,1=32 bits)
;bit 55 -> G (granularity) se setado, segmento *= 4K
db 1101_1111b;setado em ORDEM CONTRÁRIA!
;bits 24-31 -> bits 24-31 do endereço base
db 0

.end:
.pointer:
	dw GDT.pointer - GDT.start - 1;tamanho do GDT
	dq GDT.start;ponteiro


no_long_mode_msg 	db 'Sem processador 64 bits',0
no_E820_msg 		db 'Sem BIOS 0E820h',0
A20_fail			db 'Erro na linha A20',0
;no_paging_msg		db 'PAE não suportado',0

;memory_map:
	;.base_adress dq 0
	;.size dq 0
	;._type dd 0;1=RAM,2=reservado,3=ACPI utilizável,4=ACPI não volátil (inutilizável),5=região da memória que não funciona
	;.flags dd 1;bit 0=ignorar esta entrada (se limpo),bit 1=memória não volátil se setado


times 510-($-$$) db 0

dw 0AA55h
