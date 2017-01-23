//
//  EndAnnotation.h
//  fa
//
//  Created by Cristina Avila on 22/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@interface EndAnnotation : NSObject<MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;

- (id)initWithTitle:(NSString *)title Location:(CLLocationCoordinate2D)location;
- (MKAnnotationView *)annotationView;
@end
