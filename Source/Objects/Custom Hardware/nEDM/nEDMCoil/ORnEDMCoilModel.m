//
//  ORnEDMCoilModel.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORnEDMCoilModel.h"
#import "ORTTCPX400DPModel.h"
#import "ORAdcProcessing.h"
#import "ORXYCom564Model.h"

NSString* ORnEDMCoilPollingActivityChanged = @"ORnEDMCoilPollingActivityChanged";
NSString* ORnEDMCoilPollingFrequencyChanged    = @"ORnEDMCoilPollingFrequencyChanged";
NSString* ORnEDMCoilADCListChanged = @"ORnEDMCoilADCListChanged";
NSString* ORnEDMCoilHWMapChanged   = @"ORnEDMCoilHWMapChanged";
NSString* ORnEDMCoilDebugRunningHasChanged = @"ORnEDMCoilDebugRunningHasChanged";

#define kADCChannelNumber 128

@interface ORnEDMCoilModel (private) // Private interface
#pragma mark •••Running
- (void) _runThread;
- (void) _runProcess;
- (void) _stopRunning;
- (void) _startRunning;
- (void) _setUpRunning:(BOOL)verbose;

#pragma mark •••Read/Write
- (void) _readADCValues;
//- (void) _writeValuesToDatabase;
- (NSData*) _calcPowerSupplyValues;
- (NSData*) _readCurrentValues;
- (void) _syncPowerSupplyValues:(NSData*)currentVector;
- (double) _fieldAtMagnetometer:(int)index;
- (void) _setCurrent:(double)current forSupply:(int)index;
- (double) _getCurrent:(int)supply;

- (void) _setADCList:(NSMutableArray*)anArray;

- (void) _setOrientationMatrix:(NSMutableArray*)anArray;
- (void) _setMagnetometerMatrix:(NSMutableArray*)anArray;
- (void) _setConversionMatrix:(NSMutableData*)anArray;

- (BOOL) _verifyMatrixSizes:(NSArray*)feedBackMatrix orientationMatrix:(NSArray*)orMax magnetometerMap:(NSArray*)magMap;
@end

#define CALL_SELECTOR_ONALL_POWERSUPPLIES(x)      \
{                                                 \
NSEnumerator* anEnum = [objMap objectEnumerator]; \
for (id obj in anEnum) [obj x];                   \
}

#define ORnEDMCoil_DEBUG 1

@implementation ORnEDMCoilModel (private) 

- (void) _runThread
{
    NSRunLoop* rl = [NSRunLoop currentRunLoop];
    // make sure we schedule the run
    [self performSelector:@selector(_runProcess) withObject:nil afterDelay:0.5];
    // perform the run loop
    while( isRunning && [rl runMode:NSDefaultRunLoopMode
                         beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]); // Cancel the run loop every second
}

- (void) _runProcess
{
    // The current calculation process
    @try {
        [self _readADCValues];
        NSData* currentVector = [self _calcPowerSupplyValues];
        [self _syncPowerSupplyValues:currentVector];
    }
    @catch(NSException* localException) { 
        NSLog(@"%@\n",[localException reason]);
        [self _stopRunning];
        //catch this here to prevent it from falling thru, but nothing to do.
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
    if(pollingFrequency!=0){
        [self performSelector:@selector(_runProcess) withObject:nil afterDelay:(float) 1.0/pollingFrequency];
    } else {
        [self _stopRunning];
    }
}


- (void) _readADCValues
{
    // Reads current ADC values, creating a list of channels (128 for each ADC)

    long sizeOfArray = kADCChannelNumber*sizeof(float)*[listOfADCs count];
    if (!currentADCValues || [currentADCValues length] != sizeOfArray) {
        [currentADCValues release];
        currentADCValues = [[NSMutableData dataWithLength:kADCChannelNumber*sizeof(float)] retain];
    }
    float* ptr = (float*)[currentADCValues bytes];
    memset(ptr, 0, kADCChannelNumber*sizeof(ptr[0]));
    
    NSEnumerator* e = [[self listOfADCs] objectEnumerator];
    id obj;
    int j = 0;
    while(obj = [e nextObject]){
        int i;
        for (i=0; i<kADCChannelNumber; i++) ptr[i+j] = (float)[obj getAdcValueAtChannel:i];
    }        
    
}

- (NSData*) _calcPowerSupplyValues
{
    // Calculates the desired power supply currents given.  Johannes, you should start here,
    // grabbing desired field values using [self _fieldAtMagnetometer:index]; and setting the 
    // current using [self _setCurrent:currentValue forSupply:index];
    
    //init FieldVectormutabl
    NSData* FieldVector = [NSMutableData dataWithLength:(NumberOfChannels*sizeof(double))];    
    NSData* CurrentVector = [self _readCurrentValues];
    double* ptr = (double*)[FieldVector bytes];
    //Grab field values
    int i;
    for (i=0; i<NumberOfChannels;i++) ptr[i] = [self _fieldAtMagnetometer:i];

    //FOR TESTING: artificial constant field
    //double one=(double)1;
    //[FieldVector replaceBytesInRange:(NSRange){(NumberOfChannels-1)*sizeof(double),sizeof(double)} withBytes:&one  length:sizeof(double)];

    // Perform multiplication with FeedbackMatrix, product is automatically added to CurrentVector    
    cblas_dgemv(CblasRowMajor, CblasNoTrans, NumberOfCoils, NumberOfChannels, 1, [FeedbackMatData bytes], NumberOfChannels, ptr,1,1,(double*)[CurrentVector bytes],1);
    
    //FOR TESTING: log current in last coil
    double* CurPtr = (double*)[CurrentVector bytes];
    NSLog([NSString  stringWithFormat:@"Last Current: %f\n",CurPtr[NumberOfCoils-1]]);

    return CurrentVector;
    
}

- (NSData*) _readCurrentValues
{
    // The following tells the power supplies to read the current value, we don't wait for the actual value.
    CALL_SELECTOR_ONALL_POWERSUPPLIES(sendCommandReadBackGetCurrentSetWithOutput:0);
    CALL_SELECTOR_ONALL_POWERSUPPLIES(sendCommandReadBackGetCurrentSetWithOutput:1);
    
    NSData* CurrentVector = [[[NSMutableData alloc] initWithLength:(NumberOfCoils*sizeof(double))] autorelease];
    double* ptr = (double*)[CurrentVector bytes];
    
    
    for (int i=0; i<NumberOfCoils;i++){
        ptr[i] = [self _getCurrent:i];
    }
    return CurrentVector;
}

- (void) _syncPowerSupplyValues:(NSData*) currentVector
{
    // Will write the saved power supply values to the hardware
    /*
    NSEnumerator* e = [self objectEnumerator];
    id anObject;
    int i;
    for (i=0;i<[objMap count]; i++){
        [[objMap objectForKey:[NSNumber numberWithInt:i]] 
    }
    while (anObject = [e nextObject]) {
        [objMap setObject:anObject forKey:[NSNumber numberWithInt:[anObject tag]]];
    }*/
    
    if ([self debugRunning]) CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:NO);
    double* dblPtr = (double*)[currentVector bytes];
    double Current[NumberOfCoils];
    int i;    
    //Account for reversed wiring in PowerSupplies
    for (i=0;i<NumberOfCoils;i++) {
        Current[i]=dblPtr[i]*[[OrientationMatrix objectAtIndex:i] intValue];    
    }
    // Check if current ranges of power supplies are exceeded, cancel
    for (i=0;i<NumberOfCoils;i++) {
        if (Current[i]>MaxCurrent) {
            //[NSException raise:@"Current Exceeded in Coil" format:@"Current Exceeded in Coil Channel: %d",i];
        }
        if (Current[i]<0) {
            //[NSException raise:@"Current Negative in Coil" format:@"Current Negative in Coil Channel: %d",i];            
        }
        NSLog(@"Current Value (%d): %f\n",i,Current[i]);
    }
    for (i=0; i<NumberOfCoils;i++){
        [self _setCurrent:dblPtr[i] forSupply:i];
    }
    if (![self debugRunning]) CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:YES);        
}

- (double) _fieldAtMagnetometer:(int)index
{
    // Returns the field at a given magnetometer, index is mapped.
    
    // MagnetometerMap is to contain list of channels of magnetometers in order of appearance in FM
    // Channel values are as in currentADCValues: 128 slots for each ADC
    
    // ToBeFixed: in current setup, z-channels are reading inverted values. Where to account for orientation? -> FluxGate object will be created
    //  Read proper units!
    //FOR TESTING
    //return (float)0;
    //return [[currentADCValues objectAtIndex:[[MagnetometerMap objectAtIndex:index] intValue]] floatValue];
    //For Testing: ACD-output units are manually converted to Volt
    const float* ptr = [currentADCValues bytes];
    assert([[MagnetometerMap objectAtIndex:index] intValue] < [currentADCValues length]/sizeof(ptr[0]));
    float raw = ptr[[[MagnetometerMap objectAtIndex:index] intValue]];
    if (raw < 32768) {
        raw += 32768;
		} else {
        raw -= 32768;
        }
    double volrange = 20; // +-10V
    double adcrange = 65536; // 16bit
    double vol = raw -32768; // offset
    double vol2 = vol * volrange / adcrange; //scaling
    return vol2;
    
}

- (void) _setCurrent:(double)current forSupply:(int)index 
{
    // Will save the current for a given supply,
    // magnetometers and channels naturally ordered
    // Mapping will be taken care of at GUI level
    [[objMap objectForKey:[NSNumber numberWithInt:(index/2)]] setWriteToSetCurrentLimit:current withOutput:(index%2)];
}

- (double) _getCurrent:(int)supply
{
    return [[objMap objectForKey:[NSNumber numberWithInt:(supply/2)]] readBackGetCurrentSetWithOutput:(supply%2)];
}

#pragma mark •••Running
- (void) _stopRunning
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_runProcess) object:nil];
	isRunning = NO;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingActivityChanged
	 object: self]; 
    NSLog(@"Stopping nEDM Coil Compensation processing.\n");
}

- (void) _startRunning
{
    [self connectAllPowerSupplies];
    if (FeedbackMatData != nil && OrientationMatrix != nil &&
        MagnetometerMap != nil &&
        [self _verifyMatrixSizes:nil
               orientationMatrix:OrientationMatrix
                 magnetometerMap:MagnetometerMap] ) {
        [self _setUpRunning:YES];    
    } else {
        [[NSAlert alertWithMessageText:@"Error"
                         defaultButton:nil
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"Input matrices are inconsistent or non-existent.  Process can not be started."] runModal];
    }
}

- (void) _setUpRunning:(BOOL)verbose
{
	
	if(isRunning && pollingFrequency != 0)return;
    
    if(pollingFrequency!=0){  
		isRunning = YES;
        if(verbose) NSLog(@"Running nEDM Coil compensation at a rate of %.2f Hz.\n",pollingFrequency);
        [NSThread detachNewThreadSelector:@selector(_runThread)
                                 toTarget:self
                               withObject:nil];
    }
    else {
        if(verbose) NSLog(@"Not running nEDM Coil compensation, polling frequency set to 0\n");
    }
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingActivityChanged
	 object: self];
}

- (void) _setADCList:(NSMutableArray*)anArray
{
    [anArray retain];
    [listOfADCs release];
    listOfADCs = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];        
}


- (void) _setOrientationMatrix:(NSMutableArray*)anArray
{
    [anArray retain];
    [OrientationMatrix release];
    OrientationMatrix = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}

- (void) _setMagnetometerMatrix:(NSMutableArray*)anArray
{
    [anArray retain];
    [MagnetometerMap release];
    MagnetometerMap = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}
- (void) _setConversionMatrix:(NSMutableData*)anArray
{
    [anArray retain];
    [FeedbackMatData release];
    FeedbackMatData = anArray;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilHWMapChanged object: self];
}


- (BOOL) _verifyMatrixSizes:(NSArray*)feedBackMatrix orientationMatrix:(NSArray*)orMax magnetometerMap:(NSArray*)magMap
{
    // Returns YES when matrix sizes are OK.
    
    @try {
        if (feedBackMatrix != nil) {
            // Means the feedback matrix is being defined.
            for (id e in feedBackMatrix) {
                if (![e isKindOfClass:[NSArray class]]) {
                    [NSException raise:@"MatrixReadInError"
                                format:@"Feedback Matrix is mal-formed."];
                }
                for (id var in e) {
                    if (![var isKindOfClass:[NSNumber class]]) {
                        [NSException raise:@"MatrixReadInError"
                                    format:@"Feedback Matrix is mal-formed."];
                    }
                }
            }
            NumberOfChannels   = [[feedBackMatrix objectAtIndex: 0] count];
            NumberOfCoils      = [feedBackMatrix count];
        }

        for (id e in orMax) {
            if (![e isKindOfClass:[NSNumber class]]) {
                [NSException raise:@"MatrixReadInError"
                            format:@"Input matrices are malformed."];
            }
        }
        for (id e in magMap) {
            if (![e isKindOfClass:[NSNumber class]]) {
                [NSException raise:@"MatrixReadInError"
                            format:@"Input matrices are malformed."];
            }
        }
        
        // Can't test if we don't know the number of coils or channels
        if (NumberOfCoils == 0 || NumberOfChannels == 0) return YES;
        if ((orMax != nil && [orMax count] != NumberOfCoils) &&
            (magMap != nil && [magMap count] != NumberOfChannels)) {
            [NSException raise:@"MatrixReadInError"
                        format:@"Input matrices are inconsistent.  Either try again, or reset the already input data."];
        }

    } @catch(NSException *e) {
        // This means something was wrong with the data, return NO!
        [[NSAlert alertWithMessageText:@"Error"
                         defaultButton:nil
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:[e reason]] runModal];
        return NO;
    }
    return YES;
}

@end

@implementation ORnEDMCoilModel

#pragma mark •••initialization

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [objMap release];
    [listOfADCs release];
    [currentADCValues release];  
    [FeedbackMatData release];
    [super dealloc];
}

- (void) makeConnectors
{	
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"nEDMCoil"]];
    // The following code might still be useful, hold on to it for the time being.  - M. Marino
}

- (void) makeMainController
{
    [self linkToController:@"ORnEDMCoilController"];
}

- (BOOL) isRunning
{
    return isRunning;
}

- (float) pollingFrequency
{
    return pollingFrequency;
}

- (BOOL) debugRunning
{
    return debugRunning;
}

- (void) setDebugRunning:(BOOL)debug
{
    if (debug == debugRunning) return;
    debugRunning = debug;
    if (debugRunning) CALL_SELECTOR_ONALL_POWERSUPPLIES(setAllOutputToBeOn:NO);
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilDebugRunningHasChanged
	 object: self];     
}

- (void) connectAllPowerSupplies
{
    CALL_SELECTOR_ONALL_POWERSUPPLIES(connect);
}

- (void) addADC:(id)adc
{
    if (!listOfADCs) listOfADCs = [[NSMutableArray array] retain];
    // FixME Add protection for double entries
    [listOfADCs addObject:adc];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];     
}

- (void) removeADC:(id)adc
{
    [listOfADCs removeObject:adc];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilADCListChanged
	 object: self];         
}

- (NSArray*) listOfADCs
{
    if (!listOfADCs) listOfADCs = [[NSMutableArray array] retain];
    return listOfADCs;
}

- (int) numberOfChannels
{
    return NumberOfChannels;
}

- (int) numberOfCoils
{
    return NumberOfCoils;
}

- (int) mappedChannelAtChannel:(int)aChan
{
    if (aChan >= [MagnetometerMap count]) return -1;
    return [[MagnetometerMap objectAtIndex:aChan] intValue];
}

- (double) conversionMatrix:(int)channel coil:(int)aCoil
{
    if (aCoil > NumberOfCoils || channel > NumberOfChannels) return 0.0;
    double* dblPtr = (double*)[FeedbackMatData bytes];
    return dblPtr[aCoil*NumberOfChannels + channel];
}

- (void) setPollingFrequency:(float)aFrequency
{
    
    pollingFrequency = aFrequency;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORnEDMCoilPollingFrequencyChanged
	 object: self];
}

- (void) toggleRunState
{
    if (isRunning) [self _stopRunning];
    else [self _startRunning];
}


- (void) initializeConversionMatrixWithPlistFile:(NSString*)plistFile
{
    NSLog(@"Reading FeedbackMatrix\n");

    // reads FeedbackMatrix from GUI
    // FeedbackMatrix is 24 x 180 (Coils x Channels), unused columns filled with 0s
    
    // Build the array from the plist  
    NSArray *RawFeedbackMatrix = [NSArray arrayWithContentsOfFile:plistFile];
    
    
    // Verify matrix sizes
    if (![self _verifyMatrixSizes:RawFeedbackMatrix
                orientationMatrix:OrientationMatrix
                  magnetometerMap:MagnetometerMap]) return;
    
    // If we get here, NumberOfChannels and NumberOfCoils are properly set.

    // Bring contents of RawFeedbackMatrix to FeedbackMatrix
    // While RFM is two-dimensional, FM is a simple double Array, dimensions are handled by cblas
    
    // Initialise FeedbackMatData
    NSMutableData* matData = [NSMutableData dataWithLength:NumberOfChannels*NumberOfCoils*sizeof(double)];
    double* dblPtr = (double*)[matData bytes];
    
    int line,i;
    for(line=0; line<[RawFeedbackMatrix count]; line++){
        for (i=0; i<NumberOfChannels;i++){
            dblPtr[line*NumberOfChannels + i] = [[[RawFeedbackMatrix objectAtIndex:line] objectAtIndex:i] doubleValue];
        }
    }
    [self _setConversionMatrix:matData];    
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"Filled FeedbackMatData\n");
    for (i=0; i<NumberOfCoils*NumberOfChannels;i++) NSLog(@"%f\n",dblPtr[i]);
    NSLog(@"output complete\n");
#endif
    

    
}

- (void) initializeOrientationMatrixWithPlistFile:(NSString*)plistFile
{
    
    NSMutableArray* orientMat = [NSMutableArray arrayWithContentsOfFile:plistFile];

    if( ![self _verifyMatrixSizes:nil orientationMatrix:orientMat magnetometerMap:MagnetometerMap] ) return;
    [self _setOrientationMatrix:orientMat];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"OrientationMatrix read:");
    int i;
    for (i=0; i<[orientMat count]; i++) {
        NSLog([NSString stringWithFormat:@"element: %f\n",[[orientMat objectAtIndex:i] floatValue]]);
    }
#endif

    
}

- (void) initializeMagnetometerMapWithPlistFile:(NSString*)plistFile
{
    NSMutableArray* magMap = [NSMutableArray arrayWithContentsOfFile:plistFile];
    if( ![self _verifyMatrixSizes:nil orientationMatrix:OrientationMatrix magnetometerMap:magMap] ) return;
    [self _setMagnetometerMatrix:magMap];
    
#ifdef ORnEDMCoil_DEBUG
    NSLog(@"MagnetometerMap read:\n");
    int i;
    for (i=0; i<[magMap count]; i++) {
        NSLog([NSString stringWithFormat:@"element: %f\n",[[magMap objectAtIndex:i] floatValue]]);
    }
#endif
}
- (void) resetConversionMatrix
{
    [self _setConversionMatrix:nil];
    NumberOfChannels = 0;
    NumberOfCoils    = 0;
    [self resetMagnetometerMap];
    [self resetOrientationMatrix];
}
- (void) resetMagnetometerMap
{
    [self _setMagnetometerMatrix:nil];
}
- (void) resetOrientationMatrix
{
    [self _setOrientationMatrix:nil];
}

- (NSArray*) magnetometerMap
{
    return MagnetometerMap;
}

- (NSArray*) orientationMatrix
{
    return OrientationMatrix;
}

- (NSData*)  feedbackMatData
{
    return FeedbackMatData;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    //NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
}

#pragma mark •••ORGroup
- (void) objectCountChanged
{
    // Recalculate the obj map
    if (!objMap) objMap = [[NSMutableDictionary dictionary] retain];
    [objMap removeAllObjects];
    NSEnumerator* e = [self objectEnumerator];
    for (id anObject in e) {
        [objMap setObject:anObject forKey:[NSNumber numberWithInt:[anObject tag]]];
    }
}

- (int) rackNumber
{
	return [self uniqueIdNumber];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"nEDM Coil %d",[self rackNumber]];
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self uniqueIdNumber] - [anObj uniqueIdNumber];
}

#pragma mark •••CardHolding Protocol
#define objHeight 71
#define objectsInRow 2
- (int) maxNumberOfObjects	{ return 12; }	//default
- (int) objWidth			{ return 100; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
    return NO;
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	float y = aPoint.y;
    float x = aPoint.x;
	int objWidth = [self objWidth];
    int columnNumber = (int)x/objWidth;
	int rowNumber = (int)y/objHeight;
	
    if (rowNumber >= [self maxNumberOfObjects]/objectsInRow ||
        columnNumber >= objectsInRow) return -1;
    return rowNumber*objectsInRow + columnNumber;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
    int rowNumber = aSlot/objectsInRow;
    int columnNumber = aSlot % objectsInRow;
    return NSMakePoint(columnNumber*[self objWidth],rowNumber*objHeight);
}

- (void) place:(id)aCard intoSlot:(int)aSlot
{
    [aCard setTag:aSlot];
	[aCard moveTo:[self pointForSlot:aSlot]];
}
- (int) slotForObj:(id)anObj
{
    return [anObj tag];
}
- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];

    [self setPollingFrequency:[decoder decodeFloatForKey:@"kORnEDMCoilPollingFrequency"]];
    [self setDebugRunning:[decoder decodeBoolForKey:@"kORnEDMCoilDebugRunning"]]; 
    [self _setMagnetometerMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilMagnetometerMap"]];
    [self _setOrientationMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilOrientationMatrix"]];
    [self _setConversionMatrix:[decoder decodeObjectForKey:@"kORnEDMCoilFeedbackMatrixData"]];
    NumberOfChannels = [decoder decodeIntForKey:@"kORnEDMCoilNumChannels"];    
    NumberOfCoils = [decoder decodeIntForKey:@"kORnEDMCoilNumCoils"]; 
    
    [self _setADCList:[decoder decodeObjectForKey:@"kORnEDMCoilListOfADCs"]];    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:pollingFrequency forKey:@"kORnEDMCoilPollingFrequency"];
    [encoder encodeBool:debugRunning forKey:@"kORnEDMCoilDebugRunning"];
    [encoder encodeObject:MagnetometerMap forKey:@"kORnEDMCoilMagnetometerMap"];
    [encoder encodeObject:OrientationMatrix forKey:@"kORnEDMCoilOrientationMatrix"];
    [encoder encodeObject:FeedbackMatData forKey:@"kORnEDMCoilFeedbackMatrixData"];
    [encoder encodeInt:NumberOfChannels forKey:@"kORnEDMCoilNumChannels"];    
    [encoder encodeInt:NumberOfCoils forKey:@"kORnEDMCoilNumCoils"];        
    
    [encoder encodeObject:listOfADCs forKey:@"kORnEDMCoilListOfADCs"];       
}

#pragma mark •••Holding ADCs
- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessing)];
}

@end

