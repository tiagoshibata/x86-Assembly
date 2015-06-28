; code.google.com/p/corkami/wiki/PE
; 3.1.3
; 79 - Data Definitions
%define FALSE	0
%define TRUE	1
%imacro BOOLEAN 0-1
	%if %0 == 0
		resb 1
	%else
		db %1
	%endif
%endmacro
%idefine INT8	BOOLEAN
%idefine UINT8	INT8
%imacro INT16 0-1
	alignb 2
	%if %0 == 0
		resw 1
	%else
		dw %1
	%endif
%endmacro
%idefine UINT16	INT16
%imacro INT32 0-1
	alignb 4
	%if %0 == 0
		resd 1
	%else
		dd %1
	%endif
%endmacro
%idefine UINT32	INT32
%imacro INTN 0-1
	alignb 8
	%if %0 == 0
		resq 1
	%else
		dq %1
	%endif
%endmacro
%idefine UINTN	INTN
%idefine INT64	INTN
%idefine UINT64	INTN
%idefine DPTR	INTN
%idefine CHAR8	db


%idefine EFI_HANDLE

struc EFI_TABLE_HEADER
	.Signature:	UINT64
	.Revision:	UINT32	; BCD words
	.HeaderSize:	UINT32	; sizeof (table)
	.CRC32:		UINT32	; w/ this field = 0
	.Reserved:	UINT32	; 0
endstruc

struc EFI_SYSTEM_TABLE	; Only Hdr, FirmwareVendor, FirmwareRevision, RuntimeServices, NumberOfTableEntries, ConfigurationTable valid after ExitBootServices()
	.Hdr:			resb EFI_TABLE_HEADER_size
	.FirmwareVendor:	DPTR
	.FirmwareRevision:	UINT32
	.ConsoleInHandle:	DPTR
	.ConIn:			DPTR
	.ConsoleOutHandle:	DPTR
	.ConOut:		DPTR
endstruc

[bits 64]
[org 0]
image_start:
incbin 'dos.exe'
db 'PE',0,0
dw 8664h
dw (section_headers.end - section_headers) / 40	; # seções (<= 96)
dd __POSIX_TIME__
dd 0				; PointerToSymbolTable
dd 0				; NumberOfSymbols (após SymbolTable = StringTable)
dw RVA.end - optional_header	; SizeOfOptionalHeader
; Characteristics
%define IMAGE_FILE_RELOCS_STRIPPED	1
%define IMAGE_FILE_EXECUTABLE_IMAGE	2
%define IMAGE_FILE_LINE_NUMS_STRIPPED	4
%define IMAGE_FILE_LOCAL_SYMS_STRIPPED	8
%define IMAGE_FILE_LARGE_ADDRESS_AWARE 32	; can handle > 2GiB
%define IMAGE_FILE_32BIT_MACHINE	256
%define IMAGE_FILE_DEBUG_STRIPPED	512
%define IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP 1024
%define IMAGE_FILE_NET_RUN_FROM_SWAP	2048
%define IMAGE_FILE_SYSTEM		4096
%define IMAGE_FILE_DLL			8192
%define IMAGE_FILE_UP_SYSTEM_ONLY	16384	; uniprocessor only
dw IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_LINE_NUMS_STRIPPED | IMAGE_FILE_LOCAL_SYMS_STRIPPED | IMAGE_FILE_LARGE_ADDRESS_AWARE | IMAGE_FILE_DEBUG_STRIPPED | IMAGE_FILE_SYSTEM | IMAGE_FILE_DLL
.end:
optional_header:
dw 20Bh			; Magic Number (x64)
db 0, 1			; Linker Version
dd __main_aligned_end - __main	; SizeOfCode (sections)
dd 0;+ __reloc_aligned_end - __reloc		; SizeOfInitializedData (sections)
dd 0			; SizeOfUninitializedData (sections)
%define IMAGE_BASE	400000h
dd 1000h		; AddressOfEntryPoint
dd 1000h		; BaseOfCode
dq IMAGE_BASE		; ImageBase (multiple of 64 KiB)
%define SectionAlignment	4 * 1024
dd SectionAlignment
%define FileAlignment		512
dd FileAlignment
; 64 bytes
dw 1			; MajorOperatingSystemVersion
dw 0			; MinorOperatingSystemVersion
dw 0			; MajorImageVersion
dw 1			; MinorImageVersion
dw 5			; MajorSubsystemVersion
dw 0			; MinorSubsystemVersion
dd 0			; Win32VersionValue (reserved)
dd image_end		; SizeOfImage (c/ headers, múltiplo de SectionAlignment)
dd __main		; SizeOfHeaders (MSDOS stub + PE header + Section Headers, arredondado para cima para FileAlignment)
dd 0					; Checksum
%define IMAGE_SUBSYSTEM_UNKNOWN			0
%define IMAGE_SUBSYSTEM_NATIVE			1	; Device drivers and native Windows processes
%define IMAGE_SUBSYSTEM_WINDOWS_GUI		2
%define IMAGE_SUBSYSTEM_WINDOWS_CUI		3	; The Windows character subsystem
%define IMAGE_SUBSYSTEM_POSIX_CUI		7	; The Posix character subsystem
%define IMAGE_SUBSYSTEM_WINDOWS_CE_GUI		9	; Windows CE
%define IMAGE_SUBSYSTEM_EFI_APPLICATION	10
%define IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER 11	; An EFI driver with boot services
%define IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER	12	; An EFI driver with run-time services
%define IMAGE_SUBSYSTEM_EFI_ROM			13
%define IMAGE_SUBSYSTEM_XBOX			14
dw IMAGE_SUBSYSTEM_EFI_APPLICATION	; Subsystem
%define IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE		40h
%define IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY	80h
%define IMAGE_DLL_CHARACTERISTICS_NX_COMPAT		100h
%define IMAGE_DLLCHARACTERISTICS_NO_ISOLATION		200h	; Isolation aware, but do not isolate the image
%define IMAGE_DLLCHARACTERISTICS_NO_SEH		400h	; Does not use structured exception (SE) handling
%define IMAGE_DLLCHARACTERISTICS_NO_BIND		800h
%define IMAGE_DLLCHARACTERISTICS_WDM_DRIVER		2000h
%define IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE	8000h
dw IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE | IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY | IMAGE_DLLCHARACTERISTICS_NO_SEH	; DllCharacteristics
dq 2000h	; SizeOfStackReserve. Only SizeOfStackCommit is committed; the rest is made available one page at a time until the reserve size is reached
dq 2000h	; SizeOfStackCommit
dq 2000h	; SizeOfHeapReserve
dq 2000h	; SizeOfHeapCommit
dd 0		; LoaderFlags (reserved)
dd (RVA.end - RVA) / 8	; NumberOfRvaAndSizes
; RVA's:
RVA:
times 10h dq 0
times 152 db 0
dd __reloc
dd __reloc_end - __reloc
.end:
; Section Table (ascending order, adjacent, multiple of SectionAlignment):
section_headers:
%define IMAGE_SCN_CNT_CODE			20h
%define IMAGE_SCN_CNT_INITIALIZED_DATA		40h
%define IMAGE_SCN_CNT_UNINITIALIZED_ DATA	80h
%define IMAGE_SCN_GPREL				8000h		; contains data referenced through the global pointer
%define IMAGE_SCN_LNK_NRELOC_OVFL		1000000h	; contains extended relocations
%define IMAGE_SCN_MEM_DISCARDABLE		2000000h	; can be discarded as needed
%define IMAGE_SCN_MEM_NOT_CACHED		4000000h
%define IMAGE_SCN_MEM_NOT_PAGED			8000000h	; not pageable
%define IMAGE_SCN_MEM_SHARED			10000000h
%define IMAGE_SCN_MEM_EXECUTE			20000000h
%define IMAGE_SCN_MEM_READ			40000000h
%define IMAGE_SCN_MEM_WRITE			80000000h
db '.text',0,0,0	; Name
dd __main_end - __main	; VirtualSize
dd 1000h		; VirtualAddress
dd __main_aligned_end - __main	; SizeOfRawData
dd __main		; PointerToRawData
dd 0			; PointerToRelocations
dd 0			; PointerToLinenumbers
dw 0			; NumberOfRelocations
dw 0			; NumberOfLinenumbers
dd IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_EXECUTE	; Characteristics

db '.data',0,0,0			; Name
dd __rdata_end - __rdata		; VirtualSize
dd 2000h			; VirtualAddress
dd __rdata_aligned_end - __rdata	; SizeOfRawData
dd __rdata			; PointerToRawData
dd 0				; PointerToRelocations
dd 0				; PointerToLinenumbers
dw 0				; NumberOfRelocations
dw 0				; NumberOfLinenumbers
dd IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE	; Characteristics

db '.reloc',0,0		; Name
dd 0			; VirtualSize
dd 3000h		; VirtualAddress
dd 0			; SizeOfRawData
dd __reloc		; PointerToRawData
dd 0			; PointerToRelocations
dd 0			; PointerToLinenumbers
dw 0			; NumberOfRelocations
dw 0			; NumberOfLinenumbers
dd IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_DISCARDABLE	; Characteristics
.end:
align FileAlignment, db 0
__main:
; rcx = ImageHandle
; rdx = SystemTable
%define rdata(x)	x - __rdata + IMAGE_BASE + 2000h
sub rsp, 4 * 8			; args
mov [rdata(Handle)], rcx                   ; ImageHandle
mov [rdata(SystemTable)], rdx              ; Pointer to SystemTable.x
mov rdx, rdata(msg)
mov rcx, [rdata(SystemTable)]
mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
call [rcx + 8]
add rsp, 4*8
xor eax, eax
retn

__main_end:
align FileAlignment, db 0
__main_aligned_end:
__rdata:
Handle                                  dq 0
SystemTable                             dq 0
msg                                     db 'H',0,'i',0,13,10,0,0
__rdata_end:
align FileAlignment, db 0
__rdata_aligned_end:
__reloc:
%define IMAGE_REL_BASED_ABSOLUTE	0
%define IMAGE_REL_BASED_HIGH		1 << 12	; Salva 16 bits altos do deslocamento
%define IMAGE_REL_BASED_LOW		2 << 12
%define IMAGE_REL_BASED_HIGHLOW		3 << 12	; 32 bits
%define IMAGE_REL_BASED_HIGHADJ		4 << 12	; 16 altos + 16 baixos
%define IMAGE_REL_BASED_DIR64		10 << 12; 64 bits
__reloc_main:
; in 4KiB blocks:
dd __main
dd .end - __reloc_main
dw IMAGE_REL_BASED_DIR64 | (__main - image_start + 2)
.end:
__reloc_end:
align FileAlignment, db 0
__reloc_aligned_end:
image_end:
