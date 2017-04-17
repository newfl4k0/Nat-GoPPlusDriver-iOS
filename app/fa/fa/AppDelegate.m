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
    self.serverUrl = @"http://192.168.15.44:8000/"; //@"http://godriver.azurewebsites.net/";
    [Fabric with:@[[Crashlytics class]]];
    [GMSServices provideAPIKey:@"AIzaSyBFtapySRpYnSA8LC6HqsQWgtDIFeuWzto"];
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

- (void)registerForRemoteNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAlertStyleAlert | UNAuthorizationOptionBadge ) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
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
        NSLog(@"[didRegisterForRemoteNotificationsWithDeviceToken] strDeviceToken is null");
    }
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //(NSLog(@"Push Notification Information : %@", userInfo);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@ = %@", NSStringFromSelector(_cmd), error);
    NSLog(@"Error = %@",error);
}

- (void)handleNotification:(NSDictionary *)notification {
    @try {
        if ([notification objectForKey:@"id"] != nil) {
            NSString *id_notif = [notification objectForKey:@"id"];
            
            if ([id_notif isEqualToString:@"close-connection"]) {
                if (self.locationManager!=nil) {
                    [self.locationManager stopUpdatingLocation];
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

// UNUserNotificationCenter Delegate // >= iOS 10
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self handleNotification:notification.request.content.userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
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
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
