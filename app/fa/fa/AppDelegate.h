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
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MMDrawerController *drawerController;
@property (strong, nonatomic) AFHTTPSessionManager *manager;
@property (strong, nonatomic) NSString *serverUrl;
@property (strong, nonatomic) DataLibrary *dataLibrary;
@property (strong, nonatomic) CLLocation *selfLocation;

- (void)initDrawerWindow;
- (void)initLoginWindow;
@end

