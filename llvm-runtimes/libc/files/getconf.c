/* getconf for LLVM libc.
 *
 * Answers for the variables sysconf, pathconf and confstr take and the limits
 * the headers define, naming each only where the library has it. Written for
 * this library, not taken from another: musl's getconf names more than this
 * library has.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct entry {
  const char *name;
  long value;
};

#define SC(n) {#n, _SC_##n},
static const struct entry sysconf_names[] = {
#ifdef _SC_ARG_MAX
    SC(ARG_MAX)
#endif
#ifdef _SC_CHILD_MAX
    SC(CHILD_MAX)
#endif
#ifdef _SC_CLK_TCK
    {"CLK_TCK", _SC_CLK_TCK},
#endif
#ifdef _SC_NGROUPS_MAX
    SC(NGROUPS_MAX)
#endif
#ifdef _SC_OPEN_MAX
    SC(OPEN_MAX)
#endif
#ifdef _SC_PAGESIZE
    {"PAGESIZE", _SC_PAGESIZE},
    {"PAGE_SIZE", _SC_PAGESIZE},
#endif
#ifdef _SC_NPROCESSORS_CONF
    {"_NPROCESSORS_CONF", _SC_NPROCESSORS_CONF},
#endif
#ifdef _SC_NPROCESSORS_ONLN
    {"_NPROCESSORS_ONLN", _SC_NPROCESSORS_ONLN},
#endif
#ifdef _SC_PHYS_PAGES
    {"_PHYS_PAGES", _SC_PHYS_PAGES},
#endif
#ifdef _SC_AVPHYS_PAGES
    {"_AVPHYS_PAGES", _SC_AVPHYS_PAGES},
#endif
#ifdef _SC_LINE_MAX
    SC(LINE_MAX)
#endif
#ifdef _SC_HOST_NAME_MAX
    SC(HOST_NAME_MAX)
#endif
#ifdef _SC_LOGIN_NAME_MAX
    SC(LOGIN_NAME_MAX)
#endif
#ifdef _SC_TTY_NAME_MAX
    SC(TTY_NAME_MAX)
#endif
#ifdef _SC_SYMLOOP_MAX
    SC(SYMLOOP_MAX)
#endif
#ifdef _SC_GETPW_R_SIZE_MAX
    SC(GETPW_R_SIZE_MAX)
#endif
#ifdef _SC_GETGR_R_SIZE_MAX
    SC(GETGR_R_SIZE_MAX)
#endif
#ifdef _SC_THREAD_STACK_MIN
    SC(THREAD_STACK_MIN)
#endif
#ifdef _SC_THREAD_THREADS_MAX
    SC(THREAD_THREADS_MAX)
#endif
#ifdef _SC_SIGQUEUE_MAX
    SC(SIGQUEUE_MAX)
#endif
#ifdef _SC_MQ_OPEN_MAX
    SC(MQ_OPEN_MAX)
#endif
#ifdef _SC_RTSIG_MAX
    SC(RTSIG_MAX)
#endif
#ifdef _SC_SEM_NSEMS_MAX
    SC(SEM_NSEMS_MAX)
#endif
#ifdef _SC_SEM_VALUE_MAX
    SC(SEM_VALUE_MAX)
#endif
#ifdef _SC_AIO_MAX
    SC(AIO_MAX)
#endif
#ifdef _SC_DELAYTIMER_MAX
    SC(DELAYTIMER_MAX)
#endif
#ifdef _SC_TIMER_MAX
    SC(TIMER_MAX)
#endif
#ifdef _SC_VERSION
    SC(VERSION)
#endif
#ifdef _SC_2_VERSION
    {"_POSIX2_VERSION", _SC_2_VERSION},
#endif
    {0, 0}};

#define PC(n) {#n, _PC_##n},
static const struct entry pathconf_names[] = {
#ifdef _PC_LINK_MAX
    PC(LINK_MAX)
#endif
#ifdef _PC_MAX_CANON
    PC(MAX_CANON)
#endif
#ifdef _PC_MAX_INPUT
    PC(MAX_INPUT)
#endif
#ifdef _PC_NAME_MAX
    PC(NAME_MAX)
#endif
#ifdef _PC_PATH_MAX
    PC(PATH_MAX)
#endif
#ifdef _PC_PIPE_BUF
    PC(PIPE_BUF)
#endif
#ifdef _PC_CHOWN_RESTRICTED
    PC(CHOWN_RESTRICTED)
#endif
#ifdef _PC_NO_TRUNC
    PC(NO_TRUNC)
#endif
#ifdef _PC_VDISABLE
    PC(VDISABLE)
#endif
    {0, 0}};

static const struct entry limit_names[] = {
    {"LONG_BIT", sizeof(long) * CHAR_BIT},
    {"WORD_BIT", sizeof(int) * CHAR_BIT},
    {"CHAR_BIT", CHAR_BIT},
    {"CHAR_MAX", CHAR_MAX},
    {"CHAR_MIN", CHAR_MIN},
    {"SCHAR_MAX", SCHAR_MAX},
    {"SCHAR_MIN", SCHAR_MIN},
    {"UCHAR_MAX", UCHAR_MAX},
    {"SHRT_MAX", SHRT_MAX},
    {"SHRT_MIN", SHRT_MIN},
    {"USHRT_MAX", USHRT_MAX},
    {"INT_MAX", INT_MAX},
    {"INT_MIN", INT_MIN},
    {"UINT_MAX", (long)UINT_MAX},
    {"LONG_MAX", LONG_MAX},
    {"LONG_MIN", LONG_MIN},
    {"SSIZE_MAX", SSIZE_MAX},
    {"NZERO", 20},
    {0, 0}};

static const struct entry *find(const struct entry *table, const char *name) {
  for (; table->name; ++table)
    if (strcmp(table->name, name) == 0)
      return table;
  return 0;
}

static int print_confstr(const char *name) {
  int which;
  if (strcmp(name, "PATH") == 0 || strcmp(name, "CS_PATH") == 0)
    which = _CS_PATH;
#ifdef _CS_GNU_LIBC_VERSION
  else if (strcmp(name, "GNU_LIBC_VERSION") == 0)
    which = _CS_GNU_LIBC_VERSION;
#endif
#ifdef _CS_GNU_LIBPTHREAD_VERSION
  else if (strcmp(name, "GNU_LIBPTHREAD_VERSION") == 0)
    which = _CS_GNU_LIBPTHREAD_VERSION;
#endif
  else
    return -1;
  char buf[256];
  size_t n = confstr(which, buf, sizeof buf);
  if (n == 0)
    return 1;
  puts(buf);
  return 0;
}

int main(int argc, char **argv) {
  int arg = 1;
  if (argc > arg && strcmp(argv[arg], "-v") == 0) {
    /* The programming environments are not selectable here. */
    arg += 2;
  }
  if (argc > arg && strcmp(argv[arg], "-a") == 0) {
    const struct entry *e;
    const char *path = argc > arg + 1 ? argv[arg + 1] : "/";
    for (e = sysconf_names; e->name; ++e) {
      errno = 0;
      long v = sysconf((int)e->value);
      if (v == -1 && errno == 0)
        printf("%s: undefined\n", e->name);
      else if (v != -1)
        printf("%s: %ld\n", e->name, v);
    }
    for (e = pathconf_names; e->name; ++e) {
      errno = 0;
      long v = pathconf(path, (int)e->value);
      if (v != -1)
        printf("%s: %ld\n", e->name, v);
    }
    for (e = limit_names; e->name; ++e)
      printf("%s: %ld\n", e->name, e->value);
    return 0;
  }
  if (argc - arg < 1 || argc - arg > 2) {
    fprintf(stderr, "usage: getconf [-v specification] name [path]\n"
                    "       getconf -a [path]\n");
    return 2;
  }
  const char *name = argv[arg];
  const char *path = argc - arg == 2 ? argv[arg + 1] : 0;
  const struct entry *e;

  if ((e = find(pathconf_names, name)) != 0) {
    if (!path) {
      fprintf(stderr, "getconf: %s needs a path\n", name);
      return 2;
    }
    errno = 0;
    long v = pathconf(path, (int)e->value);
    if (v == -1 && errno != 0) {
      perror(path);
      return 1;
    }
    if (v == -1)
      puts("undefined");
    else
      printf("%ld\n", v);
    return 0;
  }
  if ((e = find(sysconf_names, name)) != 0) {
    errno = 0;
    long v = sysconf((int)e->value);
    if (v == -1 && errno != 0) {
      fprintf(stderr, "getconf: %s: %s\n", name, strerror(errno));
      return 1;
    }
    if (v == -1)
      puts("undefined");
    else
      printf("%ld\n", v);
    return 0;
  }
  if ((e = find(limit_names, name)) != 0) {
    printf("%ld\n", e->value);
    return 0;
  }
  int r = print_confstr(name);
  if (r >= 0)
    return r;
  fprintf(stderr, "getconf: unknown variable: %s\n", name);
  return 1;
}
