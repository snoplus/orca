#if !defined IPE4TBTOOLS_H
#define IPE4TBTOOLS_H


/***************************************************************************
    ipe4tbtools.h  -  description: header file  for the IPE4 Edelweiss software (Orca and ipe4reader)
    
	history: see *.icc file

    begin                : Jan 07 2013
    copyright            : (C) 2012 by Till Bergmann, KIT
    email                : Till.Bergmann@kit.edu
 ***************************************************************************/

//This is the version of the IPE4 readout code (display is: version/1000, so cew_controle will e.g. display 1934003 as 1934.003) -tb-


#if 0 //moved to ipe4reader.h
//This is the version of the IPE4 readout code (display is: version/1000, so cew_controle will display 1934003 as 1934.003) -tb-
// VERSION_IPE4_HW is 1934 which means IPE4  (1=I, 9=P, 3=E, 4=4)
// VERSION_IPE4_SW is the version of the readout software (this file)
#define VERSION_IPE4_HW      1934200
#define VERSION_IPE4_SW           10
#define VERSION_IPE4READOUT (VERSION_IPE4_HW + VERSION_IPE4_SW)
#endif


// update 2013-01-03 -tb-

/*--------------------------------------------------------------------
  includes
  --------------------------------------------------------------------*/




/*--------------------------------------------------------------------
 *    function prototypes
 *       
 *--------------------------------------------------------------------*/ //-tb-

// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address
int slotOfPCIAddr(uint32_t address);

// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address>>2
int slotOfAddr(uint32_t address);

//return number of bits in 'val'
int numOfBits(uint32_t val);



//counts all processes named "ipe4reader*" (used to prohibit double start)
int count_ipe4reader_instances(void);


//kill all ipe4reader* instances except myself
int kill_ipe4reader_instances(void);

/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/



//TODO: use this for ipe4reader AND Orca -tb-


    //SLT registers
	static const uint32_t SLTControlReg			= 0xa80000 >> 2;
	static const uint32_t SLTStatusReg			= 0xa80004 >> 2;
	static const uint32_t SLTCommandReg			= 0xa80008 >> 2;
	static const uint32_t SLTInterruptMaskReg	= 0xa8000c >> 2;
	static const uint32_t SLTInterruptRequestReg= 0xa80010 >> 2;
	static const uint32_t SLTVersionReg			= 0xa80020 >> 2;

	static const uint32_t SLTPixbusPErrorReg     = 0xa80024 >> 2;
	static const uint32_t SLTPixbusEnableReg     = 0xa80028 >> 2;
	static const uint32_t SLTBBOpenedReg         = 0xa80034 >> 2;

	
	static const uint32_t SLTSemaphoreReg    = 0xb00000 >> 2;
	
	static const uint32_t CmdFIFOReg         = 0xb00004 >> 2;
	static const uint32_t CmdFIFOStatusReg   = 0xb00008 >> 2;
	static const uint32_t OperaStatusReg0    = 0xb0000c >> 2;
	static const uint32_t OperaStatusReg1    = 0xb00010 >> 2;
	static const uint32_t OperaStatusReg2    = 0xb00014 >> 2;
	
	static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
	
	//TODO: multiple FIFOs are obsolete, remove it -tb-
	static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10 
	static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAEOffsetReg   = 0xe00008 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAFOffsetReg   = 0xe0000c >> 2;//obsolete 2012-10
	static const uint32_t BB0csrReg         = 0xe00010 >> 2;//obsolete 2012-10
	
	#if 0
	static const uint32_t FIFOModeReg       = 0xe00000 >> 2;
	static const uint32_t FIFOStatusReg     = 0xe00004 >> 2;
	static const uint32_t PAEOffsetReg      = 0xe00008 >> 2;
	static const uint32_t PAFOffsetReg      = 0xe0000c >> 2;
	static const uint32_t FIFOcsrReg        = 0xe00010 >> 2;
    #endif

	static const uint32_t SLTTimeLowReg     = 0xb00018 >> 2;
	static const uint32_t SLTTimeHighReg    = 0xb0001c >> 2;


	
inline uint32_t FIFOStatusReg(int numFIFO);

inline uint32_t FIFOModeReg(int numFIFO);
inline uint32_t FIFOAddr(int numFIFO);
inline uint32_t PAEOffsetReg(int numFIFO);
inline uint32_t PAFOffsetReg(int numFIFO);
inline uint32_t BBcsrReg(int numFIFO);

    //FLT registers
	static const uint32_t FLTStatusRegBase      = 0x000000 >> 2;
	static const uint32_t FLTControlRegBase     = 0x000004 >> 2;
	static const uint32_t FLTCommandRegBase     = 0x000008 >> 2;
	static const uint32_t FLTVersionRegBase     = 0x00000c >> 2;
	
	static const uint32_t FLTFiberSet_1RegBase  = 0x000024 >> 2;
	static const uint32_t FLTFiberSet_2RegBase  = 0x000028 >> 2;
	static const uint32_t FLTStreamMask_1RegBase  = 0x00002c >> 2;
	static const uint32_t FLTStreamMask_2RegBase  = 0x000030 >> 2;
	static const uint32_t FLTTriggerMask_1RegBase  = 0x000034 >> 2;
	static const uint32_t FLTTriggerMask_2RegBase  = 0x000038 >> 2;

	static const uint32_t FLTAccessTestRegBase     = 0x000040 >> 2;
	
	static const uint32_t FLTTotalTriggerNRegBase  = 0x000084 >> 2;

	static const uint32_t FLTBBStatusRegBase    = 0x00001400 >> 2;

	static const uint32_t FLTRAMDataRegBase     = 0x00003000 >> 2;
	
// 
// NOTE: numFLT from 1...20  !!!!!!!!!!!!
//
// (NOT from 0 ... 19!!!)
//
	//TODO: 0x3f or 0x1f?????????????
inline uint32_t FLTStatusReg(int numFLT);
inline uint32_t FLTControlReg(int numFLT);
inline uint32_t FLTCommandReg(int numFLT);
inline uint32_t FLTVersionReg(int numFLT);
inline uint32_t FLTFiberSet_1Reg(int numFLT);
inline uint32_t FLTFiberSet_2Reg(int numFLT);
inline uint32_t FLTStreamMask_1Reg(int numFLT);
inline uint32_t FLTStreamMask_2Reg(int numFLT);
inline uint32_t FLTTriggerMask_1Reg(int numFLT);
inline uint32_t FLTTriggerMask_2Reg(int numFLT);
inline uint32_t FLTAccessTestReg(int numFLT);
inline uint32_t FLTBBStatusReg(int numFLT, int numChan);
inline uint32_t FLTTotalTriggerNReg(int numFLT);
inline uint32_t FLTRAMDataReg(int numFLT, int numChan);












/*--------------------------------------------------------------------
  classes:
  --------------------------------------------------------------------*/






/*--------------------------------------------------------------------
 *    function:     
 *    purpose:      
 *    author:       Till Bergmann, 2011
 *--------------------------------------------------------------------*/ //-tb-
 
 
#endif
//of #if !defined IPE4TBTOOLS_H
