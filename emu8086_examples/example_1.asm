; ah = 0, bx = cor_warn, dx = warn_position
#make_boot#    ; Arquivo bootavel
org 7c00h      ; localizacao em disco = 0000h:7C00h.

; INICIALIZACAO:
    ; muda segmento de dados:
    ;push    cs
    ;pop     ds

    ; modo de video 80x25:
    mov al, 03h
    int 10h    ;/0


    ; blinking desativado para rodar em DOS e no emulador:
    mov ax, 1003h
    int 10h     ; bx = 0, int 10h/0 = cores intensas


    ; PROGRAMA:

    lea bp,mensagem ; bp = posicao de mensagem na memoria.
    mov cx,mensagem_size
    mov ax,1301h
    mov bl,startup_color
    int 10h

    mov bx,warn_color

    ;PRINCIPAL:
    principal:
    ; move cursor:
    mov bh,0 ;page n
    mov dh,24 ;linha
    mov dl,0  ; coluna
    mov ah,2
    int 10h ;10h/2

    mov al,'>'
    mov ah,0Eh ;pede comando
    int 10h

    mov ah,0
    int 16h
    lea bp,teste
    mov cx,21
    call warn
    mov ah,05h
    mov al,0  ; page n = 1. unir p/ compilar al e ah.
    int 10h
    jmp principal
 ;REBOOT:

        lea bp,warn_message
        mov cx,warn_buffer_size
        call warn
        int 19h        ; interrupcao 19h = reiniciar




;###########################################################################################
;  CONSTANTES E VARIAVEIS:
;###########################################################################################

newl equ 13,10   ; codigo ASCII para nova linha e cursor na ponta da tela.
warn_color equ 00000001_1100_1001b ; page = 1, fonte azul, fundo vermelho.
warn_position equ 00000110_00000110b ; 03 e 03.

; define byte mensagem como array com frase ASCII, nova linha, outra frase e caractere nulo.
mensagem DB 'SO pequeno exemplo!', newl
         DB 'Digite "help" para visualizar uma lista de comandos.'

mensagem_size equ 73


warn_message DB 'Pressione algo...'
warn_buffer_size equ 17

teste db 'Ol',160,', isso ',130,' um teste!'

startup_color equ 80h

black equ 0h
blue equ 1h
green equ 2h
cyan equ 3h
red equ 4h
magenta equ 5h
brown equ 6h
light_gray equ 7h
dark_gray equ 8h
light_blue equ 9h
light_green equ 0Ah
light_cyan equ 0Bh
light_red equ 0Ch
light_magenta equ 0Dh
light_yellow equ 0Eh
light_white equ 0Fh



;###########################################################################################
;  PROCEDURES:
;###########################################################################################

warn proc  ; ponteiro em bp, tamanho da string em cx
    ;push cs
    ;pop es  ; es=cs?
    ;mov bl,warn_color        ; cor da fonte em high-byte, fundo em low-byte.
    ; http://www.emu8086.com/assembler_tutorial/8086_bios_and_dos_interrupts.html#attrib
    ;mov dx,warn_position     ; linha e coluna (high- e low- byte)

    mov dh,4   ; linha
    mov dl,4   ; coluna
    mov ax,1301h         ; ah = int (13), al = contem attr (bit 0 = atualizar cursor,
    ;bit 1 = atributos de cor)
    mov bh,1 ; page n
    int 10h              ; mostra string

    ; completar c/ espacos:
    add cx,8 ; espacos antes e depois do warn horizontalmente
    sub cx,80
    neg cx   ; cx = n de vezes p/ desenhar

    mov al,' '; completa c/ espacos

    mov ah,09h; desenha espacos
    int 10h



    mov ah,05h
    mov al,1  ; page n = 1. unir p/ compilar al e ah.
    int 10h

    mov ah,0             ; espera por tecla
    int 16h

    ret                  ; retorna controle ao programa
warn endp
