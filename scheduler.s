section .rodata

section .bss

section .data
    currDroneId: dd 0
    currRound: dd 0  

section .text


initProcesses:
    initTargetProcess

runScheduler:
