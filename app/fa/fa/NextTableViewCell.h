//
//  NextTableViewCell.h
//  fa
//
//  Created by Cristina Avila on 03/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AppDelegate.h"
#import "StartAnnotation.h"
#import "EndAnnotation.h"

@interface NextTableViewCell : UITableViewCell<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic) int serviceId;
@property (nonatomic) float lat_o;
@property (nonatomic) float lng_o;
@property (nonatomic) float lat_d;
@property (nonatomic) float lng_d;
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) UIAlertController *alertController;

- (void)initAppAndService:(AppDelegate *)app :(int)service_id :(float) lat_o :(float) lng_o :(float)lat_d :(float)lng_d;
@end
