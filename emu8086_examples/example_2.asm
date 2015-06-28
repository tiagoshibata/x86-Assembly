; substituir cmp por loop
; memory table (hex):               |
; ----------------------------------|
; 07c0:0000         |   boot        |
; 07c0:01ff         |   (512 bytes) |
; ----------------------------------|
; 07c0:0200 (32256) |    stack      |
; 07c0:03ff (32767) |   (255 words) |
; ----------------------------------|
; 0800:0000 (32768) |memoria de     |
;    ...            |programas      |
; ----------------------------------|

%macro teletype_putc 0
    mov al,%1
    mov ah,0Eh
    int 10h
%endmacro

%macro setup_screen 0
        ; modo de video 80x25:
        mov al, 03h
        int 10h;/0

        mov ax,700h;desce texto(ah=07h)
        ;al=0(desce tudo)
        mov bh, background_color ; atributo
        ;mov cx,0 ;ch=linha topo,cl=coluna topo
        mov dx,0001_1000_0100_1111b;dh=ultima linha,dl=ultima coluna
        int 10h

        ;desce 2 linhas:
        mov al,2
        mov bh,startup_color
        int 10h;/07h

        ;sobe 1 linha (comando):
        mov ch,linhas-1
        mov ax,601h;ah=06h,al=1
        mov bh,prompt_color
        int 10h

        ; set cursor position to top
        ; of the screen:
        ;mov bh,0;current page.
        ;mov dx,0;dl=coluna,dh=linha
        ;mov ah,02
        ;int 10h
%endmacro

org 7c00h      ; localizacao em disco = 0000h:7C00h.

setup_screen

; inicializa stack (SS:SP; segmento:offset):
mov     ax, 07c0h
mov     ss, ax   ;segmento
mov     sp, 03feh ;offset do topo

; INICIALIZACAO:

    ; blinking desativado para rodar em DOS e no emulador:
    ;mov ax, 1003h
    ;int 10h     ; bx = 0, int 10h/0 = cores intensas


    ; PROGRAMA:
    xor dx,dx;linha,coluna
    mov bp,mensagem ; bp = posicao de mensagem na memoria.
    mov cx,mensagem_size
    mov ax,1301h
    mov bx,startup_color
    int 10h

    ; move cursor:
    ;mov bh,0 ;page n

    ;mov dh,24 ;linha
    ;mov dl,0  ; coluna
    mov dx,1800h
    mov ah,2
    int 10h;10h/2

    ;mov al,'>'
    ;mov ah,0Eh
    mov ax,0E3Eh
    int 10h

    ;PRINCIPAL:
    principal:
    ; move cursor:
    ;mov dh,24 ;linha
    ;mov dl,1  ; coluna
    xor bh,bh;page n
    mov dx,1801h
    mov ax,200h;ah=2,al=0
    int 10h;10h/2
    ;apaga comando antigo:
    ;mov al,0;null
    mov cx,1;desenha 1 vez

    mov ah,0Ah
    int 10h
    xor si,si;nenhum char no buffer
    get_keys_loop:

    mov ah,00h
    int 16h   ;pega tecla em al

    cmp al,13
    je enter_pressed
    cmp al,8
    je principal;back = 8 ASCII
    cmp si,0
    jne get_keys_loop;buffer cheio - retorna
    mov si,ax;si=ax(ah=Scan code da BIOS,al=char)
    mov ah,0Eh
    int 10h;mostra ASCII em al
    jmp get_keys_loop

    enter_pressed:
    ;or si,00000000_0110_0000b;converte para minuscula
    or si,11111111_0110_0000b

    cmp si,11111111_01100010b;b
    je boot

    cmp si,11111111_01110010b;r
    je reboot

    cmp si,11111111_01100001b;a
    je about

    cmp si,11111111_01100011b;c
    je clear_log

    mov di,invalido_size
    mov bp,invalido
    mov al,2;linhas
    jmp add_log

  ;Boot:
  boot:
  jmp principal

  reboot:
  int 19h

  about:
  mov di,about_size
  mov bp,about_message
  mov al,about_lines
  jmp add_log


  clear_log:
   mov al,linhas-2
   mov bh,background_color
   mov cx,200h
   mov dx,174Fh
   mov ah,06h
   int 10h
   jmp principal

  add_log:
    mov bh,background_color
    mov cx,200h
    mov dx,174Fh

    mov ah,06h ;sobe janela
    int 10h

    ;mostra string:
    mov dx,00011000_00000000b;dh=linhas,dl=0
    sub dh,al
    mov bx,background_color
    mov cx,di

    mov ax,00010011_00000001b
    int 10h    ;mostra string!

    ;se "about":
    cmp si,11111111_01100001b
    jne linha
    int 12h;recebe memoria em ax
    xor cl,cl;n de algarismos
    mov bx,10
    start_loop_64:

    inc cl
    xor dx,dx ;zera segmento
    div bx;dx:ax /= 10.ax=divisao,dx=resto

    push dx
    cmp ax,0
    jne start_loop_64

    print_loop_64:
    pop ax
    add al,30h
    mov ah,0Eh;teletype print
    int 10h
    loop print_loop_64


    linha:
    ;teletype_putc 13
    ;teletype_putc 10;pula linha
    mov ax,00001110_00001101b
    int 10h
    mov al,10
    int 10h

    ;xor bh,bh   ;page n
    mov cx,colunas;n de vezes p desenhar

    mov ax,00001010_11001101b
    int 10h  ;desenha na tela


   jmp principal




;###########################################################################################
;  CONSTANTES E VARIAVEIS:
;###########################################################################################

%define newl 13,10   ; codigo ASCII para nova linha e cursor na ponta da tela.
warn_color equ 00000001_1100_1001b ; page = 1, fonte azul, fundo vermelho.
warn_position equ 00000110_00000110b ; 03 e 03.

; define byte mensagem como array com frase ASCII, nova linha, outra frase e caractere nulo.
mensagem db 'Bem-vindo ao OpenASMOS, o sistema operacional em assembly em c',162,'digo aberto!'
         db newl,'Digite "h" para ver uma lista de comandos ou "b" para iniciar o sistema.'

mensagem_size equ 149

startup_color equ 0001_1010b ;azul + verde
background_color equ 0000_1110b ;preto + amarelo
prompt_color equ 0001_1111b ;azul + branco

;black equ 0h
;blue equ 1h
;green equ 2h
;cyan equ 3h
;red equ 4h
;magenta equ 5h
;brown equ 6h
;light_gray equ 7h
;dark_gray equ 8h
;light_blue equ 9h
;light_green equ 0Ah
;light_cyan equ 0Bh
;light_red equ 0Ch
;light_magenta equ 0Dh
;light_yellow equ 0Eh
;light_white equ 0Fh

; int 10h, 13h
;attr equ 00h ;atributo em bl
;attr_update_cursor equ 01h

; resolucao em 80x25
linhas equ 18h
colunas equ 50h

about_message db 201
		times 11 db 205
		db 187,newl
              db 186,' OpenASMOS ',186,newl
              db 200
              times 11 db 205
              db 188,newl
              db 'Vers',198,'o:        | Beta',newl
              db 'Mem',162,'ria RAM:   | '
about_size equ 85
about_lines equ 6

invalido db 'Comando inv',160,'lido!'
invalido_size equ 17


;###########################################################################################
;  PROCEDURES:
;###########################################################################################

;warn proc  ; ponteiro em bp, tamanho da string em cx
;
;    ;seta cursor:
;    mov dh,4  ;linha
;    mov dl,4  ;coluna
;    mov bh,1  ;page n
;    mov ah,2  ;int n
;    int 10h
;
;    ; linha antes da string:
;    push cx
;    mov al,' ';char
;    mov cx,72  ;desenhar 72 vezes
;    mov bh,1  ;page n
;    mov ah,09h
;    int 10h
;    pop cx
;
;    ;atualizar cursor ou calcular posicao?
;    mov dh,5   ; linha
;    mov dl,5   ; coluna
;    mov ah,13h
;    mov al,01h ; ah = int (13), al = contem attr (bit 0 = atualizar cursor,
;    ;bit 1 = atributos de cor)
;    ;mov ax,1301h
;    mov bh,1 ; page n
;    int 10h              ; mostra string
;
;    ; completar c/ espacos:
;    add cx,9 ; espacos antes e depois do warn horizontalmente
;    sub cx,80
;    neg cx   ; cx = n de vezes p/ desenhar
;
;    mov al,' '; completa c/ espacos
;
;    mov ah,09h; desenha espacos
;    int 10h
;
;
;
;    mov ah,05h
;    mov al,1  ; page n = 1. unir p/ compilar al e ah.
;    int 10h
;
;    mov ah,0             ; espera por tecla
;    int 16h
;
;    ret                  ; retorna controle ao programa
;warn endp



;add_log proc near  ; ponteiro em bp, tamanho da string em di, al=n de linhas do texto
;    ;pular linhas e mostrar string ou mostrar char por char?
;    mov bh,background_color
;    ;mov ch,2;linha inicial
;    ;xor cl,cl;coluna inicial
;    mov cx,200h
;    ;mov dh,17h;n total de linhas
;    ;mov dl,4Fh ;n total de colunas
;    mov dx,174Fh
;
;    mov ah,06h ;sobe janela
;    int 10h
;
;    ;mostra string:
;    mov dx,00011000_00000000b;dh=linhas,dl=0
;    sub dh,al
;    mov bx,background_color
;    mov cx,di
;
;    mov ax,00010011_00000001b
;    int 10h    ;mostra string!
;
;    ;teletype_putc 13
;    ;teletype_putc 10;pula linha
;    mov ax,00001110_00001101b
;    int 10h
;    mov al,10
;    int 10h
;
;    xor bh,bh   ;page n
;    mov cx,colunas;n de vezes p desenhar
;
;    mov ax,00001010_11001101b
;    int 10h  ;desenha na tela
;
;    ret
;add_log endp
times 510-($-$$) db 0
dw 0AA55h ; assinatura de boot :D
