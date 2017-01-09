//
//  DummyData.h
//  fa
//
//  Created by Cristina Avila on 04/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DummyData : NSObject

- (NSDictionary*)doLoginWithUser:(NSString*)user withPassword:(NSString*)password;
- (NSDictionary*)doLogoutWithSessionId:(NSInteger*)sessionId;

@end

