;APM -> interrupções 15h, ah = 53h
%define APM_int_n			53h << 8
%define INSTALL_CHECK		0 | APM_int_n
%define CON_INTERF_REAL		1 | APM_int_n
%define CON_INTERF_16_PMODE	2 | APM_int_n
%define CON_INTERF_32_PMODE	3 | APM_int_n
%define APM_DISCON			4 | APM_int_n
%define SET_STATE			7 | APM_int_n
%define SET_POWER_MANAG		8 | APM_int_n
%define APM_NOT_CON_ERROR	3
%define ALL_DEVICES			1
%define POWER_MANAG_ON		1
%define STATE_STANDBY		1
%define STATE_SUSPEND		2
%define STATE_OFF			3

%macro string 1
	db %1, 0
%endmacro

[org 0h]
[bits 16]
cli
cld
xor ah, ah
int 16h

;seta 80x25
mov ax,3
int 10h

push cs
pop ds

;Informações do controlador:
mov ax, 4F00h
xor di, di
mov es, di
mov di, VbeInfoBlock + 7C00h
int 10h
cmp ax, 4Fh
jne no_VESA
cmp dword [VbeInfoBlock.VbeSignature], 'VESA'
jne no_VESA

mov di, 0B800h
mov es, di
xor di, di
mov ss, di
mov sp, 7C00h
mov esi, s.VESA_ok
call print
mov si, VbeInfoBlock.VbeVersion
call print_BCD
call nl

mov si, s.GPU_name_family
call print
push ds
lds si, [VbeInfoBlock.OemStringPtr]
call print
call nl
pop ds

mov si, s.color_q
call print
mov cl, [VbeInfoBlock.Capabilities + 3]
test cl, 1
jz q6_only
	inc si
	call print
q6_only:
call nl

mov si, s.VGA_comp
call print
test cl, 10b
jnz no_comp
	mov si, s.yes
	jmp EO_VGA_comp
no_comp:
	mov si, s.no
EO_VGA_comp:
call print
call nl

mov si, s.scr_blank
call print
test cl, 100b
jz no_scr_blanking
	mov si, s.yes
	jmp EO_scr_blanking
no_scr_blanking:
	mov si, s.no
EO_scr_blanking:
call print
call nl

mov si, s.stereo_3D
call print
test cl, 1000b
jz no_stereo_3D
	mov si, s.yes
	call print
	call nl
	mov si, s.VESA_stereo_3D
	call print
	test cl, 10000b
	jz no_VESA_stereo_3D
		mov si, s.yes
		jmp EO_stereo_3D
	no_VESA_stereo_3D:
		mov si, s.no
	jmp EO_stereo_3D
no_stereo_3D:
	mov si, s.no
EO_stereo_3D:
call print
call nl

mov si, s.total_mem
call print
xor eax, eax
mov ax, [VbeInfoBlock.TotalMemory]
shl eax, 6
call print_eax
call nl

mov si, s.Softw_rev
call print
mov si, VbeInfoBlock.OemSoftwareRev
call print_BCD
call nl

mov si, s.vendor
call print
push ds
lds si, [VbeInfoBlock.OemVendorNamePtr]
call print
call nl
pop ds

mov si, s.product_name
call print
push ds
lds si, [VbeInfoBlock.OemProductNamePtr]
call print
call nl
pop ds

mov si, s.product_rev
call print
push ds
lds si, [VbeInfoBlock.OemProductRevPtr]
call print
call nl
pop ds

; mov bp, ds
; lds si, [VbeInfoBlock.VideoModePtr]
; lodsw
; cmp ax, -1
; xchg ds, bp
; jne VESA_modes_ok
	; mov si, s.no_modes
	; jmp shutdown
; VESA_modes_ok:
; mov si, s.press_key

; show_mode:
	; call print
	; xor cx, cx
	; mov es, cx
	; mov di, ModeInfoBlock + 7C00h
	; mov cx, ax
	; mov ax, 4F01h
	; int 10h
	; cmp ax, 4Fh
	; jne .ok
		; mov si, s.error_mode_test
		; jmp shutdown
	; .ok:
	; xor ah, ah
	; int 16h
	; xchg ds, bp
	; lodsw
	; xchg ds, bp
	; cmp ax, -1
; jne show_mode


shutdown:
call print
xor ah, ah
int 16h

;Testa se há APM:
mov ax, INSTALL_CHECK	;0 = installation check
xor bx, bx				;ID do dispositivo (0 = APM BIOS)
int 15h
jnc APM_supported
	mov si, APM_not_supported_msg
	jmp exit
APM_supported:
mov si, APM_supported_msg
call print
call nl
;Conecta em interface para Real Mode:
mov ax, CON_INTERF_REAL
xor bx, bx
int 15h
jnc realmode_interface_ok
	mov si, no_realmode_interf_msg
	jmp exit
realmode_interface_ok:
mov si, realmode_interf_ok_msg
call print
call nl
;Ativa Power Management para todos os dispositivos conectados:
mov ax, SET_POWER_MANAG
mov bx, ALL_DEVICES
mov cx, POWER_MANAG_ON
int 15h
jnc set_pm_ok
	mov si, pm_set_failed_msg
	jmp exit
set_pm_ok:
mov si, pm_set_msg
call print
call nl
xor ah, ah
int 16h
;Muda estado:
mov ax, SET_STATE
mov bx, ALL_DEVICES
mov cx, STATE_OFF	;OFF, SUSPEND ou STANDBY
int 15h

exit:
call print
stop:
hlt
jmp stop

no_VESA:
	mov si, s.no_VESA
	jmp shutdown
	
s:
	.no_VESA			db 'VESA not supported', 0
	.VESA_ok			db 'VESA Version - ', 0
	.GPU_name_family	db 'GPU name/family: ', 0
	.color_q			db 'Color Quality: 6bpp', 0
	.c8bpp				db '/8bpp', 0
	.VGA_comp			db 'VGA compatible:', 0
	.no					db ' No', 0
	.yes				db ' Yes', 0
	.scr_blank			db 'Screen blanking required:', 0
	.stereo_3D			db 'Stereoscopic 3D support:', 0
	.VESA_stereo_3D		db 'Stereo 3D support in VESA Controller:', 0
	.total_mem			db 'Total Video Memory (Kb): ', 0
	.Softw_rev			db 'Software Revision: ', 0
	.vendor				db 'Vendor: ', 0
	.product_name		db 'Product Name: ', 0
	.product_rev		db 'Product Revision: ', 0
	.no_modes			db 'No Video Modes supported!', 0
	.press_key			db 'Press any key to a video mode...', 0
	.error_mode_test	db 'Error testing VESA mode!', 0

print:
	lodsb
	stosb
	inc di
	test al, al
	jnz print
ret

print_BCD:
	lodsb
	add al, 30h
	stosb
	;inc di
	mov byte [es:di + 1], '.'
	add di, 3
	lodsb
	add al, 30h
	stosb
	inc di
ret

print_eax:
	mov ebx, 10
	xor cx, cx
	.loop_div:
		xor edx, edx
		div ebx ;edx:eax /= ebx, eax = resultado, edx = sobra
		push dx
		inc cx
		test ax, ax
	jnz .loop_div
	.loop_print:
		pop ax
		add al, 30h
		stosb
		inc di
	loop .loop_print
ret

nl:
	mov ax, di
	mov bl, 80
	div bl ;ax /= bl, al = resultado, ah = sobra
	sub bl, ah
	xor bh, bh
	add di, bx
ret

startup_msg				string ">>> APM Initialization and State Setting <<<"
APM_not_supported_msg	string "APM not supported!"
APM_supported_msg		string "APM supported!"
no_realmode_interf_msg	string "No APM Real Mode interface!"
realmode_interf_ok_msg	string "APM Real Mode interface OK!"
pm_set_msg				string "Power Management set for all devices!"
pm_set_failed_msg		string "Failed to set Power Management!"
state_set_failed_msg	string "Setting State failed!"
state_set_ok_msg		string "Setting State worked!"

VbeInfoBlock:
	.VbeSignature		db 'VBE2';Retorna 'VESA' se suportado
	.VbeVersion			resw 1	;Valor BCD, 0300h para 3.0, 0102h para 1.2, etc.
	.OemStringPtr		resd 1	;VbeFarPtr para OEM null terminated String, usada para identificar placa de vídeo e/ou família da placa de vídeo.
								;Aponta para RAM ou ROM. Em VBE 3.0, pode estar em OemData.
	.Capabilities 		resb 4	;Capacidades do controlador.
								;Bit 0 = 0 se apenas 6 bits por cor são suportados, 1, se suporta 6 e 8 bits (iniciando qualquer mdo em 6 bits por padrão).
								;Bit 1 = 0 se controlador é compatível com VGA
								;Bit 2 = 1 para setar bit de correção de branqueamento de tela na função 9h (em controladores antigos)
								;Bit 3 = 1 para 3D stereoscópio por hardware suportado.
								;Bit 4 = 1 para sinal stereoscópio suportado por VESA EVC. Se bit 3 = 1 e bit 4 = 0, 3D stereoscópio é suportado
								;por um controlador externo.
	.VideoModePtr		resd 1	;VbeFarPtr para VideoModeList (cada modo = word, lista acaba em -1). VBE 3.0 pode salvar na área reservada.
								;Se a lista começa em -1, VBE não é suportado, apenas função 0h.
								;Antes de setar um modo, se deve testá-lo com a função 1h, para checar se memória é suficiente e é suportado pelo monitor.
	.TotalMemory		resw 1	;Memória de vídeo / 64Kb
	;Added for VBE 2.0+
	.OemSoftwareRev 	resw 1	;Versão VBE em BCD, apenas com assinatura = 'VBE2'
								;OemVendorNamePtr, OemProductNamePtr e OemProductRevPtr devem ter menos que 256 bytes para caberem em OemData se nescessário.
	.OemVendorNamePtr 	resd 1	;VbeFarPtr para vendedor, apenas com assinatura = 'VBE2'
	.OemProductNamePtr 	resd 1	;VbeFarPtr para nome da placa, apenas com assinatura = 'VBE2'
	.OemProductRevPtr 	resd 1	;VbeFarPtr para revisão/versão da placa, apenas com assinatura = 'VBE2'
	.Reserved			resb 222 ;Reservado para lista de modos de vídeo se nescessário.
	.OemData			resb 256 ;Reservado para Strings se nescessário.

ModeInfoBlock: