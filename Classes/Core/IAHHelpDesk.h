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
#import "IAHTicketSource.h"


@protocol IAHGearProtocol;


@interface IAHHelpDesk : NSObject

+ (id)instance;

/**
    Set the type of gear to be used.
 */
@property (nonatomic, strong, readwrite) IAHGear* gear;

@property (nonatomic, strong, readonly) IAHAppearance* appearance;

@property (nonatomic, assign) BOOL requiresNetwork;

@property (nonatomic) BOOL conversationLaunched;
/**
    Whenever you want to display HelpDesk screen, call this. This will open help screen as a modal view controller for iPhone and as a form sheet on ipad.
 
    Note: There should be a gear set, otherwise gear initialization will fail.
 */

- (void)initWithCompanyName:(NSString*)company withAppId:(NSString*)appId withAppKey:(NSString*)appKey;
- (void)showHelp:(UIViewController*)controller;
- (void)showHelp:(UIViewController*)controller completion:(void (^)(void))completion;
- (void)showHelp:(UIViewController*)controller fromPush:(NSDictionary*)pushInfo;
- (void)handlePush:(NSDictionary*)pushInfo withViewController:(UIViewController*)viewController launchedFromPush:(bool)launched;

- (void)setThemeFrompList:(NSString*)pListPath;

- (void)setUserId:(NSString *)userId;
- (void)setUserSecret:(NSString *)userSecret;
- (void)setPushToken:(NSData *)pushToken;
- (void)setPushTokenString:(NSString *)pushToken;

- (NSString*) getCompanyName;

@end






