//
//  AppDelegate.h
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MMDrawerController.h"
#import "AFNetworking.h"
#import "DataLibrary.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MMDrawerController *drawerController;
@property (strong, nonatomic) AFHTTPSessionManager *manager;
@property (strong, nonatomic) NSString *serverUrl;
@property (strong, nonatomic) NSString *payworksUrl;
@property (strong, nonatomic) DataLibrary *dataLibrary;
@property (strong, nonatomic) CLLocation *selfLocation;
@property (nonatomic) NSInteger currentStatus;
@property (nonatomic) NSInteger hasService;
@property (strong, nonatomic) NSString *deviceToken;
@property BOOL isAlertOpen;

- (void)initDrawerWindow;
- (void)initLoginWindow;
- (BOOL)noInternetConnection;
- (BOOL)noBattery;
- (void)showLocalNotification:(NSString *)message;
- (NSString *)getDeviceToken;
- (void)registerForRemoteNotifications;
- (void)playNotificationSound;
@end

