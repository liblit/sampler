#include "anchor.h"
#include "lock.h"
#include "report.h"
#include "unit.h"


struct CompilationUnit compilationUnitAnchor = { &compilationUnitAnchor,
						 &compilationUnitAnchor,
						 "", 0, 0 };


void registerCompilationUnit(struct CompilationUnit *unit)
{
  CRITICAL_REGION({
    unit->prev = &compilationUnitAnchor;
    unit->next = compilationUnitAnchor.next;
    compilationUnitAnchor.next->prev = unit;
    compilationUnitAnchor.next = unit;
  });
}


void unregisterCompilationUnit(struct CompilationUnit *unit)
{
  CRITICAL_REGION({
    if (unit->prev) unit->prev->next = unit->next;
    if (unit->next) unit->next->prev = unit->prev;
    unit->prev = unit->next = 0;

    if (reportFile)
      reportCompilationUnit(unit);
  });
}
