
/* 
 Control Arduino board functions with the following messages:
 
 r a                 -> read analog pins
 r d [mask]          -> read digital pins, mask used to restrict reads to input pins
 w d [pin] [value]   -> write digital pin
 w a [pin] [value]   -> write analog pin
 w m [mask] [vMask   -> write all digital pins using mask
 
 //reponses
 a [adc0] [adc1] [adc2] [adc3] [adc4] [adc5]   -> from read analog
 d [pin2] [pin3] ... [pin13]                   -> from read digital
 
 //unsolicited responses
 i [Hiinputs]               ->mask containing hi pins  
 
 Base: Thomas Ouellet Fredericks 
 Additions: Adapted for use in ORCA by Mark Howe (UNC Physics Deptpartment) 
 */

#include <SimpleMessageSystem.h> 

unsigned short inputMask  = 0x0; 
unsigned short oldInputs = 0;

void setup()
{
  Serial.begin(57600); 
}

void loop()
{
  if (messageBuild() > 0) { // Checks ifmessage is complete and erase any previous message
    switch (messageGetChar()) { 
      case 'r': readpins(); break; 
      case 'w': writepin(); break;
    }
  }
  
  if(inputMask){
      unsigned short inputs = 0;
      if(inputMask){
        for (char i=2;i<14;i++) {
          if(inputMask & (1<<i)){
            inputs |= ((unsigned short)debouncedDigitalRead(i) << i);
          }
        }
        if(inputs != oldInputs){
          oldInputs = inputs;
          messageSendChar('i');
          messageSendInt(inputs);
          messageEnd();
        }
      }
  }
}

void readpins()
{ 
  switch (messageGetChar()) { 
    case 'd': //READ digital pins
       inputMask = messageGetInt();
       messageSendChar('d');
       for (char i=0;i<14;i++) {
          if(inputMask & (1<<i)) {
            if(i>=2){
               pinMode(i, INPUT_PULLUP);
               messageSendInt(digitalRead(i)); // Read pins 2 to 13
            }
            else messageSendInt(0); //return 0 for the serial lines
          }
          else   messageSendInt(0);
      }
      messageEnd(); // Terminate the message being sent
    break; // Break from the switch

    case 'a': // READ analog pins
      messageSendChar('a');
      for (char i=0;i<6;i++) {
        messageSendInt(analogRead(i));
      }
      messageEnd();
    break;
  }
}

void writepin() 
{ 
  int pin;
  int state;

  switch (messageGetChar()) { // Gets the next word as a character
    case 'a': // WRITE an analog pin
      pin   = messageGetInt(); 
      state = messageGetInt();
      if(pin>=2 && (~inputMask & (1<<pin))){
        pinMode(pin, OUTPUT);
        analogWrite(pin, state); //Sets the PWM value of the pin 
      }
      messageSendChar('Y');      //Have to return something
      messageEnd(); 
    break; 
    
    case 'd': // WRITE a digital pin
      pin   = messageGetInt();  
      state = messageGetInt();  
      if(pin>=2 && (~inputMask & (1<<pin))){
         pinMode(pin,OUTPUT);  
         if( state)  digitalWrite(pin,HIGH);
         else        digitalWrite(pin,LOW);
      }
      messageSendChar('Y');    //Have to return something
      messageEnd();          
    break;  
    
    case 'm': // WRITE all digital pins using mask
      int outputTypeMask  = messageGetInt() & ~inputMask; //don't write inputs
      int writeMask       = messageGetInt() & ~inputMask;  
      if(outputTypeMask){
        for(pin=2;pin<14;pin++){
          if(outputTypeMask & (1<<pin)){
             pinMode(pin,OUTPUT);
             if( writeMask & (1<<pin))  digitalWrite(pin,HIGH);
             else                       digitalWrite(pin,LOW);
          }
        }
      }
      else writeMask = 0;
      
      messageSendChar('m');
      messageSendInt(writeMask);
      messageEnd();
      
    break;  
  }
}

boolean          lastPinState[14];
boolean          pinState[14];
unsigned long   lastDebounceTime[14];
unsigned long   debounceDelay = 50;

boolean debouncedDigitalRead(int aPin)
{
  boolean currentValue = digitalRead(aPin);
  if (currentValue != lastPinState[aPin]) {
    lastDebounceTime[aPin] = millis();
  } 
  
  if ((millis() - lastDebounceTime[aPin]) > debounceDelay) {
    pinState[aPin] = currentValue;
  }

  lastPinState[aPin] = currentValue;
  return pinState[aPin];
}
