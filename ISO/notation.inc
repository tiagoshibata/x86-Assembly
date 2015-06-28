%macro BIG_ENDIAN_WORD 1
	db %1 >> 8
	db %1 & 0FFh
%endmacro

%macro BIG_ENDIAN_DWORD 1
	db %1 >> 24
	db (%1 >> 16) & 0FFh
	db (%1 >> 8) & 0FFh
	db %1 & 0FFh
%endmacro

%macro BOTH_ENDIAN_WORD 1
	dw %1
	BIG_ENDIAN_WORD %1
%endmacro

%macro BOTH_ENDIAN_DWORD 1
	dd %1
	BIG_ENDIAN_DWORD %1
%endmacro

%define MIXED_ENDIAN_DWORD		BOTH_ENDIAN_DWORD
%define MIXED_ENDIAN_WORD		BOTH_ENDIAN_WORD