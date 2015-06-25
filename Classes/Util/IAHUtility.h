#import <Foundation/Foundation.h>

@interface IAHUtility : NSObject

+ (Boolean) isValidEmail: (NSString*) email;

+ (NSString*) stringFortimeSinceDateFull: (NSDate*) date;

+ (NSMutableDictionary*) deviceInformation;

@end
