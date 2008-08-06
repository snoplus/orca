//--------------------------------------------------------------------------------
/*!\class	ORHP4405AModel
 * \brief	This class the hardware interaction with the HP4405A Agilent spectral analyzer.
 * \methods
 *			\li \b 	init						- Constructor - Default first time
 *											      object is created
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 * \private
 * \note	1) The hardware access methods use the internally stored state
 *			   to actually set the hardware.  Thus one first has to use the
 *			   accessor methods prior to setting the oscilloscope hardware.
 *			
 * \author	 J. A. Formaggio
 * \history	2008-15-07 (jaf) - Original.
 */
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

#import "OROscBaseModel.h"
#import "ORHP4405AData.h"
#import "OROscDecoder.h"

#define ORHP4405A 1
#define ORHPMaxRecSize 50000
#define ORHPMaxSampleRate 0.125e-9;

// Interface description of ORHP4405AModel oscilloscope.
@interface ORHP4405AModel : OROscBaseModel {
    @private
	ORHP4405AData*		mDataObj[ kMaxOscChnls ];       // Pointers channel data.
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark ***Hardware - General
- (short)	oscScopeId;
- (bool) 	oscBusy;
- (long)	oscGetDateTime;
- (void)	oscSetDateTime: (time_t) aTime;
- (void)	oscLockPanel: (bool) aFlag;
- (void)	oscResetOscilloscope;
- (void)	oscSendTextMessage: (NSString*) aMessage;
- (void)	oscSetQueryFormat: (short) aFormat;
- (void)	oscSetScreenDisplay: (bool) aDisplayOn;

#pragma mark ***Hardware - Channel

#pragma mark ***Hardware - Horizontal settings

#pragma mark ***Hardware - Trigger

#pragma mark ***Get and set oscilloscope specific settings.

#pragma mark ***Hardware - Data Acquisition
- (BOOL)	runInProgress;
- (void)	oscGetHeader;
- (void)	oscGetWaveform: (unsigned short) aMask;
- (void) 	oscGetWaveformTime: (unsigned short) aMask;
- (void)	oscRunOsc: (NSString*) aStartMsg;
- (void)	oscSetAcqMode: (short) aMode;
- (void)	oscSetDataReturnMode;
- (void)	oscStopAcquisition;
                                                    
#pragma mark •••DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (void)	takeDataTask:(id)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;

#pragma mark ***Specialty routines.
//- (NSString*) 	triggerSourceAsString;
- (void)	oscHP4405AConvertTime: (unsigned long long*) a10MhzTime timeToConvert: (char*) aCharTime;
- (void) doNothing;
/*- 
- 
- (BOOL)	OscResetOscilloscope;	
- (BOOL)	OscWait;
*/

@end

@interface ORHP4405ADecoderForScopeData : OROscDecoder
{}
@end

@interface ORHP4405ADecoderForScopeGTID : OROscDecoder
{} 
@end

@interface ORHP4405ADecoderForScopeTime : OROscDecoder
{}
@end

extern NSString* ORHP4405ALock;
extern NSString* ORHP4405AGpibLock;
