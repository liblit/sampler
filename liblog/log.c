#include <stdio.h>
#include "log.h"


int logIsImminent(unsigned within __attribute__((unused)))
{
  return 1;
}


void logWrite(const char filename[], unsigned line,
	      const void *address, unsigned size,
	      const void *data __attribute__((unused)))
{
  fprintf(stderr, "%s:%u: write %p for %u bytes\n",
	  filename, line, address, size);
}


void logSkip()
{
}
