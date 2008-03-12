TARGET  = OrcaReadout
SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c 


OBJECTS = $(SOURCES:.c=.o)

#----original flags.... 
#UCFLAGS =  -g -Wall -gstabs+ -D_LINUX -I/usr/local/universe/include
#LFLAGS  = -lpthread -lstdc++ -L/usr/local/universe/lib -luniverse_api

#----add in flags for your driver libraries and include files
UCFLAGS =  -g -Wall -gstabs+ -D_LINUX 
LFLAGS  = -lpthread -lstdc++ 

LIBs    = 

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CC)  -o $(TARGET) $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

clean :
	rm $(TARGET) *.o
