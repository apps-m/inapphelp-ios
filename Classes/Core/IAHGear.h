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
#import "IAHAppearance.h"
#import "IAHKBitem.h"
#import "IAHTicket.h"
#import "IAHUpdate.h"
#import "IAHUser.h"
#import "IAHAttachment.h"
#import "IAHTicketReply.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>



/**
 
 HSGear helps you implement your own favorite HelpDesk solution at ease.
 
 We have integrated AFNetworking for you to use.
 
 Note: We are doing caching for you -> Only important fields are cached and stored in 'HelpStack' directory.
 
 */

#define HALog(fmt, ...) NSLog((@"HelpApp:- " fmt),  ##__VA_ARGS__)

@protocol IAHGearProtocol <NSObject>

///-------------------------------------
/// @name Fetch KB articles from server
///-------------------------------------
/**
 
 Fetch KB articles for given section and return an array to display. Section will be nil for first time, and after that user selection section will be sent.
 
 @params section The sub-section for which KB is to be fetch. Can be nil to get first set of sections.
 
 @return, array of type HSKBItem when operation is success.

 Note: Make sure, to set if the given KB is of type section or article.

 Note: Call success even if you are not doing anything here.
 
 */
- (void)fetchKBForSection:(IAHKBItem*)section success:(void (^)(NSMutableArray* kbarray))success failure:(void(^)(NSError* e))failure;


///------------------------------------------
/// @name Create a ticket
///-------------------------------------------

/**
 This is called before creating a ticket so validation on user information can be done.
 
 @params user user object that contains name and email of user
 
 @return valid user object, this object will be send back during ticket creation.
 */
- (void)checkAndFetchValidUser:(IAHUser*)user withSuccess:(void (^)(IAHUser* validUser))success failure:(void(^)(NSError* e))failure;

/**
///------------------------------------------
/// @name Fetch all updates on ticket
///-------------------------------------------
    Fetch Updates on given Ticket.
 
    @params user The user object that is formed when ticket is created.
    @params user Time of last message we have

    @return array of HSUpdate object when operation is success
 
 */
- (void)fetchAllUpdateForUser:(IAHUser *)user fromTime:(long long)time success:(void (^)(NSMutableArray* updateArray))success failure:(void (^)(NSError* e))failure;

///------------------------------------------
/// @name Add reply to a ticket
///-------------------------------------------

/*
 Add reply to update

 @params reply The reply to be added to a given ticket.
 @params user The user object that is formed when ticket is created.
 @params user Time of last message we have

 @return update object when operation is success
 */
- (void)addReply:(IAHTicketReply *)reply byUser:(IAHUser *)user getUpdatesFromTime:(long long) time success:(void (^)(NSMutableArray* updateArray))success failure:(void (^)(NSError* e))failure;



@optional
///------------------------------------------
/// @name Search KB articles for given String
///-------------------------------------------
/**
 Filter your KB articles and return an array to display. 
 Default implementation, filters array within sections.
 */
- (void)searchKB:(NSString*)searchString success:(void (^)(NSMutableArray* kbarray))success failure:(void(^)(NSError* e))failure;


// To let email handle issue creation return yes. emailgear return yes. default is no.
- (BOOL)doLetEmailHandleIssueCreation;

@end



@interface IAHGear : NSObject <IAHGearProtocol>

@property (nonatomic, strong) NSString* supportEmailAddress;
@property (nonatomic, strong) NSString* localArticlePath;
@property (nonatomic, strong) AFHTTPRequestOperationManager* networkManager;


@end





