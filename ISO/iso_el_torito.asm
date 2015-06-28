;http://bcos.hopto.org/www2/80x86/bootcd/0index_asm.html#30



; ISO e El-Torito:
; ISO:


; Volume Descriptor: (2Kb)
; Offset	Length (bytes)		 Field Name		Description
; 0		1	 				Type	 		Volume Descriptor type code (see below).
; 1		5	 				Identifier		Always 'CD001'.
; 6		1	 				Version	 		Volume Descriptor Version (0x01).
; 7		2041	 			Data	 		Depends on the volume descriptor type.


; Volume Descriptor Type Codes:
; Value	Description
; 0		Volume descriptor is a Boot Record
; 1	 	Primary Volume Descriptor
; 2	 	Supplementary Volume Descriptor
; 3	 	Volume Partition Descriptor
; 4-254	Reserved
; 255	 	Volume Descriptor Set Terminator

; Setor 10h = Primary Volume Descriptor

; Offset	Length (bytes)	Field Name	 			Description
; 0	 	1	 			Type Code	 			Always 0x01 for a Primary Volume Descriptor.
; 1	 	5	 			Standard 				Identifier	 Always 'CD001'.
; 6	 	1	 			Version	 				Always 0x01.
; 7	 	1	 			Unused	 				Always 0x00.
; 8	 	32	 			System Identifier	 	The name of the system that can act upon sectors 0x00-0x0F for the volume in a-characters.
; 40	 	32			 	Volume Identifier	 	Identification of this volume in d-characters.
; 72	 	8	 			Unused Field	
; 80	 	8	 			Volume Space Size	 	Number of Logical Blocks in which the volume is recorded. This is a 32 bit value in both-endian format.
; 88	 	32	 			Unused Field	
; 120	 	4	 			Volume Set Size	 		The size of the set in this logical volume (number of disks). This is a 16 bit value in both-endian format.
; 124	 	4	 			Volume Sequence Number	The number of this disk in the Volume Set. This is a 16 bit value in both-endian format.
; 128	 	4	 			Logical Block Size	 	The size in bytes of a logical block in both-endian format. NB: This means that a logical block on a CD could be something other than 2KiB!
; 132	 	8	 			Path Table Size	 				The size in bytes of the path table in 32 bit both-endian format.
; 140	 	4	 			Location of Type-L Path Table	LBA location of the path table, recorded in LSB-first (little endian) format. The path table pointed to also contains LSB-first values.
; 144	 	4	 			Location of the Optional Type-L Path Table	 	LBA location of the optional path table, recorded in LSB-first (little endian) format. The path table pointed to also contains LSB-first values. Zero means that no optional path table exists.
; 148	 	4	 			Location of Type-M Path Table	 		LBA location of the path table, recorded in MSB-first (big-endian) format. The path table pointed to also contains MSB-first values.
; 152	 	4	 			Location of Optional Type-M Path Table	LBA location of the optional path table, recorded in MSB-first (big-endian) format. The path table pointed to also contains MSB-first values.
; 156	 	34	 			Directory entry for the root directory.	 	Note that this is not an LBA address, it is the actual Directory Record, which contains a zero-length Directory Identifier, hence the fixed 34 byte size.
; 190	 	128	 			Volume Set Identifier	 Identifier of the volume set of which this volume is a member in d-characters.
; 318	 	128	 			Publisher Identifier	 The volume publisher in a-characters. If unspecified, all bytes should be 0x20. For extended publisher information, the first byte should be 0x5F, followed by an 8.3 format file name. This file must be in the root directory and the filename is made from d-characters.
; 446	 	128	 			Data Preparer Identifier	 The identifier of the person(s) who prepared the data for this volume. Format as per Publisher Identifier.
; 574	 	128	 			Application Identifier	 		Identifies how the data are recorded on this volume. Format as per Publisher Identifier.
; 702	 	38	 			Copyright File Identifier	 Identifies a file containing copyright information for this volume set. The file must be contained in the root directory and is in 8.3 format. If no such file is identified, the characters in this field are all set to 0x20.
; 740	 	36	 			Abstract File Identifier	 Identifies a file containing abstract information for this volume set in the same format as the Copyright File Identifier field.
; 776	 	37	 			Bibliographic File Identifier	 Identifies a file containing bibliographic information for this volume set. Format as per the other File Identifier fields.
; 813	 	17	 			Volume Creation Date and Time	 Date and Time format as specified below.
; 830	 	17	 			Volume Modification Date and Time	 Date and Time format as specified below.
; 847	 	17	 			Volume Expiration Date and Time	 	Date and Time format as specified below. After this date and time, the volume should be considered obsolete. If unspecified, then the information is never considered obsolete.
; 864	 	17	 			Volume Effective Date and Time	 	Date and Time format as specified below. Date and time from which the volume should be used. If unspecified, the volume may be used immediately.
; 881	 	1	 			File Structure Version	 	An 8 bit number specifying the directory records and path table version (always 0x01).
; 882	 	1	 			Unused	 Always 0x00.
; 883	 	512	 			Application Used	 Contents not defined by ISO 9660.
; 1395	653	 			Reserved	 Reserved by ISO.


; a-characters: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 _ 
              ; ! " % & ' ( ) * + , - . / : ; < = > ?

; d-characters: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 _


; A 16-bit numeric value (usually called a word) may be represented on a CD-ROM in any of three ways:

; Little Endian Word:
; The value occupies two consecutive bytes, with the less significant byte first.
; Big Endian Word:
; The value occupies two consecutive bytes, with the more significant byte first.
; Both Endian Word:
; The value occupies FOUR consecutive bytes; the first and second bytes contain the value expressed as a little endian word, and the third and fourth bytes contain the same value expressed as a big endian word.
; A 32-bit numeric value (usually called a double word) may be represented on a CD-ROM in any of three ways:

; Little Endian Double Word:
; The value occupies four consecutive bytes, with the least significant byte first and the other bytes in order of increasing significance.
; Big Endian Double Word:
; The value occupies four consecutive bytes, with the most significant first and the other bytes in order of decreasing significance.
; Both Endian Double Word:
; The value occupies EIGHT consecutive bytes; the first four bytes contain the value expressed as a little endian double word, and the last four bytes contain the same value expressed as a big endian double word.

; Limite de 8 camadas em diretórios
		; {Root}
		; /	\
	; Dir1	Dir2
	; /
	; Dir
	; |
	; blablabla
	; |
	; arquivo.exe;2
	
; Tamanho do caminho (nome do arquivo + nº de diretórios sobre ele + tamanho dos nomes dos diretórios) até um arquivo não pode passar de 255 bytes:
; Dir1 + Dir + blablabla + arquivo.exe;2 + 3 = 4 + 3 + 9 + 13 + 3 = 32

; Arquivos:

; Um arquivo pode ter nome, extensão e versão: arquivo.exe;2
; É obrigatório que um arquivo tenha nome ou extensão. O tamanho do nome + tamanho da extensão não deve ultrapassar 30.
; Diretórios não possuem "." nem ";".

;http://bcos.hopto.org/
;http://bcos.hopto.org/www2/80x86/bootcd/0index_asm.html

%include "notation.inc"
%macro PATH_TABLE_L 0
	path_table_l:
	PATH_TABLE L
	PATH_ENTRY ROOT_DIR, 1, 0
	PATH_ENTRY ROOT_DIR, 1, 'AUTORUN.INF'
	PATH_TABLE_END
%endmacro

%macro PATH_TABLE_M 0
	path_table_m:
	PATH_TABLE M
	PATH_ENTRY ROOT_DIR, 1, 0
	PATH_ENTRY ROOT_DIR, 1, 'AUTORUN.INF'
	PATH_TABLE_END
%endmacro

%define BOOT_SECTORS_TO_LOAD		0 ;setores de 512 bytes para carregar (0 para calcular no momento de compilar)
%define CD_ROM_LOGICAL_SECTOR_SIZE	2048 ; 2 Kb
%define UNUSED						0
%define RESERVED					0
%define ISO_ID						'CD001'
%define GREENWICH_OFFSET			-3 * 4 ; com precisão de 15 minutos

%ifdef __UTC_DATE_NUM__
	%ifdef __UTC_TIME_NUM__
		%define USE_UTC
	%endif
%endif
 
%ifdef USE_UTC
	%defstr CURRENT_DATE_STRING __UTC_DATE_NUM__
	%defstr CURRENT_TIME_STRING __UTC_TIME_NUM__
%else
	%warn SEM UTC!!!
	%defstr CURRENT_DATE_STRING __DATE_NUM__
	%defstr CURRENT_TIME_STRING __TIME_NUM__
%endif

%macro DEFINE_NO_TIME 0
	times 16 db '0'
	db 0
%endmacro

%macro DEFINE_TIME 0
	db CURRENT_DATE_STRING
	db CURRENT_TIME_STRING
	db '00' ; centenas de segundos
	db GREENWICH_OFFSET
%endmacro

%macro DIR_ENTRY 3+
 %%l1:
       db %%l4 - %%l1                                              ;Length of directory entry
       db 0                                                        ;Length of extended data
       MIXED_ENDIAN_DWORD (%1 - IMAGE_OFFSET) / 2048                ;Starting sector
       MIXED_ENDIAN_DWORD %{1}.end - %1                            ;Number of bytes of data
    db (__UTC_DATE_NUM__ / 10000) - 1900 ;anos desde 1900
	db (__UTC_DATE_NUM__ / 100) % 100 ;mês
	db __UTC_DATE_NUM__  % 100 ;dia
	db (__UTC_TIME_NUM__ / 10000) - 1900 ;hora
	db (__UTC_TIME_NUM__ / 100) % 100 ;minuto
	db __UTC_TIME_NUM__  % 100 ;segundo
	db GREENWICH_OFFSET                                                       ;Offset from "Greenwich Mean Time"
       db %2                                                       ;File flags
       db 0                                                        ;File unit size (zero if file doesn't used interleaved mode)
       db 0                                                        ;Interleave gap size (zero if file doesn't used interleaved mode)
       MIXED_ENDIAN_WORD 1                                         ;Volume sequence number
       db %%l3 - %%l2                                              ;File identifier length
 %%l2:
       db %3                                                       ;File identifier
 %%l3:
       times ~(%%l3 - %%l2) & 1 db 0                               ;Padding byte (only if file identifer length is even)
 %%l4:
 %endmacro


%macro DIR_START 2
	DIR_ENTRY %1, F_DIRECTORY, SELF
	DIR_ENTRY %2, F_DIRECTORY, PARENT
%endmacro

%macro F_END 0
	.end:
	align 2048, db 0
%endmacro

%macro DIR_END 0
	align 2048, db 0
	.end:
%endmacro

VOLUME_DESCRIPTOR:
	.BOOT_RECORD	equ 0
	.PRIMARY		equ 1
	.TERMINATOR		equ 255

%define F_HIDDEN		0x01
%define F_DIRECTORY		0x02
%define SELF			0x00
%define PARENT			0x01

%macro PATH_TABLE 1
	%ifidni %1, L
		%push PATH_L
	%else
		%push PATH_M
	%endif
%endmacro

%macro PATH_ENTRY 3+
	db %%l2 - %%l1                                              ;Length of directory identifier
	db 0                                                        ;Length of extended data
	%ifctx PATH_L
		dd (%1 - IMAGE_OFFSET) / 2048                                ;Starting sector
		dw %2                                                       ;Parent directory number
	%else
		BIG_ENDIAN_DWORD (%1 - IMAGE_OFFSET) / 2048                  ;Starting sector
		BIG_ENDIAN_WORD %2                                          ;Parent directory number
	%endif
	%%l1:
	db %3                                                       ;Directory identifier
	%%l2:
	times (%%l2 - %%l1) & 1 db 0                                ;Padding byte (only if directory identifer length is odd)
%endmacro



%macro PATH_TABLE_END 0
	%ifctx PATH_L
		%pop
	%endif
	%ifctx PATH_M
		%pop
	%endif
	.end:
	align 2048, db 0
%endmacro





[org 0] ;início do CD

IMAGE_OFFSET:
;16 setores para uso do sistema:
BOOTLOADER:
incbin "bootloader.bin"
F_END ;fim do arquivo


times 2048 * 16 - ($ - $$) db 0
;16º setor = Primary Volume Descriptor


VOLUME_TYPE					db VOLUME_DESCRIPTOR.PRIMARY
IDENTIFIER					db ISO_ID
ISO_VERSION					db 1
							db UNUSED
SYS_ID						db 'EXAMPLE OPERATING SYSTEM SECTORS' ; 32 caracteres a. Identifica o sistema que deve utilizar os setores 0 - 15.
VOLUME_ID					db 'EXAMPLE_SYSTEM___________CD_ROM_' ; 32 caracteres d
times 8						db UNUSED
BOTH_ENDIAN_DWORD (IMAGE_END - IMAGE_OFFSET + 2047) / 2048 ; Número de setores usados por esta unidade
times 32					db UNUSED

VOLUME_SET_SIZE:
				BOTH_ENDIAN_WORD 1 ; Número de volumes no disco em both-endian
VOLUME_SEQUENCE_NUMBER		BOTH_ENDIAN_WORD 1 ; Número deste volume no disco. Começa em 1 e aumenta conforme a posição física do setor.
LOGICAL_BLOCK_SIZE			BOTH_ENDIAN_WORD CD_ROM_LOGICAL_SECTOR_SIZE ; tamanho de um bloco lógico em bytes em both-endian (geralmente 2 Kb)
PATH_TABLE_SIZE				BOTH_ENDIAN_DWORD path_table_l.end - path_table_l ;tamanho em both-endian da path table, tabela que mostra a árvore
																				;de diretórios.
TYPE_L_PATH_TABLE_LOCATION	dd (path_table_l - IMAGE_OFFSET) / CD_ROM_LOGICAL_SECTOR_SIZE ; posição LBA em little endian (LSB-first)
OPT_TYPE_L_PATH_TABLE_LOC	dd 0 ; posição LBA em litte endian da L path table secundária, 0's significam que não existe
TYPE_M_PATH_TABLE_LOCATION	BIG_ENDIAN_DWORD (path_table_m - IMAGE_OFFSET) / CD_ROM_LOGICAL_SECTOR_SIZE ; posição LBA em big endian (MSB-first)
dd 0 ; posição LBA em big endian da TYPE_M_PATH_TABLE opcional, 0's significam que não existe
; directory record da raíz do disco:
DIR_ENTRY ROOT_DIR, F_DIRECTORY, SELF
; 128 caracteres d. Nome do conjunto de volumes em que este volume está:
VOLUME_SET_ID	db 'EXAMPLE_OPERATING_SYSTEM____SIMPLE_EXAMPLE_OF_ISO_BOOTABLE_IMAGE_________CC_BY_NC_SA_3_0________________________________________'
						
PUBLISHER_ID	db 'TIAGO_SHIBATA___________________________________________________________________________________________________________________'
							; identificação em 128 caracteres-a. Para não identificado, todos os caracteres devem ser 20h. Para id maior que 128
							; bytes, deve-se iniciar com 5Fh, seguido de um arquivo em 8.3 em caracteres d, que deve estar na raíz do disco.
DATAPREPARER_ID db 'TIAGO_KOJI_CASTRO_SHIBATA_______________________________________________________________________________________________________' ;identifica quem preparou os dados para este volume. Formatado como PUBLISHER_ID

APP_ID					db 'EXAMPLE_SYSTEM__________CD_ROM' ;identifica os dados guardados no volume. Formato igual a PUBLISHER_ID
						db '______________________________'
						db '______________________________'
						db '______________________________'
						db '________'

COPYRIGHT_FILE_ID		db '                                     ' ; 37 bytes com o arquivo 8.3 com licença
ABSTRACT_FILE_ID		db '                                     ' ; arquivo contendo informações abstratas sobre este volume. Formatado como a licença
BIBLIOGRAPHIC_FILE_ID	db '                                     ' ; arquivo com informações bibliográficas sobre o volume. Formatado como licença
DEFINE_TIME ; data e hora de criação (ano, mês, dia, hora, minuto, segundo, centenas de segundo, distância de GMT com precisão de 15 minutos
DEFINE_TIME ; data de modificação. Formatado como criação
DEFINE_NO_TIME ; data de expiração. Formatado como criação. Após esta data, o volume é considerado obsoleto.
DEFINE_NO_TIME ; data de efetivação. A partir desta data, o arquivo/dir pode ser usado.
FILE_STRUCTURE_VERSION	db 1h ; sempre 1h
						db UNUSED
times 512 db 0 ; Uso da aplicação, como desejar
times 653 db RESERVED


;El Torito:
;17º setor = Boot Record Volume Descriptor
db VOLUME_DESCRIPTOR.BOOT_RECORD
db 'CD001'
DESCRIPTOR_VERSION		db 1 ; para ISO 9660
BOOT_SYSTEM_ID			db 'EL TORITO SPECIFICATION', 0, 0, 0, 0, 0, 0, 0, 0, 0 ; 32 chars. Identifica o sistema que pode bootar este disco. a-chars
times 32 db UNUSED;não utilizados
dd (BOOT_CATALOGUE - IMAGE_OFFSET) / 2048;setor do catálogo de boot
times 1973 db UNUSED;não utilizados

;fim de Volume Descriptor's:
db VOLUME_DESCRIPTOR.TERMINATOR
db 'CD001'
db 1h
times 2041 db UNUSED

BOOT_CATALOGUE:
;entrada de validação:
db 1 ;cabeçalho, deve ser 1
db 0 ;plataforma, 0=80x86, 1=Power PC, 2=Mac
dw RESERVED
db 'TIAGO SHIBATA', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;criador (pessoa ou empresa) do CD (24 chars)
dw -(1 + 0AA55h + 'TI' + 'AG' + 'O ' + 'SH' + 'IB' + 'AT' + 'A');Checksum. somada com todas as words do catálogo, deve dar 0.
dw 0AA55h

;entrada inicial/padrão:
db 88h ;bootável. 0 = não bootável
db 0 ;sem emulação. 1=disquete 1.2 Mb, 2="" 1.44"", 3="" 2.88"", 4=HD
dw 7C0h ;segmento para carregar. Se 0, usa segmento padrão.
db 0 ;tipo de sistema. 0 para sem emulação
db UNUSED
%if (BOOT_SECTORS_TO_LOAD == 0)
	dw (BOOTLOADER.end - BOOTLOADER + 511) / 512 ;número de setores de 512 bytes para carregar em 7C00h
%else
	dw BOOT_SECTORS_TO_LOAD
%endif
dd 0 ;endereço LBA onde o disco começa (enquanto usar funções da BIOS)
times 20 db UNUSED
times (62 * 32) db 0 ;Section Headers / Section Entries /  Section Entry Extensions


PATH_TABLE_L
PATH_TABLE_M

ROOT_DIR:
DIR_START ROOT_DIR,ROOT_DIR ; o diretório raíz é pai dele mesmo

DIR_ENTRY AUTORUN,0,"AUTORUN.INF"
DIR_ENTRY INIT,0,"INIT.COM"
DIR_ENTRY ICO,0,".ICO"

DIR_END

AUTORUN:
db 'Example AUTORUN.INF'
F_END

INIT:
db 'Example INIT.COM'
F_END

ICO:
db "Example .ICO"
F_END




align 32*1024, db 0
IMAGE_END:
