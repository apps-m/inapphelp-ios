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
#import "IAHTicketSource.h"
#import "IAHHelpDesk.h"

#define CACHE_DIRECTORY_NAME    @"HelpStack"
#define TICKET_CACHE_FILE_NAME  @"HelpApp_Ticket.plist"
#define USER_CACHE_FILE_NAME    @"HelpApp_User.plist"

@interface IAHTicketSource ()

@property (nonatomic, strong) NSMutableArray* ticketArray;
@property (nonatomic, strong) NSMutableArray* updateArray;
@property (nonatomic, strong, readwrite) IAHGear* gear;
@property (nonatomic, strong, readwrite) IAHUser* user;

@end

@implementation IAHTicketSource

+ (id)instance {
    static IAHTicketSource *ticketSource = nil;
    IAHGear* gear = [[IAHHelpDesk instance] gear];
    NSAssert (gear != nil, @"No gear was set to HSHelpStack");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ticketSource = [[IAHTicketSource alloc] initWithGear:gear];
    });
    return ticketSource;
}

/**
    Set HAGear, so its method can be called.
 */
- (id)initWithGear:(IAHGear *)gear {
    if(self = [super init]) {
        [self setGear:gear];
        [self initializeUserFromCache];
    }
    return self;
}

- (void) initializeUserFromCache {
    self.user = [IAHTicketSource userAtPath:USER_CACHE_FILE_NAME];
    if (self.user == nil)
        self.user = [[IAHUser alloc] init];
}

- (void)setPushToken:(NSString *)pushToken {
    self.user.pushToken = pushToken;
    [IAHTicketSource saveUser:self.user atPath:USER_CACHE_FILE_NAME];
}

- (void)setUserSecret:(NSString *)userSecret {
    self.user.userSecret = userSecret;
    [IAHTicketSource saveUser:self.user atPath:USER_CACHE_FILE_NAME];
}

- (void)setUserId:(NSString *)userId {
    self.user.userId = userId;
    [IAHTicketSource saveUser:self.user atPath:USER_CACHE_FILE_NAME];
}

- (void)registerUserWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email success:(void (^)(void))success failure:(void (^)(NSError *error))failure {

    self.user.firstName = firstName;
    self.user.lastName = lastName;
    self.user.email = email;
    
    // TODO: may be a check for user info can be performed here.
    [self.gear checkAndFetchValidUser:self.user withSuccess:^(IAHUser *validUser) {
        success();
    } failure:^(NSError *e) {
        HALog("searchOrRegisterUser failed: %@",e);
        failure(e);
    }];
}

//////////////////////////////////////////////////

// Store HSUser and check for it while creating a new ticket
- (BOOL)shouldShowUserDetailsFormWhenCreatingTicket {
    BOOL answer = [self.user isValideUser];
    return answer;
}
/////////////////////////////////////////////////

- (void)createNewTicket:(IAHTicketReply *)details success:(void (^)(void))success failure:(void (^)(NSError *))failure {
    IAHUser* user = self.user;
    // Checking if gear implements createTicket:success:failure:
    if([self.gear respondsToSelector:@selector(addReply:byUser:getUpdatesFromTime:success:failure:)]) {
        [self.gear addReply:details byUser:user getUpdatesFromTime:0l success:^(NSMutableArray* updates) {
            [IAHTicketSource saveUser:user atPath:USER_CACHE_FILE_NAME];
            success();
        } failure:^(NSError *e) {
            HALog("Create new ticket failed: %@",e);
            failure(e);
        }];
    }
    else {
        success();
    }
}

- (void) prepareTicket {
    [self.updateArray removeAllObjects];
}

- (void)prepareUpdate:(IAHUser *)user success:(void (^)(void))success failure:(void (^)(NSError *))failure {
    // Preparing update array for new ticket, dumping array for old ticket
    long long from;
    if ([self updateCount] > 0){
        from = [((IAHUpdate*)[self.updateArray lastObject]) updatedId];
    } else {
        from = 0ll;
        self.updateArray = [[NSMutableArray alloc] init];
    }
    
    [self.gear fetchAllUpdateForUser:self.user fromTime:from success:^(NSMutableArray *updatesArray) {
        IAHUpdate* lastUpdate = [self.updateArray lastObject];
        if(updatesArray!=nil) {
            for(IAHUpdate *updateDict in updatesArray) {
                if (lastUpdate == nil || lastUpdate.updatedId < updateDict.updatedId)
                    [self.updateArray addObject:updateDict];
            }
        }
        success();
    } failure:^(NSError *e) {
        HALog("Fetch all update failed: %@",e);
        failure(e);
    }];
}

- (NSUInteger)updateCount {
    return self.updateArray.count;
}

- (IAHUpdate *)updateAtPosition:(NSInteger)position {
    IAHUpdate* update = [self.updateArray objectAtIndex:position];
    return update;
}

- (void)addReply:(IAHTicketReply *)details byUser:(IAHUser *)user getUpdatesFromTime:(long long)time success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // Checking if gear implements addReply:ticket:success:failure:
    __block NSMutableArray* updates = self.updateArray;

    if([self.gear respondsToSelector:@selector(addReply:byUser:getUpdatesFromTime:success:failure:)]) {
        [self.gear addReply:details byUser:self.user getUpdatesFromTime:time success:^(NSMutableArray *update) {
            IAHUpdate* lastUpdate = [updates lastObject];
            if(update!=nil) { // Safe check
                for(IAHUpdate *updateDict in update) {
                    if (lastUpdate == nil || lastUpdate.updatedId < updateDict.updatedId)
                        [updates addObject:updateDict];
                }
            }
            success();
        } failure:^(NSError *e) {
            HALog("Add reply to a ticket failed: %@",e);
            failure(e);
        }];
    }
    else {
        success();
    }
}

// Ticket Protocol properties
- (BOOL) isTicketProtocolImplemented {
    if ([self.gear respondsToSelector:@selector(doLetEmailHandleIssueCreation)]) {
        return ![self.gear doLetEmailHandleIssueCreation];
    }
    return YES;
}

- (NSString*) supportEmailAddress {
    return self.gear.supportEmailAddress;
}

#pragma mark - Cache functions
+ (void)saveUser:(IAHUser *)user atPath:(NSString *)fileName {
    NSString* cacheFilePath = [self fileCachePath:fileName];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:cacheFilePath]) {
        [fm removeItemAtPath:cacheFilePath error:nil];
    }
    
    if (user) { // Save only for non nil user
        [NSKeyedArchiver archiveRootObject:user toFile:cacheFilePath];
    }
}

+ (IAHUser *)userAtPath:(NSString *)fileName {
    NSString* cacheFilePath = [self fileCachePath:fileName];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFilePath];;
}

+ (NSString *)directoryName {
    return CACHE_DIRECTORY_NAME;
}

+ (NSString *) fileCachePath:(NSString *)fileName {
    NSString* cacheDirectoryPath = [self getCacheDirectory];
    NSString* cacheFilePath = [cacheDirectoryPath stringByAppendingPathComponent:fileName];
    return cacheFilePath;
}

+ (NSString *) getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:[self directoryName]];
    
    // Create directory if not already exist
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    
    return documentsDirectory;
}

@end
