// The parts of musl's ABI that this libc does not already answer to.
//
// A musl program's undefined symbols are resolved against this library and
// then, through it, against libc itself, so only the names whose behaviour
// differs are defined here. Everything else falls through untouched.

#define _GNU_SOURCE
#include <elf.h>
#include <link.h>
#include <stdlib.h>
#include <sys/auxv.h>
#include <unistd.h>

extern char **environ;

// Describes the thread this process was entered on. llvm-libc's own startup
// code does this, and a program that started through musl's has not. Until
// it is done pthread_self and anything reached through pthread_once fault.
int __llvm_libc_init_main_thread(void);

typedef void (*init_fn)(int, char **, char **);

// musl's crt1.o hands over the executable's _init but not its init array,
// because on musl the dynamic linker runs that. The loader here deliberately
// does not: it skips the executable so a normal program's own startup code
// can run its initialisers once. So they are run from here instead, found
// through the program headers the kernel left in the auxiliary vector.
static void run_init_array(int argc, char **argv, char **envp) {
	unsigned long phdr_addr = getauxval(AT_PHDR);
	unsigned long phnum = getauxval(AT_PHNUM);
	unsigned long phent = getauxval(AT_PHENT);
	if (phdr_addr == 0 || phnum == 0 || phent == 0)
		return;

	const char *phdrs = (const char *)phdr_addr;
	// Where the executable was actually placed, which is the difference
	// between the addresses in the headers and the one it is loaded at.
	ElfW(Addr) base = 0;
	int have_base = 0;
	for (unsigned long i = 0; i < phnum; ++i) {
		const ElfW(Phdr) *ph = (const ElfW(Phdr) *)(phdrs + i * phent);
		if (ph->p_type == PT_PHDR) {
			base = phdr_addr - ph->p_vaddr;
			have_base = 1;
			break;
		}
	}
	if (!have_base)
		return;

	const ElfW(Dyn) *dyn = NULL;
	for (unsigned long i = 0; i < phnum; ++i) {
		const ElfW(Phdr) *ph = (const ElfW(Phdr) *)(phdrs + i * phent);
		if (ph->p_type == PT_DYNAMIC) {
			dyn = (const ElfW(Dyn) *)(base + ph->p_vaddr);
			break;
		}
	}
	if (dyn == NULL)
		return;

	ElfW(Addr) preinit = 0, preinit_sz = 0, init = 0, init_sz = 0;
	for (; dyn->d_tag != DT_NULL; ++dyn) {
		switch (dyn->d_tag) {
		case DT_PREINIT_ARRAY:   preinit = dyn->d_un.d_ptr; break;
		case DT_PREINIT_ARRAYSZ: preinit_sz = dyn->d_un.d_val; break;
		case DT_INIT_ARRAY:      init = dyn->d_un.d_ptr; break;
		case DT_INIT_ARRAYSZ:    init_sz = dyn->d_un.d_val; break;
		default: break;
		}
	}

	// The addresses in the dynamic section are the ones the headers carry,
	// so where the executable actually landed has to be added. For one that
	// is not position independent that is zero and this changes nothing.
	if (preinit != 0) {
		init_fn *fns = (init_fn *)(base + preinit);
		for (size_t i = 0; i < preinit_sz / sizeof(init_fn); ++i)
			fns[i](argc, argv, envp);
	}
	if (init != 0) {
		init_fn *fns = (init_fn *)(base + init);
		for (size_t i = 0; i < init_sz / sizeof(init_fn); ++i)
			fns[i](argc, argv, envp);
	}
}

int __libc_start_main(int (*main_fn)(int, char **, char **), int argc,
                      char **argv, void (*init)(void), void (*fini)(void),
                      void (*ldso_fini)(void)) {
	(void)ldso_fini;
	char **envp = argv + argc + 1;
	environ = envp;

	if (__llvm_libc_init_main_thread() != 0)
		_exit(127);

	if (init != NULL)
		init();
	run_init_array(argc, argv, envp);
	if (fini != NULL)
		atexit(fini);

	exit(main_fn(argc, argv, envp));
}
