section .rodata
    %define droneSize 20
    %define xOffset 0
    %define yOffset 2
    %define speedOffset 4
    %define angleOffset 6
    %define scoreOffset 8
    %define isAliveOffset 12
    %define pidOffset 16
    %define 3.14159265359

section .bss

section .data

section .text
    extern getDrone
    extern getRandomNumber
    

%macro getSelf 0
    mov eax, [ebp-4]    ;eax = index of self
    getDrone eax
%endmacro

%macro getSpecPtr 1
    mov ecx, %1
    getSelf
    add eax, ecx
%endmacro    

;;arg is spec to update with random
%macro update16BitSpec 1
    mov eax, %1
    getSpecPtr eax
    push eax                ;top of stack = specAdrs
    call getRandomNumber    ;random in eax (ax)
    pop ebx                 ;ebx = specAdrs 
    mov word[ebx],ax        ;spec = random
%endmacro 

;;TODO: 
;; 1) check carry flag and clamp to bound if needed
;; 2) divide random by 10 before adding (for sake of common unit ratios)
%macro updateSpeed 0
    mov eax, speedOffset
    getSpecPtr eax
    push eax                ;top of stack = specAdrs
    call getRandomNumber    ;random in eax (ax)
    ;;divide random by 10 before adding!!
    pop ebx                 ;ebx = specAdrs 
    add word[ebx],ax        ;speed = speed + random
    ;;check for overflow!!!
%endmacro 

;;TODO: 
;; 1) check carry flag and clamp to bound if needed
;; 2) divide random by 6 before adding (for sake of common unit ratios)
%macro updateAngle 0
    mov eax, angleOffset
    getSpecPtr eax
    push eax                ;top of stack = specAdrs
    call getRandomNumber    ;random in eax (ax)
    ;;divide random by 6!!
    pop ebx                 ;ebx = specAdrs 
    add word[ebx],ax        ;speed = speed + random
    ;;check for overflow!!!
%endmacro 



;;TODO: Implement!
%macro move 0
    getSelf
    mov ebx, 0
    mov bx, [eax+xOffset]
    mov ecx, 0
    mov cx, [eax+yOffset]
    
    ;;update position
%endmacro


%macro updateSpecs 0
    getRandomNumber     ;eax = random 16 bits
    push eax
    getSpecPtr xOffset
    mov ebx, eax


%endmacro


resumeDroneCoroutine:
    ;;index stored at ebp - 4
    push dword[esp + 4]
    call getDrone


    

