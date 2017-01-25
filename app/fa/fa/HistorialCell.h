//
//  HistorialCell.h
//  fa
//
//  Created by Cristina Avila on 09/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface HistorialCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UIImageView *map;
@property (weak, nonatomic) IBOutlet UILabel *data;

- (void)createMapImage:(MKMapView *)map;
@end
