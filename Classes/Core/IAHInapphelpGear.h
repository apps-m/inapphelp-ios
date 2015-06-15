//
//  INInapphelpGear.h
//  Pods
//
//  Created by MniLL on 18.05.15.
//
//

#import <Foundation/Foundation.h>
#import "IAHGear.h"

@interface IAHInapphelpGear : IAHGear

@property (nonatomic, strong) NSString *api_key;
@property (nonatomic, strong) NSString *auth_code;
@property (nonatomic, strong) NSString *instanceUrl;
@property (nonatomic, strong) NSDictionary *articleSections;
@property (nonatomic, strong) NSString *hfPriorityID;
@property (nonatomic, strong) NSString *hfCategoryID;

- (id)initWithCompanyName:(NSString *)company appId:(NSString *)app_id appKey:(NSString *)app_key;

@end
