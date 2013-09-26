//--------------------------------------------------------------------------------
//ORCV977Model.m
//Mark A. Howe 20013-09-26
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORCV977Model.h"

#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x9

//NSString* OR792SelectedRegIndexChanged 	= @"792 Selected Register Index Changed";
//NSString* OR792SelectedChannelChanged 	= @"792 Selected Channel Changed";
//NSString* OR792WriteValueChanged          = @"792 Write Value Changed";

// Define all the registers available to this unit.
static V977NamesStruct reg[kNumRegisters] = {
	{@"Input Set",              0x0000,		kReadWrite},  
	{@"Input Mask",             0x0002,		kReadWrite},
	{@"Input Read",             0x0004,		kReadOnly},
	{@"Single Hit Read",        0x0006,		kReadOnly},
	{@"Multihit Read",          0x0008,		kReadOnly},
	{@"Output Set",             0x000A,		kReadWrite},
	{@"Output Mask",            0x000C,		kReadWrite},
	{@"Interrupt Mask",         0x000E,		kReadWrite},
	{@"Clear Output",           0x0010,		kWriteOnly},
	{@"Singlehit Read-Clear",   0x0016,		kReadOnly},
	{@"Multihit Read-Clear",    0x0018,		kReadOnly},
	{@"Test Control",           0x001A,		kReadWrite},
	{@"Interrupt Level",        0x0020,		kReadWrite},
	{@"Interrupt Vector",       0x0022,		kReadWrite},
	{@"Serial Number",          0x0024,		kReadOnly},
	{@"Firmware Revision",      0x0026,		kReadOnly},
	{@"Control Register",       0x0028,		kReadWrite},
	{@"Software Reset",         0x002E,		kWriteOnly},
};

NSString* ORCV977ModelInputSetChanged  = @"ORCV977ModelInputSetChanged";
NSString* ORCV977ModelInputMaskChanged = @"ORCV977ModelInputMaskChanged";

@implementation ORCV977Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C977"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV977Controller"];
}


- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x2F);
}

- (NSSize) thresholdDialogSize //inherited
{
	return NSMakeSize(610,200);
}

#pragma mark ***Accessors
- (unsigned long)inputSet {
	
    return inputSet;
}

- (void)setInputSet:(unsigned long)anInputSet
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputSet:[self inputSet]];
    inputSet = anInputSet;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelInputSetChanged object:self];
}

- (BOOL)inputSetBit:(int)bit
{
	return inputSet&(1<<bit);
}

- (void) setInputSetBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = inputSet;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setInputSet:aMask];
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset:(short) anIndex
{
    return(reg[anIndex].addressOffset);
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

#pragma mark ***DataTaker

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 977 (Slot %d) ",[self slot]];
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
   	[self setInputSet:		[aDecoder decodeInt32ForKey:@"inputSet"]];

    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt32:inputSet		forKey:@"inputSet"];
}
@end

