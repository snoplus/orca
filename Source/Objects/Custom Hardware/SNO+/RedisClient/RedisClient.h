//
//  RedisClient.h
//  Orca
//
//  Created by Eric Marzec on 1/15/16.
//
//

#import <Foundation/Foundation.h>
#import "hiredis.h"
@interface RedisClient : NSObject
{
    NSString *host;
    redisContext *context;
    int port;
    long timeout;
}
@property (nonatomic) int port;
@property (nonatomic) long timeout;

- (void) connect;
- (void) disconnect;
- (redisReply*) vcommand: (const char*) fmt args:(va_list) args;
- (redisReply*) command: (const char *) fmt, ...;
- (void) okCommand: (const char *) fmt, ...;
- (int) intCommand: (const char *) fmt, ...;
@end
