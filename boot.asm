; when bios loads us initially we don't know what the segment registers are. It makes sense for programmer to initialize segments themselves
ORG 0 ; origin tells assembler how to offset our data
BITS 16 ; we're using 16-bit architecture

; sometimes bios overwrites data when booting from flash drive because of bios parameter block (BPB)
_start:
    jmp short start ; allows the program to jump to a target address within a relatively small range
    nop ; no operation

times 33 db 0 ; create 33 bytes after short jump (bios parameter block). In case bios starts overwriting values in these null bytes

start: ; a label is a name given to an address. without them a programmer would have to manually calculate them
    jmp 0x7c0:step2 ; make code segment 0x7c0

step2:
    cli ; clear interrupts
    mov ax, 0x7c0 ; we can't directly move 0x7c0 into ds or es. we need to move it into intermediate ax register
    mov ds, ax ; ideal if programmer manually sets ds, ss and es registers rather than deleagate that to bios
    mov es, ax
    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7c00 ; stack pointer
    sti ; enables interrupts
    mov si, message ; move message address to si register
    call print ; call print subroutine to print contents of si onto screen
    jmp $ ; don't execute signature.


print: 
    mov bx, 0 ; set page number and foreground colour
.loop: ; sub label. labels that only apply to main label
    lodsb ; load character si register is pointing to, and then increment to next character. It moves character into al register
    cmp al, 0 ; 0 signifies end of string. If its zero jump to done else call print_char
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh ; move 0eh into ah register. http://www.ctyme.com/intr/rb-0106.htm
    int 0x10 ; interrupt. here we're calling a bios routine. It prints character to terminal screen
    ret ; return from subroutine
    
message: db 'Hello World!', 0 ; message label containing 'Hello World!!'


times 510-($ - $$) db 0 ; fill atleast 510 bytes of data. If we don't manage to fill first 510 bytes of data, we pad the rest with 0s
dw 0xAA55 ; intel machines are little endian; bytes get flipped when working with words. This command puts boot signature at 511th and 512th byte