//
//  MapViewController.h
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@interface MapViewController : ViewController<CLLocationManagerDelegate>
@property (strong, nonatomic) NSString *demoString;
@property (strong, nonatomic) CLLocationManager *locationManager;
@end