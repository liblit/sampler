#include <assert.h>
#include <gsl/gsl_randist.h>
#include <limits.h>
#include "countdown.h"


unsigned nextEventCountdown = UINT_MAX;

double density;
gsl_rng *generator;


unsigned getNextCountdown()
{
  unsigned result;
  assert(generator);
  result = gsl_ran_geometric(generator, density);
  assert(result > 0);
  return result;
}


__attribute__((constructor)) static void initialize()
{
  const char * const environ = getenv("SAMPLER_SPARSITY");
  if (environ)
    {
      char *end;
      const double sparsity = strtod(environ, &end);
      if (*end != '\0')
	{
	  fprintf(stderr, "countdown: trailing garbage in $SAMPLER_SPARSITY: %s", end);
	  exit(2);
	}
      else if (sparsity < 1)
	{
	  fputs("countdown: $SAMPLER_SPARSITY must be at least 1", stderr);
	  exit(2);
	}
      else
	density = 1 / sparsity;
    }
  else
    {
      fputs("countdown: must give sampling sparsity in $SAMPLER_SPARSITY\n", stderr);
      exit(2);
    }
  
  assert(!generator);
  generator = gsl_rng_alloc(gsl_rng_env_setup());
  nextEventCountdown = getNextCountdown();
}


__attribute__((destructor)) static void shutdown()
{
  assert(generator);
  gsl_rng_free(generator);
  generator = 0;
}
