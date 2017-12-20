# HWMakefile.mk
#

UCFLAGS =  -g -Wall -DNeedHwMutex
LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
