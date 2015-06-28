; code.google.com/p/corkami/wiki/PE
; http://www.phreedom.org/research/tinype/
; 3.1.3
; 77/78 - Runtime Services/Calling Conventions
; 79 - Data Definitions
; 86-89 - x64 Platforms
; 94-97 - Protocols
; 110-114 - Elements
; 124 - Global Variables
; 133... - EFI System Table
; 488
; Create Load Option at install
; To call runtime services:
;	-Preserve runtime code/data
;	-Paging, virtual=physical or SetVirtualAddressMap()
;	-Direction Flag clear
;	-4 KiB or more of stack, 32 bytes of shadow space abobe call address, stack 16-byte aligned for the callee
;	-ACPI tables in EfiACPIReclaimMemory (recommended) or EfiACPIMemoryNVS
;	-No virtual mapping for EfiACPIReclaimMemory or EfiACPIMemoryNVS
;	-Mem. descriptors of type EfiACPIReclaimMemory or EfiACPIMemoryNVS aligned in 4 KiB and size multiple of 4 KiB
;	-An ACPI Memory Op-region inherits cacheability from the UEFI memory map, else from namespace, else suume non cacheable
;	-ACPI tables loaded at runtime contained in EfiACPIMemoryNVS, cacheability defined in UEFI mem map. If no info found in UEFI, use ACPI, else assume non-cached
;	-UEFI Configuration Tables loaded at boot time (e.g., SMBIOS) are EfiRuntimeServicesData (recommended, no virtual mapping required), EfiBootServicesdata,
; EfiACPIReclaimMemory or EfiACPIMemoryNVS
;	-Tables loaded at runtime are EfiRuntimeServicesData (recommended) or EfiACPIMemoryNVS
;	-args in rcx, rdx, r8, r9, stack. 8, 16, 32, 64 bits in register, else pointer
;	-return values <= 64 bits (including float) in rax, else pointer in rcx. Then rdx, r8, r9, stack. 1, 2, 4, 8, 16, 32, 64 bits in register, else pointer
;	-rbx, rbp, rdi, rsi, r12-r15, xmm6-15 are nonvolatile
;	-Return XMM 128-bits, floats, doubles in xmm0. Floating point status register is volatile. Calling w/ float/double in xmm0-3, integer slot ignored. XMM in mem,
; callee receives pointer. MMX as integer of same size. Callees may unmask exception providing exception handlers.

; Characteristics: RELOCS_STRIPPED!
%include 'uefi.inc'
%define IMAGE_BASE		10000000h;800000000h
%define FileAlignment		512
%define SectionAlignment	(4 * 1024)
%define nl 10, 13
%define KiB			* 1024
%define MiB			* 1024 KiB

[bits 64]
%ifidn __OUTPUT_FORMAT__, bin
[org 0]
%endif
SOF:
db 'MZ'


;;
; align 8, db 0
times 3Ch - ($-$$) db 0
dd PE_header
PE_header:
;;


db 'PE',0,0
dw 8664h
dw (section_headers.end - section_headers) / 40	; # seções (<= 96)
dd 0;__POSIX_TIME__
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
%define txtrdat_sections	((__main_end - __main + SectionAlignment - 1) / SectionAlignment) * SectionAlignment
dd txtrdat_sections	; SizeOfCode
dd txtrdat_sections	; SizeOfInitializedData
dd 0			; SizeOfUninitializedData
dd 1000h		; AddressOfEntryPoint
dd 1000h		; BaseOfCode
dq IMAGE_BASE		; ImageBase (multiple of 64 KiB)
dd SectionAlignment
dd FileAlignment
; 64 bytes
dw 1			; MajorOperatingSystemVersion
dw 0			; MinorOperatingSystemVersion
dw 0			; MajorImageVersion
dw 1			; MinorImageVersion
dw 5			; MajorSubsystemVersion
dw 0			; MinorSubsystemVersion
dd 0			; Win32VersionValue (reserved)
dd 3000h		; SizeOfImage (c/ headers, múltiplo de SectionAlignment)
dd __main		; SizeOfHeaders (MSDOS stub + PE header + Section Headers, arredondado para cima para FileAlignment)
dd 0			; Checksum
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
dq 2000h		; SizeOfStackReserve. Only SizeOfStackCommit is committed; the rest is made available one page at a time until the reserve size is reached
dq 1000h		; SizeOfStackCommit
dq 10000h		; SizeOfHeapReserve
dq 0		; SizeOfHeapCommit
dd 0		; LoaderFlags (reserved)
dd (RVA.end - RVA) / 8	; NumberOfRvaAndSizes
; RVA's:
RVA:
times 5 dq 0
dd 3000h
dd 0
.end:
; Section Table (ascending order, adjacent, multiple of SectionAlignment):
section_headers:
%define IMAGE_SCN_CNT_CODE			20h
%define IMAGE_SCN_CNT_INITIALIZED_DATA		40h
%define IMAGE_SCN_CNT_UNINITIALIZED_DATA	80h
%define IMAGE_SCN_GPREL				8000h		; contains data referenced through the global pointer
%define IMAGE_SCN_LNK_NRELOC_OVFL		1000000h	; contains extended relocations
%define IMAGE_SCN_MEM_DISCARDABLE		2000000h	; can be discarded as needed
%define IMAGE_SCN_MEM_NOT_CACHED		4000000h
%define IMAGE_SCN_MEM_NOT_PAGED			8000000h	; not pageable
%define IMAGE_SCN_MEM_SHARED			10000000h
%define IMAGE_SCN_MEM_EXECUTE			20000000h
%define IMAGE_SCN_MEM_READ			40000000h
%define IMAGE_SCN_MEM_WRITE			80000000h


%define txtrdat_SizeOfRawData	((__initdata_end - __main + FileAlignment - 1) / FileAlignment) * FileAlignment
db '.txtdata'		; Name (text + data)
dd txtrdat_sections	; VirtualSize
dd 1000h		; VirtualAddress
dd txtrdat_SizeOfRawData	; SizeOfRawData
dd __main		; PointerToRawData
dd 0			; PointerToRelocations
dd 0			; PointerToLinenumbers
dw 0			; NumberOfRelocations
dw 0			; NumberOfLinenumbers
dd IMAGE_SCN_CNT_CODE | IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE	; Characteristics

; db '.bss',0,0,0,0	; Name
; dd 1000h		; VirtualSize
; dd 1000h + txtrdat_sections	; VirtualAddress
; dd 0			; SizeOfRawData
; dd 0			; PointerToRawData
; dd 0			; PointerToRelocations
; dd 0			; PointerToLinenumbers
; dw 0			; NumberOfRelocations
; dw 0			; NumberOfLinenumbers
; dd IMAGE_SCN_CNT_UNINITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE	; Characteristics

db '.reloc',0,0		; Name
dd 0			; VirtualSize
dd 2000h			; VirtualAddress
dd 0			; SizeOfRawData
dd 0			; PointerToRawData
dd 0			; PointerToRelocations
dd 0			; PointerToLinenumbers
dw 0			; NumberOfRelocations
dw 0			; NumberOfLinenumbers
dd IMAGE_SCN_CNT_UNINITIALIZED_DATA | IMAGE_SCN_MEM_DISCARDABLE	; Characteristics

.end:

align FileAlignment, db 0

%macro print 1
	mov rcx, [SystemTable]
	mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
	lea rdx, [%1]
	call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]
%endmacro
__main:
default rel	; use rip-relative addresses
; rcx = ImageHandle
; rdx = SystemTable
; init
sub rsp, 48
mov [Handle], rcx
mov [SystemTable], rdx

; EB9D2D30-2D88-11D3 9A16-0090273FC14D
%define ACPI_TABLE_GUID_1	11D32D88EB9D2D30h
%define ACPI_TABLE_GUID_2	0090273FC14D9A16h

; mov rax, ACPI_TABLE_GUID_1
; mov rbx, ACPI_TABLE_GUID_2
; call search_conf_table


mov rbx, [SystemTable]
mov rbx, [rbx + EFI_SYSTEM_TABLE.NumberOfTableEntries]
call printhex

mov rdx, [SystemTable]
mov rdx, [rdx + EFI_SYSTEM_TABLE.ConfigurationTable]
mov rcx, rbx
shl rcx, 6			; *= 64
lea rcx, [2 * rcx + rcx]	; mov + add + add?
; sub rcx, 3 * 64			; FIXME: dec acima?
xor rax, rax

print_table:
	mov rbx, [rdx + rax]
	push rax
	push rcx
	push rdx
	call printhex
	pop rdx
	pop rcx
	pop rax
	
; 	mov rbx, [rdx + rax + 64]
; 	push rax
; 	push rcx
; 	push rdx
; 	call printhex
; 	pop rdx
; 	pop rcx
; 	pop rax
; 	add rax, 3 * 64

	add rax, 64
	cmp rax, rcx
jne print_table



; ; change TPL
; mov rcx, TPL_NOTIFY
; mov rax, [SystemTable]
; mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
; call [rax + EFI_BOOT_SERVICES.RaiseTPL]

;	-args in rcx, rdx, r8, r9, stack. 8, 16, 32, 64 bits in register, else pointer
;	-return values <= 64 bits (including float) in rax, else pointer in rcx. Then rdx, r8, r9, stack. 1, 2, 4, 8, 16, 32, 64 bits in register, else pointer
;	-rbx, rbp, rdi, rsi, r12-r15, xmm6-15 are nonvolatile


; mov r8, 2	; 2 páginas de 4 KiB
; xor rcx, rcx		; AllocateAnyPages
; mov rdx, EfiLoaderData
; mov rax, [SystemTable]
; mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
; call [rax + EFI_BOOT_SERVICES.AllocatePages]
; ; rdx = mem pointer
; test rax, rax
; jnz quit


get_memmap:
; get memmap
lea rcx, [memmap_size]
mov qword [rcx], 4 KiB
lea rdx, [memmap]
lea r8, [mapkey]
lea r9, [descriptor_size]
lea rax, [descriptor_version]
push rax
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.GetMemoryMap]
pop rcx
test rax, rax
jnz halt

; print msg.mapsize
; mov rbx, [memmap_size]
; call printhex
; 
; print msg.mapkey
; mov rbx, [mapkey]
; call printhex
; 
; print msg.descsize
; mov rbx, [descriptor_size]
; call printhex
; 
; print msg.descv
; mov rbx, [descriptor_version]
; call printhex

; exit boot services:
mov rcx, [Handle]
mov rdx, [mapkey]	; MapKey
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.ExitBootServices]
test rax, rax
jnz get_memmap


quit:
; mov rcx, EfiResetShutdown
; mov rdx, EFI_SUCCESS
; xor r8, r8
; mov rax, [SystemTable]
; mov rax, [rax + EFI_SYSTEM_TABLE.RuntimeServices]
; call [rax + EFI_RUNTIME_SERVICES.ResetSystem]

halt:
cli
hlt
jmp $-1

search_conf_table:
mov rdx, [SystemTable]
mov rcx, [rdx + EFI_SYSTEM_TABLE.NumberOfTableEntries]
shl rcx, 6			; *= 64
lea rcx, [2 * rcx + rcx]	; mov + add + add?
sub rcx, 3 * 64
search_table:
	cmp [rdx + rcx + EFI_SYSTEM_TABLE.ConfigurationTable], rax
	jne .invalid
		cmp [rdx + rcx + EFI_SYSTEM_TABLE.ConfigurationTable + 64], rbx
		jne .invalid
			ret	; rcx = entry pointer
	.invalid:
	sub rcx, 3 * 64
jnc search_table
jmp halt	; FIXME

printhex:
mov rbp, 16
.loop:
	rol rbx, 4
	mov rax, rbx
	and rax, 0Fh
	lea rcx, [msg.hex]
	mov rax, [rax + rcx]
	mov byte [msg.num], al
	print msg.num
	dec rbp
jnz .loop
print msg.nl
ret

align 8, db 0
msg:
.ok					dw __utf16__ ('OK!'),nl,0
.end					dw __utf16__ ('END!'),0
.error					dw __utf16__ ('FAIL!'),nl,0
.invalid				dw __utf16__ ('Invalid map key!'),nl,0
.mapsize				dw __utf16__ ('Memory map size: '),0
.mapkey					dw __utf16__ ('Memory map key: '),0
.descsize				dw __utf16__ ('Memory descriptor size: '),0
.descv					dw __utf16__ ('Memory descriptor version: '),0
.hex					db '0123456789ABCDEF'
.num					dw 0,0
.nl					dw nl,0
;FIXME: alinhamento
align 8,db 0
__initdata_end:
Handle					dq 0
SystemTable				dq 0
memmap_size				dq 0
mapkey					dq 0
descriptor_size				dq 0
descriptor_version			dd 0
memmap					resb	4 KiB
__main_end:
image_end: