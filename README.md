random?

```
rngFast:
    ldh a, [RNG_pointer]
    ld b, a
    rrca
    rrca
    rrca
    xor $1f

    add b
    sbc 255
    ldh [RNG_pointer], a
    ret

; 19c 14b
```