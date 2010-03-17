#include "ORShaperReadout.hh"
#include <errno.h>
#import <sys/timeb.h>

bool ORShaperReadout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t conversionRegOffset = GetDeviceSpecificData()[1];
    
    uint8_t theConversionMask;
    int32_t result = VMERead(GetBaseAddress() + conversionRegOffset,
                             0x29, 
                             sizeof(theConversionMask),
                             theConversionMask);
    if(result == (int32_t) sizeof(theConversionMask) && theConversionMask != 0){

        uint32_t dataId            = GetHardwareMask()[0];
        uint32_t timeId            = GetHardwareMask()[1];
        uint32_t locationMask      = ((GetCrate() & 0x01e)<<21) | 
                                     ((GetSlot() & 0x0000001f)<<16);
        uint32_t onlineMask        = GetDeviceSpecificData()[0];
        uint32_t firstAdcRegOffset = GetDeviceSpecificData()[2];
		uint8_t  shipTimeStamp     = GetDeviceSpecificData()[3];
		ensureDataCanHold(2*8 + 4*8); //max this card can produce
		
        for (int16_t channel=0; channel<8; ++channel) {
            if(onlineMask & theConversionMask & (1L<<channel)){
				
				if(shipTimeStamp){
					
					struct timeb mt;
					if (ftime(&mt) == 0) {
						unsigned long data[4];
						data[dataIndex++] = timeId | 4;
						data[dataIndex++] = locationMask | ((channel & 0x000000ff)<<8);
						data[dataIndex++] = mt.time;
						data[dataIndex++] = mt.millitm;
					}						
					
				}
				
                uint16_t aValue;
                result = VMERead(GetBaseAddress() + firstAdcRegOffset + 2*channel,
                                 0x29, 
                                 sizeof(aValue),
                                 aValue);
                if(result == sizeof(aValue)){
                    if(((dataId) & 0x80000000)){ //short form
                        data[dataIndex++] = dataId | locationMask | 
                            ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    } 
					else { //long form
                        data[dataIndex++] = dataId | 2;
                        data[dataIndex++] = locationMask | 
                            ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                } 
				else if (result < 0) {
                    LogBusError("Rd Err: Shaper 0x%04x %s",
                        GetBaseAddress(),strerror(errno));                
                }
            }
        }
    } else if (result < 0) {
        LogBusError("Rd Err: Shaper 0x%04x %s",GetBaseAddress(),strerror(errno)); 
    }

    return true; 
}
