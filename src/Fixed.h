#ifndef FIXED_H
#define FIXED_H

#include <sys/types.h>
#include "SizedTypes.h"

#define fixed(a) (int)((double)a * 4096)

#define FIXED_MAX 0x7FFFFFFF
#define FIXED_MIN 0x80000000

#endif