%ifndef GFXTEXT
%define GFXTEXT

%ifndef GFXTEXT_FONT
%error No font specified!
%endif

%ifndef GFXTEXT_VBUF_OFFSET
%warning Location of video buffer not specified!
%define GFXTEXT_VBUF_OFFSET 0xa000
%endif

%include "gfxtext/gfxputc.asm"
%include "gfxtext/gfxputs.asm"

;Make sure that font data is located at address divisible by 16
times 16 - ( ( $ - $$ ) % 16 ) db 0
gfxtext_font: incbin GFXTEXT_FONT

%endif
