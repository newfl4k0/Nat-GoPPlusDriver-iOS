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

- (NSInteger)getInteger:(NSString *)stringForKey {
    NSInteger savedValue = [[NSUserDefaults standardUserDefaults] integerForKey:stringForKey];
    
    return savedValue;
}

- (NSString *)getString:(NSString *)stringForKey {
    NSString *savedValue = [[NSUserDefaults standardUserDefaults] stringForKey:stringForKey];
    
    return savedValue;
}

- (NSDictionary *)getDictionary:(NSString *)stringForKey {
    NSDictionary *savedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:stringForKey];
    return savedDictionary;
}

- (void)deleteKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

- (void)deleteAll {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

@end
