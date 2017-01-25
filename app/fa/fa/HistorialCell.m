//
//  HistorialCell.m
//  fa
//
//  Created by Cristina Avila on 09/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "HistorialCell.h"
#import "StartAnnotation.h"
#import "EndAnnotation.h"

@implementation HistorialCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)createMapImage:(MKMapView *)map {
    //Create image from map
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = map.region;
    options.scale = [UIScreen mainScreen].scale;
    options.size = map.frame.size;
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionHandler:^(MKMapSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        UIImage *image = snapshot.image;
        CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
        pin.image = [UIImage imageNamed:@"pinstart"];
        UIImage *pinImage = pin.image;
        
        [image drawAtPoint:CGPointMake(0, 0)];
        
        for (id<MKAnnotation>annotation in map.annotations) {
            @try {
                if ([annotation isKindOfClass:[StartAnnotation class]]) {
                    pinImage = [UIImage imageNamed:@"pinstart"];
                } else if ([annotation isKindOfClass:[EndAnnotation class]]) {
                    pinImage = [UIImage imageNamed:@"pinend"];
                }
                
                CGPoint point = [snapshot pointForCoordinate:annotation.coordinate];
                
                if (CGRectContainsPoint(finalImageRect, point)) {
                    CGPoint pinCenterOffset = pin.centerOffset;
                    point.x -= pin.bounds.size.width / 2.0;
                    point.y -= pin.bounds.size.height / 2.0;
                    point.x += pinCenterOffset.x;
                    point.y += pinCenterOffset.y;
                    
                    [pinImage drawAtPoint:point];
                }
            }@catch(NSException *exception) {
                NSLog(@"%@", exception);
            }
        }
        
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self.map setImage:finalImage];
    }];
}

@end
