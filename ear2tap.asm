START   equ     16384
F_OPEN  equ     $9A
F_CLOSE equ     $9B
F_WRITE equ     $9E

        org     8192
        ld      a, h
        or      l
        jr      nz, StartProcessing

        ld      hl, Usage
PrintMsgLoop:
        ld      a, (hl)
        or      a
        ret     z
        rst     10h
        inc     hl
        jr      PrintMsgLoop

StartProcessing:
        call    getFileName
        ld      hl, buffer
        ld      a, 42
        ld      b, 12                   ; create file
        rst     8
        db      F_OPEN                  ; open
        ret     c
        ld      (handle), a             ; save handle

        ; Move the stack so it doesn't get clobbered by the loading
        ld      sp, stack
loop:
        ld      ix, START+2
        ld      de, $ffff-(START+2)
        ld      a, 0
        scf
        call    ld_bytes
save:
        or      a
        ld      hl, START+2
        ld      d, ixh
        ld      e, ixl
        ex      de, hl
        sbc     hl, de
        jr      z, exit
        ld      (START), hl
        ld      b, h
        ld      c, l
        ld      hl, START

        ; Extra 2 bytes for the block length in the TAP file
        inc     bc
        inc     bc

        ld      a, (handle)
        rst     8
        db      F_WRITE                 ; write
        jr      loop

exit:
        ld      a, (handle)
        rst     8
        db      F_CLOSE                 ; close
        rst     0

ld_ret:
        push    af
        ld      a, $0c                  ; Border green
        out     (254), a
        ei
ld_end:
        pop     af
        ret

ld_bytes:
        inc     d
        ex      af, af'
        dec     d
        di
        ld      a, 0x0f
        out     (254), a
        ld      hl, ld_ret
        push    hl
        in      a, (254)
        rra
        and     0x20
        or      0x02
        ld      c, a
        cp      a
ld_break:
        ret     nz
ld_start:
        call    ld_edge_1
        jr      nc, ld_break
        ld      hl, 0x0415
ld_wait:
        djnz    ld_wait
        dec     hl
        ld      a, h
        or      l
        jr      nz, ld_wait
        call    ld_edge_2
        jr      nc, ld_break
ld_leader:
        ld      b, 0x9c
        call    ld_edge_2
        jr      nc, ld_break
        ld      a, 0xc6
        cp      b
        jr      nc, ld_start
        inc     h
        jr      nz, ld_leader
ld_sync:
        ld      b, 0xc9
        call    ld_edge_1
        jr      nc, ld_break
        ld      a, b
        cp      0xd4
        jr      nc, ld_sync
        call    ld_edge_1
        ret     nc
        ld      a, c
        xor     0x03
        ld      c, a
        ld      h, 0
        ld      b, 0xb0
        jr      ld_marker
ld_loop:
        ex      af, af'
        ld      (ix+0), l
ld_next:
        inc     ix
ld_dec:
        dec     de
        ex      af, af'
        ld      b, 0xb2
ld_marker:
        ld      l, 1
ld_8_bits:
        call    ld_edge_2
        ret     nc
        ld      a, 0xcb
        cp      b
        rl      l
        ld      b, 0xb0
        jp      nc, ld_8_bits
        ld      a, h
        xor     l
        ld      h, a
        ld      a, d
        or      e
        jr      nz, ld_loop
        ld      a, h
        cp      1
        ret

ld_edge_2:
        call    ld_edge_1
        ret     nc
ld_edge_1:
        ld      a, 0x16
ld_delay:
        dec     a
        jr      nz, ld_delay
        and     a
ld_sample:
        inc     b
        ret     z
        ld      a, 0x7f
        in      a, (254)
        rra
        ret     nc
        xor     c
        and     0x20
        jr      z, ld_sample
        ld      a, c
        cpl
        ld      c, a
        and     0x07
        or      0x08
        out     (254), a
        scf
        ret

getFileName:
        ld      b, 255
        ld      de, buffer
fileNameLoop:
        ld      a, (hl)
        ld      (de), a
        or      a
        ret     z

        cp      $0d
        jr      z, fileNameDone

        cp      ':'
        jr      z, fileNameDone

        inc     hl
        inc     de
        djnz    fileNameLoop
fileNameDone:
        xor     a
        ld      (de), a
        ret

Usage:
        db      ".ear2tap <new tap file>", 13, 13
        db      "Copy from EAR to new.tap file.", 13
        db      "Similar to COPY-COPY program.", 13
        db      "It restarts the machine after BREAK.", 13, 0

        dw      32
stack:
handle:
        db      0
Lab8461:
        db      0                       ;drive
Lab8462:
        db      0                       ;device
Lab8463:
        db      0                       ; attr
Lab8464:
        db      0                       ; date
        db      0
        db      0
        db      0
Lab8468:                                ; size
        db      0
        db      0
        db      0
        db      0
LabDlug:
        db      0
        db      0
Lab8472:
        db      0
        db      0
header:
        ds      255
buffer:
        db      0
