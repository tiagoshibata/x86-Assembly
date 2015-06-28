#make_boot#    ; Arquivo bootavel
#cs=0#
#ip=7c00#

gotoxy  macro   col, row ; vai para linha e coluna. Usa ax, bx, dx.
        push    ax
        push    bx
        push    dx
        mov     ah, 02h
        mov     dh, row
        mov     dl, col
        mov     bh, 0
        int     10h
        pop     dx
        pop     bx
        pop     ax
endm

putc macro char
        mov AL,char
        mov AH,0Eh
        int 10h
        mov AH,0    ; este programa usa apenas 0 em AH.
endm

full_arg_print macro position, color, ssize, attr ;ponteiro em bp
    ;push cs
    ;pop es  ; es=cs?
    mov bl,color        ; cor da fonte em high-byte, fundo em low-byte.
    ; http://www.emu8086.com/assembler_tutorial/8086_bios_and_dos_interrupts.html#attrib
    mov cx,ssize        ; tamanho (chars)
    mov dx,position     ; linha e coluna (high- e low- byte)
    mov ax,attr         ; ah = int (13), al = contem attr (bit 0 = atualizar cursor,
    ;bit 1 = atributos de cor.
    int 10h
endm






; INICIALIZACAO:

    org 7c00h      ; localizacao em disco = 0000h:7C00h.

    ; muda segmento de dados:
    push    cs
    pop     ds


    ; modo de video 80x25:
    mov ah, 00h
    mov al, 03h
    int 10h


    ; blinking desativado para rodar em DOS e no emulador:
    mov ax, 1003h
    int 10h     ; bx = 0, int 10h/0

    mov dx,warn_position
    lea bp,mensagem1 ; SI = posicao de mensagem na memoria.
    mov cx,mensagem1_size
    call warn
    inc dh
    lea bp,mensagem2
    mov cx,mensagem2_size
    call warn
    mov ah,0
    int 16h





 ;REBOOT:
        lea bp,reboot_message
        mov cx,reboot_msg_size
        call warn
        mov AH,0       ; AH = 0
        int 16h        ; interrupcao 16h com AH = 0 recebe um caractere do teclado
        int 19h        ; interrupcao 19h = reiniciar




;###########################################################################################
;  CONSTANTES E VARIAVEIS:
;###########################################################################################

newl equ 13,10   ; codigo ASCII para nova linha e cursor na ponta da tela.
warn_color equ 1100_1001b ; fonte azul, fundo vermelho.
warn_position equ 0011_0011b ; 03 e 03.

; define byte mensagem como array com frase ASCII, nova linha, outra frase e caractere nulo.
mensagem1 DB 9,'SO pequeno exemplo!',9
mensagem2 DB 9,'Digite "help" para visualizar uma lista de comandos.',9
mensagem3 DB 9,'Pressione qualquer tecla para continuar...',9

mensagem1_size equ 21
mensagem2_size equ 54
mensagem3_size equ 44


reboot_message DB newl,newl,'Remova o CD/Disquete do SO e pressione qualquer tecla para reiniciar...'
reboot_msg_size equ 75



;###########################################################################################
;  PROCEDURES:
;###########################################################################################

warn proc  ; ponteiro em bp, tamanho da string em cx, posicao em dx
    ;push cs
    ;pop es  ; es=cs?
    mov bl,warn_color        ; cor da fonte em high-byte, fundo em low-byte.
    ; http://www.emu8086.com/assembler_tutorial/8086_bios_and_dos_interrupts.html#attrib
    ; linha e coluna (high- e low- byte)
    mov ax,1301h         ; ah = int (13), al = contem attr (bit 0 = atualizar cursor,
    ;bit 1 = atributos de cor.
    int 10h
    mov ah,0
    int 16h
warn endp
