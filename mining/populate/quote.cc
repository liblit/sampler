#include <clocale>
#include <iomanip>
#include <sstream>
#include "quote.h"


string quote(const char *suspicious, char special)
{
  ostringstream result;
  result << oct << setfill('0');
  
  for (const char *scan = suspicious; *scan; ++scan)
    if (isprint(*scan) && *scan != special)
      result << *scan;
    else
      result << '\\' << setw(3) << (int) *scan;

  return result.str();
}
