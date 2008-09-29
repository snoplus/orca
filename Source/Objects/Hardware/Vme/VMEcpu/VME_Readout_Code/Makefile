TARGET  = OrcaReadout
SOURCES = SBC_Readout.c CircularBuffer.c HW_Readout.c VME_Trigger32.c SNOMtc.c


OBJECTS = $(SOURCES:.c=.o)
UCFLAGS =  -g -Wall -gstabs+ -D_LINUX -I/usr/local/universe/include
LFLAGS  = -lpthread -lstdc++ -L/usr/local/universe/lib -luniverse_api
LIBs    = 

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CC)  -o $(TARGET) $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

clean :
	rm $(TARGET) *.o
