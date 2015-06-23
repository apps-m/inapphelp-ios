//Copyright (c) 2014 HelpStack (http://helpstack.io)
//
//Permission is hereby granted, free of charge, to any person obtaining a cop
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.
#import <Foundation/Foundation.h>
#import "IAHGear.h"
#import "IAHUser.h"
#import "IAHTicketReply.h"

@interface IAHTicketSource : NSObject

+ (id)instance;

// Initialize with gear to use
- (id)initWithGear:(IAHGear *)gear;

@property(nonatomic, strong, readonly) IAHGear *gear;
@property(nonatomic, strong, readonly) IAHUser *user;


/**
 Fetches ticket properties from given gear.
 Note: You should call this on viewDidAppear or anytime you need fresh data from server.
 */
- (void)prepareTicket;
- (NSUInteger)updateCount;
- (IAHUpdate *)updateAtPosition:(NSInteger)position;
- (void)prepareUpdate:(IAHUser *)user success:(void (^)(void))success failure:(void (^)(NSError *))failure;

// Creating new ticket
- (BOOL)shouldShowUserDetailsFormWhenCreatingTicket;
// Registers user, but save user details only after first ticket is created successfully
- (void)registerUserWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email success:(void (^)(void))success failure:(void (^)(NSError *error))failure;



- (void)createNewTicket:(IAHTicketReply *)details success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)setUserId:(NSString *)userId;
- (void)setUserSecret:(NSString *)userSecret;
- (void)setPushToken:(NSString *)pushToken;

// Add reply on ticket
- (void)addReply:(IAHTicketReply *)details byUser:(IAHUser *)user getUpdatesFromTime:(long long)time success:(void (^)(void))success failure:(void (^)(NSError *))failure;


// Ticket Protocol properties
- (BOOL) isTicketProtocolImplemented;
- (NSString *) supportEmailAddress;

@end
