// setjmp and longjmp against musl's jmp_buf, which is eight registers and
// sixty four bytes. This library's own are larger, so they would write past
// the end of a buffer a musl program declared.
//
// Derived from the register layout musl documents in
// src/setjmp/x86_64/setjmp.s, which is the layout the ABI here has to match.

	.text
	.global setjmp
	.global _setjmp
	.global __setjmp
	.type setjmp,@function
	.type _setjmp,@function
	.type __setjmp,@function
setjmp:
_setjmp:
__setjmp:
	mov %rbx, (%rdi)
	mov %rbp, 8(%rdi)
	mov %r12, 16(%rdi)
	mov %r13, 24(%rdi)
	mov %r14, 32(%rdi)
	mov %r15, 40(%rdi)
	lea 8(%rsp), %rdx		/* the stack pointer without our return address */
	mov %rdx, 48(%rdi)
	mov (%rsp), %rdx		/* and the return address as the new rip */
	mov %rdx, 56(%rdi)
	xor %eax, %eax
	ret
	.size setjmp, .-setjmp

	.global longjmp
	.global _longjmp
	.type longjmp,@function
	.type _longjmp,@function
longjmp:
_longjmp:
	xor %eax, %eax
	cmp $1, %esi			/* a val of zero has to come back as one */
	adc %esi, %eax
	mov (%rdi), %rbx
	mov 8(%rdi), %rbp
	mov 16(%rdi), %r12
	mov 24(%rdi), %r13
	mov 32(%rdi), %r14
	mov 40(%rdi), %r15
	mov 48(%rdi), %rsp
	jmp *56(%rdi)
	.size longjmp, .-longjmp

	.section .note.GNU-stack,"",@progbits
