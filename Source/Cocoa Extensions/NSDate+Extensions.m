//
//  NSDate_Extensions.h
//  Orca
//
//  Created by Mark Howe on 11/14/14.
//
//

#import <Cocoa/Cocoa.h>
#import "NSDate+Extensions.h"

@implementation NSDate (ORCADateExtension)

//these methods are to have a central place to get around the 10.10 depreciations
- (id) stdDescription
{
    return [self descriptionFromTemplate:@"MM/dd/yy HH:mm:ss"];
}
- (NSString*) utcDescription
{
    return [self descriptionFromTemplate:@"MM/dd/yy HH:mm:ss" timeZone:@""];
}
- (NSString*) descriptionFromTemplate:(NSString*)aTemplate
{
    return [self descriptionFromTemplate:aTemplate timeZone:nil];
}

- (NSString*) utcDateStringFromTemplate:(NSString*)aTemplate
{
    return [self descriptionFromTemplate:aTemplate timeZone:@"UTC"];
}
- (NSString*) descriptionFromTemplate:(NSString*)aTemplate timeZone:(NSString*)aTimeZone
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:aTemplate options:0 locale:[NSLocale currentLocale]]];
    if(aTimeZone!=nil)[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:aTimeZone]];
    
    NSString* s = [dateFormatter stringFromDate:self];
    return [s stringByReplacingOccurrencesOfString:@"," withString:@""];
}

+ (NSDate*) dateUsingYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(NSString *)aTimeZone
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithAbbreviation:aTimeZone];
    [calendar setTimeZone:timeZone];
    
    NSDateComponents* components = [[[NSDateComponents alloc] init] autorelease];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    
    return [calendar dateFromComponents:components];
}

+ (NSDate*) dateFromString:(NSString*)aDateStr calendarFormat:(NSString*)aFormat
{
    NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormat setDateFormat:aFormat];
    return [dateFormat dateFromString:aDateStr];
}

- (NSInteger) secondOfMinute
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:(NSSecondCalendarUnit) fromDate:self];
    return [components second];
#else
    NSCalendar* gregorian               = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitSecond fromDate:self];
    return [components second];
#endif
}

- (NSInteger) minuteOfHour
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:NSMinuteCalendarUnit fromDate:self];
    return [components minute];
#else
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitMinute fromDate:self];
    return [components minute];
#endif
    
}

- (NSInteger) hourOfDay
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:NSHourCalendarUnit fromDate:self];
    return [components hour];
#else
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitHour fromDate:self];
    return [components hour];
#endif
 
}

- (NSInteger) dayOfMonth
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:NSDayCalendarUnit fromDate:self];
    return [components day];
#else
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitDay fromDate:self];
    return [components day];
#endif
}

- (NSInteger) monthOfYear
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:NSMonthCalendarUnit fromDate:self];
    return [components month];
#else
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitMonth fromDate:self];
    return [components month];
#endif
}
- (NSInteger) yearOfCommonEra
{
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents* components = [gregorian components:NSYearCalendarUnit fromDate:self];
    return [components year];
#else
    NSCalendar* gregorian        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents* components = [gregorian components:NSCalendarUnitYear fromDate:self];
    return [components year];
#endif
}
@end
