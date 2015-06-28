; 0x6907000


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
SOF:
%ifidn __OUTPUT_FORMAT__, bin
	[org 0]
%endif
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

%define txtrdat_SizeOfRawData	((__main_end - __main + FileAlignment - 1) / FileAlignment) * FileAlignment
db '.txtrdat'		; Name (text + rdata)
dd txtrdat_sections	; VirtualSize
dd 1000h		; VirtualAddress
dd txtrdat_SizeOfRawData; SizeOfRawData
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
dd 2000h		; VirtualAddress
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
; %imacro debug 0-1
; 	mov rcx, [SystemTable]
; 	mov rcx, [rcx + EFI_SYSTEM_TABLE.ConOut]
; 	lea rdx, [%%msg]
; 	call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]
; 	jmp %%after
; 	align 2, db 0
; 	%defstr line_n	__LINE__
; 	%if %0 == 1
; 		%define dbg_msg	' executing.'
; 	%else
; 		%define dbg_msg %1, ' executing.'
; 	%endif
; 	dw nl, __utf16__ ('File '), __utf16__ (__FILE__), __utf16__ (', line '), __utf16__ (line_n), __utf16__ (' executing.'),0
; 	%%after:
; %endmacro
__main:
default rel	; use rip-relative addresses
; rcx = ImageHandle
; rdx = SystemTable
; init
sub rsp, 48
mov [Handle], rcx
mov [SystemTable], rdx

; print
mov rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]
lea rdx, [msg.start]
call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]
jmp quit
; change TPL
mov rcx, TPL_NOTIFY
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.RaiseTPL]

;	-args in rcx, rdx, r8, r9, stack. 8, 16, 32, 64 bits in register, else pointer
;	-return values <= 64 bits (including float) in rax, else pointer in rcx. Then rdx, r8, r9, stack. 1, 2, 4, 8, 16, 32, 64 bits in register, else pointer
;	-rbx, rbp, rdi, rsi, r12-r15, xmm6-15 are nonvolatile

get_memmap:

print msg.alloc

; malloc
mov r8, [memmap_size]
add r8, 2 << 12
and r8, ~0FFFh
mov [memmap_size], r8
shr r8, 12
xor rcx, rcx		; AllocateAnyPages
mov rdx, EfiLoaderData
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.AllocatePages]
; rdx = mem pointer
test rax, rax
jnz quit

; mov rbx, rdx
; print msg.alloc

; get memmap
lea rcx, [memmap_size]
; mov rdx, rbx	; *map
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.GetMemoryMap]
pop rcx
test rax, rax
jnz quit
;print msg.getmap

; exit boot services:
mov rcx, [Handle]
mov rdx, r8	; MapKey
mov rax, [SystemTable]
mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
call [rax + EFI_BOOT_SERVICES.ExitBootServices]
test rax, rax
jz .ok
cmp rax, 2
je .inv

print msg.fail
jmp quit
; mov rcx, rbx	; *Memory
; mov rdx, [memmap_size]
; shr rdx, 12
; mov rax, [SystemTable]
; mov rax, [rax + EFI_SYSTEM_TABLE.BootServices]
; call [rax + EFI_BOOT_SERVICES.FreePages]
; test rax, rax
; jz .freed
; print msg.notfreed
; jmp quit
; .freed:
; print msg.invalid
; jmp get_memmap

.inv:
print msg.invalid
jmp quit

.ok:
print msg.exitboot


quit:
add rsp, 48
xor rax, rax
retn

printhex:
	mov rcx, 16
	lea rbp, [msg.p]
	.rep:
	rol rax, 4
	mov rbx, rax
	and rax, 0Fh
	mov al, [msg.hex + rax]
	mov [rbp], ax
	mov rax, rbx
	add rbp, 2
	dec rcx
	jnz .rep
	print msg.p
ret

align 8, db 0
%assign mem	$-__main
%warning mem
Handle					dq 0
SystemTable				dq 0
memmap_size				dq 4 MiB
msg:
.start					dw __utf16__ ('UEFI bootloader'),0
.raiseTPL				dw nl,__utf16__ ('TPL raised.'),0
.alloc					dw nl,__utf16__ ('Allocated memory for mapping.'),0
.getsize				dw nl,__utf16__ ('Received size for memory map.'),0
; .getmap					dw nl,__utf16__ ('Received memory map.'),0
.invalid				dw nl,__utf16__ ('ExitBootServices() error: Invalid MapKey.'),0
.exitboot				dw nl,__utf16__ ('Memory allocated and exited Boot Services.'),0
.notfreed				dw nl,__utf16__ ('Failed to free memory.'),0
.fail					dw nl, __utf16__ ('Failed'),0
.hex					db '0123456789ABCDEF'
.p					dw __utf16__('00000000'),0
__main_end:
image_end:
