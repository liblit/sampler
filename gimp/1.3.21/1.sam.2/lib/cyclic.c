#define _GNU_SOURCE		/* for PTHREAD_ADAPTIVE_MUTEX_INITIALIZER_NP */

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include "countdown.h"
#include "cyclic.h"
#include "cyclic-size.h"
#include "lock.h"


#define MAP_SIZE (PRECOMPUTE_COUNT * sizeof(unsigned))


const void * const SAMPLER_REENTRANT(providesLibCyclic);

const unsigned *nextEventPrecomputed = 0;
SAMPLER_THREAD_LOCAL unsigned nextEventSlot = 0;

unsigned cyclicInitCount;

pthread_mutex_t cyclicLock = PTHREAD_ADAPTIVE_MUTEX_INITIALIZER_NP;


static void failed(const char function[])
{
  fprintf(stderr, "%s failed: %s\n", function, strerror(errno));
  exit(2);
}


static void *checkedMmap(int prot, int fd)
{
  void * const mapping = mmap(0, MAP_SIZE, prot, MAP_PRIVATE, fd, 0);

  if (mapping == (void *) -1)
    failed("mmap");

  if (close(fd))
    failed("close");

  return mapping;
}


static int checkedOpen(const char filename[])
{
  const int fd = open(filename, O_RDONLY);

  if (fd == -1)
    fprintf(stderr, "open of %s failed: %s\n", filename, strerror(errno));

  return fd;
}


void initialize_thread()
{
  nextEventCountdown = getNextEventCountdown();
}


static void finalize()
{
  CRITICAL_REGION(cyclicLock, {
    if (nextEventPrecomputed)
      {
	munmap((void *) nextEventPrecomputed, MAP_SIZE);
	nextEventPrecomputed = 0;
      }
  });
}


__attribute__((constructor)) static void initialize()
{
  CRITICAL_REGION(cyclicLock, {
    if (!cyclicInitCount++)
      {
	const char envar[] = "SAMPLER_EVENT_COUNTDOWNS";
	const char * const environ = getenv(envar);
	void *mapping;
  
	if (environ)
	  {
	    const int fd = checkedOpen(environ);
	    mapping = checkedMmap(PROT_READ, fd);
	    unsetenv(envar);
	  }
	else
	  {
	    int fd;
	    fprintf(stderr, "%s: no countdowns file named in $%s; using extreme sparsity\n",  __FUNCTION__, envar);
	    fd = checkedOpen("/dev/zero");
	    mapping = checkedMmap(PROT_READ | PROT_WRITE, fd);
	    memset(mapping, -1, MAP_SIZE);
	    mapping = mremap(mapping, MAP_SIZE, MAP_SIZE, PROT_READ);
	    if (mapping == (void *) -1)
	      failed("mremap");
	  }

	atexit(finalize);
	nextEventPrecomputed = (const unsigned *) mapping;
	initialize_thread();
      }
  });
}
