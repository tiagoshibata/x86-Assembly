%define CLUSTER_SIZE		BYTES_PER_SECTOR * SECTORS_PER_CLUSTER
%define TIME			(SECOND >> 1) | (MINUTE << 5) | (HOUR << 11)
%define DATE			DAY | (MONTH << 5) | ((YEAR - 1980) << 9)
%define CLUSTER_NUMBER(x)	(x) / CLUSTER_SIZE - RESERVED_SECTORS	; physical position to cluster number

%macro FILE 2-3		; file name, pointer, attributes
	%xdefine POS		1
	%strlen size		%1
	%rep 8					; define 8 bytes for the name
		%ifdef %%name_ended		; the name has ended (no extension or dot found?)
			db ' '			; pad with spaces
		%else
			%if (POS > size)	; if we found the end of the name + extension string (no extension)
				%if (POS == 1)	; if there's no name, %error
					%error Files must have names!
				%endif
				%define %%name_ended	; found the end!
				db ' '			; pad with spaces
			%else
				%substr char %1 POS	; else, get next char
				%if (char == '.')	; if dot..
					%if (POS == 1)	; if there's no name, error
						%error Files must have names!
					%endif
					%define %%name_ended	; found the end!
					db ' '			; pad with spaces
				%else
					db char		; else, define the char
				%endif
			%endif
			%xdefine POS	POS+1		; advance string position
		%endif
	%endrep
	%ifndef %%name_ended			; if the name is bigger than 8 bytes and we haven't found a dot...
		%if (size != 8)
			%substr char %1 POS	; check if next char is a dot; if not, name is > than 8 bytes (%error)
			%if (char != '.')
				%error Filenames must be smaller than or equal to 8 bytes!
			%endif
			%xdefine POS POS+1
		%endif
	%endif
	%xdefine ext_size (size-(POS)+1)	; get extension size (total size - name size + 1) (when we scan the name, POS points to the char >after< the dot,
 	%if (ext_size > 3)			;							that's why I add 1)
 		%fatal Extensions must be smaller than or equal to 3 bytes!	; if extension is bigger than 3 bytes, %fatal
 	%endif
	%substr extension %1 POS ext_size	; get extension
	%%ext_start:
	db extension
	%%ext_end:
	times (3 - (%%ext_end - %%ext_start)) db ' '	; pad with spaces
	%if (%0 == 3)
		db %3					; attributes
	%else
		db 0
	%endif
	db 0					; reserved
	db SECOND_100				; creation time in 1/100 seconds
	dw TIME					; creation time
	dw DATE					; creation date
	dw DATE					; access date
	dw 0					; first cluster (high bits)
	dw TIME					; last modification time
	dw DATE					; last modification date
	dw CLUSTER_NUMBER(%2 - $$)		; low bits of cluster number
	dd %2.end - %2				; file size
%endmacro
%macro DIR 2-3
	.start:
	%%start:
	db %1
	%%end:
	times 11 - (%%end-%%start) db ' '
	%if (%0 == 3)
		db %3 | F.SUBDIR		; attributes
	%else
		db F.SUBDIR
	%endif
	db 0					; reserved
	db SECOND_100				; creation time in 1/100 seconds
	dw TIME					; creation time
	dw DATE					; creation date
	dw DATE					; access date
	dw 0					; first cluster (high bits)
	dw TIME					; last modification time
	dw DATE					; last modification date
	dw CLUSTER_NUMBER(%2 - $$)		; low bits of cluster number
	dd 0					; file size
%endmacro
%macro DIR_END 0
	align CLUSTER_SIZE, db 0
%endmacro
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
%macro INC_FILE 1
	incbin %1
	.end:
	DIR_END
%endmacro

SOF:
jmp short start	; cs and ip are undefined, so we use a short jump
nop
db OEM_ID
dw BYTES_PER_SECTOR		; bytes per setor
db SECTORS_PER_CLUSTER		; sectors per cluster
dw RESERVED_SECTORS		; reserved sectors before FAT 1
db NUMBER_FATS			; number of FATs
dw ROOT_DIRS			; number of root entries
dw ((IMAGE_SIZE) + 511) / 512	; number of clusters
db MEDIA			; media type
%if (FAT_LOG_SECTORS <= 0FFFFh)
	dw FAT_LOG_SECTORS
%else
	dw 0
%endif
dw SECTORS_PER_TRACK
dw HEADS_PER_DISK
dd HIDDEN_SECTORS
%if (FAT_LOG_SECTORS > 0FFFFh)
	dd FAT_LOG_SECTORS	; used only if > 0FFFh (usar se a word de setores lógicos acima for insuficiente)
%else
	dd 0
%endif
db BIOS_DRIVE_NUMBER
db 0				; reserved
db 29h				; extended boot signature
dd SERIAL			; # serial
db LABEL			; label
db 'FAT12   '			; FS

start:
incbin BOOTLOADER
times (510-($-$$)) db EMPTY
dw 0AA55h

; More data to reserved sectors here:

; End of reserved sectors!
times RESERVED_SECTORS * BYTES_PER_SECTOR - ($-$$) db EMPTY



FAT:
WRITE_FAT
.end:
%define FAT_PAD	(FAT_LOG_SECTORS * CLUSTER_SIZE - (.end-FAT))
times FAT_PAD db 0
%rep NUMBER_FATS - 1
	WRITE_FAT
	times FAT_PAD db 0
%endrep
