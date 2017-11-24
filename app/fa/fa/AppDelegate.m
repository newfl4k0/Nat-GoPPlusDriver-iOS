//
//  AppDelegate.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "AppDelegate.h"
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
    self.serverUrl = @"https://godriverqa.azurewebsites.net/";
    self.payworksUrl = @"https://gopspayqa.azurewebsites.net/";
    self.isAlertOpen = NO;

    [Fabric with:@[[Crashlytics class]]];
    [GMSServices provideAPIKey:@"AIzaSyD9eeKFw_dwCH5blRwv9k1U9lEBHrfPyZw"];
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
    
    self.drawerController = [[MMDrawerController alloc] initWithCenterViewController:centerNavigation
                                                            leftDrawerViewController:leftNavigation];
    
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
            //NSLog(@"registerForRemoteNotifications %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *strDevicetoken = [[NSString alloc]initWithFormat:@"%@", [[[deviceToken description]
                                                                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                                                        stringByReplacingOccurrencesOfString:@" "
                                                                        withString:@""]];
    
    if (strDevicetoken != nil) {
        [self.dataLibrary saveString:strDevicetoken :@"token"];
    } else {
        //NSLog(@"[didRegisterForRemoteNotificationsWithDeviceToken] strDeviceToken is null");
    }
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //NSLog(@"Push Notification Information : %@", userInfo);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //NSLog(@"%@ = %@", NSStringFromSelector(_cmd), error);
    //NSLog(@"Error = %@",error);
}

- (void)handleNotification:(NSDictionary *)notification {
    @try {
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
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self handleNotification: response.notification.request.content.userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self validaConexion];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    NSLog(@"quit value: %@", [self.dataLibrary getString:@"quit"]);
}


- (void)applicationWillTerminate:(UIApplication *)application {
    
    if (self.isAlertOpen) {
        [self.dataLibrary saveString:@"1" :@"quit"];
        NSLog(@"sancionar");
    }
 
}


- (void) validaConexion {
    if ([self.dataLibrary existsKey:@"connection_id"] == YES) {
        [self.manager GET:[self.serverUrl stringByAppendingString:@"connection-status"] parameters:@{ @"id": [NSNumber numberWithInteger:[self.dataLibrary getInteger:@"connection_id"]] } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
                if ([[[responseObject objectForKey:@"data"] objectForKey:@"abierto"] integerValue] == 0) {
                    
                    if (self.locationManager!=nil) {
                        [self.locationManager stopUpdatingLocation];
                        [self.locationManager stopUpdatingHeading];
                        self.locationManager = nil;
                    }
                    
                    [self.dataLibrary deleteAll];
                    [self initLoginWindow];
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"%@", error);
        }];
    }
}


@end
