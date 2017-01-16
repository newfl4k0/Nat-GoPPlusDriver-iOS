//
//  DataLibrary.h
//  fa
//
//  Created by Cristina Avila on 16/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataLibrary : NSObject
- (BOOL)existsKey:(NSString *)key;
- (void)saveInteger:(NSInteger)value :(NSString *)key;
- (void)saveString:(NSString *)value :(NSString *)key;
- (void)saveDictionary:(NSDictionary *)value :(NSString *)key;
- (NSInteger)getInteger:(NSString *)stringForKey;
- (NSString *)getString:(NSString *)stringForKey;
- (NSDictionary *)getDictionary:(NSString *)stringForKey;
- (void)deleteKey:(NSString *)key;
- (void)deleteAll;
@end
