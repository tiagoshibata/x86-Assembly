;TODO: validar tabelas com CRC
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
%imacro EFI_GUID 0-11
	alignb 8
	%if %0 == 0
		resq 2
	%elif %0 == 11
		dd %1
		dw %2, %3
		db %4, %5, %6, %7, %8, %9, %10, %11
	%else
		%error EFI_GUID: invalid number of arguments
	%endif
%endmacro
%define EFI_PHYSICAL_ADDRESS	UINT64
%define EFI_VIRTUAL_ADDRESS	UINT64


%idefine EFI_HANDLE

%define ERR				8000000000000000h
%define EFI_SUCCESS			0
%define EFI_LOAD_ERROR			ERR | 1
%define EFI_INVALID_PARAMETER		ERR | 2
%define EFI_UNSUPPORTED 		ERR | 3
%define EFI_BAD_BUFFER_SIZE		ERR | 4
%define EFI_BUFFER_TOO_SMALL		ERR | 5
%define EFI_NOT_READY			ERR | 6
%define EFI_DEVICE_ERROR		ERR | 7
%define EFI_WRITE_PROTECTED		ERR | 8
%define EFI_OUT_OF_RESOURCES		ERR | 9
%define EFI_VOLUME_CORRUPTED		ERR | 10
%define EFI_VOLUME_FULL 		ERR | 11
%define EFI_NO_MEDIA			ERR | 12
%define EFI_MEDIA_CHANGED		ERR | 13
%define EFI_NOT_FOUND			ERR | 14
%define EFI_ACCESS_DENIED		ERR | 15
%define EFI_NO_RESPONSE 		ERR | 16
%define EFI_NO_MAPPING			ERR | 17
%define EFI_TIMEOUT			ERR | 18
%define EFI_NOT_STARTED 		ERR | 19
%define EFI_ALREADY_STARTED		ERR | 20
%define EFI_ABORTED			ERR | 21
%define EFI_ICMP_ERROR			ERR | 22
%define EFI_TFTP_ERROR			ERR | 23
%define EFI_PROTOCOL_ERROR		ERR | 24

%define EFI_SYSTEM_TABLE_SIGNATURE	5453595320494249h
%define EFI_2_31_SYSTEM_TABLE_REVISION ((2<<16) | (31))
%define EFI_2_30_SYSTEM_TABLE_REVISION ((2<<16) | (30))
%define EFI_2_20_SYSTEM_TABLE_REVISION ((2<<16) | (20))
%define EFI_2_10_SYSTEM_TABLE_REVISION ((2<<16) | (10))
%define EFI_2_00_SYSTEM_TABLE_REVISION ((2<<16) | (00))
%define EFI_1_10_SYSTEM_TABLE_REVISION ((1<<16) | (10))
%define EFI_1_02_SYSTEM_TABLE_REVISION ((1<<16) | (02))
%define EFI_SYSTEM_TABLE_REVISION	EFI_2_30_SYSTEM_TABLE_REVISION
%define EFI_SPECIFICATION_VERSION	EFI_SYSTEM_TABLE_REVISION
%define EFI_SYSTEM_TABLE_REVISION	EFI_2_31_SYSTEM_TABLE_REVISION

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
	.StandardErrorHandle:	DPTR
	.StdErr:		DPTR
	.RuntimeServices:	DPTR
	.BootServices:		DPTR
	.NumberOfTableEntries:	DPTR
	.ConfigurationTable:	DPTR
endstruc


%define EFI_BOOT_SERVICES_SIGNATURE	56524553544f4f42h
%define EFI_BOOT_SERVICES_REVISION	EFI_SPECIFICATION_VERSION

struc EFI_BOOT_SERVICES
	.Hdr:				resb EFI_TABLE_HEADER_size
	.RaiseTPL:			DPTR
	.RestoreTPL:			DPTR
	.AllocatePages:			DPTR
	.FreePages:			DPTR
	.GetMemoryMap:			DPTR
	.AllocatePool:			DPTR
	.FreePool:			DPTR
	.CreateEvent:			DPTR
	.SetTimer:			DPTR
	.WaitForEvent:			DPTR
	.SignalEvent:			DPTR
	.CloseEvent:			DPTR
	.CheckEvent:			DPTR
	.InstallProtocolInterface:	DPTR
	.ReinstallProtocolInterface:	DPTR
	.UninstallProtocolInterface:	DPTR
	.HandleProtocol:		DPTR
	.Reserved:			DPTR
	.RegisterProtocolNotify:	DPTR
	.LocateHandle:			DPTR
	.LocateDevicePath:		DPTR
	.InstallConfigurationTable:	DPTR
	.LoadImage:			DPTR
	.StartImage:			DPTR
	.Exit:				DPTR
	.UnloadImage:			DPTR
	.ExitBootServices:		DPTR
	.GetNextMonotonicCount:		DPTR
	.Stall:				DPTR
	.SetWatchdogTimer:		DPTR
	.ConnectController:		DPTR
	.DisconnectController:		DPTR
	.OpenProtocol:			DPTR
	.CloseProtocol:			DPTR
	.OpenProtocolInformation:	DPTR
	.ProtocolsPerHandle:		DPTR
	.LocateHandleBuffer:		DPTR
	.LocateProtocol:		DPTR
	.InstallMultipleProtocolInterfaces:	DPTR
	.UninstallMultipleProtocolInterfaces:	DPTR
	.CalculateCrc32:		DPTR
	.CopyMem:			DPTR
	.SetMem:			DPTR
	.CreateEventEx:			DPTR
endstruc

%define EFI_RUNTIME_SERVICES_SIGNATURE		56524553544E5552h
%define EFI_RUNTIME_SERVICES_REVISION		EFI_SPECIFICATION_VERSION

struc EFI_RUNTIME_SERVICES
	.Hdr:				resb EFI_TABLE_HEADER_size
	.GetTime:			DPTR
	.SetTime:			DPTR
	.GetWakeupTime:			DPTR
	.SetWakeupTime:			DPTR
	.SetVirtualAddressMap:		DPTR
	.ConvertPointer:		DPTR
	.GetVariable:			DPTR
	.GetNextVariableName:		DPTR
	.SetVariable:			DPTR
	.GetNextHighMonotonicCount:	DPTR
	.ResetSystem:			DPTR
	.UpdateCapsule:			DPTR
	.QueryCapsuleCapabilities:	DPTR
	.QueryVariableInfo:		DPTR
endstruc

%define EFI_ACPI_20_TABLE_GUID			{0x8868e871,0xe4f1,0x11d3,0xbc,0x22,0x0,0x80,0xc7,0x3c,0x88,0x81}
%define ACPI_TABLE_GUID				{0xeb9d2d30,0x2d88,0x11d3,0x9a,0x16,0x0,0x90,0x27,0x3f,0xc1,0x4d}
%define SAL_SYSTEM_TABLE_GUID			{0xeb9d2d32,0x2d88,0x11d3,0x9a,0x16,0x0,0x90,0x27,0x3f,0xc1,0x4d}
%define SMBIOS_TABLE_GUID			{0xeb9d2d31,0x2d88,0x11d3,0x9a,0x16,0x0,0x90,0x27,0x3f,0xc1,0x4d}
%define MPS_TABLE_GUID				{0xeb9d2d2f,0x2d88,0x11d3,0x9a,0x16,0x0,0x90,0x27,0x3f,0xc1,0x4d}
%define EFI_ACPI_TABLE_GUID			{0x8868e871,0xe4f1,0x11d3,0xbc,0x22,0x0,0x80,0xc7,0x3c,0x88,0x81}
%define ACPI_10_TABLE_GUID			{0xeb9d2d30,0x2d88,0x11d3,0x9a,0x16,0x0,0x90,0x27,0x3f,0xc1,0x4d}
%define EFI_HARDWARE_ERROR_VARIABLE		{0x414E6BDD,0xE47B,0x47cc,0xB2,0x44,0xBB,0x61,0x02,0x0C,0xF5,0x16}

struc EFI_CONFIGURATION_TABLE
	.VendorGuid:			EFI_GUID
	.VendorTable:			DPTR
endstruc

%idefine EFI_TPL		UINTN
%define TPL_APPLICATION		4
%define TPL_CALLBACK		8
%define TPL_NOTIFY		16
%define TPL_HIGH_LEVEL		31

%define AllocateAnyPages	0
%define AllocateMaxAddress	1
%define AllocateAddress		0
%define MaxAllocateType		0

%define EfiReservedMemoryType	0
%define EfiLoaderCode		1
%define EfiLoaderData		2
%define EfiBootServicesCode	3
%define EfiBootServicesData	4
%define EfiRuntimeServicesCode	5
%define EfiRuntimeServicesData	6
%define EfiConventionalMemory	7
%define EfiUnusableMemory	8
%define EfiACPIReclaimMemory	9
%define EfiACPIMemoryNVS	10
%define EfiMemoryMappedIO	11
%define EfiMemoryMappedIOPortSpace	12
%define EfiPalCode		13
%define EfiMaxMemoryType	14

%define EFI_MEMORY_UC		1
%define EFI_MEMORY_WC		2
%define EFI_MEMORY_WT		4
%define EFI_MEMORY_WB		8
%define EFI_MEMORY_UCE		10h
%define EFI_MEMORY_WP		1000h
%define EFI_MEMORY_RP		2000h
%define EFI_MEMORY_XP		4000h
%define EFI_MEMORY_RUNTIME	8000000000000000h
%define EFI_MEMORY_DESCRIPTOR_VERSION 1

struc EFI_MEMORY_DESCRIPTOR
	.Type:				UINT32
	.PhysicalStart:			EFI_PHYSICAL_ADDRESS
	.VirtualStart:			EFI_VIRTUAL_ADDRESS
	.NumberOfPages:			UINT64
	.Attribute:			UINT64
endstruc

%define BS	8	; Backspace
%define TAB	9
%define LF	0Ah	; Line feed
%define CR	0Dh	; Carriage return
; Scan Codes for EFI_SIMPLE_TEXT_INPUT_PROTOCOL:
%define CURSOR_UP	1
%define CURSOR_DOWN	2
%define CURSOR_RIGHT	3
%define CURSOR_LEFT	4
%define HOME		5
%define END		6
%define INS		7
%define DEL		8
%define PAGE_UP		9
%define PAGE_DOWN	0Ah
%define FUNC_1		0Bh
%define FUNC_2		0Ch
%define FUNC_3		0Dh
%define FUNC_4		0Eh
%define FUNC_5		0Fh
%define FUNC_6		10h
%define FUNC_7		11h
%define FUNC_8		12h
%define FUNC_9		13h
%define FUNC_10		14h
%define ESC		17h
; Scan Codes for EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL:
%define FUNC_11		15h
%define FUNC_12		16h
%define FUNC_13		68h
%define FUNC_14		69h
%define FUNC_15		6Ah
%define FUNC_16		6Bh
%define FUNC_17		6Ch
%define FUNC_18		6Dh
%define FUNC_19		6Eh
%define FUNC_20		6Fh
%define FUNC_21		70h
%define FUNC_22		71h
%define FUNC_23		72h
%define FUNC_24		73h
%define MUTE		7Fh
%define VOL_UP		80h
%define VOL_DOWN	81h
%define BRIGHT_UP	100h
%define BRIGHT_DOWN	101h
%define SUSPEND		102h
%define HIBERNATE	103h
%define TOGGLE_DISP	104h
%define RECOVERY	105h
%define EJECT		106h

struc EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL
	.Reset:				DPTR
	.ReadKeyStrokeEx:		DPTR
	.WaitForKeyEx:			DPTR
	.SetState:			DPTR
	.RegisterKeyNotify:		DPTR
	.UnregisterKeyNotify:		DPTR
endstruc

struc EFI_SIMPLE_TEXT_INPUT_PROTOCOL
	.Reset:				DPTR
	.ReadKeyStroke:			DPTR
	.WaitForKey:			DPTR
endstruc

struc EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
	.Reset:				DPTR
	.OutputString:			DPTR
	.TestString:			DPTR
	.QueryMode:			DPTR
	.SetMode:			DPTR
	.SetAttribute:			DPTR
	.ClearScreen:			DPTR
	.SetCursorPosition:		DPTR
	.EnableCursor:			DPTR
	.Mode:				DPTR
endstruc

struc SIMPLE_TEXT_OUTPUT_MODE
	.MaxMode:			INT32
	.Mode:				INT32
	.Attribute:			INT32
	.CursorColumn:			INT32
	.CursorRow:			INT32
	.CursorVisible:			BOOLEAN
endstruc

%define EfiResetCold			0
%define EfiResetWarm			1
%define EfiResetShutdown		2