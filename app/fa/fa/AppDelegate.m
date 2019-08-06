//
//  AppDelegate.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "AppDelegate.h"
#import "Reachability.h"
#import "LeftViewController.h"
#import <AudioToolbox/AudioToolbox.h>
@import GoogleMaps;

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.dataLibrary = [[DataLibrary alloc] init];
    self.manager = [AFHTTPSessionManager manager];
    self.currentStatus = 0;
    self.hasService = 0;
    self.serverUrl = @"https://godriver.azurewebsites.net/";
    self.payworksUrl = @"https://gopspay.azurewebsites.net/";
    self.isAlertOpen = NO;

    [GMSServices provideAPIKey:@"AIzaSyAaxU4-c1ifle2YqKr6NHGQLoPncjq7fWY"];
    //Push notifications
    [self registerForRemoteNotifications];
    return YES;
}

- (void)initDrawerWindow {
    UIStoryboard *mainStoryBoard             = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *leftViewController     = [mainStoryBoard instantiateViewControllerWithIdentifier:@"LeftViewController"];
    UIViewController *centerViewController   = [mainStoryBoard instantiateViewControllerWithIdentifier:@"CenterViewController"];
    UINavigationController *leftNavigation   = [[UINavigationController alloc] initWithRootViewController:leftViewController];
    UINavigationController *centerNavigation = [[UINavigationController alloc] initWithRootViewController:centerViewController];
    
    self.drawerController = [[MMDrawerController alloc] initWithCenterViewController:centerNavigation leftDrawerViewController:leftNavigation];
    self.drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningCenterView;
    self.drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModePanningCenterView;
    
    _window.rootViewController = self.drawerController;
    [_window makeKeyAndVisible];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)initLoginWindow {
    UIStoryboard *mainStoryBoard           = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *accessViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AccessViewController"];
    _window.rootViewController = accessViewController;
    [_window makeKeyAndVisible];
}

// UNUserNotificationCenter Delegate // >= iOS 10
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    //NSLog(@"userNotificationCenter");
    
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self handleNotification:notification.request.content.userInfo];
}

- (void)registerForRemoteNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAlertStyleAlert | UNAuthorizationOptionBadge ) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }];
        } else {
            NSLog(@"registerForRemoteNotifications %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *strDevicetoken = [[NSString alloc]initWithFormat:@"%@", [[[deviceToken description]
                                                                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                                                        stringByReplacingOccurrencesOfString:@" "
                                                                        withString:@""]];
    
    if (strDevicetoken != nil) {
        self.deviceToken = strDevicetoken;
        [self.dataLibrary saveString:strDevicetoken :@"token"];
    }
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification : %@", userInfo);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)handleNotification:(NSDictionary *)notification {
    @try {
        [self playNotificationSound];
        
        if ([notification objectForKey:@"id"] != nil) {
            NSString *id_notif = [notification objectForKey:@"id"];
            
            if ([id_notif isEqualToString:@"close-connection"]) {
                if (self.locationManager!=nil) {
                    [self.locationManager stopUpdatingLocation];
                    [self.locationManager stopUpdatingHeading];
                    self.locationManager = nil;
                }
                
                [self.dataLibrary deleteAll];
                [self initLoginWindow];
            } else if ([id_notif isEqualToString:@"new-service"] || [id_notif isEqualToString:@"service-cancel"]) {
                NSString *controllerName =  NSStringFromClass([[self.drawerController centerViewController] class]);
                
                if ([controllerName isEqualToString:@"MapViewController"] == NO) {
                    [self.drawerController setCenterViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MapViewController"]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeStatsDetails" object:nil userInfo:@{}];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeUpperViews" object:nil userInfo:@{}];
                    });
                }
            }
        }
    } @catch (NSException *exception) {
        //NSLog(@"Error: %@", exception);
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self handleNotification: response.notification.request.content.userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeView" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self showLocalNotification: @"Gopplus está por terminar su tiempo de vida. Entra a la aplicación para extenderlo."];
}

- (BOOL)noInternetConnection {
    return [[Reachability reachabilityForInternetConnection]currentReachabilityStatus] == NotReachable;
}

- (BOOL)noBattery {
    UIDevice *device = [UIDevice currentDevice];
    [device setBatteryMonitoringEnabled:YES];
    
    return ((float)[device batteryLevel] * 100) < 5;
}

- (void)showLocalNotification:(NSString *)message {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = message;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = 0;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (NSString *)getDeviceToken {
    NSString *send_token = @"";
    
    if ([self.dataLibrary existsKey:@"token"]) {
        send_token = [self.dataLibrary getString:@"token"];
    } else if (self.deviceToken!= nil && [self.deviceToken isEqualToString:@""] == NO) {
        send_token = self.deviceToken;
    }
    
    return send_token;
}

- (void)playNotificationSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound" ofType:@"mp3"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    AudioServicesPlaySystemSound(soundID);
}

@end
