//
//  MapViewController.h
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ChatViewController.h"
@import GoogleMaps;

@interface MapViewController : ViewController <UIWebViewDelegate>
@property (strong, nonatomic) NSString *demoString;
@end
