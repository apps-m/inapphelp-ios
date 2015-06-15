#import "IAHUtility.h"
#import <UIKit/UIKit.h>

@implementation IAHUtility

+ (Boolean) isValidEmail: (NSString*) email {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:
                                  @"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
                                                                           options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray* matchesInString = [regex matchesInString:email options:0 range:NSMakeRange(0, [email length])];
    if([matchesInString count]==1)
        return true;
    else
        return false;
}

+ (NSString*)stringFortimeSinceDateFull:(NSDate*)date
{
    NSString* timeString;
    NSTimeInterval secondsSinceUpdate = fabs([date timeIntervalSinceNow]);
    if (secondsSinceUpdate < 60) {
        int seconds = fabs(round(secondsSinceUpdate));
        NSString* str = (seconds == 1)? @"sec":@"secs";
        timeString = [NSString stringWithFormat:@"%d %@", seconds,str];
        
    }else if (secondsSinceUpdate > 60 && secondsSinceUpdate < 3600){
        int minutes = fabs(round(secondsSinceUpdate/60.0));
        NSString* str = (minutes == 1)? @"min":@"mins";
        timeString = [NSString stringWithFormat:@"%d %@", minutes,str];
        
    }else if (secondsSinceUpdate > 3600 && secondsSinceUpdate < 86400){
        int hours = fabs(round(secondsSinceUpdate/3600.0));
        NSString* str = (hours == 1)? @"hour":@"hours";
        timeString = [NSString stringWithFormat:@"%d %@", hours,str];
        
    }else{
        int days = fabs(floor(secondsSinceUpdate/86400.0));
        NSString* str = (days == 1)? @"day":@"days";
        timeString = [NSString stringWithFormat:@"%d %@", days,str];
    }
    
    return timeString;
}

+ (NSString*)deviceInformation
{
    NSString* deviceModel = [[UIDevice currentDevice] model];
    NSString* osVersion = [[UIDevice currentDevice] systemVersion];
    NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString* bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSString* deviceInformation = [NSString stringWithFormat:@"Device:%@,iOS:%@,App information:%@,Version:%@", deviceModel, osVersion, bundleName, bundleVersion];
    
    return deviceInformation;
}
@end
