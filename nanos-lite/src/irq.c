#include <common.h>
#define EVENT_YIELD 1
#define EVENT_SYSCALL 2
static Context* do_event(Event e, Context* c) {
  switch (e.event) {
    case EVENT_YIELD: printf("event 's EVENT_YIELD\n");break;
    case EVENT_SYSCALL: printf("event 's EVENT_SYSCALL\n");break;
    default: panic("Unhandled event ID = %d", e.event);
  }

  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
