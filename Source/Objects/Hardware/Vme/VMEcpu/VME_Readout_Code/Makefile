TARGET  = OrcaReadout
SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c


OBJECTS = $(SOURCES:.c=.o)
UCFLAGS =  -g -Wall -gstabs+ -D_LINUX 
LFLAGS  = -lpthread -lstdc++ -lcctvme
LIBs    = 

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CC)  -o $(TARGET) $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

clean :
	rm $(TARGET) *.o
