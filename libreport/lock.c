#include <pthread.h>
#include "lock.h"


pthread_mutex_t reportLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP;
