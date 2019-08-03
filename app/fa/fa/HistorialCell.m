//
//  HistorialCell.m
//  fa
//
//  Created by Cristina Avila on 09/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "HistorialCell.h"

@implementation HistorialCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setMapImage:(NSString *)mapUrl{
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSData *imageremote = [NSData dataWithContentsOfURL:[NSURL URLWithString:[mapUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.mapView setImage:[UIImage imageWithData:imageremote]];
        });
    });
    
}

@end
