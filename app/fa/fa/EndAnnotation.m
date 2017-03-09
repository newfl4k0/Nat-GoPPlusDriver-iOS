//
//  EndAnnotation.m
//  fa
//
//  Created by Cristina Avila on 22/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "EndAnnotation.h"

@implementation EndAnnotation
- (id)initWithTitle:(NSString *)title Location:(CLLocationCoordinate2D)location {
    self = [super init];
    
    if (self) {
        self.title = title;
        self.coordinate = location;
    }
    
    return self;
}

- (MKAnnotationView *)annotationView {
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"EndAnnotation"];
    
    annotationView.enabled = YES;
    annotationView.image = [UIImage imageNamed:@"pinend"];
    annotationView.canShowCallout = YES;
    return annotationView;
}
@end
