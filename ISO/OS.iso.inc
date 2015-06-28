%define __ISO_TIME	db DATE_STR, TIME_STR, HUND_SEC, GREENWICH_OFST
%define __ISO_NO_TIME	db '0000000000000000', 0
%define __ISO_UNUSED	0
%define __ISO_RESERVED	0

SYS_PERM:
	.NO_READ	equ 1
	.NO_EXEC	equ 1 << 2

OWNER_PERM:
	.NO_READ	equ 1 << 4
	.NO_EXEC	equ 1 << 6

GROUP_PERM:
	.NO_READ	equ 1 << 8
	.NO_EXEC	equ 1 << 10

OTHER_GROUP_PERM:
	.NO_READ	equ 1 << 12
	.NO_EXEC	equ 1 << 14

FFLAGS:
	.HIDDEN		equ 1
	.DIR		equ 1 << 1
	.ASSOC		equ 1 << 2	; Associated file: has relationship with another file with same ID in the same directory
	.RECORD		equ 1 << 3	; Record Format Field != 0 in extended attributes
	.PROTECT	equ 1 << 4	; There is a user and group ID and not all users may read or execute the file
	.MULT_EXT	equ 1 << 7	; if set, this is not the finalDirectory Record of the file
	.THIS_D		equ 0
	.ROOT		equ 0
	.PARENT		equ 1
	
%macro EXT_FILE 6
	; File with extended attributes:
	ENTRY %1, %2, %3, %%end - %%ext_attr
	align 2048, db 0
	%%ext_attr:
	BOTH_ENDIAN_WORD %4			; owner, 0 = undefined
	BOTH_ENDIAN_WORD %5			; owner group, 0 = undefined
	dw %6 | 10101010_10101010b		; permissions
	__ISO_TIME				; creation
	__ISO_TIME				; change
	__ISO_NO_TIME				; expiration
	__ISO_NO_TIME				; efetivation
	db 0					; record format: 0 = structure of the information recorded in the file is not specified by this field
						; 1 = fixed length, 2/3 = variable length in LSB or MSB
	db 0					; Record Attributes: ignored if Record Format = 0.
						; 0 = before each entry, there is line feed and after each there is carriage return
						; 1 = first byte of a record shall be interpreted as specified in ISO 1539 for vertical spacing
						; 2 = the record contains the necessary control information
	dw 0					; record length
	db '                                '	; 32 a-characters identifing system
	times 64	db 0			; system use
	db 1					; extended attribute record version
	db 0					; escape sequences length
	times 64	db __ISO_RESERVED
	db %%end-%%app_start			; app usage area size
	%%app_start:
	; app usage area (with escape sequences)
	%%end:
	align 2048, db 0
%endmacro

%macro DESCRIPTOR 1
	db %1, 'CD001', 1	; Descriptor, Iso ID, versão da especificação
%endmacro

%macro ENTRY 3-4
%%start:
	db %%end - %%start			; entry size
	; Extended attributes size:
	%if (%0 == 4)
		db %4
	%else
		db 0
	%endif
	BOTH_ENDIAN_DWORD (%1 - SOF) / 2048	; initial sector
	BOTH_ENDIAN_DWORD %{1}.end - %1		; file size
	db (DATE_NUM / 10000) - 1900		; years
	db (DATE_NUM / 100) % 100		; month
	db DATE_NUM  % 100			; day
	db ((TIME_NUM / 10000) - 1900) & 0FFh	; hour
	db (TIME_NUM / 100) % 100		; minute
	db TIME_NUM  % 100			; second
	db GREENWICH_OFST
	db %2					; Flags
	db 0, 0					; File Unit Size and Interleave Gap for Interleaved Mode
	BOTH_ENDIAN_WORD 1			; volume where we are now
	db %%ID_end - %%ID_start		; ID size
%%ID_start db %3				; ID
%%ID_end:
	; padding:
	%if (~(%%ID_end - %%ID_start) & 1)
		db 0
	%endif
%%end:
%endmacro

%macro BOOTL 1
	__ISO_BOOTL:
	incbin %1
	.end:
%endmacro

%macro S_DIR 2
	%1:
	ENTRY %1, FFLAGS.DIR, FFLAGS.THIS_D
	ENTRY %2, FFLAGS.DIR, FFLAGS.PARENT
%endmacro

%macro E_DIR 0
	align 2048, db 0
	.end:
%endmacro

%macro FILE 2
	%1:
	incbin %2
	.end:
	align 2048, db 0
%endmacro

%macro PATH_ENTRY 3
	db %%E_ID - %%S_ID		; ID size
	db 0				; extended data
	; initial sector + directory it's inside
	%ifdef __ISO_DEF_PTM
		BIG_ENDIAN_DWORD (%1 - SOF) / 2048
		BIG_ENDIAN_WORD %2
	%else
		dd (%1 - SOF) / 2048
		dw %2
	%endif
	%%S_ID:
	db %3				; ID
	%%E_ID:
	; padding:
	%if ((%%E_ID - %%S_ID) & 1)
		db 0
	%endif
%endmacro


[org 0]
SOF:
; 16 sectors for system usage
SYS_1
times 2048 * 16 - ($ - $$) db 0

; Primary Volume Descriptor
DESCRIPTOR 1
db __ISO_UNUSED
db SYS_ID
db VOLUME_NAME
times 8 db __ISO_UNUSED
BOTH_ENDIAN_DWORD (EOF - SOF + 2047) / 2048	; sectors used by this volume
times 32 db __ISO_UNUSED
BOTH_ENDIAN_WORD 1				; # of volumes in this CD
BOTH_ENDIAN_WORD 1				; # of this volume. Starts in 1
BOTH_ENDIAN_WORD 2048				; logical block size
BOTH_ENDIAN_DWORD __ISO_PTL.end - __ISO_PTL	; path table size
dd (__ISO_PTL - SOF) / 2048			; LBA position of PTL
dd 0						; LBA position of secondary PTL, 0 = none
BIG_ENDIAN_DWORD (__ISO_PTM - SOF) / 2048	; LBA position of PTL in big-endian
dd 0						; LBA position of secondary PTL in big endian, 0 = none
; directory record of the root directory:
ENTRY ROOT, FFLAGS.DIR, FFLAGS.THIS_D
db VOLUME_SET_NAME
db PUBLISHER_ID
db DATA_PREPARER_ID
db VOLUME_DATA
db LICENCE
db ABSTRACT_DATA
db BIBLIOGRAPHIC_DATA
__ISO_TIME		; creation
__ISO_TIME		; modification
__ISO_NO_TIME		; expiration
__ISO_NO_TIME		; efetivation
db 1h, __ISO_UNUSED
APP_1
times 2048 * 17 - ($ - $$) db 0

%ifdef BOOTABLE
	;El Torito:
	;17º sector = Boot Record Volume Descriptor
	DESCRIPTOR 0
	db 'EL TORITO SPECIFICATION', 0, 0, 0, 0, 0, 0, 0, 0, 0
	times 32 db __ISO_UNUSED
	dd (BOOT_CATALOGUE - SOF) / 2048				; sector of boot catalogue
	times 1973 db __ISO_UNUSED
%endif

; end of Volume Descriptor's:
DESCRIPTOR 255			; Volume Descriptor => Terminator
times 2041 db __ISO_UNUSED

%ifdef BOOTABLE
	BOOT_CATALOGUE:
	; validation entry:
	db 1			;header
	db 0			;platform, 0=80x86, 1=Power PC, 2=Mac
	dw __ISO_RESERVED
	.creator_start:
	db BOOT_CD_CREATOR
	.creator_end:
	times 24-(.creator_end-.creator_start) db 0
	dw CHECKSUM
	dw 0AA55h		; boot signature
	db 88h			; 0 = not bootable, 80h = bootable
	db 0			; 0 = no emulation, 1=floppy 1.2 Mb, 2=floppy 1.44 Mb, 3=floppy 2.88 Mb, 4=HD
	dw 7C0h			; segment to load, 0 = standard
	db 0			; system type. In the specs: This must be a copy of byte 5 (System Type) from the Partition Table found in the boot image.
	db __ISO_UNUSED
	dw (__ISO_BOOTL.end - __ISO_BOOTL + 511) / 512	; # of sectors to load
	dd 0				; LBA address to start of disk (when using BIOS functions)
	times 20 db __ISO_UNUSED
	times (62 * 32) db 0		; Section Headers / Section Entries /  Section Entry Extensions
%endif

__ISO_PTL:
DEFINE_PATH_TABLE
.end:
align 2048, db 0
%define __ISO_DEF_PTM
__ISO_PTM:
DEFINE_PATH_TABLE
.end:
align 2048, db 0