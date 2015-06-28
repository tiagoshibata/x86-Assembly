; TODO: Interleaved Mode,
; a-characters: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 _
              ; ! " % & ' ( ) * + , - . / : ; < = > ? space
; d-characters: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 _

; Directory depth limit = 8
; File path (file name + # of directories it's inside + directories names) size limit = 255
; Tamanho do caminho (nome do arquivo + n� de diret�rios sobre ele + tamanho dos nomes dos diret�rios) at� um arquivo n�o pode passar de 255 bytes:
; Example:
; ROOT -> SUBDIR1 -> SUBDIR2 -> YOURFILE.TXT;2
; File path of YOURFILE.TXT;2 = 4 (size of "ROOT" string) + 7 + 7 (sizes of "SUBDIR1" and "SUBDIR2" strings) +
;				14 (size of "YOURFILE.TXT;2" string) + 3 (# of directories it's inside)

; A file name MUST have a name or extension. It may have both. It must have a version number after the extension (';' followed by version number).
; A file name MUST use only d-characters. The size of name + extension + version number + 2 ('.' and ';') MUST be <= 32 bytes (without considering the dot).
; File version MUST be between 1 and 32767.
; Examples:
; Invalid files:
;	myfile.txt	; non-d-characters
;	MY_FILE!.TXT	; non-d-characters
;	MYFILE.TXT	; no version
;	.		; no name or extension
;	;3		; no name or extension
; Valid files:
;	MY_FILE.TXT;2	; version number = 2
;	.TXT;2		; has a extension and version number
;	MY_FILE;1	; name and version
; Directories must NOT have '.' or ';'. The size of a directory identifier must be <= 31 bytes.

; From the ECMA specification:
; 6.9.1  Order  of  Path Table  Records:
; The records in a Path Table shall be ordered by the following criteria in descending order of significance:
; -  in ascending order according to level in the directory hierarchy;
; -  in ascending order according to the directory number of the Parent Directory of the directory identified by
; the record;
; -  in ascending order according to the relative value of the Directory Identifier field in the record, where the
; Directory Identifiers shall be valued as follows:
; . If the two Directory Identifiers do not contain the same number  of  byte positions, the shorter Directory
; Identifier shall be treated as if it were padded on the right with all padding bytes set to (20), and as if both
; Directory Identifiers contained the identical number of byte positions.
; . After any padding necessary to treat the Directory Identifiers as if they were of equal length, the characters
; in the corresponding byte positions, starting with the first position, of the Directory Identifiers are compared
; until a byte position is found that does not contain the same character  in  both Directory Identifiers. The
; greater Directory Identifier is the one that contains the character with the higher code position value in the
; coded graphic character sets used to interpret the Directory Identifier of the Path Table Record.

; 9.3 Order of Directory Records
; The records of a Directory shall be ordered according to the relative value of the File Identifier field by the
; following criteria in descending order of significance:
; - In ascending order according to the relative value of File Name, where File Names shall be valued as follows:
; . If two File Names have the same content in all byte positions, then these two File Names are said to be equal
; in value.
; . If two File Names do not contain the same number of byte positions, the shorter File Name shall be treated as
; if it were padded on the right with all padding bytes set to (20) and as if both File Names contained the
; identical number of byte positions.
; . After any padding necessary to treat the File Names as if they were of equal length, the characters in the
; corresponding byte positions, starting with the first position, of the File Names are compared until a byte
; position is found that does not contain the same character in both File Names. The greater File Name is the
; one that contains the character with the higher code position value in the coded graphic character sets used to
; interpret the File Identifier field of the Directory Record.
; - in ascending order according to the relative value of File Name Extension, where File Name Extensions shall be
; valued as follows:
; . If two File Name Extensions have the same content in all byte positions, then these two File Name
; Extensions are said to be equal in value.
; . If two File Name Extensions do not contain the same number of byte positions, the shorter File Name
; Extension shall be treated as if it were padded on the right with all padding bytes set to (20) and as if both
; File Name Extensions contained the identical number of byte positions.
; . After any padding necessary to treat the File Name Extensions as if they were of equal length, the characters
; in the corresponding byte positions, starting with the first position, of the File Name Extensions are
; compared until a byte position is found that does not contain the same character in both File Name
; Extensions. The greater File Name Extension is the one that contains the character with the higher code
; position value in the coded graphic character sets used to interpret the File Identifier field of the Directory
; Record.
; - in descending order according to the relative value of File Version Number, where File Version Numbers shall
; be valued as follows:
; . If two File Version Numbers have the same content in all byt~6 positions, then these two File Version
; Numbers are said to be equal in value.
; . If two File Version Numbers do not contain the same number of byte positions, the shorter File Version
; Number shall be treated as if it were padded on the left with all padding bytes set to (30) and as if both File
; Version Numbers contained the identical number of byte positions.
; . After any padding necessary to treat the File Version Numbers as if they were of equal length, the characters
; in the corresponding byte positions, starting with the first position, of the File Version Numbers are
; compared until a byte position is found that does not contain the same character in both File Version
; Numbers. The greater File Version Number is the one that contains the character with the higher code
; position value in the coded graphic character sets used to interpret the File Identifier field of the Directory
; Record.
; - in descending order according to the value of the Associated File bit of the File Flags field.
; - The order of the File Sections of the file.


%include 'notation.inc'
; Date and time for files:
%defstr DATE_STR		__DATE_NUM__
%defstr TIME_STR		__TIME_NUM__
%define DATE_NUM		__DATE_NUM__
%define TIME_NUM		__TIME_NUM__
%define HUND_SEC		'00'
%define GREENWICH_OFST		0					; Precision of 15 minutes

%define SYS_ID			'EXAMPLE OPERATING SYSTEM SECTORS'	; a-characters, identifies the system using the first 16 sectors
%define VOLUME_NAME		'EXAMPLE_SYSTEM_INSTALLER_CD_ROM_'	; d-characters, identifies the volume
; 128 d-characters
%define VOLUME_SET_NAME		'EXAMPLE_OPERATING_SYSTEM________VERSION__00_00_01________TYPE__BETA________VERSION_NAME__CHILD__________________________________'
; The following three field use d-characters. If you won't use these fields, set all bytes to 20h. If the data doesn't fit 128 bytes, use 5Fh, followed by the
; name of a 8.3 file in the root directory. This file will have the corresponding information.
%define PUBLISHER_ID		'TIAGO_SHIBATA___________________________________________________________________________________________________________________'
%define DATA_PREPARER_ID	PUBLISHER_ID
%define VOLUME_DATA		'EXAMPLE_OPERATING_SYSTEM____SIMPLE_EXAMPLE_OF_ISO_BOOTABLE_IMAGE_________CC_BY_NC_SA_3_0________________________________________'
; The following three fields are files with the corresponding data. All bytes = 20h mean none. Max. 8 bytes for name and 3 for extension.
%define NO_FILE 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, \
	20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h
%define LICENCE			'LICENCE.TXT                          '		; 37 bytes
%define ABSTRACT_DATA		NO_FILE
%define BIBLIOGRAPHIC_DATA	NO_FILE
%define BOOTABLE		; if defined, the disk is bootable
%define BOOT_CD_CREATOR		'TIAGO SHIBATA'				; a-characters
%define CHECKSUM		-(0AA56h + 'TI' + 'AG' + 'O ' + 'SH' + 'IB' + 'AT' + 'A') & 0FFFFh ; boot catalogue checksum

%macro DEFINE_PATH_TABLE 0	; the directory path table:
	PATH_ENTRY ROOT, 1, FFLAGS.ROOT		; root dir (entry 1)
	PATH_ENTRY ANOTHER_DIR, 1, 'ANOTHER_DIR'; inside entry 1 (root). This is entry 2
 	PATH_ENTRY TEST_DIR, 1, 'TEST_DIR'	; inside entry 1 (root). This is entry 3
 	PATH_ENTRY ONE_MORE_DIR, 3, 'ONE_MORE_DIR';inside entry 3 (TEST_DIR). This is entry 4
%endmacro

%macro SYS_1 0	; 16 sectors with 2048 bytes each to system usage. I put the bootloader here (but it can be put anywhere. If you wish, you can include it as a file, too)
	BOOTL 'bootloader.bin'
%endmacro

%macro APP_1 0	; 512 bytes to aplication usage
%endmacro

%include 'OS.iso.inc'

S_DIR ROOT,ROOT ; root dir is inside itself
 	ENTRY ANOTHER_DIR, FFLAGS.DIR, 'ANOTHER_DIR'
	ENTRY LIC, 0, 'LICENCE.TXT;1'
 	ENTRY TEST_DIR, FFLAGS.DIR, 'TEST_DIR'
E_DIR

S_DIR ANOTHER_DIR, ROOT

E_DIR

S_DIR TEST_DIR,ROOT
	ENTRY TXT, 0, 'FILE.TXT;1'
	ENTRY ONE_MORE_DIR, FFLAGS.DIR, 'ONE_MORE_DIR'
E_DIR

S_DIR ONE_MORE_DIR,TEST_DIR
E_DIR

FILE LIC, 'image_files/LICENCE.TXT'
FILE TXT, 'image_files/FILE.TXT'

EOF:
