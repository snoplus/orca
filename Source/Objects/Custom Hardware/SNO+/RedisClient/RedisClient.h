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
- (redisReply*) vcommand: (char*) fmt args:(va_list) args;
- (redisReply*) command: (char *) fmt, ...;
- (void) okCommand: (char *) fmt, ...;
- (int) intCommand: (char *) fmt, ...;
@end
