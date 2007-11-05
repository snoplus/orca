TARGET  = OrcaReadout
SOURCES = SBC_Readout.c CircularBuffer.c AcqirisDC440.c HW_Readout.c


OBJECTS = $(SOURCES:.c=.o)
UCFLAGS =  -g -Wall -gstabs+ -D_LINUX -D_Acqiris  -I/opt/Acqiris/new/include
LFLAGS  = -lpthread -lstdc++ -lAnDBSLib -lAqLib
LIBs = -L/opt/Acqiris/new/lib

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CC)  -o $(TARGET)  $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

clean :
	rm $(TARGET) *.o