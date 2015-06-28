[bits 16]
; Ensure you don't use cluster numbers bigger than 0FFF5h!
; Configurations here:
%define OEM_ID			'MSWIN4.1'	; 8 bytes
%define IMAGE_SIZE		16 * 1024	; 16 KiB
%define EMPTY			0		; value for empty bytes
%define BYTES_PER_SECTOR	512
%define SECTORS_PER_CLUSTER	1
%define RESERVED_SECTORS	1		; for bootloader and other data
%define NUMBER_FATS		1		; no backup
%define ROOT_DIRS		16		; 16 * 32 entries = 512 bytes
%define MEDIA			0F8h		; Fixed Media
%define FAT_LOG_SECTORS		1		; FAT uses 512 bytes
%define SECTORS_PER_TRACK	20h		; if CHS addressing isn't used, SECTORS_PER_TRACK and HEADS_PER_DISK can be set to 0 or 1
%define HEADS_PER_DISK		40h
%define HIDDEN_SECTORS		0		; sectors before this partition
%define BIOS_DRIVE_NUMBER	80h		; hard disk
%define SERIAL			0D3DAB580h	; unique number to identify your disk (dword)
%define LABEL			'OASYS CD   '	; CD name (11 bytes)
%define BOOTLOADER		'bootloader.bin'; bootloader file (will start at 7c00h + size of FAT header)
; The following times will be used for file creation, modification and access times.
%xdefine SECOND			__TIME_NUM__ % 100
%xdefine SECOND_100		100 * (SECOND & 1)		; 1/100 seconds, 0 - 199
%xdefine MINUTE			(__TIME_NUM__ / 100) % 100
%xdefine HOUR			__TIME_NUM__ / 10000
%xdefine DAY			__DATE_NUM__ % 100
%xdefine MONTH			(__DATE_NUM__ / 100) % 100
%xdefine YEAR			(__DATE_NUM__ / 10000)
; FAT
%macro WRITE_FAT 0
	; Cluster: 0 = Free, if found in a cluster chain, End-Of-chain
	; 1 = Reserved, if found in a cluster chain, EOC. Used by DOS to mark temporary clusters while a cluster chain is created.
	; 2 - 0FFF5h = Cluster with data
	; 0FFF6h = Reserved. If found in a cluster chain, data.
	; 0FFF7h = Bad sector/reserved cluster. If found in a cluster chain, data cluster.
	; 0FFF8 - 0FFFFh = EOC

	; First cluster = media type | 0F00h
	; Second cluster = EOC. Bit 7 set = last shutdown was OK, bit 6 set = last usage had no IO errors
	clusters MEDIA | 0F00h, 0FFFh,		\
		0FFFh, 0FFFh, 0FFFh, 6, 0FFFh	; EFI, BOOT and BOOTX64 use 1 cluster each, file VERYLONG.TXT, however, uses 2 clusters (cluster 5 points to 6).
%endmacro
; End of configurations!

; Media types (from http://en.wikipedia.org/wiki/File_Allocation_Table):
; 0xED
; 5.25-inch (130 mm) Double sided, 80 tracks per side, 9 sector, 720 KB (Tandy 2000 only)
; 0xF0
; 3.5-inch (90 mm) Double Sided, 80 tracks per side, 18 or 36 sectors per track (1.44 MB or 2.88 MB).
; Designated for use with custom floppy and superfloppy formats where the geometry is defined in the BPB.
; Used also for other media types such as tapes.
; 0xF8
; Fixed disk (i.e., typically a partition on a hard disk). (since DOS 2.0)
; Designated to be used for any partitioned fixed or removable media, where the geometry is defined in the BPB.
; 3.5-inch Single sided, 80 tracks per side, 9 sectors per track (360 KB) (MSX-DOS only)
; 5.25-inch Double sided, 80 tracks per side, 9 sectors per track (720 KB) (Sanyo 55x DS-DOS 2.11 only)
; 0xF9
; 3.5-inch Double sided, 80 tracks per side, 9 sectors per track (720 KB)
; 5.25-inch Double sided, 80 tracks per side, 15 sectors per track (1.2 MB)
; 0xFA
; 3.5-inch and 5.25-inch Single sided, 80 tracks per side, 8 sectors per track (320 KB)
; Used also for RAM disks and ROM disks (f.e. on HP 200LX)
; Hard disk (Tandy MS-DOS only)
; 0xFB
; 3.5-inch and 5.25-inch Double sided, 80 tracks per side, 8 sectors per track (640 KB)
; 0xFC
; 5.25-inch Single sided, 40 tracks per side, 9 sectors per track (180 KB)
; 0xFD
; 5.25-inch Double sided, 40 tracks per side, 9 sectors per track (360 KB)
; 8-inch (200 mm) Double sided, 77 tracks per side, 26 sectors per track, 128 bytes per sector (500.5 KB)
; 0xFE
; 5.25-inch Single sided, 40 tracks per side, 8 sectors per track (160 KB)
; 8-inch Single sided, 77 tracks per side, 26 sectors per track, 128 bytes per sector (250.25 KB)
; 8-inch Double sided, 77 tracks per side, 8 sectors per track, 1024 bytes per sector (1232 KB)
; 0xFF
; 5.25-inch Double sided, 40 tracks per side, 8 sectors per track (320 KB)
; Hard disk (Sanyo 55x DS-DOS 2.11 only)
%include 'FAT.inc'
; Diretório Raíz
F:
	.RO		equ 1
	.HIDDEN		equ 2
	.SYS		equ 4
	.VLABEL		equ 8
	.SUBDIR		equ 16
	.ARCHIV		equ 32	; Dirty
	.LONGNAME	equ 0Fh
; Root:
DIR 'EFI', EFI, F.RO | F.SYS
DIR_END

; Cluster 2:
EFI:
DIR 'BOOT', BOOT, F.RO | F.SYS
DIR_END

; Cluster 3:
BOOT:
FILE 'BOOTX64.TXT', BOOTX64, F.RO | F.SYS
FILE 'VERYLONG.TXT', VERYLONG, F.RO | F.SYS
DIR_END

; Cluster 4:
BOOTX64:
INC_FILE 'image_files/BOOTX64.EFI'

; Cluster 5 and 6:
VERYLONG:
INC_FILE 'image_files/VERYLONG.TXT'

times (IMAGE_SIZE-($-$$)) db EMPTY
EOF:
