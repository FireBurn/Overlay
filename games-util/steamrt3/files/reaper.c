// A 64-bit stand-in for the reaper Valve ships, which is 32-bit. It runs a
// command as a child subreaper and waits until every descendant has gone.
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/wait.h>
#include <unistd.h>

static void fail(const char *message) {
  fputs(message, stderr);
  exit(1);
}

int main(int argc, char **argv) {
  int command = -1;
  for (int i = 0; i < argc; ++i) {
    if (strcmp(argv[i], "--") == 0) {
      command = i + 1;
      break;
    }
  }
  if (command < 0 || command >= argc)
    fail("reaper: no sub-command!\n");

  // Orphans the command leaves behind come back here to be waited for.
  if (prctl(PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0) == -1)
    fail("reaper: prctl() failed!\n");

  pid_t child = fork();
  if (child == -1)
    fail("reaper: fork() failed!\n");
  if (child == 0) {
    execvp(argv[command], &argv[command]);
    perror(argv[command]);
    _exit(127);
  }

  while (wait(NULL) != -1 || errno != ECHILD)
    ;
  return 0;
}
