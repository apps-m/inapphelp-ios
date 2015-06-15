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

#import "IAHHelpDesk.h"
#import "IAHInapphelpGear.h"
#import <JCNotificationCenter.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "IAHIssueDetailViewController.h"

@interface IAHHelpDesk ()

@property (nonatomic, strong, readwrite) IAHAppearance* appearance;
@property (nonatomic, strong, readwrite) NSString* company;
@property (nonatomic, strong, readwrite) NSString* appId;
@property (nonatomic, strong, readwrite) NSString* appKey;
@property (nonatomic, strong, readwrite) NSString* localPushToken;
@property (nonatomic, strong, readwrite) NSString* localUserId;
@property (nonatomic, strong, readwrite) NSString* localUserSecret;

@end

@implementation IAHHelpDesk


/**
 Creates Singleton instance of class.
 **/
+ (id)instance {
    static IAHHelpDesk *helpStack = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helpStack = [[self alloc] init];
        helpStack.appearance = [IAHAppearance instance];
        helpStack.requiresNetwork = YES;
        helpStack.conversationLaunched = NO;
    });
    return helpStack;
}


- (void)setThemeFrompList:(NSString *)pListPath {
    [self.appearance setCustomThemeProperties:[self readThemePropertiesFrompList:pListPath]];
}

- (NSDictionary *)readThemePropertiesFrompList:(NSString *)pListPath {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:pListPath ofType:@"plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath]){
        NSDictionary *properties = [[NSDictionary alloc] initWithContentsOfFile:filePath];
        return properties;
    }
    return nil;
}

- (void)setPushToken:(NSString *)pushToken {
    self.localPushToken = pushToken;
    if (self.gear!= nil)
        [[IAHTicketSource instance] setPushToken:pushToken];
}

- (void)setUserSecret:(NSString *)userSecret {
    self.localUserSecret = userSecret;
    if (self.gear!= nil)
        [[IAHTicketSource instance] setUserSecret:userSecret];
}

- (void)setUserId:(NSString *)userId {
    self.localUserId = userId;
    if (self.gear!= nil)
        [[IAHTicketSource instance] setUserId:userId];
}

- (void)initWithCompanyName:(NSString*)company withAppId:(NSString*)appId withAppKey:(NSString*)appKey {
    NSAssert (company != nil, @"Company is null");
    NSAssert (appId != nil, @"AppId is null");
    NSAssert (appKey != nil, @"AppKey is null");

    self.appId = appId;
    self.appKey = appKey;
    self.company = company;
    self.gear = [[IAHInapphelpGear alloc] initWithCompanyName:company appId:appId appKey:appKey];
    
    if (self.localPushToken)
        [[IAHTicketSource instance] setPushToken:self.localPushToken];
    if (self.localUserSecret)
        [[IAHTicketSource instance] setUserSecret:self.localUserSecret];
    if (self.localUserId)
        [[IAHTicketSource instance] setUserId:self.localUserId];
}

- (NSString*) getCompanyName {
    return self.company;
}
/**
    start HelpStackController for given gear.
 */
- (void)showHelp:(UIViewController*)parentController {
    [self showHelp:parentController completion:nil];
}

- (void)showHelp:(UIViewController*)controller fromPush:(NSDictionary*)pushInfo{
    
}

- (void)showConversation:(UIViewController*)parentController {
    IAHIssueDetailViewController* issueDetailController;
    UIViewController* topAlmost = parentController;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIStoryboard* helpStoryboard = [UIStoryboard storyboardWithName:@"InapphelpStoryboard-iPad" bundle:[NSBundle mainBundle]];
        issueDetailController = [helpStoryboard instantiateViewControllerWithIdentifier:@"IAHIssueDetailViewController"];
        issueDetailController.ticketSource = [IAHTicketSource instance];
        [issueDetailController setModalPresentationStyle:UIModalPresentationFormSheet];
    } else {
        UIStoryboard* helpStoryboard = [UIStoryboard storyboardWithName:@"InapphelpStoryboard" bundle:[NSBundle mainBundle]];
        issueDetailController = [helpStoryboard instantiateViewControllerWithIdentifier:@"IAHIssueDetailViewController"];
        issueDetailController.ticketSource = [IAHTicketSource instance];
    }

    if ([topAlmost.restorationIdentifier isEqual:@"IAHNavigationController"]) {
        [((UINavigationController*) topAlmost) pushViewController:issueDetailController animated:YES];
    } else {
        issueDetailController.fromPush = true;
        [topAlmost presentViewController:issueDetailController animated:YES completion:nil];
    }
}

- (void)showConversationFromTimer:(NSTimer *)timer {
    UIViewController* viewContainer = (UIViewController* )[timer userInfo];
    [self showConversation:viewContainer];
}

- (void)handlePush:(NSDictionary*)pushInfo withViewController:(UIViewController*)viewController launchedFromPush:(bool)launched {
    if (self.gear == nil) {
        self.gear = [[IAHInapphelpGear alloc] initWithCompanyName:[pushInfo objectForKey:@"company"] appId:[pushInfo objectForKey:@"appid"] appKey:[pushInfo objectForKey:@"appkey"]];
    }
    [self setUserId:[pushInfo objectForKey:@"userid"]];
    [self setUserSecret:[pushInfo objectForKey:@"secretkey"]];
    
    if (self.conversationLaunched) {
        return;
    }
    
    if (launched) {
        [self showConversation:viewController];
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(showConversationFromTimer:)
                                       userInfo:viewController
                                        repeats:NO];

    } else {
        NSString* title = @"New message from support";
        NSString* alert = @"Tap to open dialog";
        
        SystemSoundID soundID = 0x450;
        AudioServicesPlaySystemSound(soundID);
        AudioServicesDisposeSystemSoundID(soundID);
        [JCNotificationCenter
         enqueueNotificationWithTitle:title
         message:alert
         tapHandler:^{
             NSLog(@"Received tap on notification banner!");
             [self showConversation:viewController];
         }];
    }
}

- (void)showHelp:(UIViewController*)parentController completion:(void (^)(void))completion {
    UIViewController* mainController;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIStoryboard* helpStoryboard = [UIStoryboard storyboardWithName:@"InapphelpStoryboard-iPad" bundle:[NSBundle mainBundle]];
        mainController = [helpStoryboard instantiateInitialViewController];
        [mainController setModalPresentationStyle:UIModalPresentationFormSheet];
        [parentController presentViewController:mainController animated:YES completion:completion];
    } else {
        UIStoryboard* helpStoryboard = [UIStoryboard storyboardWithName:@"InapphelpStoryboard" bundle:[NSBundle mainBundle]];
        mainController = [helpStoryboard instantiateInitialViewController];
        [parentController presentViewController:mainController animated:YES completion:completion];
    }
}


- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}
@end
