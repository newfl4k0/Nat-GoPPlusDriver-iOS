//
//  HistorialCell.h
//  fa
//
//  Created by Cristina Avila on 09/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "StartAnnotation.h"
#import "EndAnnotation.h"
#import "AppDelegate.h"

@interface HistorialCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *clientLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mapView;

- (void)setMapImage:(NSString *)mapUrl;
@end
