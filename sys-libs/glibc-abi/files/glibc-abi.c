// The parts of glibc's ABI that this libc does not answer to.
//
// A program built for glibc has its undefined symbols resolved against
// libc.so.6 and the empty libraries glibc split off from it. This library is
// libc.so.6 here: it needs libc.so.1, so everything this libc already has is
// found through it, and only the names glibc has internally, or spells
// differently, are defined below.

#define _GNU_SOURCE
#include <ctype.h>
#include <dlfcn.h>
#include <locale.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <wchar.h>
#include <wctype.h>

#define ABI __attribute__((visibility("default")))

// Fortified entry points. The size the compiler passed says whether the
// call would have overrun, and glibc stops the program when it would.
static void overflow(void) { abort(); }

ABI void *__memcpy_chk(void *d, const void *s, size_t n, size_t dl) {
	if (n > dl) overflow();
	return memcpy(d, s, n);
}
ABI void *__memmove_chk(void *d, const void *s, size_t n, size_t dl) {
	if (n > dl) overflow();
	return memmove(d, s, n);
}
ABI void *__memset_chk(void *d, int c, size_t n, size_t dl) {
	if (n > dl) overflow();
	return memset(d, c, n);
}
ABI char *__strcpy_chk(char *d, const char *s, size_t dl) {
	if (strlen(s) >= dl) overflow();
	return strcpy(d, s);
}
ABI char *__strncpy_chk(char *d, const char *s, size_t n, size_t dl) {
	if (n > dl) overflow();
	return strncpy(d, s, n);
}
ABI char *__strcat_chk(char *d, const char *s, size_t dl) {
	if (strlen(d) + strlen(s) >= dl) overflow();
	return strcat(d, s);
}
ABI char *__strncat_chk(char *d, const char *s, size_t n, size_t dl) {
	size_t l = strlen(s);
	if (strlen(d) + (l < n ? l : n) >= dl) overflow();
	return strncat(d, s, n);
}
ABI size_t __fread_chk(void *p, size_t pl, size_t sz, size_t n, FILE *f) {
	if (sz != 0 && n > pl / sz) overflow();
	return fread(p, sz, n, f);
}
ABI char *__realpath_chk(const char *p, char *r, size_t rl) {
	(void)rl;
	return realpath(p, r);
}
ABI ssize_t __recv_chk(int fd, void *b, size_t n, size_t bl, int fl) {
	if (n > bl) overflow();
	return recv(fd, b, n, fl);
}
ABI long __fdelt_chk(long d) {
	if (d < 0 || d >= 1024) overflow();
	return d / (8 * (long)sizeof(long));
}

ABI int __vsnprintf_chk(char *s, size_t n, int fl, size_t sl, const char *f, va_list ap) {
	(void)fl;
	if (n > sl) overflow();
	return vsnprintf(s, n, f, ap);
}
ABI int __snprintf_chk(char *s, size_t n, int fl, size_t sl, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = __vsnprintf_chk(s, n, fl, sl, f, ap);
	va_end(ap);
	return r;
}
ABI int __vsprintf_chk(char *s, int fl, size_t sl, const char *f, va_list ap) {
	(void)fl;
	return vsnprintf(s, sl, f, ap);
}
ABI int __sprintf_chk(char *s, int fl, size_t sl, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = __vsprintf_chk(s, fl, sl, f, ap);
	va_end(ap);
	return r;
}
ABI int __vfprintf_chk(FILE *fp, int fl, const char *f, va_list ap) {
	(void)fl;
	return vfprintf(fp, f, ap);
}
ABI int __fprintf_chk(FILE *fp, int fl, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = vfprintf(fp, f, ap);
	va_end(ap);
	(void)fl;
	return r;
}
ABI int __printf_chk(int fl, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = vprintf(f, ap);
	va_end(ap);
	(void)fl;
	return r;
}
ABI int __dprintf_chk(int fd, int fl, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = vdprintf(fd, f, ap);
	va_end(ap);
	(void)fl;
	return r;
}
ABI int __vasprintf_chk(char **p, int fl, const char *f, va_list ap) {
	(void)fl;
	return vasprintf(p, f, ap);
}
ABI int __swprintf_chk(wchar_t *s, size_t n, int fl, size_t sl, const wchar_t *f, ...) {
	va_list ap;
	(void)fl;
	if (n > sl) overflow();
	va_start(ap, f);
	int r = vswprintf(s, n, f, ap);
	va_end(ap);
	return r;
}

// Names glibc gives an entry point which has another name here
ABI int __isoc99_sscanf(const char *s, const char *f, ...) {
	va_list ap;
	va_start(ap, f);
	int r = vsscanf(s, f, ap);
	va_end(ap);
	return r;
}
ABI char *__strdup(const char *s) { return strdup(s); }
ABI long long strtoq(const char *s, char **e, int b) { return strtoll(s, e, b); }
ABI unsigned long long strtouq(const char *s, char **e, int b) { return strtoull(s, e, b); }
// These return twice, so they cannot be C functions that call the real ones:
// they are the real ones, entered by a jump with the caller's frame intact.
// <setjmp.h> is not included, since its macros rename these.
__asm__(
	".text\n"
	".globl _setjmp\n.type _setjmp,@function\n_setjmp:\n\tjmp setjmp@PLT\n"
	".globl _longjmp\n.type _longjmp,@function\n_longjmp:\n\tjmp longjmp@PLT\n"
	".globl __longjmp_chk\n.type __longjmp_chk,@function\n__longjmp_chk:\n\tjmp longjmp@PLT\n");
ABI void *dlmopen(long ns, const char *f, int fl) {
	(void)ns;
	return dlopen(f, fl);
}
ABI int __pthread_key_create(pthread_key_t *k, void (*d)(void *)) {
	return pthread_key_create(k, d);
}
ABI int __register_atfork(void (*pre)(void), void (*par)(void), void (*chi)(void), void *dso) {
	(void)dso;
	return pthread_atfork(pre, par, chi);
}

// stat before it became a plain function: the first argument is a version
ABI int __xstat(int v, const char *p, struct stat *b) { (void)v; return stat(p, b); }
ABI int __lxstat(int v, const char *p, struct stat *b) { (void)v; return lstat(p, b); }
ABI int __fxstat(int v, int fd, struct stat *b) { (void)v; return fstat(fd, b); }
ABI int __xstat64(int v, const char *p, struct stat *b) { (void)v; return stat(p, b); }
ABI int __lxstat64(int v, const char *p, struct stat *b) { (void)v; return lstat(p, b); }
ABI int __fxstat64(int v, int fd, struct stat *b) { (void)v; return fstat(fd, b); }
ABI int __fxstatat64(int v, int fd, const char *p, struct stat *b, int f) { (void)v; return fstatat(fd, p, b, f); }
ABI int __xmknod(int v, const char *p, mode_t m, dev_t *d) {
	(void)v;
	return mknod(p, m, *d);
}

// Character class tables: glibc's <ctype.h> reads these directly, indexed
// from -128 to 255, with its own bit layout for the classes.
static unsigned short ctype_b[384];
static int ctype_lower[384];
static int ctype_upper[384];
static const unsigned short *ctype_b_p = ctype_b + 128;
static const int *ctype_lower_p = ctype_lower + 128;
static const int *ctype_upper_p = ctype_upper + 128;
static int ctype_ready;

static void ctype_init(void) {
	if (ctype_ready) return;
	for (int c = -128; c < 256; ++c) {
		int i = c + 128;
		unsigned short b = 0;
		int ch = c < 0 ? 0 : c;
		if (c >= 0 && c < 128) {
			if (isupper(ch)) b |= 1 << 8;
			if (islower(ch)) b |= 1 << 9;
			if (isalpha(ch)) b |= 1 << 10;
			if (isdigit(ch)) b |= 1 << 11;
			if (isxdigit(ch)) b |= 1 << 12;
			if (isspace(ch)) b |= 1 << 13;
			if (isprint(ch)) b |= 1 << 14;
			if (isgraph(ch)) b |= 1 << 15;
			if (isblank(ch)) b |= 1 << 0;
			if (iscntrl(ch)) b |= 1 << 1;
			if (ispunct(ch)) b |= 1 << 2;
			if (isalnum(ch)) b |= 1 << 3;
		}
		ctype_b[i] = b;
		ctype_lower[i] = (c >= 0 && c < 128) ? tolower(ch) : c;
		ctype_upper[i] = (c >= 0 && c < 128) ? toupper(ch) : c;
	}
	ctype_ready = 1;
}
ABI const unsigned short **__ctype_b_loc(void) { ctype_init(); return &ctype_b_p; }
ABI const int **__ctype_tolower_loc(void) { ctype_init(); return &ctype_lower_p; }
ABI const int **__ctype_toupper_loc(void) { ctype_init(); return &ctype_upper_p; }

// The locale-taking forms under their double underscore names. Only the C
// locale is in use, so the locale argument is not consulted.
ABI int __strcoll_l(const char *a, const char *b, locale_t l) { (void)l; return strcoll(a, b); }
ABI size_t __strxfrm_l(char *d, const char *s, size_t n, locale_t l) { (void)l; return strxfrm(d, s, n); }
ABI double __strtod_l(const char *s, char **e, locale_t l) { (void)l; return strtod(s, e); }
ABI float __strtof_l(const char *s, char **e, locale_t l) { (void)l; return strtof(s, e); }
ABI size_t __strftime_l(char *s, size_t n, const char *f, const struct tm *t, locale_t l) {
	(void)l;
	return strftime(s, n, f, t);
}
ABI size_t __wcsftime_l(wchar_t *s, size_t n, const wchar_t *f, const struct tm *t, locale_t l) {
	(void)l;
	return wcsftime(s, n, f, t);
}
ABI int __wcscoll_l(const wchar_t *a, const wchar_t *b, locale_t l) { (void)l; return wcscoll(a, b); }
ABI size_t __wcsxfrm_l(wchar_t *d, const wchar_t *s, size_t n, locale_t l) { (void)l; return wcsxfrm(d, s, n); }
ABI wint_t __towlower_l(wint_t c, locale_t l) { (void)l; return towlower(c); }
ABI wint_t __towupper_l(wint_t c, locale_t l) { (void)l; return towupper(c); }
ABI int __iswctype_l(wint_t c, wctype_t t, locale_t l) { (void)l; return iswctype(c, t); }
ABI wctype_t __wctype_l(const char *n, locale_t l) { (void)l; return wctype(n); }
ABI char *__nl_langinfo_l(int i, locale_t l);
#include <langinfo.h>
ABI char *__nl_langinfo_l(int i, locale_t l) { (void)l; return nl_langinfo(i); }
// libstdc++ asks for every category with the bit for LC_ALL itself, which
// glibc takes to mean all of them.
ABI locale_t __newlocale(int m, const char *n, locale_t b) {
	if (m & (1 << LC_ALL))
		m = (m & ~(1 << LC_ALL)) | LC_ALL_MASK;
	return newlocale(m, n, b);
}
ABI locale_t __duplocale(locale_t l) { return duplocale(l); }
ABI void __freelocale(locale_t l) { freelocale(l); }
ABI locale_t __uselocale(locale_t l) { return uselocale(l); }

// gettext is not translated: the message is its own translation.
ABI char *gettext(const char *m) { return (char *)m; }
ABI char *dgettext(const char *d, const char *m) { (void)d; return (char *)m; }
ABI char *bindtextdomain(const char *d, const char *dir) { (void)d; return (char *)dir; }
ABI char *bind_textdomain_codeset(const char *d, const char *c) { (void)d; return (char *)c; }
