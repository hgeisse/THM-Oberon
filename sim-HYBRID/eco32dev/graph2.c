/*
 * graph2.c -- graphics controller 2 simulation
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>

#include "common.h"
#include "console.h"
#include "error.h"
#include "except.h"
#include "graph2.h"
#include "mouse.h"
#include "kbd.h"


static Bool debug = false;
static Bool volatile installed = false;


/**************************************************************/
/**************************************************************/

/* common definitions, global variables */


#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>


#define WINDOW_SIZE_X		1024
#define WINDOW_SIZE_Y		768
#define WINDOW_POS_X		0
#define WINDOW_POS_Y		0


#define C2B(c,ch)		(((((c) & 0xFF) * ch.scale) >> 8) * ch.factor)
#define RGB2PIXEL(r,g,b)	(0xFF000000 | \
				 C2B(r, vga.red) | \
				 C2B(g, vga.green) | \
				 C2B(b, vga.blue))

#define B2C(b,ch)		(((((b) / ch.factor) << 8) / ch.scale) & 0xFF)
#define PIXEL2R(p)		B2C(p, vga.red)
#define PIXEL2G(p)		B2C(p, vga.green)
#define PIXEL2B(p)		B2C(p, vga.blue)


typedef struct {
  unsigned long scale;
  unsigned long factor;
} ColorChannel;


typedef struct {
  int argc;
  char **argv;
  Display *display;
  Window win;
  GC gc;
  XImage *image;
  ColorChannel red, green, blue;
  XExposeEvent expose;
  XClientMessageEvent shutdown;
} VGA;


static VGA vga;


/**************************************************************/

/* monitor server */


static ColorChannel mask2channel(unsigned long mask) {
  unsigned long f;
  ColorChannel ch;

  if (mask == 0) {
    error("color mask is 0 in mask2channel");
  }
  for (f = 1; (mask & 1) == 0; f <<= 1) {
    mask >>= 1;
  }
  ch.factor = f;
  ch.scale = mask + 1;
  while ((mask & 1) != 0) {
    mask >>= 1;
  }
  if (mask != 0) {
    error("scattered color mask bits in mask2channel");
  }
  return ch;
}


static Cursor makeBlankCursor(Display *display, Window win) {
  char data[1] = { 0 };
  Pixmap blank;
  XColor dummy;
  Cursor cursor;

  blank = XCreateBitmapFromData(display, win, data, 1, 1);
  cursor = XCreatePixmapCursor(display, blank, blank,
                               &dummy, &dummy, 0, 0);
  XFreePixmap(display, blank);
  return cursor;
}


static void initMonitor(int argc, char *argv[]) {
  int screenNum;
  Window rootWin;
  XVisualInfo visualTemp;
  XVisualInfo *visualInfo;
  int visualCount;
  int bestMatch;
  int bestDepth;
  Visual *visual;
  int i;
  unsigned long pixel;
  int x, y;
  Colormap colormap;
  XSetWindowAttributes attrib;
  XSizeHints *sizeHints;
  XWMHints *wmHints;
  XClassHint *classHints;
  XTextProperty windowName;
  XGCValues gcValues;

  /* connect to X server */
  if (XInitThreads() == 0) {
    error("no thread support for X11");
  }
  vga.display = XOpenDisplay(NULL);
  if (vga.display == NULL) {
    error("cannot connect to X server");
  }
  screenNum = DefaultScreen(vga.display);
  rootWin = RootWindow(vga.display, screenNum);
  /* find TrueColor visual */
  visualTemp.screen = screenNum;
  visualTemp.class = TrueColor;
  visualInfo = XGetVisualInfo(vga.display,
                              VisualClassMask | VisualScreenMask,
                              &visualTemp, &visualCount);
  if (visualInfo == NULL || visualCount == 0) {
    error("no TrueColor visual found");
  }
  bestMatch = 0;
  bestDepth = visualInfo[0].depth;
  visual = visualInfo[0].visual;
  for (i = 1; i < visualCount; i++) {
    if (visualInfo[i].depth > bestDepth) {
      bestMatch = i;
      bestDepth = visualInfo[i].depth;
      visual = visualInfo[i].visual;
    }
  }
  /* build color channels */
  vga.red = mask2channel(visualInfo[bestMatch].red_mask);
  vga.green = mask2channel(visualInfo[bestMatch].green_mask);
  vga.blue = mask2channel(visualInfo[bestMatch].blue_mask);
  /* create and initialize image */
  vga.image = XCreateImage(vga.display, visual, bestDepth, ZPixmap,
                           0, NULL, WINDOW_SIZE_X, WINDOW_SIZE_Y, 32, 0);
  if (vga.image == NULL) {
    error("cannot allocate image");
  }
  vga.image->data = malloc(vga.image->height * vga.image->bytes_per_line);
  if (vga.image->data == NULL) {
    error("cannot allocate image memory");
  }
  pixel = RGB2PIXEL(0, 0, 0);
  for (y = 0; y < WINDOW_SIZE_Y; y++) {
    for (x = 0; x < WINDOW_SIZE_X; x++) {
      XPutPixel(vga.image, x, y, pixel);
    }
  }
  /* allocate a colormap */
  colormap = XCreateColormap(vga.display, rootWin, visual, AllocNone);
  /* create the window */
  attrib.colormap = colormap;
  attrib.event_mask = ExposureMask |
                      PointerMotionMask |
                      ButtonPressMask | ButtonReleaseMask |
                      KeyPressMask | KeyReleaseMask;
  attrib.background_pixel = RGB2PIXEL(0, 0, 0);
  attrib.border_pixel = RGB2PIXEL(0, 0, 0);
  vga.win =
    XCreateWindow(vga.display, rootWin,
                  WINDOW_POS_X, WINDOW_POS_Y,
                  WINDOW_SIZE_X, WINDOW_SIZE_Y,
                  0, bestDepth, InputOutput, visual,
                  CWEventMask | CWColormap | CWBackPixel | CWBorderPixel,
                  &attrib);
  /* give hints to window manager */
  sizeHints = XAllocSizeHints();
  wmHints = XAllocWMHints();
  classHints = XAllocClassHint();
  if (sizeHints == NULL ||
      wmHints == NULL ||
      classHints == NULL) {
    error("hint allocation failed");
  }
  sizeHints->flags = PMinSize | PMaxSize;
  sizeHints->min_width = WINDOW_SIZE_X;
  sizeHints->min_height = WINDOW_SIZE_Y;
  sizeHints->max_width = WINDOW_SIZE_X;
  sizeHints->max_height = WINDOW_SIZE_Y;
  wmHints->flags = StateHint | InputHint;
  wmHints->input = True;
  wmHints->initial_state = NormalState;
  classHints->res_name = "ECO32";
  classHints->res_class = "ECO32";
  if (XStringListToTextProperty(&classHints->res_name, 1, &windowName) == 0) {
    error("property allocation failed");
  }
  XSetWMProperties(vga.display, vga.win, &windowName, NULL,
                   argv, argc, sizeHints, wmHints, classHints);
  /* create a GC */
  vga.gc = XCreateGC(vga.display, vga.win, 0, &gcValues);
  /* create an invisible cursor (the application rolls its own) */
  XDefineCursor(vga.display, vga.win,
                makeBlankCursor(vga.display, vga.win));
  /* finally get the window displayed */
  XMapWindow(vga.display, vga.win);
  /* prepare expose event */
  vga.expose.type = Expose;
  vga.expose.display = vga.display;
  vga.expose.window = vga.win;
  vga.expose.x = 0;
  vga.expose.y = 0;
  vga.expose.width = WINDOW_SIZE_X;
  vga.expose.height = WINDOW_SIZE_Y;
  vga.expose.count = 0;
  /* prepare shutdown event */
  vga.shutdown.type = ClientMessage;
  vga.shutdown.display = vga.display;
  vga.shutdown.window = vga.win;
  vga.shutdown.message_type = XA_WM_COMMAND;
  vga.shutdown.format = 8;
  /* say that the graphics controller is installed */
  XSync(vga.display, False);
  installed = true;
}


static void exitMonitor(void) {
  XFreeGC(vga.display, vga.gc);
  XUnmapWindow(vga.display, vga.win);
  XDestroyWindow(vga.display, vga.win);
  XDestroyImage(vga.image);
  XCloseDisplay(vga.display);
  installed = false;
}


static int ioErrorHandler(Display *display) {
  error("connection to monitor window lost");
  /* never reached */
  return 0;
}


static void *server(void *ignore) {
  Bool run;
  XEvent event;

  initMonitor(vga.argc, vga.argv);
  XSetIOErrorHandler(ioErrorHandler);
  run = true;
  while (run) {
    XNextEvent(vga.display, &event);
    switch (event.type) {
      case Expose:
        XPutImage(vga.display, vga.win, vga.gc, vga.image,
                  event.xexpose.x, event.xexpose.y,
                  event.xexpose.x, event.xexpose.y,
                  event.xexpose.width, event.xexpose.height);
        break;
      case ClientMessage:
        if (event.xclient.message_type == XA_WM_COMMAND &&
            event.xclient.format == 8) {
          run = false;
        }
        break;
      case MotionNotify:
        mouseMoved(event.xmotion.x, event.xmotion.y);
        break;
      case ButtonPress:
        mouseButtonPressed(event.xbutton.button);
        break;
      case ButtonRelease:
        mouseButtonReleased(event.xbutton.button);
        break;
      case KeyPress:
        keyPressed(event.xkey.keycode);
        break;
      case KeyRelease:
        keyReleased(event.xkey.keycode);
        break;
      default:
        break;
    }
  }
  exitMonitor();
  return NULL;
}


/**************************************************************/

/* refresh timer */


static Bool volatile refreshRunning = false;


static void *refresh(void *ignore) {
  struct timespec delay;

  while (refreshRunning) {
    XSendEvent(vga.display, vga.win, False, 0, (XEvent *) &vga.expose);
    XFlush(vga.display);
    delay.tv_sec = 0;
    delay.tv_nsec = 20 * 1000 * 1000;
    nanosleep(&delay, &delay);
  }
  return NULL;
}


/**************************************************************/

/* server interface */


static int myArgc = 1;
static char *myArgv[] = {
  "eco32",
  NULL
};

static pthread_t monitorThread;
static pthread_t refreshThread;


static void vgaInit(void) {
  /* start monitor server in a separate thread */
  vga.argc = myArgc;
  vga.argv = myArgv;
  if (pthread_create(&monitorThread, NULL, server, NULL) != 0) {
    error("cannot start monitor server");
  }
  while (!installed) ;
  /* start refresh timer in another thread */
  refreshRunning = true;
  if (pthread_create(&refreshThread, NULL, refresh, NULL) != 0) {
    error("cannot start refresh timer");
  }
}


static void vgaExit(void) {
  refreshRunning = false;
  pthread_join(refreshThread, NULL);
  XSendEvent(vga.display, vga.win, False, 0, (XEvent *) &vga.shutdown);
  XSync(vga.display, False);
  pthread_join(monitorThread, NULL);
}


static void vgaWrite(int x, int y, int r, int g, int b) {
  XPutPixel(vga.image, x, y, RGB2PIXEL(r, g, b));
}


static void vgaRead(int x, int y, int *r, int *g, int *b) {
  unsigned long pixel;

  pixel = XGetPixel(vga.image, x, y);
  *r = PIXEL2R(pixel);
  *g = PIXEL2G(pixel);
  *b = PIXEL2B(pixel);
}


/**************************************************************/
/**************************************************************/

/* loading the splash screen */


#define BACKGROUND		0
#define FOREGROUND		1


static int colors[2] = {
  0x007CD4D6,			/* background */
  0x00000000			/* foreground */
};


static int splashData[] = {
#include "gr2splash"
};


static void loadSplashScreen(void) {
  int sum, i;
  int count;
  int plane;
  int x, y;
  int r, g, b;

  /* check splash data */
  sum = 0;
  for (i = 0; i < sizeof(splashData)/sizeof(splashData[0]); i++) {
    sum += splashData[i];
  }
  if (sum != WINDOW_SIZE_X * WINDOW_SIZE_Y) {
    return;
  }
  /* display splash data */
  count = 0;
  plane = FOREGROUND;
  i = 0;
  for (y = 0; y < WINDOW_SIZE_Y; y++) {
    for (x = 0; x < WINDOW_SIZE_X; x++) {
      while (count == 0) {
        plane = (plane == BACKGROUND ? FOREGROUND : BACKGROUND);
        r = (colors[plane] >> 16) & 0xFF;
        g = (colors[plane] >>  8) & 0xFF;
        b = (colors[plane] >>  0) & 0xFF;
        count = splashData[i++];
      }
      count--;
      vgaWrite(x, y, r, g, b);
    }
  }
}


/**************************************************************/

/* graphics device interface */


Word graph2Read(Word addr) {
  int x, y;
  int i;
  int r, g, b;
  Word data;

  if (debug) {
    cPrintf("\n**** GRAPH2 READ from 0x%08X", addr);
  }
  if (!installed) {
    throwException(EXC_BUS_TIMEOUT);
  }
  if (addr >= WINDOW_SIZE_X * WINDOW_SIZE_Y / 8) {
    throwException(EXC_BUS_TIMEOUT);
  }
  /* read pixels from frame buffer memory */
  x = (addr << 3) % WINDOW_SIZE_X;
  y = (addr << 3) / WINDOW_SIZE_X;
  data = 0;
  for (i = 0; i < 32; i++) {
    vgaRead(x + i, y, &r, &g, &b);
    if (r == ((colors[FOREGROUND] >> 16) & 0xFF) &&
        g == ((colors[FOREGROUND] >>  8) & 0xFF) &&
        b == ((colors[FOREGROUND] >>  0) & 0xFF)) {
      data |= (0x80000000 >> i);
    }
  }
  if (debug) {
    cPrintf(", data = 0x%08X ****\n", data);
  }
  return data;
}


void graph2Write(Word addr, Word data) {
  int x, y;
  int i;
  int plane;
  int r, g, b;

  if (debug) {
    cPrintf("\n**** GRAPH2 WRITE to 0x%08X, data = 0x%08X ****\n",
            addr, data);
  }
  if (!installed) {
    throwException(EXC_BUS_TIMEOUT);
  }
  if (addr >= WINDOW_SIZE_X * WINDOW_SIZE_Y / 8) {
    throwException(EXC_BUS_TIMEOUT);
  }
  /* write pixels to frame buffer memory */
  x = (addr << 3) % WINDOW_SIZE_X;
  y = (addr << 3) / WINDOW_SIZE_X;
  for (i = 0; i < 32; i++) {
    plane = (data & (0x80000000 >> i)) ? FOREGROUND : BACKGROUND;
    r = (colors[plane] >> 16) & 0xFF;
    g = (colors[plane] >>  8) & 0xFF;
    b = (colors[plane] >>  0) & 0xFF;
    vgaWrite(x + i, y, r, g, b);
  }
}


void graph2Reset(void) {
  if (!installed) {
    return;
  }
  cPrintf("Resetting Graphics2...\n");
  loadSplashScreen();
}


void graph2Init(void) {
  vgaInit();
  graph2Reset();
}


void graph2Exit(void) {
  if (!installed) {
    return;
  }
  vgaExit();
}
