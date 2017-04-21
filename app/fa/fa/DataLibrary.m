//
//  DataLibrary.m
//  fa
//
//  Created by Cristina Avila on 16/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "DataLibrary.h"

@implementation DataLibrary

- (void)saveInteger:(NSInteger)value :(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveString:(NSString *)value :(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDictionary:(NSDictionary *)value :(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveArray:(NSArray *)value :(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDouble:(double)value :(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDriverImage:(UIImage *) imageData {
    [[NSUserDefaults standardUserDefaults] setObject:UIImageJPEGRepresentation(imageData, 0.5) forKey:@"driverImage"];
}

- (BOOL)existsKey:(NSString *)key {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:key] == nil) {
        return NO;
    } else {
        return YES;
    }
}

- (NSInteger)getInteger:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

- (NSString *)getString:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

- (NSDictionary *)getDictionary:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
}

- (NSArray *)getArray:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:key];
}

- (double)getDouble:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:key];
}

- (void)deleteKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

- (void)deleteAll {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (NSInteger)getStatusIdForName:(NSString *)key {
    NSArray *statusArray = [self getArray:@"estatus"];
    NSInteger statusId = 0;
    
    for (NSDictionary *dict in statusArray) {
        if ([dict[@"nombre"] isEqualToString:key]) {
            statusId = [[dict valueForKey:@"id"] integerValue];
        }
    }
    
    return statusId;
}

- (UIImage *)getDriverImage {
    @try {
        return [UIImage imageWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"driverImage"]];
    } @catch (NSException *exception) {
        return [UIImage imageNamed:@"bglogintop"];
    }
}

@end
