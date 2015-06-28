[bits 16]
%define ncluster	((EOF - SOF) + 511) / 512
%macro clusters 0-*
	%rep %0 >> 1
		dw %1 | ((%2 & 0Fh) << 12)
		db %2 >> 4
		%rotate 2
	%endrep
	%if %0 & 1
		dw %1
	%endif
%endmacro

;TODO: http://en.wikipedia.org/wiki/File_Allocation_Table#VFAT_long_file_names
;http://wiki.osdev.org/MBR
;http://wiki.osdev.org/System_Initialization_(x86)
;http://wiki.osdev.org/Partition_Table
;http://wiki.osdev.org/Boot_Sequence
;http://wiki.osdev.org/FAT
;http://wiki.osdev.org/Volume_Boot_Record
; Carrega código de boot em 7C00h, seta dl com # do drive, aponta DS:SI para a partição selecionada no MBR.
SOF:
jmp short start
nop
; OEM ID
db 'MSWIN4.1'
dw 512				; bytes por setor
db 1				; setores por cluster
dw 1				; setores reservados (bootloader...) até FAT 1
db 1				; número de FAT's (1, sem backup)
dw 16				; 16 diretórios na raíz (16 * 32 bytes = 512 bytes)
dw ncluster			; # de setores lógicos (clusters)
db 0F8h				; tipo de mídia (Fixed Disk)
dw 1				; setores lógicos por FAT
dw 32				; setores por trilha
dw 16				; cabeças por disco
dd 0				; setores ocultos antes desde volume FAT
dd 0				; total de setores lógicos (usar se a word de setores lógicos acima for insuficiente)
db 80h				; # do drive na BIOS (setar conforme dl)
db 0				; reservado
db 29h				; assinatura de boot extendida
dd 0D3DAB580h			; # serial
db '           '		; label
db 'FAT12   '			; FS
start:
incbin "bootloader.bin"
times (510-($-$$)) db 0
dw 0AA55h


; FAT:
; Cluster: 0 = Free, se encontrado em corrente, End-Of-chain
; 1 = Reservado, se em corrente, EOC. Usado em DOS para marcar clusters usados temporariamente enquanto se constrói a corrente.
; 2 - 0FFF5h = Cluster com dados, valor aponta para próximo cluster
; 0FFF6h = Reservado. Se ocorrer em corrente, tratar como dados.
; 0FFF7h = Bad sector/cluster reservado. Se em corrente, tratar como dados.
; 0FFF8 - 0FFFFh = EOC
; Primeiro cluster:
; dw 0FFF8h	; Tipo de mídia | 0FF00h
; dw 0FFFFh	; End Of Chain + bit 7 setado = desligamento normal, bit 6 setado = último uso sem erros de disco
; dw 4
; dw 0FFFFh
; dw 5
; dw 0FFFFh


clusters 0FF8h, 0FFFh, 0, 0,  0FFFh, 0Fh;0FFFh, 0FFFh

times (1024-($-$$)) db 0

; Diretório Raíz
F:
	.RO		equ 1
	.HIDDEN		equ 2
	.SYS		equ 4
	.VLABEL		equ 8
	.SUBDIR		equ 16
	.ARCHIV		equ 32	; Dirty
	.LONGNAME	equ 0Fh
; EFI/BOOT/BOOTX64.EFI
db 'EFI     '	; nome. Se char 0 = 0, entrada livre, 5 = arquivo espera para ser apagado, 2Eh = "." ou "..", 0E5h = apagado
db '   '	; extensão
db F.SUBDIR;| F.RO | F.SYS | F.ARCHIV	; atributos.
db 0		; reservado
db 0		; se existente, criação em centésimos de segundos; senão, primeiro char do arquivo deletado, se 0E5h, bloqueia UNDELETE, se 0, UNDELETE pede ao
		; usuário o primeiro caractere.
dw 0		; criação: bits 0-4 = segundos/2, 5-10 = minutos, 11-15 = horas. Testar se é válido, não usar se 14h tem um bitmap de acesso.
dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de criação. 0-4 dia, 5-8 mês, 9-15 ano começando em 1980
dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de acesso
dw 0		; bits altos do primeiro cluster, 0 em FAT12/16
dw 0		; hora da última modificação
dw 3 | (7 << 5) | ((2012 - 1980) << 9)		; data da última modificação
dw 3		; 12 bits baixos do primeiro cluster
dd 0		; tamanho do arquivo, se 0 em arquivo, pendente para deletar. Volume Label e SUBDIR sempre = 0


align 512, db 0


; db 'BOOT       '
; db F.RO | F.SYS | F.ARCHIV | F.SUBDIR	; atributos.
; db 0		; reservado
; db 0		; se existente, criação em centésimos de segundos; senão, primeiro char do arquivo deletado, se 0E5h, bloqueia UNDELETE, se 0, UNDELETE pede ao
; 		; usuário o primeiro caractere.
; dw 0		; criação: bits 0-4 = segundos/2, 5-10 = minutos, 11-15 = horas. Testar se é válido, não usar se 14h tem um bitmap de acesso.
; dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de criação. 0-4 dia, 5-8 mês, 9-15 ano começando em 1980
; dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de acesso
; dw 0		; bits altos do primeiro cluster, 0 em FAT12/16
; dw 0		; hora da última modificação
; dw 0		; data da última modificação
; dw 4		; 12 bits baixos do primeiro cluster
; dd 0		; tamanho do arquivo, se 0 em arquivo, pendente para deletar. Volume Label e SUBDIR sempre = 0
; 
; align 512, db 0
; 
; db 'BOOTX64'
; db 'EFI'
; db F.RO | F.SYS | F.ARCHIV	; atributos.
; db 0		; reservado
; db 0		; se existente, criação em centésimos de segundos; senão, primeiro char do arquivo deletado, se 0E5h, bloqueia UNDELETE, se 0, UNDELETE pede ao
; 		; usuário o primeiro caractere.
; dw 0		; criação: bits 0-4 = segundos/2, 5-10 = minutos, 11-15 = horas. Testar se é válido, não usar se 14h tem um bitmap de acesso.
; dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de criação. 0-4 dia, 5-8 mês, 9-15 ano começando em 1980
; dw 3 | (7 << 5) | ((2012 - 1980) << 9)	; data de acesso
; dw 0		; bits altos do primeiro cluster, 0 em FAT12/16
; dw 0		; hora da última modificação
; dw 0		; data da última modificação
; dw 6		; 12 bits baixos do primeiro cluster
; dd 2		; tamanho do arquivo, se 0 em arquivo, pendente para deletar. Volume Label e SUBDIR sempre = 0
; 
; [bits 64]
; incbin "bootloader.bin"
; 
; align 512, db 0
EOF:
; Enche disco com 0's:
times (262144 - (EOF - SOF)) db 0
