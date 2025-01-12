#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;
static int canvas_x = 0, canvas_y = 0;
uint32_t init_time = 0 ;

uint32_t NDL_GetTicks() {
	struct timeval tv;
	gettimeofday(&tv,NULL);
  if( init_time == 0 ) {
    init_time = tv.tv_sec * 1000 + tv.tv_usec/1000;
  }
  uint32_t now = tv.tv_sec * 1000 + tv.tv_usec/1000;
  uint32_t total_time = (now - init_time);
  return total_time;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events",0,0);
  
  return read(fd,buf,len);
}

void NDL_OpenCanvas(int *w, int *h) {
  assert( screen_w != 0 && screen_h != 0 );
  if((*w == 0) && (*h == 0)){
    *w = screen_w;
    *h = screen_h;
  }
  canvas_w = *w ; 
  canvas_h = *h ; 
  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}


int NDL_Init(uint32_t flags) {
  // 打开vga的dispinfo文件并解析出屏幕大小
  int vga_fd = open("/proc/dispinfo", 0,0);
  char buf[64];
  read(vga_fd, buf, sizeof(buf));
  sscanf(buf, "WIDTH:%d\nHEIGHT:%d\n", &screen_w, &screen_h);
  printf("screen_w:%d, screen_h:%d\n", screen_w, screen_h);

  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
