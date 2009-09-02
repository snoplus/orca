/* ORHP4405AController */
//--------------------------------------------------------------------------------
/*!\class	ORHP4405AController
 * \brief	This class is the top level class handling interaction between the
 *			Agilent HP4405A GUI and its hardware.
 * \methods
 *			\li \b 	init						- Constructor - Opens correct nib
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 *			\li \b	connect						- Connect device to GPIB.
 *			\li \b	primaryAddressChanged		- Respond when person changes address.
 *			\li \b	secondaryAddressChanged		- Respond when person changes address.
 * \private
 *			\li \b	populatePullDowns			- Populate pulldowns in GUI.
 * \note	1) The hardware access methods use the internally stored state
 *			   to actually set the hardware.  Thus one first has to use the
 *			   accessor methods prior to setting the oscilloscope hardware.
 *			
 * \author	J. A. Formaggio
 * \history	2007-07-15 (jaf) - Original.
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
#pragma mark ¥¥¥Imported Files

#import "OROscBaseController.h"
#import <Cocoa/Cocoa.h>

@interface ORHP4405AController : OROscBaseController {    
}

// Register notifications that this class will listen for.
- (void) registerNotificationObservers;

#pragma mark ***Initialization
- (id) 			init;

#pragma mark ***Interface Management
- (void)		updateWindow;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions

- (IBAction)attenutation:(id)sender;
- (IBAction)burstType:(id)sender;
- (IBAction)calWideband:(id)sender;
- (IBAction)centerFreq:(id)sender;
- (IBAction)channelTCS:(id)sender;
- (IBAction)delay:(id)sender;
- (IBAction)detFormat:(id)sender;
- (IBAction)freqUnit:(id)sender;
- (IBAction)iqInvert:(id)sender;
- (IBAction)measType:(id)sender;
- (IBAction)modeType:(id)sender;
- (IBAction)opt10MHz:(id)sender;
- (IBAction)optFreq:(id)sender;
- (IBAction)refFilter:(id)sender;
- (IBAction)refLevel:(id)sender;
- (IBAction)refUnit:(id)sender;
- (IBAction)scaleLevel:(id)sender;
- (IBAction)scaleUnit:(id)sender;
- (IBAction)searchLengthUnit:(id)sender;
- (IBAction)searchLengthValue:(id)sender;
- (IBAction)searchThreshUnit:(id)sender;
- (IBAction)searchThreshValue:(id)sender;
- (IBAction)startFreq:(id)sender;
- (IBAction)stopFreq:(id)sender;
- (IBAction)symbolRate:(id)sender;
- (IBAction)symbolUnit:(id)sender;
- (IBAction)timeSlot:(id)sender;
- (IBAction)traceMode:(id)sender;
- (IBAction)triggerPolarity:(id)sender;
- (IBAction)triggerType:(id)sender;
@end
