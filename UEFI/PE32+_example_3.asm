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
%define IMAGE_BASE		0;400000h
%define FileAlignment		512
%define SectionAlignment	4 * 1024

[bits 64]
[org 0]
%ifndef CODECOMP
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
dd 2000h		; SizeOfInitializedData (sections)
dd 0			; SizeOfUninitializedData (sections)
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
dd __reloc_end - __reloc
times 10 dq 0
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
%endif
__main:
default rel	; use rip-relative addresses
; rcx = ImageHandle
; rdx = SystemTable
; %define rdata(x)	x - __rdata + IMAGE_BASE + 2000h

; push rbp
; mov rbp, rsp
; sub rbp, 1000h - 8
sub rsp, 48
; mov [do_efi_call.stack_addr], rbp
mov [Handle],rcx	;rdata(Handle) - (.e - a)], rcx	; ImageHandle
mov [SystemTable], rdx	; Pointer to SystemTable


; mov rcx, [rdata(SystemTable)]
; mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; call [rcx + 8]
mov rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]
lea rdx, [msg]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

mov rcx, [SystemTable]
mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
lea rdx, [msg]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]
; ;	-args in rcx, rdx, r8, r9, stack. 8, 16, 32, 64 bits in register, else pointer
; ;	-return values <= 64 bits (including float) in rax, else pointer in rcx. Then rdx, r8, r9, stack. 1, 2, 4, 8, 16, 32, 64 bits in register, else pointer
; ;	-rbx, rbp, rdi, rsi, r12-r15, xmm6-15 are nonvolatile
lea rcx, [memmap_size]
lea rdx, [memmap]
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.GetMemoryMap]
pop rax
test rax, rax
jnz quit

mov rcx, [SystemTable]
mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
lea rdx, [msg]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

quit:
add rsp, 48
xor rax, rax
retn
; mov rax, [memmap_size]
; mov rcx, [SystemTable]
; mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; mov rdx, msg
; call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

; 
; do_efi_call:
; ;	-4 KiB or more of stack, 32 bytes of shadow space abobe call address, stack 16-byte aligned for the callee
; 	xchg rbp, rsp
; ; 	mov rsp, 0FFFFFFFFFFFFFFFFh
; ; 	.stack_addr equ $-8
; 	call [rbx]
; 	xchg rsp, rbp
; ret

; printa:
; 	mov rdx, rdata(hex_prefix)
; 	mov rcx, [rdata(SystemTable)]
; 	mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; 	call [rcx + 8]
; 	mov rbp, 16
; 	.print:
; 		rol rax, 4
; 		mov rbx, rax
; 		and rbx, 0Fh
; 		mov rbx, [rbx + rdata(hex)]
; 		mov rdx, rdata(char_output)
; 		mov [rdx], rbx
; 		mov rcx, [rdata(SystemTable)]
; 		mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; 		call [rcx + 8]
; 		dec rbp
; 	jnz .print
		
	
; 	xor rdi, rdi
; 	.rep:
; 		mov rcx, rbp
; 		and rbp, 0Fh
; 		push qword [rdata(hex) + rbp]
; 		shr rcx, 4
; 		mov rbp, rcx
; 		test rcx, rcx
; 		inc rdi
; 	jnz .rep
; 	.print:
; 		mov rdx, rdata(char_output)
; 		pop qword [rdx]
; 		mov rcx, [rdata(SystemTable)]
; 		mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; 		call [rcx + 8]
; 		dec rdi
; 	jnz .print
; ret

__main_end:
%ifdef CODECOMP
	align SectionAlignment, db 0
%else
	align FileAlignment, db 0
%endif
__main_aligned_end:
__rdata:
init_rsp				dq 0
msg:					dw __utf16__ ('Hi!'),13,10,0
hex_prefix				dw __utf16__ ('0x'),0
char_output:				dw 0, 0
hex					db '0123456789ABCDEF'
Handle					dq 0
SystemTable				dq 0
memmap_size				dq 2*1024
memmap: times 2*1024 db 0
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
.end:
__reloc_end:
align FileAlignment, db 0
__reloc_aligned_end:
image_end: