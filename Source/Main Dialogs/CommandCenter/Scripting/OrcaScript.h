typedef enum { typeCon, typeId, typeOpr, typeSelVar, typeStr, typeArray, typeArg, typeOperationSymbol} nodeEnum;

enum {
	kPostInc,
	kPreInc,
	kPostDec,
	kPreDec,
	kAppend,
	kTightAppend,
	kObjList,
	kDefineArray,
	kLeftArray,
	kRightArray,
	kSelName,
	kFuncCall,
	kMakeArgList,
	kConditional,
	kArrayListAssign,
	kArrayAssign,
	kWaitTimeOut
};