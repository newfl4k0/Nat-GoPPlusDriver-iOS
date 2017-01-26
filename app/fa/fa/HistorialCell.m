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

- (void)initWithCoords:(float)lat_o :(float)lng_o :(float)lat_d :(float)lng_d :(AppDelegate*)app{
    self.lat_o = lat_o;
    self.lng_o = lng_o;
    self.lat_d = lat_d;
    self.lng_d = lng_d;
    self.app   = app;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)doOpenMap:(id)sender {
    UIViewController *controller = [[UIViewController alloc]init];
    CGRect rect = CGRectMake(0, 0, 272, 250);
    [controller setPreferredContentSize:rect.size];
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:rect];
    StartAnnotation *annotationOrigin = [[StartAnnotation alloc] initWithTitle:self.startLabel.text Location:CLLocationCoordinate2DMake(self.lat_o, self.lng_o)];
    EndAnnotation *annotationDestiny = [[EndAnnotation alloc] initWithTitle:self.endLabel.text Location:CLLocationCoordinate2DMake(self.lat_d, self.lng_d)];
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta  = 0.05;
    span.longitudeDelta = 0.05;
    
    CLLocationCoordinate2D location =  CLLocationCoordinate2DMake(21.119894, -101.674890);
    
    region.span   = span;
    region.center = location;
    
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    [mapView addAnnotation:annotationOrigin];
    [mapView addAnnotation:annotationDestiny];
    
    [controller.view addSubview:mapView];
    [controller.view bringSubviewToFront:mapView];
    [controller.view setUserInteractionEnabled:YES];
    UIAlertController *alertMap = [UIAlertController
                                   alertControllerWithTitle:@"Historial"
                                   message:@"Mapa del servicio"
                                   preferredStyle:UIAlertControllerStyleAlert];
    [alertMap setValue:controller forKey:@"contentViewController"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }];
    [alertMap addAction:cancelAction];
    [self.app.drawerController.centerViewController presentViewController:alertMap animated:YES completion:nil];
}

@end
