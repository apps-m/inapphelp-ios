#import <Foundation/Foundation.h>

@interface IAHUtility : NSObject

+ (Boolean) isValidEmail: (NSString*) email;

+ (NSString*) stringFortimeSinceDateFull: (NSDate*) date;

+ (NSString*) deviceInformation;

@end
