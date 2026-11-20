/* Let SDK dexdump read an already-open anonymous APK-derived descriptor.
 * Android's host utility uses O_NOFOLLOW, which rejects /proc/self/fd links.
 * This shim only removes that flag for an inherited self-fd path. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>

static int adjusted(const char *path, int flags) {
    if (path && strncmp(path, "/proc/self/fd/", 14) == 0) return flags & ~O_NOFOLLOW;
    return flags;
}
int open(const char *path, int flags, ...) {
    static int (*real_open)(const char *, int, ...) = 0;
    if (!real_open) real_open = dlsym(RTLD_NEXT, "open");
    mode_t mode = 0;
    if (flags & O_CREAT) { va_list ap; va_start(ap, flags); mode = va_arg(ap, int); va_end(ap); }
    return real_open(path, adjusted(path, flags), mode);
}
int open64(const char *path, int flags, ...) {
    static int (*real_open64)(const char *, int, ...) = 0;
    if (!real_open64) real_open64 = dlsym(RTLD_NEXT, "open64");
    mode_t mode = 0;
    if (flags & O_CREAT) { va_list ap; va_start(ap, flags); mode = va_arg(ap, int); va_end(ap); }
    return real_open64(path, adjusted(path, flags), mode);
}
