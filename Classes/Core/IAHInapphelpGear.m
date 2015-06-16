//
//  INInapphelpGear.m
//  Pods
//
//  Created by MniLL on 18.05.15.
//
//

#import "IAHInapphelpGear.h"
#import <AFNetworkActivityIndicatorManager.h>
#import "IAHUtility.h"

@interface IAHInapphelpGear()

@property (nonatomic, strong) NSString *company;
@property (nonatomic, strong) NSString *app_id;
@property (nonatomic, strong) NSString *app_key;

@end
@implementation IAHInapphelpGear

- (id)initWithCompanyName:(NSString *)company appId:(NSString *)app_id appKey:(NSString *)app_key {
    
    if ( (self = [super init]) ) {
        
        self.company = company;
        self.app_id = app_id;
        self.app_key = app_key;
        

        self.networkManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString: [NSString stringWithFormat:@"http://www.%@.inapphelp.com/", company]]];

        [self.networkManager setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [self.networkManager setResponseSerializer:[AFJSONResponseSerializer serializer]];
        [self.networkManager.requestSerializer setValue:[NSString stringWithFormat:@"http://www.%@.inapphelp.com/", self.company] forHTTPHeaderField:@"referer"];
        
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }
    
    return self;
}

- (void)fetchKBForSection:(IAHKBItem*)section success:(void (^)(NSMutableArray* kbarray))success failure:(void(^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"api/faq/%@", self.app_id];
    [self.networkManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.articleSections = responseObject;
        NSMutableArray *articles = [self getArticlesFromData:responseObject];
        success(articles);
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

-(NSMutableArray *)getArticlesFromData:(NSDictionary *) responseData{
    NSMutableArray *articles = [[NSMutableArray alloc] init];
    for(id article in responseData){
        IAHKBItem *kbarticle = [[IAHKBItem alloc] initAsArticle:[article objectForKey:@"title"] textContent:[article objectForKey:@"text"] kbID:nil];
        [articles addObject:kbarticle];
    }
    return articles;
}


- (void)fetchAllUpdateForUser:(IAHUser *)user fromTime:(long long)time success:(void (^)(NSMutableArray* updateArray))success failure:(void (^)(NSError* e))failure {
    NSString *path = @"api/chat/updates";
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:user.name forKey:@"name"];
    [parameters setObject:[NSString stringWithFormat:@"%lld", time] forKey:@"time"];
    [parameters setObject:self.app_id forKey:@"appid"];
    [parameters setObject:self.app_key forKey:@"appkey"];

    if (user.userSecret != nil) {
        [parameters setObject:user.userSecret forKey:@"secretkey"];
    }
    
    if (user.userId != nil) {
        [parameters setObject:user.userId forKey:@"userid"];
    } else {
        NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
        [parameters setObject:[oNSUUID UUIDString] forKey:@"userid"];
    }
    
    [self.networkManager GET:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableArray *tickUpdates = [self getTicketUpdatesFromResponseData:responseObject];
        success(tickUpdates);
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

-(NSMutableArray *)getTicketUpdatesFromResponseData:(NSArray *)responseData {
    NSMutableArray *tickUpdates = [[NSMutableArray alloc] init];
    for(id updateDict in responseData) {
        
        if([updateDict objectForKey:@"t"] != [NSNull null]) {
            
            IAHUpdate *tick_update = [[IAHUpdate alloc] init];
            tick_update.content = [updateDict objectForKey:@"t"];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
            [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            long long ts =[[updateDict objectForKey:@"ts"] longLongValue];
            tick_update.updatedId = ts;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:(long long)(ts/1000)];
            tick_update.updatedAt = date;
            NSString *type = [updateDict objectForKey:@"s"];
            if(type == nil) {
                tick_update.updateType = HATypeUserReply;
            } else {
                tick_update.updateType = HATypeStaffReply;
            }
            
            if([updateDict objectForKey:@"a"] != nil) {
                NSMutableArray *attachments = [[NSMutableArray alloc] init];
                IAHAttachment *attachment = [[IAHAttachment alloc] init];
                attachment.url = [updateDict objectForKey:@"a"];
                attachment.mimeType = [updateDict objectForKey:@"am"];
                [attachments addObject:attachment];
                tick_update.attachments = attachments;
            }
            [tickUpdates addObject:tick_update];
        }
    }
    return tickUpdates;
}

- (void)addReply:(IAHTicketReply *)reply byUser:(IAHUser *)user getUpdatesFromTime:(long long)time success:(void (^)(NSMutableArray* update))success failure:(void (^)(NSError* e))failure {

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:user.name forKey:@"name"];
    [parameters setObject:[NSString stringWithFormat:@"%lld", time] forKey:@"time"];
    [parameters setObject:user.email forKey:@"email"];
    [parameters setObject:@"ios" forKey:@"platform"];
    [parameters setObject:self.app_id forKey:@"appid"];
    [parameters setObject:self.app_key forKey:@"appkey"];
    [parameters setObject:reply.content forKey:@"text"];
    [parameters setObject:[IAHUtility deviceInformation] forKey:@"deviceinfo"];
    
    if (user.userSecret != nil) {
        [parameters setObject:user.userSecret forKey:@"secretkey"];
    }
    
    if (user.userId != nil) {
        [parameters setObject:user.userId forKey:@"userid"];
    } else {
        NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
        [parameters setObject:[oNSUUID UUIDString] forKey:@"userid"];
    }

    if (user.pushToken != nil) {
        [parameters setObject:user.pushToken forKey:@"pushtoken"];
    }
    
    NSArray *attachments = reply.attachments;
    
    [self.networkManager POST:@"api/chat/submit" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData){
        if(attachments != nil && (attachments.count > 0)) {
            for(IAHAttachment *attachment in attachments){
                [formData appendPartWithFileData:attachment.attachmentData name:@"attachments" fileName:((IAHAttachment *)attachment).fileName mimeType:((IAHAttachment *)attachment).mimeType];
            }
        }
    }success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableArray *updates = [self getTicketUpdatesFromResponseData:responseObject];
        success(updates);
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HALog(@"Failed to create a ticket %@", error);
        if (operation.responseString) {
            HALog(@"Error Description %@", operation.responseString);
        }
        failure(error);
    }];
}
@end
