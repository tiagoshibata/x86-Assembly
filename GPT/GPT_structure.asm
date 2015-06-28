db 'EFI PART'	; Signature
dd 10000h	; Revision
dd 93		; HeaderSize: 92 < HeaderSize < LBA size
dd HeaderCRC32	; HeaderCRC32 with this field = 0
dd 0		; Reserved
dq 1		; MyLBA
dq 0		; AlternateLBA
dq 0		; FirstUsableLBA
dq 0		; LastUsableLBA
dq 0, 0		; DiskGUID
dq 0		; PartitionEntryLBA (GPT)
dd 0		; NumberOfPartitionEntries
dd 0		; SizeOfPartitionEntry - The size, in bytes, of each the GUID Partition Entry structures in the GUID Partition Entry
; array. This field shall be set to a value of 128 x 2n where n is an integer greater than or equal
; to zero (e.g., 128, 256, 512, etc.). NOTE: Previous versions of this specification allowed any multiple of 8.
dd 0		; PartitionEntryArrayCRC32
times LogBlock_size-($-$$) db 0