#ifndef TK_EXECINFO_H
#define TK_EXECINFO_H

#ifdef __linux__

#include <execinfo.h>
#include <sys/wait.h>
#include <unistd.h>
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <libgen.h>
#include <limits.h>

static inline void tk_execinfo_handler(int sig)
{
  void *array[32];
  size_t size = (size_t) backtrace(array, 32);
  char **strings = backtrace_symbols(array, size);
  fprintf(stderr, "\nunexpected signal: %d\n", sig);
  char cwd[PATH_MAX];
  getcwd(cwd, sizeof(cwd));
  // For each frame, extract .so path and offset, then call addr2line
  for (size_t i = 0; i < size; i ++) {
    // Try to extract .so and offset
    char *so_start = strstr(strings[i], ".so");
    if (!so_start) continue;
    // Find the start of the path
    char *path_start = so_start;
    while (path_start > strings[i] && *path_start != ' ' && *path_start != '(') path_start--;
    if (*path_start == ' ' || *path_start == '(') path_start++;
    // .so path length
    size_t path_len = (size_t)(so_start - path_start + 3); // ".so" is 3 chars
    char so_path[PATH_MAX] = {0};
    if (path_len >= sizeof(so_path)) continue;
    strncpy(so_path, path_start, path_len);
    so_path[path_len] = 0;
    if (access(so_path, R_OK) != 0) continue;
    // Extract offset
    char *plus = strstr(strings[i], "+0x");
    if (!plus) continue;
    char *end = strchr(plus, ')');
    if (!end) continue;
    size_t olen = (size_t)(end - (plus + 1));
    if (olen >= 32) continue;
    char offset[32] = {0};
    strncpy(offset, plus + 1, olen);
    offset[olen] = 0;
    // Run addr2line -f -e so_path offset
    int pipefd[2];
    if (pipe(pipefd) != 0) continue;
    pid_t pid = fork();
    if (pid == 0) {
      // child
      dup2(pipefd[1], STDOUT_FILENO);
      close(pipefd[0]);
      close(pipefd[1]);
      execlp("addr2line", "addr2line", "-f", "-e", so_path, offset, NULL);
      _exit(127);
    }
    close(pipefd[1]);
    char buf[512] = {0};
    ssize_t n = read(pipefd[0], buf, sizeof(buf) - 1);
    close(pipefd[0]);
    int status;
    waitpid(pid, &status, 0);
    if (n <= 0) continue;
    buf[n] = 0;
    // addr2line -f prints two lines: function, then file:line
    char *func = buf;
    char *file = strchr(buf, '\n');
    if (!file) continue;
    *file++ = 0;
    // filter unresolved lines
    if (strncmp(file, "??:0", 4) == 0 || strncmp(file, "??", 2) == 0) continue;
    // make path relative to cwd if possible
    if (strncmp(file, cwd, strlen(cwd)) == 0 && file[strlen(cwd)] == '/')
      file += strlen(cwd) + 1;
    // Print in your preferred format
    fprintf(stderr, "%s %s %s", offset, func, file);
    if (file[strlen(file)-1] != '\n') fputc('\n', stderr);
  }
  free(strings);
  exit(1);
}

// NOTE: This runs automatically in GCC/clang on linux, but can be called
// separately on other platforms
__attribute__((constructor)) static inline void tk_execinfo_init () {
  signal(SIGSEGV, tk_execinfo_handler);
  signal(SIGABRT, tk_execinfo_handler);
}

#endif // __linux__
#endif // TK_EXECINFO_H
