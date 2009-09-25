TARGET  = OrcaReadout
SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c 


OBJECTS = $(SOURCES:.c=.o)

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
UCFLAGS =  -g -Wall  -gstabs+ -I/home/katrin/src/v4/feshell/src -I/home/katrin/src/v4/pbusaccess
#LFLAGS  = -fexceptions -lpbusaccess -lPbus1394 -lakutil -lpthread -lstdc++ \
#                                /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
#                                /System/Library/Frameworks/IOKit.framework/IOKit 

#-tb- Use this for Pbus  simulation mode (yes, -lPbusSim is needed two times!):
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusSim -lHw -lPbusSim  -lakutil -lpthread -lstdc++ 

#-tb- Use this for V4 SLT PbusPCI lib (Linux only!):
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusPCI -lHw -lPbusPCI  -lakutil -lpthread -lstdc++ 
 
#-tb- Use this for V4 SLT PbusPCI lib (Linux only!):
LFLAGS  =  -fexceptions -lpbusaccess -lPbusPCI -lHw -lPbusPCI  -lakutil -lpthread -lstdc++ 
 

LIBs    = 

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CC)  -o $(TARGET) $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

clean :
	rm $(TARGET) *.o
