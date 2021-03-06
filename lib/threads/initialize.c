#include "once.h"
#include "random.h"
#include "report.h"
#include "verbose.h"


static cbi_once_t once = CBI_ONCE_INIT;


static void
initializeOnce()
{
  VERBOSE("begin");
  cbi_initializeVerbose();
  cbi_initializeRandom();
  cbi_initializeReport();
  VERBOSE("end");
}


void cbi_initialize() __attribute__((constructor));
void cbi_initialize()
{
  cbi_once(&once, initializeOnce);
}
