#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char number_buf[128];
void reverse(char *str, int length)
{
  int start = 0;
  int end = length - 1;

  while (start < end)
  {
    char temp = str[start];
    str[start] = str[end];
    str[end] = temp;
    start++;
    end--;
  }
}

static char *sky_itoa(uint32_t num, char *str, int base)
{
  int i = 0;
  int isNegative = 0;

  
  if (num == 0)
  {
    str[i] = '\0';
    return str;
  }
  
  if (num < 0 && base == 10)
  {
    isNegative = 1;
    num = -num;
  }
  uint32_t remainder;
 
  while (num != 0)
  {
    remainder = num % base;
    str[i++] = (remainder > 9) ? (remainder - 10) + 'a' : remainder + '0';
    num = num / base;
  }

  
  if (isNegative)
    str[i++] = '-';

  str[i] = '\0'; 


  reverse(str, i);

  return str;
}

void change_format_x(uint64_t x_number) {
  int i;
  if( x_number == 0 ) {
    number_buf[0] = '0' ;
    number_buf[1] = '0' ;
    number_buf[2] = '\0';
    return ;
  }
  else if ( x_number == 0xffffffffffffffff ) {
    number_buf[0] = '0' ;
    for( i=1; i<17; i++ )  number_buf[i] = 'f';
    number_buf[i] = '\0';
  
  }
  else {
    uint64_t system = 1ull;
    uint64_t bits   = 1ull;
    while( x_number / system != 0ull ) {
      bits ++ ;
      system = system * 16ull ;
      if(bits == 17 )  { system = 0xffffffffffffffff; break; }
    }
    bool modefied = false ;
    for( i=0; i<bits; i++ ) {
      uint64_t bit_number = x_number / system ;
      if(bit_number < 10ull )  number_buf[i] = bit_number + '0' ;
      else                 number_buf[i] = bit_number + 'a' - 10 ;
      x_number = x_number % system ;
      if(bits == 17 && modefied == false ) {
        system = 0x1000000000000000;
        modefied = true;
      }
      else { system = system / 16ull; }
    }
    number_buf[i] = '\0';
  }
}

void change_format_d(int64_t input_number) {
  int64_t d_number = input_number;
  int i;
  if( input_number == 0 ) {
    number_buf[0] = ' ' ;
    number_buf[1] = '0' ;
    number_buf[2] = '\0';
    return ;
  
  }
  if( d_number < 0 )  {
    d_number = - d_number ;
    number_buf[0] = '-' ;
  
  }
  else {
    number_buf[0] = ' ';
  
  }
  int64_t system = 1;
  int64_t bits   = 1;
  while( d_number / system != 0 ) {
    bits ++ ;
    system = system * 10 ;
  }
  system = system / 10;
  for( i=1; i<bits; i++ ) {
    int64_t bit_number = d_number / system ;
    number_buf[i] = bit_number + '0' ;
    d_number = d_number % system ;
    system = system / 10;
  }
  number_buf[i] = '\0';
}

int printf(const char *fmt, ...) {
  int i=0;
  const char *s;
  char buf[17];
  int d,x;
  va_list ap;
  va_start(ap, fmt);
  while(*fmt){
    if (*fmt == '%')
    {
      switch (*++fmt)
      {
      case 'x':
        x = va_arg(ap, int);
        sky_itoa(x, buf, 16);
        for (s = buf; *s; s++)
        {
          putch(*s);
        }
        fmt++;
        break;
      case 's':
        s = va_arg(ap, const char *); 
        for (; *s; s++)
        {
          putch(*s);
        }
        fmt++;
        break;
      case 'c':
        char q = va_arg(ap, int); 
        putch(q);
        fmt++;
        break;
      case 'd':
        d = va_arg(ap, int);
        sky_itoa(d, buf, 10);
        for (s = buf; *s; s++)
        {
          putch(*s);
        }
        fmt++;
        break;
      }
    }
    else
    {
      putch(*fmt);
      fmt++;
    }
    i++;
  }
  
  return i;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}






int sprintf(char *str, const char *fmt, ...)
{
  memset(str, 0, strlen(str));
  const char *s;
  char buf[17];
  int d,x;
  va_list ap;
  int i = 0;
  va_start(ap, fmt);

  while (*fmt)
  {
    if (*fmt == '%')
    {
      switch (*++fmt)
      {
      case 's':
        s = va_arg(ap, const char *); 
        for (; *s; s++)
        {
          *str++ = *s;
        }
        fmt++;
        break;
      case 'd':
        d = va_arg(ap, int);
        sky_itoa(d, buf, 10);
        for (s = buf; *s; s++)
        {
          *str++ = *s;
        }
        fmt++;
        break;
      case 'x':
        x = va_arg(ap, int);
        sky_itoa(x, buf, 16);
        for (s = buf; *s; s++)
        {
          *str++ = *s;
        }
        fmt++;
        break;
      }
    }
    else
    {
      *str++ = *fmt++;
    }
    i++;
  }
  str[i] = '\0';
 
  return i;
}


int snprintf(char *out, size_t n, const char *fmt, ...) {

  size_t len = 0;
  va_list valist;
  va_start(valist, fmt);

  char *out_offset = out;
  char *char_buf ;
  while( *fmt ) {
    if( ( *fmt == '%' && *(fmt+1) == 'x' )  ||
        ( *fmt == '%' && *(fmt+1) == 'p' ) ) {
      uint64_t x_number = va_arg(valist, uint64_t);
      change_format_x(x_number);
      char_buf = number_buf + 1 ;
      while( *char_buf ) {
        *out_offset = *char_buf;
        len++;
        char_buf++;
        out_offset ++;
      }
      fmt++;
    }

    else if( (*fmt == '%' && *(fmt+1) == 'd') || 
        (*fmt == '%' && *(fmt+1) == '0'  && *(fmt+2) == '2' && *(fmt+3) == 'd' ) ) {
      int64_t d_number = va_arg(valist, int64_t);
      printf("2\n");
      change_format_d(d_number);
      char_buf = number_buf ;
      while( *char_buf ) {
        *out_offset = *char_buf ;
        len++;
        char_buf++;
        out_offset ++ ;
      }
      if (*fmt == '%' && *(fmt+1) == '0'  && *(fmt+2) == '2' && *(fmt+3) == 'd' ) {
          fmt = fmt  + 2 ;
      }
      fmt++;
    }

    else if( *fmt == '%' && *(fmt+1) == 's' ) {
      char* string = va_arg(valist, char*);
        while( *string ){
          *out_offset = *string ;
          len++;
        char_buf++;
          string++;
          out_offset++;
        }
      fmt++;
    }

    else if( *fmt == '%' && *(fmt+1) == 'c' ) {
      char character = va_arg(valist, int);
      *out_offset = character ;
      len++;
        char_buf++;
        char_buf++;
      fmt++;
      out_offset ++;
    }

    else {
      *out_offset = *fmt ;
      len++;
      out_offset ++ ;
    }

      fmt++;

  }
  *out_offset = '\0';
  va_end(valist);
  return len;
}
int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
