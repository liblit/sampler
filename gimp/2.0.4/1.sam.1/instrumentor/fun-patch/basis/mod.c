/* Generated by CIL v. 1.0 */

struct $statics;
static struct $statics  const  $statics ;
static int (*foo$replacement)(struct $statics  const  * ) ;
# 1 "foo.c"
static int foo(void) 
{ int tmp1 ;

  {
  if (foo$replacement) {
    tmp1 = foo$replacement(& $statics);
    return (tmp1);
  } else {
# 3
    return (7);
  }
}
}
void (*bar$replacement)(struct $statics  const  * , int *y ) ;
# 7 "foo.c"
void bar(int *y ) 
{ 

  {
  if (bar$replacement) {
    bar$replacement(& $statics, y);
  } else {
# 9
    (*y) = foo((*y));
# 9
    return;
  }
}
}
struct $statics {
   int (* const  foo)(void) ;
};
static struct $statics  const  $statics  =    {& foo};
