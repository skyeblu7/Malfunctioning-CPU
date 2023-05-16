


lw x1, A
lw x2, GOOD
lh x3, TEST
lb x4, NOPE



lw x1, 0(x2)
sw x1, 0(x3)
lw x3, 0(x4)
sw x3, 0(x2)
sw x2, 0(x4)


HALT:
j HALT


A:      .word 0x00000010
GOOD:   .word 0x600D60D0
NOPE:   .word 0x0BADBAD0
TEST:   .word 0x00000000
FULL:   .word 0xFFFFFFF0


