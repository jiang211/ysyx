#include <common.h>
#define EVENT_YIELD 1
static Context* do_event(Event e, Context* c) {
  switch (e.event) {
    case EVENT_YIELD: printf("event 's ID = 1\n",e.event);c->mepc += 4;break;
    default: panic("Unhandled event ID = %d", e.event);
  }

  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
