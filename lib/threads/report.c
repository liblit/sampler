#define _GNU_SOURCE    /* for PTHREAD_ADAPTIVE_MUTEX_INITIALIZER_NP */

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include "../registry.h"
#include "../report.h"
#include "lock.h"
#include "once.h"


FILE *reportFile;

pthread_mutex_t reportLock = PTHREAD_ADAPTIVE_MUTEX_INITIALIZER_NP;
sampler_once_t reportInitOnce = SAMPLER_ONCE_INIT;


static void closeOnExec(int fd)
{
  int flags = fcntl(fileno(reportFile), F_GETFD, 0);

  if (flags >= 0)
    {
      flags |= FD_CLOEXEC;
      fcntl(fd, F_SETFD, flags);
    }
}


static void openReportFile()
{
  const char *envar;

  if ((envar = getenv("SAMPLER_REPORT_FD")))
    {
      char *tail;
      const int fd = strtol(envar, &tail, 0);
      if (*tail == '\0')
	{
	  reportFile = fdopen(fd, "w");
	  closeOnExec(fd);
	}
    }

  else if ((envar = getenv("SAMPLER_FILE")))
    {
      reportFile = fopen(envar, "w");
      closeOnExec(fileno(reportFile));
    }

  unsetenv("SAMPLER_REPORT_FD");
  unsetenv("SAMPLER_FILE");

  if (reportFile)
    fputs("<report id=\"samples\">\n", reportFile);
}


static void closeReportFile()
{
  fclose(reportFile);
  reportFile = 0;
}


/**********************************************************************/


static void reportAllCompilationUnits()
{
  if (reportFile)
    {
      samplerUnregisterAllUnits();
      fputs("</report>\n", reportFile);
      fflush(reportFile);
    }
}


static void reportDebugInfo()
{
  const char * const debugger = getenv("SAMPLER_DEBUGGER");
  if (debugger)
    {
      const pid_t pid = fork();
      switch (pid)
	{
	case -1:
	  break;

	case 0:
	  if (dup2(fileno(reportFile), STDOUT_FILENO) == -1)
	    perror("dup2 failed");
	  else
	    {
	      char arg[21];
	      snprintf(arg, sizeof(arg), "%d", getppid());
	      execl(debugger, debugger, arg, 0);
	      perror("debugger exec failed");
	    }

	  exit(errno);

	default:
	  waitpid(pid, 0, 0);
	}
    }
}


/**********************************************************************/


#define SIGNAL_PRIOR(sig)  struct sigaction samplerPrior_ ## sig = { .sa_handler = SIG_DFL }
#define SIGNAL_CASE(sig)  case SIG ## sig: prior = &samplerPrior_ ## sig; break
#define SIGNAL_INST(sig)  do { const struct sigaction action = { .sa_handler = handleSignal }; sigaction(SIG ## sig, &action, &samplerPrior_ ## sig); } while (0)


SIGNAL_PRIOR(ABRT);
SIGNAL_PRIOR(BUS);
SIGNAL_PRIOR(FPE);
SIGNAL_PRIOR(SEGV);
SIGNAL_PRIOR(TRAP);


static void finalize()
{
  CRITICAL_REGION(reportLock, {
    if (reportFile)
      {
	reportAllCompilationUnits();
	closeReportFile();
      }
  });
}


static void handleSignal(int signum)
{
  static const struct sigaction defaultAction = { .sa_handler = SIG_DFL };
  const struct sigaction *prior;

  switch (signum)
    {
      SIGNAL_CASE(ABRT);
      SIGNAL_CASE(BUS);
      SIGNAL_CASE(FPE);
      SIGNAL_CASE(SEGV);
      SIGNAL_CASE(TRAP);
    default:
      prior = &defaultAction;
    }

  sigaction(signum, prior, 0);

  CRITICAL_REGION(reportLock, {
    if (reportFile)
      {
	reportAllCompilationUnits();
	reportDebugInfo();
	fclose(reportFile);
	reportFile = 0;
      }
  });

  raise(signum);
}


static void initializeOnce()
{
  openReportFile();
  if (reportFile)
    {
      atexit(finalize);
      SIGNAL_INST(ABRT);
      SIGNAL_INST(BUS);
      SIGNAL_INST(FPE);
      SIGNAL_INST(SEGV);
      SIGNAL_INST(TRAP);
    }
}


__attribute__((constructor)) static void initialize()
{
  CRITICAL_REGION(reportLock, {
    sampler_once(&reportInitOnce, initializeOnce);
  });
}
