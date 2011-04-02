/*
	NSArray+Extensions.m
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

@implementation NSArray (OrcaExtensions)
- (id) prepareForHTML
{
	NSMutableArray* processedArray = [NSMutableArray array];
	for(id anObj in self){
		[processedArray addObject:[anObj prepareForHTML]];
	}
	return processedArray;
}

- (BOOL) containsObjectIdenticalTo: (id)obj 
{ 
    return [self indexOfObjectIdenticalTo: obj]!=NSNotFound; 
}

- (NSArray *)tabJoinedComponents
{
   NSEnumerator *components;
   NSMutableArray *rows;
   NSArray *row;
   
   components = [self objectEnumerator];
   rows = [NSMutableArray arrayWithCapacity: [self count]];
   
   while (row = [components nextObject])
   {
       [rows addObject: [row componentsJoinedByString: @"\t"]];
   }
   
   return rows;
}


- (NSString *)joinAsLinesOfEndingType:(LineEndingType)lineEndingType
{
   switch (lineEndingType)
   {
       case LineEndingTypeDOS : return [self componentsJoinedByString: @"\r\n"];
       case LineEndingTypeMac : return [self componentsJoinedByString: @"\r"];
       case LineEndingTypeUnix: return [self componentsJoinedByString: @"\n"];
       default : return [self componentsJoinedByString: @""];
   }
   
}


- (NSData *)dataWithLineEndingType:(LineEndingType)lineEndingType;
{
   NSArray *rows;
   NSString *dataString;
   
   rows = [self tabJoinedComponents];
   dataString = [rows joinAsLinesOfEndingType: lineEndingType];
   
   return [dataString dataUsingEncoding: NSASCIIStringEncoding];
}

- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	if([anArray count] == 0)return self;
	else {
		id aKey = [anArray objectAtIndex:0];
		[anArray removeObjectAtIndex:0];
		long index = [aKey intValue];
		if(index>=0 && index < [self count]){
			id anObj = [self objectAtIndex:index];
			if([anObj respondsToSelector:@selector(objectForKeyArray:)]){
				return [anObj objectForKeyArray:anArray];
			}
			else return anObj;
		}
		else return self;
	}
}
- (void) prettyPrint:(NSString*)aTitle
{
	NSLog(@"----------------------------\n");
	NSLog(@"%@\n",aTitle);
	int i;
	for(i=0;i<[self count];i++){
		NSLog(@"%d : %@\n",i,[self objectAtIndex:i]);
	}
	NSLog(@"----------------------------\n");
}
@end

@implementation NSMutableArray (OrcaExtensions)

- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index 
{
    for (NSObject *entry in array) {
        [self insertObject:entry atIndex:index++];
    }
}

- (NSMutableArray*) children
{
	return self;
}

- (void) moveObject:(id)anObj toIndex:(unsigned)newIndex
{
    if([self containsObject:anObj]){
        NSNull* aNullObj = [NSNull null];
        [self replaceObjectAtIndex:[self indexOfObject:anObj] withObject:aNullObj];
        [self insertObject:anObj atIndex:newIndex];
        [self removeObject:aNullObj];
    }
    else [self insertObject:anObj atIndex:newIndex];
}

- (unsigned) numberOfChildren
{
    return [self count];
}
@end
