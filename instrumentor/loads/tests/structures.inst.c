/* Generated by CIL v. 1.0 */

# 11 "structures.c"
struct Node {
   double value ;
   struct Node *next ;
};
# 11
typedef struct Node Node;
# 7
struct Multinode {
   int count ;
   Node node ;
};
# 7
typedef struct Multinode Multinode;
# 5 "/var/local/liblit/ocaml/sampler/libcountdown/countdown.h"
extern unsigned int nextLogCountdown ;
# 8
extern unsigned int resetCountdown() ;
# 7 "/var/local/liblit/ocaml/sampler/liblog/log.h"
extern void logTableau(void const   * , unsigned int  ) ;
# 17 "structures.c"
struct _loggerTableau3 {
   char const   file[13] ;
   unsigned int const   line ;
   char const   expr_1[7] ;
   char const   type_1 ;
   void const   *value_1 ;
   char const   expr_0[8] ;
   char const   type_0 ;
   double value_0 ;
   char const   end ;
} __attribute__((__packed__)) ;
# 17
static struct _loggerTableau3 _loggerTableau3  = 
# 17
     {"structures.c", 17U, "a.next", 15, (void const   *)0, "a.value", 13, 0, 0};
# 19
struct _loggerTableau2 {
   char const   file[13] ;
   unsigned int const   line ;
   char const   expr_0[12] ;
   char const   type_0 ;
   void const   *value_0 ;
   char const   end ;
} __attribute__((__packed__)) ;
# 19
static struct _loggerTableau2 _loggerTableau2  =    {"structures.c", 19U, "b.node.next", 15, (void const   *)0, 0};
# 17
struct _loggerTableau1 {
   char const   file[13] ;
   unsigned int const   line ;
   char const   expr_0[2] ;
   char const   type_0 ;
   int value_0 ;
   char const   end ;
} __attribute__((__packed__)) ;
# 17
static struct _loggerTableau1 _loggerTableau1  =    {"structures.c", 17U, "x", 4, 0, 0};
# 13
int main(void) 
{ int x ;
  Node a ;
  Multinode b ;
  unsigned int localCountdown5 ;

  {
  localCountdown5 = nextLogCountdown;
  if (__builtin_expect(localCountdown5 > 3U, 1)) {
    {
# 15
    x = 7;
# 16
    a.value = 3.14;
# 16
    a.next = (struct Node *)0;
    {
# 17
    localCountdown5 --;
# 17
    b.count = x;
    }
    {
# 17
    localCountdown5 --;
# 17
    b.node = a;
    }
# 18
    b.node.next = & a;
    {
# 19
    localCountdown5 --;
# 19
    (b.node.next)->value = 2.7;
    }
    }
    {
# 21
    nextLogCountdown = localCountdown5;
# 21
    return (0);
    }
  } else {
    {
# 15
    x = 7;
# 16
    a.value = 3.14;
# 16
    a.next = (struct Node *)0;
    {
# 17
    localCountdown5 --;
# 17
    if (localCountdown5 == 0) {
# 17
      localCountdown5 = resetCountdown();
# 17
      _loggerTableau1.value_0 = x;
# 17
      logTableau(& _loggerTableau1, sizeof(struct _loggerTableau1 ));
    }
# 17
    b.count = x;
    }
    {
# 17
    localCountdown5 --;
# 17
    if (localCountdown5 == 0) {
# 17
      localCountdown5 = resetCountdown();
# 17
      _loggerTableau3.value_1 = (void const   *)a.next;
# 17
      _loggerTableau3.value_0 = a.value;
# 17
      logTableau(& _loggerTableau3, sizeof(struct _loggerTableau3 ));
    }
# 17
    b.node = a;
    }
# 18
    b.node.next = & a;
    {
# 19
    localCountdown5 --;
# 19
    if (localCountdown5 == 0) {
# 19
      localCountdown5 = resetCountdown();
# 19
      _loggerTableau2.value_0 = (void const   *)b.node.next;
# 19
      logTableau(& _loggerTableau2, sizeof(struct _loggerTableau2 ));
    }
# 19
    (b.node.next)->value = 2.7;
    }
    }
    {
# 21
    nextLogCountdown = localCountdown5;
# 21
    return (0);
    }
  }
}
}
