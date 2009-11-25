#include "ORFLTv4Readout.hh"
#include "SLTv4_HW_Definitions.h"
#include "katrinhw4/subrackkatrin.h"

extern hw4::SubrackKatrin* srack; 
bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t dataId     = GetHardwareMask()[0];
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    uint32_t col        = GetSlot() - 1; //the mac slots go from 1 to n
    uint32_t crate        = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
    
    //not used for now..
    //uint32_t postTriggerTime = config->card_info[index].deviceSpecificData[0];
    uint32_t eventType = GetDeviceSpecificData()[1];
    uint32_t runMode   = GetDeviceSpecificData()[2];
    uint32_t runFlags  = GetDeviceSpecificData()[3];
    
    if(srack->theFlt[col]->isPresent()){
        if(runMode == kIpeFltV4Katrin_Run_Mode){
            uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t  fifoStatus = (status >> 24) & 0xf;
            
            if(fifoStatus != kFifoEmpty){
                //TO DO... the number of events to read could (should) be made variable 
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    uint32_t fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                    uint32_t writeptr = fstatus & 0x3ff;
                    uint32_t readptr = (fstatus >>16) & 0x3ff;
                    uint32_t diff = (writeptr-readptr+1024) % 512;
                    
                    if(diff>1){
                        uint32_t f1 = srack->theFlt[col]->eventFIFO1->read();
                        uint32_t chmap = f1 >> 8;
                        uint32_t f2 = srack->theFlt[col]->eventFIFO2->read();
                        int eventchan;
                        for(eventchan=0;eventchan<24;eventchan++){
                            if(chmap & (0x1 << eventchan)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                uint32_t evsec        = ( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                                uint32_t evsubsec    = (f2 >> 2) & 0x1ffffff; // 25 bit
                                
                                uint32_t waveformLength = 2048; 
                                if(eventType & kReadWaveForms){
                                    ensureDataCanHold(9 + waveformLength/2); 
                                    data[dataIndex++] = waveformId | 9 + waveformLength/2;    
                                }
                                else {
                                    ensureDataCanHold(7); 
                                    data[dataIndex++] = dataId | 7;    
                                }
                                

                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;    //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = pagenr;        //was listed as the event ID... put in the pagenr for now 
                                data[dataIndex++] = energy;
                                
                                if(eventType & kReadWaveForms){
                                    static uint32_t waveformBuffer32[64*1024];
                                    static uint32_t shipWaveformBuffer32[64*1024];
                                    static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                    static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                    uint32_t triggerPos = 0;
                                    
                                    srack->theSlt->pageSelect->write(0x100 | pagenr);
                                    
                                    uint32_t adccount;
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = srack->theFlt[col]->ramData->read(eventchan,adccount);
                                        waveformBuffer32[adccount] = adcval;
#if 1 //TODO: WORKAROUND - align according to the trigger flag - in future we will use the timestamp, when Denis has fixed it -tb-
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
#endif
                                    }
                                    uint32_t copyindex = (triggerPos + 1024) % 2048; // + postTriggerTime;
                                    uint32_t i;
                                    for(i=0;i<waveformLength;i++){
                                        shipWaveformBuffer16[i] = waveformBuffer16[copyindex];
                                        copyindex++;
                                        copyindex = copyindex % 2048;
                                    }
                                    
                                    //simulation mode
                                    if(0){
                                        for(i=0;i<waveformLength;i++){
                                            shipWaveformBuffer16[i]= (i>100)*i;
                                        }
                                    }
                                    //ship waveform
                                    uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    for(i=0;i<waveformLength32;i++){
                                        data[dataIndex++] = shipWaveformBuffer32[i];
                                    }
                                }
                            }
                        }
                    }
                    else break;
                }
            }
        }
        else if(runMode == kIpeFltV4Katrin_Histo_Mode) {    
                //uint32_t pagenr,oldpagenr ;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
                //sleep(1);   
                if(runFlags & 0x10000){// firstTime    
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    GetDeviceSpecificData()[3]=pageAB;
                    fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
                    //sleep(1);
                }
                else{//check timing
                    //pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    oldpageAB = GetDeviceSpecificData()[3]; //
                    pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    //fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
                    //              sleep(1);
                    
                    if(oldpageAB != pageAB){
                        fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
                        GetDeviceSpecificData()[3] = pageAB; 
                        //read data
                        int chan=0;
                        uint32_t lastFirst, last,first,llast,lfirst;
                        //static uint32_t histogramBuffer32[1024]; //comment out to clear compiler warning. mah 11/25/09121122//
                        static uint32_t shipHistogramBuffer32[2*1024];
                        for(chan=0;chan<24;chan++) {//read out histogram
                            uint32_t adccount;
                            lastFirst = srack->theFlt[col]->histLastFirst->read(chan);
                            last = (lastFirst >>16) & 0xffff;
                            first = lastFirst & 0xffff;
                            fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
                            if(last<first){
                                //no events
                                continue;
                            }
                            else{
                                //read out histogram
                                //lfirst= first/2; llast=last/2;
                                lfirst= 0; llast=1023;//TODO: there is something wrong with last/first bin information -tb-
                                //int cnt=0;
								srack->theSlt->pageSelect->write(0x100 | 0);//TODO: do it once? -tb-
                                for(adccount=0; adccount<1024;adccount++){
                                    shipHistogramBuffer32[adccount] =  srack->theFlt[col]->ramData->read(chan,adccount);
                                }
								srack->theSlt->pageSelect->write(0x100 | 1);//TODO: do it once? -tb-
                                for(adccount=0; adccount<1024;adccount++){
                                    shipHistogramBuffer32[adccount+1024] =  srack->theFlt[col]->ramData->read(chan,adccount);
                                }
                                //fprintf(stdout,"\n");
                            }
                            
                            //prepare data record
                            katrinHistogramDataStruct theEventData;
                            theEventData.readoutSec = 0;
                            theEventData.recordingTimeSec =  0;//histoRunTime; 
                            theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
                            theEventData.lastBin   = 2048;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
                            theEventData.histogramLength =2048;
                            //theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
                            //if(theEventData.histogramLength < 0){// we had no counts ...
                            //    theEventData.histogramLength = 0;
                            //}
                            theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
                            theEventData.binSize    = 1;//histoBinWidth;        
                            theEventData.offsetEMin = 0;//histoMinEnergy;
                            
                            //ship data record
                            unsigned long totalLength = 2 + (sizeof(katrinHistogramDataStruct)/sizeof(long)) + theEventData.histogramLength;// 2 = header + locationWord
                            data[dataIndex++] = histogramId | totalLength;    
                            data[dataIndex++] = location | chan<<8;
                            data[dataIndex++] = theEventData.readoutSec;
                            data[dataIndex++] = theEventData.recordingTimeSec;
                            data[dataIndex++] = theEventData.firstBin;
                            data[dataIndex++] = theEventData.lastBin;
                            data[dataIndex++] = theEventData.histogramLength;
                            data[dataIndex++] = theEventData.maxHistogramLength;
                            data[dataIndex++] = theEventData.binSize;
                            data[dataIndex++] = theEventData.offsetEMin;
                            int i;
                            for(i=0; i<theEventData.histogramLength;i++)
                                data[dataIndex++] = shipHistogramBuffer32[i];
                            
                        }
                    } 
                }
        }
    }
    return true;
    
}

#if (0)
//maybe read hit rates in the pmc at some point..... here's how....
//read hitrates
{
    int col,row;
    for(col=0; col<20;col++){
        if(srack->theFlt[col]->isPresent()){
            //fprintf(stdout,"FLT %i:",col);
            for(row=0; row<24;row++){
                int hitrate = srack->theFlt[col]->hitrate->read(row);
                //if(row<5) fprintf(stdout," %i(0x%x),",hitrate,hitrate);
            }
            //fprintf(stdout,"\n");
            //fflush(stdout);
            
        }
    }

    return true; 
}
#endif
