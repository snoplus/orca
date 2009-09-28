TARGET  = OrcaReadout

# Set to 'true' to compile HW_Readout.cpp as C++.
# fdhwlib requires C++. -tb- 2009-09-25
COMPILE_CPLUSPLUS = true
ifeq ($(COMPILE_CPLUSPLUS),true)
  SOURCES = SBC_Readout.c CircularBuffer.c 
  SOURCESCPP = HW_Readout.cpp 
else
  SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c
  #SOURCESCPP = HW_Readout.cpp 
endif


##SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c
##SOURCESCPP = HW_Readout.cpp 
#SOURCES = SBC_Readout.c CircularBuffer.c 
#SOURCESCPP = HW_Readout.cpp 

CC = gcc
CCPP = g++


OBJECTS = $(SOURCES:.c=.o)
OBJECTSCPP = $(SOURCESCPP:.cpp=.oo)

# RECOMMENDED SETUP:
# It is assuemed that the fdhwlib is compiled in the folder: ~/src/v4
#
# create the folder ~/lib and add following line in .bashrc:
# export LIBRARY_PATH=$LIBRARY_PATH:/home/katrin/lib
# add following line in .bashrc:
# export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/home/katrin/src/v4/fdhwlib/src
# 
# ... to be continued ...
#
# -tb- 2009-09 
# mail: till.bergmann@ipe.fzk.de

#----original flags.... 
#UCFLAGS =  -g -Wall -gstabs+ -D_LINUX -I/usr/local/universe/include
#LFLAGS  = -lpthread -lstdc++ -L/usr/local/universe/lib -luniverse_api

#----add in flags for your driver libraries and include files
#UCFLAGS =  -g -Wall -gstabs+ -D_LINUX -fexceptions 
# ===> use this -tb- !!!!   UCFLAGS =  -g -Wall  -gstabs+
UCFLAGS =  -g -Wall  -gstabs+ -I ~/src/v4/fdhwlib/src -I ~/src/v4/pbusaccess
#Note: -Wno-sign-compare supresses 'comparison int with unsigned int' compiler warning -tb-
#LFLAGS  = -fexceptions -lpbusaccess -lPbus1394 -lakutil -lpthread -lstdc++ \
#                                /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
#                                /System/Library/Frameworks/IOKit.framework/IOKit 

#-tb- Use this for Pbus  simulation mode (yes, -lPbusSim is needed two times!):
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusSim -lHw -lPbusSim  -lakutil -lpthread -lstdc++ 

#-tb- Use this for V4 SLT PbusPCI lib (Linux only!):
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusPCI -lHw -lPbusPCI  -lakutil -lpthread -lstdc++ 
 
#-tb- Use this for V4 SLT PbusPCI lib (Linux only!):
LFLAGS  =  -fexceptions -lpbusaccess -lPbusPCI -lhw4 -lakutil -lpthread -lstdc++ 
 

LIBs    = 

$(TARGET): $(OBJECTS) $(OBJECTSCPP)
	@echo linking $*
	$(CCPP)  -o $(TARGET) $(OBJECTS) $(OBJECTSCPP) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $* using %.o: %.c
	$(CC) -c $(UCFLAGS) $<

%.oo: %.cpp
	@echo compiling $* using %.oo: %.cpp
	$(CCPP) -c $(UCFLAGS) $< -o $*.oo

clean :
	rm $(TARGET) *.o *.oo
