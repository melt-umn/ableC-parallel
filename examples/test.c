typedef unsigned long size_t;
typedef unsigned char __u_char;
typedef unsigned short __u_short;
typedef unsigned int __u_int;
typedef unsigned long __u_long;
typedef char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short __int16_t;
typedef unsigned short __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;
typedef signed long __int64_t;
typedef unsigned long __uint64_t;
typedef signed long __quad_t;
typedef unsigned long __u_quad_t;
typedef unsigned long __dev_t;
typedef unsigned int __uid_t;
typedef unsigned int __gid_t;
typedef unsigned long __ino_t;
typedef unsigned long __ino64_t;
typedef unsigned int __mode_t;
typedef unsigned long __nlink_t;
typedef signed long __off_t;
typedef signed long __off64_t;
typedef signed int __pid_t;
typedef struct  {
  signed int __val[2];
  
} __fsid_t;
typedef signed long __clock_t;
typedef unsigned long __rlim_t;
typedef unsigned long __rlim64_t;
typedef unsigned int __id_t;
typedef signed long __time_t;
typedef unsigned int __useconds_t;
typedef signed long __suseconds_t;
typedef signed int __daddr_t;
typedef signed int __key_t;
typedef signed int __clockid_t;
typedef void  *__timer_t;
typedef signed long __blksize_t;
typedef signed long __blkcnt_t;
typedef signed long __blkcnt64_t;
typedef unsigned long __fsblkcnt_t;
typedef unsigned long __fsblkcnt64_t;
typedef unsigned long __fsfilcnt_t;
typedef unsigned long __fsfilcnt64_t;
typedef signed long __fsword_t;
typedef signed long __ssize_t;
typedef signed long __syscall_slong_t;
typedef unsigned long __syscall_ulong_t;
typedef __off64_t __loff_t;
typedef __quad_t  *__qaddr_t;
typedef char  *__caddr_t;
typedef signed long __intptr_t;
typedef unsigned int __socklen_t;
struct _IO_FILE;
typedef struct _IO_FILE FILE;
typedef struct _IO_FILE __FILE;
typedef struct  {
  signed int __count;
  union  {
    unsigned int __wch;
    char __wchb[4];
    
  } __value;
  
} __mbstate_t;
typedef struct  {
  __off_t __pos;
  __mbstate_t __state;
  
} _G_fpos_t;
typedef struct  {
  __off64_t __pos;
  __mbstate_t __state;
  
} _G_fpos64_t;
typedef __builtin_va_list __gnuc_va_list;
struct _IO_jump_t;
struct _IO_FILE;
typedef void _IO_lock_t;
struct _IO_marker {
  struct _IO_marker  *_next;
  struct _IO_FILE  *_sbuf;
  signed int _pos;
  
};
enum __codecvt_result {
  __codecvt_ok,
  __codecvt_partial,
  __codecvt_error,
  __codecvt_noconv
};
struct _IO_FILE {
  signed int _flags;
  char  *_IO_read_ptr;
  char  *_IO_read_end;
  char  *_IO_read_base;
  char  *_IO_write_base;
  char  *_IO_write_ptr;
  char  *_IO_write_end;
  char  *_IO_buf_base;
  char  *_IO_buf_end;
  char  *_IO_save_base;
  char  *_IO_backup_base;
  char  *_IO_save_end;
  struct _IO_marker  *_markers;
  struct _IO_FILE  *_chain;
  signed int _fileno;
  signed int _flags2;
  __off_t _old_offset;
  unsigned short _cur_column;
  char _vtable_offset;
  char _shortbuf[1];
  _IO_lock_t  *_lock;
  __off64_t _offset;
  void  *__pad1;
  void  *__pad2;
  void  *__pad3;
  void  *__pad4;
  size_t __pad5;
  signed int _mode;
  char _unused2[(((15 * (sizeof(signed int))) - (4 * (sizeof(void *)))) - (sizeof(size_t)))];
  
};
typedef struct _IO_FILE _IO_FILE;
struct _IO_FILE_plus;
extern struct _IO_FILE_plus _IO_2_1_stdin_;
extern struct _IO_FILE_plus _IO_2_1_stdout_;
extern struct _IO_FILE_plus _IO_2_1_stderr_;
typedef __ssize_t __io_read_fn(void  * __cookie, char  * __buf, size_t  __nbytes);
typedef __ssize_t __io_write_fn(void  * __cookie, const char  * __buf, size_t  __n);
typedef signed int __io_seek_fn(void  * __cookie, __off64_t  * __pos, signed int  __w);
typedef signed int __io_close_fn(void  * __cookie);
extern signed int __underflow(_IO_FILE  * );
extern signed int __uflow(_IO_FILE  * );
extern signed int __overflow(_IO_FILE  * , signed int  );
extern signed int _IO_getc(_IO_FILE  * __fp);
extern signed int _IO_putc(signed int  __c, _IO_FILE  * __fp);
extern signed int _IO_feof(_IO_FILE  * __fp) __attribute__((__nothrow__, __leaf__));
extern signed int _IO_ferror(_IO_FILE  * __fp) __attribute__((__nothrow__, __leaf__));
extern signed int _IO_peekc_locked(_IO_FILE  * __fp);
extern void _IO_flockfile(_IO_FILE  * ) __attribute__((__nothrow__, __leaf__));
extern void _IO_funlockfile(_IO_FILE  * ) __attribute__((__nothrow__, __leaf__));
extern signed int _IO_ftrylockfile(_IO_FILE  * ) __attribute__((__nothrow__, __leaf__));
extern signed int _IO_vfscanf(_IO_FILE  *__restrict  , const char  *__restrict  , __gnuc_va_list  , signed int  *__restrict  );
extern signed int _IO_vfprintf(_IO_FILE  *__restrict  , const char  *__restrict  , __gnuc_va_list  );
extern __ssize_t _IO_padn(_IO_FILE  * , signed int  , __ssize_t  );
extern size_t _IO_sgetn(_IO_FILE  * , void  * , size_t  );
extern __off64_t _IO_seekoff(_IO_FILE  * , __off64_t  , signed int  , signed int  );
extern __off64_t _IO_seekpos(_IO_FILE  * , __off64_t  , signed int  );
extern void _IO_free_backup_area(_IO_FILE  * ) __attribute__((__nothrow__, __leaf__));
typedef __gnuc_va_list va_list;
typedef __off_t off_t;
typedef __ssize_t ssize_t;
typedef _G_fpos_t fpos_t;
extern struct _IO_FILE  *stdin;
extern struct _IO_FILE  *stdout;
extern struct _IO_FILE  *stderr;
extern signed int remove(const char  * __filename) __attribute__((__nothrow__, __leaf__));
extern signed int rename(const char  * __old, const char  * __new) __attribute__((__nothrow__, __leaf__));
extern signed int renameat(signed int  __oldfd, const char  * __old, signed int  __newfd, const char  * __new) __attribute__((__nothrow__, __leaf__));
extern FILE  *tmpfile(void);
extern char  *tmpnam(char  * __s) __attribute__((__nothrow__, __leaf__));
extern signed int fclose(FILE  * __stream);
extern signed int fflush(FILE  * __stream);
extern FILE  *fopen(const char  *__restrict  __filename, const char  *__restrict  __modes);
extern FILE  *freopen(const char  *__restrict  __filename, const char  *__restrict  __modes, FILE  *__restrict  __stream);
extern FILE  *fdopen(signed int  __fd, const char  * __modes) __attribute__((__nothrow__, __leaf__));
extern FILE  *fmemopen(void  * __s, size_t  __len, const char  * __modes) __attribute__((__nothrow__, __leaf__));
extern FILE  *open_memstream(char  * * __bufloc, size_t  * __sizeloc) __attribute__((__nothrow__, __leaf__));
extern void setbuf(FILE  *__restrict  __stream, char  *__restrict  __buf) __attribute__((__nothrow__, __leaf__));
extern signed int setvbuf(FILE  *__restrict  __stream, char  *__restrict  __buf, signed int  __modes, size_t  __n) __attribute__((__nothrow__, __leaf__));
extern signed int fprintf(FILE  *__restrict  __stream, const char  *__restrict  __format, ...);
extern signed int printf(const char  *__restrict  __format, ...);
extern signed int sprintf(char  *__restrict  __s, const char  *__restrict  __format, ...) __attribute__((__nothrow__));
extern signed int vfprintf(FILE  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg);
extern signed int vprintf(const char  *__restrict  __format, __gnuc_va_list  __arg);
extern signed int vsprintf(char  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg) __attribute__((__nothrow__));
extern signed int snprintf(char  *__restrict  __s, size_t  __maxlen, const char  *__restrict  __format, ...) __attribute__((__nothrow__)) __attribute__((__format__(__printf__, 3, 4)));
extern signed int vsnprintf(char  *__restrict  __s, size_t  __maxlen, const char  *__restrict  __format, __gnuc_va_list  __arg) __attribute__((__nothrow__)) __attribute__((__format__(__printf__, 3, 0)));
extern signed int vdprintf(signed int  __fd, const char  *__restrict  __fmt, __gnuc_va_list  __arg) __attribute__((__format__(__printf__, 2, 0)));
extern signed int dprintf(signed int  __fd, const char  *__restrict  __fmt, ...) __attribute__((__format__(__printf__, 2, 3)));
extern signed int fscanf(FILE  *__restrict  __stream, const char  *__restrict  __format, ...);
extern signed int scanf(const char  *__restrict  __format, ...);
extern signed int sscanf(const char  *__restrict  __s, const char  *__restrict  __format, ...) __attribute__((__nothrow__, __leaf__));
extern signed int fscanf(FILE  *__restrict  __stream, const char  *__restrict  __format, ...) __asm__("" "__isoc99_fscanf");
extern signed int scanf(const char  *__restrict  __format, ...) __asm__("" "__isoc99_scanf");
extern signed int sscanf(const char  *__restrict  __s, const char  *__restrict  __format, ...) __asm__("" "__isoc99_sscanf") __attribute__((__nothrow__, __leaf__));
extern signed int vfscanf(FILE  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg) __attribute__((__format__(__scanf__, 2, 0)));
extern signed int vscanf(const char  *__restrict  __format, __gnuc_va_list  __arg) __attribute__((__format__(__scanf__, 1, 0)));
extern signed int vsscanf(const char  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg) __attribute__((__nothrow__, __leaf__)) __attribute__((__format__(__scanf__, 2, 0)));
extern signed int vfscanf(FILE  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg) __asm__("" "__isoc99_vfscanf") __attribute__((__format__(__scanf__, 2, 0)));
extern signed int vscanf(const char  *__restrict  __format, __gnuc_va_list  __arg) __asm__("" "__isoc99_vscanf") __attribute__((__format__(__scanf__, 1, 0)));
extern signed int vsscanf(const char  *__restrict  __s, const char  *__restrict  __format, __gnuc_va_list  __arg) __asm__("" "__isoc99_vsscanf") __attribute__((__nothrow__, __leaf__)) __attribute__((__format__(__scanf__, 2, 0)));
extern signed int fgetc(FILE  * __stream);
extern signed int getc(FILE  * __stream);
extern signed int getchar(void);
extern signed int getc_unlocked(FILE  * __stream);
extern signed int getchar_unlocked(void);
extern signed int fputc(signed int  __c, FILE  * __stream);
extern signed int putc(signed int  __c, FILE  * __stream);
extern signed int putchar(signed int  __c);
extern signed int putc_unlocked(signed int  __c, FILE  * __stream);
extern signed int putchar_unlocked(signed int  __c);
extern char  *fgets(char  *__restrict  __s, signed int  __n, FILE  *__restrict  __stream);
extern __ssize_t __getdelim(char  * *__restrict  __lineptr, size_t  *__restrict  __n, signed int  __delimiter, FILE  *__restrict  __stream);
extern __ssize_t getdelim(char  * *__restrict  __lineptr, size_t  *__restrict  __n, signed int  __delimiter, FILE  *__restrict  __stream);
extern __ssize_t getline(char  * *__restrict  __lineptr, size_t  *__restrict  __n, FILE  *__restrict  __stream);
extern signed int fputs(const char  *__restrict  __s, FILE  *__restrict  __stream);
extern signed int puts(const char  * __s);
extern signed int ungetc(signed int  __c, FILE  * __stream);
extern size_t fread(void  *__restrict  __ptr, size_t  __size, size_t  __n, FILE  *__restrict  __stream);
extern size_t fwrite(const void  *__restrict  __ptr, size_t  __size, size_t  __n, FILE  *__restrict  __s);
extern signed int fseek(FILE  * __stream, signed long  __off, signed int  __whence);
extern signed long ftell(FILE  * __stream);
extern void rewind(FILE  * __stream);
extern signed int fseeko(FILE  * __stream, __off_t  __off, signed int  __whence);
extern __off_t ftello(FILE  * __stream);
extern signed int fgetpos(FILE  *__restrict  __stream, fpos_t  *__restrict  __pos);
extern signed int fsetpos(FILE  * __stream, const fpos_t  * __pos);
extern void clearerr(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern signed int feof(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern signed int ferror(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern void perror(const char  * __s);
extern signed int fileno(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern FILE  *popen(const char  * __command, const char  * __modes);
extern signed int pclose(FILE  * __stream);
extern char  *ctermid(char  * __s) __attribute__((__nothrow__, __leaf__));
extern void flockfile(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern signed int ftrylockfile(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
extern void funlockfile(FILE  * __stream) __attribute__((__nothrow__, __leaf__));
signed int f(signed int  z)
{

  ;
  {
    return ((((z) << 4)) * (((z) >> 1)));
  }
}
signed int main()
{

  ;
  {
    signed int x;
    ((x) = ((f)(4)));
    ((f)(99));
    ((x) += ((f)(7)));
    ({
      ((printf)("Hi!\n"));
      ((f)(4)); })
    ;
    ;
    for (signed int i = 0; ((i) < 10); ((i)++))
    {
      ((printf)("%d\n", (i)));
    }
    for (signed int i = 0; ((i) < 53); ((i) += 2))
    {
      {
        ((printf)("%d\n", (i)));
      }
    }
    for (signed int i = 0; ((i) > (-10)); ((i)--))
    {
      ((printf)("Hello\n"));
    }
    for (signed int i = 0; ((i) < 100); ((i) += 7))
    {
      {
        ((printf)("Bad...\n"));
      }
    }
    for (signed int i = 8; ((i) < 12); ((i) += 1))
    {
      {
        ((printf)("Testing...\n"));
      }
    }
    for (signed int i = 9; ((i) < 35); ((i) += 2))
    {
      {
        ((printf)("Test: %d\n", ((f)(7))));
        ((printf)("Testing... %d\n", ((f)(77))));
      }
    }
  }
}
