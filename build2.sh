rgbasm -ochronos.o chronos.asm && \
rgblink -ochronos.gb -nchronos.sym -mchronos.map chronos.o && \
rgbfix -p 0xFF -v chronos.gb
