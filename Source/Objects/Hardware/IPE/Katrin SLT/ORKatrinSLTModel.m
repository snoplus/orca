//
//  ORKatrinSLTModel.m
//  Orca
//
//  Created by A Kopmann on Wed Feb 29 2008.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORKatrinSLTModel.h"


@implementation ORKatrinSLTModel

- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [super dealloc];
}



- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"KatrinSLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORKatrinSLTController"];
}


- (void) initBoard
{
   // Define variables that are not in the dialog
   //
   // Control register
   [self setInhibitSource: inhibitSource | 0x1]; // Enable software inhibit
   [self setInhibitSource: inhibitSource & 0x5]; // Disable internal inhibit
   // External inhibt in dialog
   [self setTriggerSource:1]; // Enable only software trigger
   // Second strobe in dialog
   // Testpulser not used
   // Sensors not used
   // Deadtime enable in dialog
   
   // Other parameter
   [self setInterruptMask:0]; // Clear interrupt mask


   [super initBoard];
}


#pragma mark ¥¥¥Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

    [self clearExceptionCount];
	
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeSLTModel"];    
    //----------------------------------------------------------------------------------------	


	[self setSwInhibit];
	
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	

	

/*	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;
		if([dataTakers containsObject:aCard])continue;
		[aCard disableAllTriggers];
	}
*/ 
/*   
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
*/

/*	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
*/
	
  	usingPBusSimulation		  = [self pBusSim];
	lastSimSec = 0;

	first = YES;
	
}


-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

	if(first){
		[self releaseAllPages];
		[self releaseSwInhibit];
		//[self writeReg:kSLTResetDeadTime value:0];
		first = NO;
	} else {	
	
	    // TODO: Clear pages if a software trigger was generated, otherwise
		//       the stack can be completely filled !?
		//       Run a simplifed readout loop ...
				
/*
		struct timeval t0, t1;
		struct timezone tz;	
			
			
		unsigned long long lPageStatus;
		lPageStatus = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];

		// Siumartion events everey second?!
		if (usingPBusSimulation){
		  gettimeofday(&t0, &tz);
		  if (t0.tv_sec > lastSimSec) {
		    lPageStatus = 1;
			lastSimSec = t0.tv_sec;
		  }	
		}
		
		
		if(lPageStatus != 0x0){
			while((lPageStatus & (0x1LL<<actualPageIndex)) == 0){
				if(actualPageIndex>=63)actualPageIndex=0;
				else actualPageIndex++;
			}
			
			// Set start of readout 
			gettimeofday(&t0, &tz);
			
			eventCounter++;
			
			//read page start address
			unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSLTLastTriggerTimeStamp) + actualPageIndex];
			int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) %2000;
			
			unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex];
			unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex+1];
			//
			//			NSLog(@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			//			         actualPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
			
			//readout the SLT pixel trigger data
			int i;
			unsigned long buffer[2000];
			unsigned long sltMemoryAddress = (SLTID << 24) | actualPageIndex<<11;
			// Split the reading of the memory in blocks according to the maximal block size
			// supported by the firewire driver	
			// TODO: Read only the relevant trigger data for smaller page sizes!
			//       Reading needs to start in this case at start address...		
			int blockSize = 500;
			int sltSize = 2000; // Allways read the full trigger memory
			int nBlocks = sltSize / blockSize;
			for (i=0;i<nBlocks;i++)
			  [self read:sltMemoryAddress+i*blockSize data:buffer+i*blockSize size:blockSize*sizeof(unsigned long)];
			
			//for(i=0;i<2000;i++) buffer[i]=0; // only Test

            // Check result from block readout - Testing only
			//unsigned long buffer2[2000];
            //[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer2 length:2000 increment:1];
			//for(i=0;i<2000;i++) if (buffer[i]!=buffer2[i]) {
			//  NSLog(@"Error reading Slt Memory\n"); 
			//  break;
			//}  
			
		    // Re-organize trigger data to get it in a continous data stream
			// There is no automatic address wrapping like in the Flts available...
			unsigned long reorderBuffer[2000];
			unsigned long *pMult = reorderBuffer;
			memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
			memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
			
			int nTriggered = 0;
		    unsigned long xyProj[20];
			unsigned long tyProj[100];
			nTriggered = [self calcProjection:pMult xyProj:xyProj tyProj:tyProj];

			//ship the start of event record
			unsigned long eventData[5];
			eventData[0] = eventDataId | 5;	
			eventData[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
			eventData[2] = eventCounter;
			eventData[3] = timeStampH; 
			eventData[4] = timeStampL;
			[aDataPacket addLongsToFrameBuffer:eventData length:5];	//ship the event record

			//ship the pixel multiplicity data for all 20 cards (last two of 22 not used)
			unsigned long multiplicityRecord[3 + 20];
			multiplicityRecord[0] = multiplicityId | 20 + 3;	
			multiplicityRecord[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16; 
			multiplicityRecord[2] = eventCounter;
			for(i=0;i<20;i++) multiplicityRecord[3+i] = xyProj[i];
			[aDataPacket addLongsToFrameBuffer:multiplicityRecord length:20 + 3];

			int lStart = (lTimeL >> 11) & 0x3ff;
			NSEnumerator* e = [dataTakers objectEnumerator];
			
			//readout the flt waveforms
			// Added pixelList as parameter to the Flt readout in order
			// to enable selective readout
			// ak 5.10.2007
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:actualPageIndex], @"page",
				[NSNumber numberWithInt:lStart],		  @"lStart",
				[NSNumber numberWithInt:eventCounter],	  @"eventCounter",
				[NSNumber numberWithInt:pageSize],		  @"pageSize",
				nil];
			id obj;
			while(obj = [e nextObject]){			    
				unsigned long pixelList;
				if(readAll)	pixelList = 0x3fffff;
				else		pixelList = xyProj[[obj slot] - 1];
				//NSLog(@"Datataker in slot %d, pixelList %06x\n", [obj slot], pixelList);
				[userInfo setObject:[NSNumber numberWithLong:pixelList] forKey: @"pixelList"];
				
				[obj takeData:aDataPacket userInfo:userInfo];
			}

			//free the page
			[self writeReg:kSLTSetPageFree value:actualPageIndex];
			
			// Set end of readout
			gettimeofday(&t1, &tz);

			// Display event header
			if (displayEventLoop) {
				// TODO: Display number of stored pages
				// TODO: Add control to GUI that controls the update rate
				// 7.12.07 ak
				if (t0.tv_sec > lastDisplaySec){
					NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
					int nEv = eventCounter - lastDisplayCounter;
					double rate = 0.1 * nEv / (t0.tv_sec-lastDisplaySec) + 0.9 * lastDisplayRate;
					
					unsigned long tRead = (t1.tv_sec - t0.tv_sec) * 1000000 + (t1.tv_usec - t0.tv_usec);
					if (t0.tv_sec%20 == 0) {
					    NSLogFont(aFont, @"%64s  | %16s\n", "Last event", "Interval summary"); 
						NSLogFont(aFont, @"%4s %14s %4s %14s %4s %4s %14s  |  %4s %10s\n", 
								  "No", "Actual time/s", "Page", "Time stamp/s", "Trig", 
								  "nCh", "tRead/us", "nEv", "Rate");
					}			  
					NSLogFont(aFont,   @"%4d %14d %4d %14d %4d %4d %14d  |  %4d %10.2f\n", 
							  eventCounter, t0.tv_sec, actualPageIndex, timeStampH, 0, 
							  nTriggered, tRead, nEv, rate);
					
					// Keep the last display second		  
					lastDisplaySec = t0.tv_sec;	
					lastDisplayCounter = eventCounter;
					lastDisplayRate = rate;	  
				}
			}
			
		}
		
*/		
	}
	
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

	[self setSwInhibit];

/*	
	dataTakers = [[readOutGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
	[dataTakers release];
	dataTakers = nil;
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
*/	
}



@end
