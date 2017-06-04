//
//  ORKatrinv4Registers.m
//  Orca
//
//  Created by Mark Howe on Sun June 4, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#import "ORKatrinV4Registers.h"

typedef struct katrinv4FLTRegNamesStruct {
    NSString*       regName;
    unsigned long 	addressOffset;
    short			accessType;
    eKatrinFLTV4RegEnum enumCheckValue;
} katrinv4FLTRegNamesStruct;

katrinv4FLTRegNamesStruct regV4[kFLTV4NumRegs] = {

    {@"Status",			 0x0000, kFLTReadOnly,                  kFLTV4StatusReg          },
    {@"Control",		 0x0004, kFLTReadWrite,                 kFLTV4ControlReg         },
    {@"Command",		 0x0008, kFLTReadWrite,                 kFLTV4CommandReg         },
    {@"CFPGAVersion",	 0x000c, kFLTReadOnly,                  kFLTV4VersionReg         },
    {@"FPGA8Version",	 0x0010, kFLTReadOnly,                  kFLTV4pVersionReg        },
    {@"BoardIDLSB",      0x0014, kFLTReadOnly,                  kFLTV4BoardIDLsbReg      },
    {@"BoardIDMSB",      0x0018, kFLTReadOnly,                  kFLTV4BoardIDMsbReg      },
    {@"InterruptMask",   0x001C, kFLTReadWrite,                 kFLTV4InterruptMaskReg   },
    {@"HrMeasEnable",    0x0024, kFLTReadWrite,                 kFLTV4HrMeasEnableReg    },
    {@"EventFifoStatus", 0x002C, kFLTReadOnly,                  kFLTV4EventFifoStatusReg },
    {@"PixelSettings1",  0x0030, kFLTReadWrite,                 kFLTV4PixelSettings1Reg  },
    {@"PixelSettings2",  0x0034, kFLTReadWrite,                 kFLTV4PixelSettings2Reg  },
    {@"RunControl",      0x0038, kFLTReadWrite,                 kFLTV4RunControlReg      },
    {@"HistgrSettings",  0x003c, kFLTReadWrite,                 kFLTV4HistgrSettingsReg  },
    {@"AccessTest",      0x0040, kFLTReadWrite,                 kFLTV4AccessTestReg      },
    {@"SecondCounter",   0x0044, kFLTReadWrite,                 kFLTV4SecondCounterReg   },
    {@"HrControl",       0x0048, kFLTReadWrite,                 kFLTV4HrControlReg       },
    {@"HistMeasTime",    0x004C, kFLTReadWrite,                 kFLTV4HistMeasTimeReg    },
    {@"HistRecTime",     0x0050, kFLTReadOnly,                  kFLTV4HistRecTimeReg     },
    {@"HistNumMeas",     0x0054, kFLTReadOnly,                  kFLTV4HistNumMeasReg     },
    {@"PostTrigger",     0x0058, kFLTReadWrite,                 kFLTV4PostTrigger        },
    {@"Threshold",       0x2080, kFLTReadWrite | kFLTChanReg,   kFLTV4ThresholdReg       },
    {@"pStatusA",        0x2000, kFLTReadWrite | kFLTChanReg,   kFLTV4pStatusA           },
    {@"pStatusB",        0x6000, kFLTReadOnly,                  kFLTV4pStatusB           },
    {@"pStatusC",        0x26000,kFLTReadOnly,                  kFLTV4pStatusC           },
    {@"Analog Offset",   0x1000, kFLTReadOnly,                  kFLTV4AnalogOffset       },
    {@"Gain",			 0x1004, kFLTReadWrite | kFLTChanReg,   kFLTV4GainReg            },
    {@"Hit Rate",		 0x1100, kFLTReadOnly  | kFLTChanReg,   kFLTV4HitRateReg         },
    {@"Event FIFO1",	 0x1800, kFLTReadOnly,                  kFLTV4EventFifo1Reg      },
    {@"Event FIFO2",	 0x1804, kFLTReadOnly,                  kFLTV4EventFifo2Reg      },
    {@"Event FIFO3",	 0x1808, kFLTReadOnly  | kFLTChanReg,   kFLTV4EventFifo3Reg      },
    {@"Event FIFO4",	 0x180C, kFLTReadOnly  | kFLTChanReg,   kFLTV4EventFifo4Reg      },
    {@"HistPageN",		 0x200C, kFLTReadOnly,                  kFLTV4HistPageNReg       },
    {@"HistLastFirst",	 0x2044, kFLTReadOnly,                  kFLTV4HistLastFirstReg   },
    {@"TestPattern",	 0x1400, kFLTReadWrite,                 kFLTV4TestPatternReg     },
    {@"EnergyOffset",	 0x005C, kFLTReadWrite,                 kFLTV4EnergyOffsetReg    },
};

@implementation ORKatrinV4Registers
+ (ORKatrinV4Registers*) sharedRegSet
{
    //A singleton so that all the FLTs can expose the registers from this object
    if(!sharedKatrinV4Registers){
        sharedKatrinV4Registers = [[ORKatrinV4Registers alloc] init];
    }
    return sharedKatrinV4Registers;
}

- (id) init
{
    self = [super init];
    [self checkRegisterTable];
    return self;
}

- (BOOL) checkRegisterTable
{
    int i;
    for(i=0;i<kFLTV4NumRegs;i++){
        if(regV4[i].enumCheckValue != i){
            if(printedOnce){
                NSLogColor([NSColor redColor],@"KATRIN V4 Register table has error at index: %d\n",i);
                printedOnce = YES;
            }
            return NO;
        }
    }
    return YES;
}

- (void) dealloc
{
    [sharedKatrinV4Registers release];
    sharedKatrinV4Registers = nil;
    [super dealloc];
}

- (int)       numRegisters                  { return kFLTV4NumRegs; }
- (NSString*) registerName: (short) anIndex { return regV4[anIndex].regName; }
- (short)     accessType: (short) anIndex   { return regV4[anIndex].accessType; }

- (unsigned long) addressForStation:(int)aStation registerIndex:(int)aReg chan:(int)aChannel
{
    return (aStation << 17) | (aChannel << 12) | (regV4[aReg].addressOffset>>2);
}

- (unsigned long) addressForStation:(int)aStation registerIndex:(int)aReg
{
    return (aStation << 17) | (regV4[aReg].addressOffset>>2);
}

@end
