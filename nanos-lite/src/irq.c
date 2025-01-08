#include <common.h>
#define EVENT_YIELD 1
static Context* do_event(Event e, Context* c) {
  printf("Received event %d\n", e.event);
  switch (e.event) {
    case EVENT_YIELD : 
      printf("Received event 1\n");
      break;
    default: panic("Unhandled event ID = %d", e.event);
  }

  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
