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

@interface NextTableViewCell : UITableViewCell<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIImageView *mapImage;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic) int serviceId;
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) UIAlertController *alertController;

- (void)initAppAndService:(AppDelegate *)app :(int)service_id;
- (void)createMapImage:(MKMapView *)map;
@end
