/* Generated by CIL v. 1.0 */

# 5 "/var/local/liblit/ocaml/sampler/libcountdown/countdown.h"
extern unsigned int nextLogCountdown ;
# 8
extern unsigned int resetCountdown() ;
# 7 "/var/local/liblit/ocaml/sampler/liblog/log.h"
extern void logTableau(void const   * , unsigned int  ) ;
# 4 "multiple.c"
struct _loggerTableau1 {
   char const   file[11] ;
   unsigned int const   line ;
   char const   expr_0[7] ;
   char const   type_0 ;
   int value_0 ;
   char const   end ;
} __attribute__((__packed__)) ;
# 4
static struct _loggerTableau1 _loggerTableau1  =    {"multiple.c", 4U, "addend", 4, 0, 0};
# 11
int main(void) 
{ int addend ;
  int total ;
  unsigned int localCountdown4 ;

  {
  localCountdown4 = nextLogCountdown;
  if (__builtin_expect(localCountdown4 > 1U, 1)) {
    {
# 3
    addend = 3;
    {
# 4
    localCountdown4 --;
# 4
    total = addend + addend * addend;
    }
    }
    {
# 6
    nextLogCountdown = localCountdown4;
# 6
    return (0);
    }
  } else {
    {
# 3
    addend = 3;
    {
# 4
    localCountdown4 --;
# 4
    if (localCountdown4 == 0) {
# 4
      localCountdown4 = resetCountdown();
# 4
      _loggerTableau1.value_0 = addend;
# 4
      logTableau(& _loggerTableau1, sizeof(struct _loggerTableau1 ));
    }
# 4
    total = addend + addend * addend;
    }
    }
    {
# 6
    nextLogCountdown = localCountdown4;
# 6
    return (0);
    }
  }
}
}
