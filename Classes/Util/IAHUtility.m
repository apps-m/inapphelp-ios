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

+ (NSMutableArray*)deviceInformation
{
    
    NSMutableArray* deviceInfo = [[NSMutableArray alloc] init];
    
    [deviceInfo addObject:@{@"k":@"Application id", @"v": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"], @"t":@"Application"}];
    [deviceInfo addObject:@{@"k":@"Application version", @"v": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"t":@"Application"}];
    
    [deviceInfo addObject:@{@"k":@"Device", @"v": [[UIDevice currentDevice] model], @"t":@"Device"}];
    [deviceInfo addObject:@{@"k":@"OS", @"v": [[UIDevice currentDevice] systemVersion], @"t":@"Device"}];
    [deviceInfo addObject:@{@"k":@"Language", @"v": [[NSLocale preferredLanguages] objectAtIndex:0], @"t":@"Device"}];
    [deviceInfo addObject:@{@"k":@"Free space", @"v": [self getFreeSpace], @"t":@"Device"}];

    return deviceInfo;
}

+ (NSString*) getFreeSpace {
    NSString* freeSpace = @"Unknown";
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
        
        int mb = (int)([fileSystemFreeSizeInBytes longLongValue]/(1024 * 1024));
        freeSpace  = [NSString stringWithFormat:@"%.02f GB", ((float) mb)/1024.f];
    } else {
        //Handle error
    }  
    return freeSpace;
}
@end
