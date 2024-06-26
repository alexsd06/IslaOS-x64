%define MULTIBOOT_HEADER_MAGIC 0x1badb002

; Flags:
;
; bit 2: request framebuffer
%define MULTIBOOT_HEADER_FLAGS (1 << 2)

extern kernel_main

global _start

section .multiboot_header

align 4
header_start:
    dd MULTIBOOT_HEADER_MAGIC                                       ; Magic number (multiboot 1)
    dd MULTIBOOT_HEADER_FLAGS                                       ; Flags
    dd -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)           ; Checksum
header_end:

section .text
bits 64

_start:
    cli

    mov rsp, stack_top

    push rbx
    push rax

    call kernel_main ; Jump to our multiboot test kernel

section .bss
align 16
stack_bottom:
    resb 4096 * 16
stack_top:
