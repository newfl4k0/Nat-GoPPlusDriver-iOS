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

- (void)deleteKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

- (void)deleteAll {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

@end
