rgbasm -ofollin.o follin.asm && \
rgblink -ofollin.gb -nfollin.sym -mfollin.map follin.o && \
rgbfix -p 0xFF -v follin.gb
