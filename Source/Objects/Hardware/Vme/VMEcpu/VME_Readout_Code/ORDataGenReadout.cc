#include "ORDataGenReadout.hh"
#include <cmath>
bool ORDataGenReadout::Readout(SBC_LAM_Data* /*lamData*/)
{
    uint32_t dataId1D       = GetHardwareMask()[0];
    uint32_t dataId2D       = GetHardwareMask()[1];
    uint32_t dataIdWaveform =  GetHardwareMask()[2];
    
    if(random()%500 > 495 ){
      
        uint32_t card = random()%2;
        uint32_t chan = random()%8;
        uint32_t aValue = (100*chan) + ((random()%500 + random()%500 + random()%500)/3);
        if(card==0 && chan ==0)aValue = 100;
        
        ensureDataCanHold(5); 
        
        data[dataIndex++] = dataId1D | 2;
        data[dataIndex++] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
        
        data[dataIndex++] = dataId2D | 3;
        aValue = 64 + ((random()%128 + random()%128 + random()%128)/3);
        data[dataIndex++] = (aValue & 0x0fff); //card 0, chan 0
        aValue = 64 + ((random()%64 + random()%64 + random()%64)/3);
        data[dataIndex++] = (aValue & 0x0fff);
    }
    
    if(random()%20000 > 19998 ){
      
        ensureDataCanHold(2 * (2048+2));
        
        data[dataIndex++] = dataIdWaveform | (2048+2);
        data[dataIndex++] = 0x00001000; //card 0, chan 1
        float radians = 0;
        float delta = 2*3.141592/360.;
        int32_t i;
        for(i=0;i<2048;i++){
            data[dataIndex++] = (int32_t)(2*sin(4*radians));
            radians += delta;
        }  
        
        data[dataIndex++] = dataIdWaveform | (2048+2);
        data[dataIndex++] = 0; //card 0, chan 0
        int32_t a1 = (random()%20);
        int32_t a2 = (random()%20);
        for(i=0;i<2048;i++){
            data[dataIndex++] = (int32_t)((a1*sin(radians)) + (a2*sin(2*radians)));
            radians += delta;
        }
    }
    return true; 
}
