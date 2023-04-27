# Gameboy Assembly Learning

## What can we find here

- brick - my take on the breakout tutorial from https://gbdev.io/gb-asm-tutorial/part2/getting-started.html. still has some bugs
- anim - short example to nail down animation and input handling
- tictactoe - WIP tic tac toe game thingie
- misc - generic routines
- other incs - mainly tiles and tilemaps. aux routines

## TODO

- [x] tile usage
- [x] tilemap usage
- [x] frame sync
- [x] linear animation
- [x] RNG
- [x] joypad handling
- [x] draw score in BCD
- [ ] tilemap scrolling
- [ ] draw using window overlay
- [ ] load/save data
- [ ] SFX
- [ ] music
- [ ] palette animation (fade, rotate)
- [ ] frame draw effect (interrupt on HBlank?)
- [ ] other interrupts (input, timer?)
- [ ] test in actual GBC
- [ ] bank loading (if necessary)
- [ ] macros


## Tools

## tool chain

- RGBDS - https://rgbds.gbdev.io `brew install rgbds`

## syntax support

- https://github.com/DonaldHays/rgbds-vscode

### Emulators

- sameboy - https://sameboy.github.io/ `brew install sameboy`
- emulicious - https://emulicious.net/
- binjgb - https://github.com/binji/binjgb

### Disassemblers

- mgbdis - https://github.com/mattcurrie/mgbdis
- emulicious - https://emulicious.net/

### Trackers

- littlesounddj - https://www.littlesounddj.com/lsd/index.php
- hUGETracker - https://github.com/SuperDisk/hUGETracker
- carrillon - https://gbdev.gg8.se/files/musictools/Aleksi%20Eeben/

### Tricks

- change cartridge battery - https://howchoo.com/g/ody3ztq0ywe/how-to-change-your-game-boy-game-cartridge-battery
- change palette at boot - https://imgur.com/jZUXMp2


## Resources

- https://gbdev.io/pandocs/
- https://gbdev.io/gb-asm-tutorial/
- https://gbdev.io/resources.html
- https://famicom.party/book/ (NES)

- ASM examples:
    - https://github.com/tbsp/simple-gb-asm-examples/tree/master
    - https://github.com/jeremyherbert/gb-snake
    - https://github.com/search?q=%5Brgbds%5D+language%3AAssembly&type=repositories&l=Assembly
    - https://github.com/davFaithid/tetris-disassembly
    - https://github.com/jona32u4hm/pong-for-gameboy-in-assembly
    - https://github.com/bferguson3/gbjam
    - https://github.com/vypxl/gb-examples

- videos I liked the most:
    - https://www.youtube.com/playlist?list=PLu3xpmdUP-GRDp8tknpXC_Y4RUQtMMqEu
    - https://www.youtube.com/watch?v=HyzD8pNlpwI
    - https://www.youtube.com/watch?v=txkHN6izK2Y
    - https://www.youtube.com/watch?v=_h5TXh20_fQ
    - https://www.youtube.com/watch?v=TPbroUDHG0s (NES)

- roms
    - https://hh.gbdev.io/events/gbcompo21/
    - https://hh.gbdev.io/demos/
    - https://hh.gbdev.io/hb/
    - https://hh.gbdev.io/music/

- other articles
    - https://mitxela.com/projects/swotgb/about
    - http://www.dotmatrixgame.com/


## Notes

### RNG

- https://www.youtube.com/watch?v=TPbroUDHG0s
https://meatfighter.com/nintendotetrisai/#Picking_Tetriminos
16-bit Fibonacci linear feedback shift register (LFSR)
(XOR bits 1 and 9, store in bit 16, shift right)

https://en.wikipedia.org/wiki/Linear-feedback_shift_register
https://github.com/jeremyherbert/gb-snake/blob/master/snake.asm#L288

https://harddrop.com/wiki/Tetris_(Game_Boy)#Randomizer

https://simon.lc/the-history-of-tetris-randomizers

### BCD

BCD, binary coded decimal
The Gameboy's CPU has an instruction called DAA (Decimal Adjust Accumulator) that will take a byte and convert it into
a two-digit base 10 value (four bits per digit). You can then shift/mask the byte and use it as an offset to look up the correct tile in your tileset.

https://www.reddit.com/r/Gameboy/comments/4m7sm0/comment/d3tiyt5/?utm_source=share&utm_medium=web2x&context=3
