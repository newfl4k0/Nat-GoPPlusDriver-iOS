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
    self.serverUrl = @"http://godriver.azurewebsites.net/";
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
}

- (void)initLoginWindow {
    UIStoryboard *mainStoryBoard           = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *accessViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AccessViewController"];
    _window.rootViewController = accessViewController;
    [_window makeKeyAndVisible];
}

- (void)registerForRemoteNotifications {
    if (SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAlertStyleAlert | UNAuthorizationOptionBadge ) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!error) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
    } else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings
                                                                             settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                                                             categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *strDevicetoken = [[NSString alloc]initWithFormat:@"%@", [[[deviceToken description]
                                                                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                                                        stringByReplacingOccurrencesOfString:@" "
                                                                        withString:@""]];
    [self.dataLibrary saveString:strDevicetoken :@"token"];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Push Notification Information : %@", userInfo);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@ = %@", NSStringFromSelector(_cmd), error);
    NSLog(@"Error = %@",error);
}

// UNUserNotificationCenter Delegate // >= iOS 10
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"userNotificationCenter willPresentNotification Info 1 : %@", notification.request.content.userInfo);
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    
    //Here!!
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSLog(@"userNotificationCenter didReceiveNotificationResponse Info 2 : %@", response.notification.request.content.userInfo);
    completionHandler();
    //Maybe here too
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
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
