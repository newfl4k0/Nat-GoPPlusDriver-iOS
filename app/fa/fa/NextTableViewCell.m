//
//  NextTableViewCell.m
//  fa
//
//  Created by Cristina Avila on 03/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "NextTableViewCell.h"
#import "StartAnnotation.h"
#import "EndAnnotation.h"
#import "NextViewController.h"


@implementation NextTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)initAppAndService:(AppDelegate *)app :(int)service_id {
    self.app = app;
    self.serviceId = service_id;
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
        
        [self.mapImage setImage:finalImage];
    }];
}

- (IBAction)doCancelService:(id)sender {
    if (self.serviceId != 0 && self.app != nil) {
        [self createTableAlert];
    }
}

- (void)createTableAlert {
    UIViewController *controller = [[UIViewController alloc]init];
    NSInteger rowsCount = [self.app.dataLibrary getArray:@"canceloptions"].count;
    CGRect rect;
    
    if (rowsCount < 4) {
        rect = CGRectMake(0, 0, 272, 100);
        [controller setPreferredContentSize:rect.size];
        
    }
    else if (rowsCount < 6){
        rect = CGRectMake(0, 0, 272, 150);
        [controller setPreferredContentSize:rect.size];
    }
    else if (rowsCount < 8){
        rect = CGRectMake(0, 0, 272, 200);
        [controller setPreferredContentSize:rect.size];
        
    }
    else {
        rect = CGRectMake(0, 0, 272, 250);
        [controller setPreferredContentSize:rect.size];
    }
    
    UITableView *alertTableView  = [[UITableView alloc]initWithFrame:rect];
    alertTableView.delegate = self;
    alertTableView.dataSource = self;
    alertTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    [alertTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [controller.view addSubview:alertTableView];
    [controller.view bringSubviewToFront:alertTableView];
    [controller.view setUserInteractionEnabled:YES];
    [alertTableView setUserInteractionEnabled:YES];
    [alertTableView setAllowsSelection:YES];
    self.alertController = [UIAlertController
                                          alertControllerWithTitle:@"Cancelar Servicio"
                                          message:@"Selecciona una opción"
                                          preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController setValue:controller forKey:@"contentViewController"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Regresar" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
    }];
    [self.alertController addAction:cancelAction];
    [self.app.drawerController.centerViewController presentViewController:self.alertController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = [self.app.dataLibrary getArray:@"canceloptions"];
    NSDictionary *dict = [array objectAtIndex:indexPath.row];
    NSDictionary *parameters = @{@"reserva_id": [NSNumber numberWithInteger:self.serviceId],
                                 @"razon_id": [NSNumber numberWithInteger:[dict[@"id"] integerValue]]
                                };
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-cancel"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self dissmissAlert:self.alertController];
        
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"]
                   parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]}
                   progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          if ([[responseObject objectForKey:@"data"] count]>0) {
                              [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                          } else {
                              [self.app.dataLibrary deleteKey:@"vc-services"];
                          }
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          
                      }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self showAlert:@"Cancelar Servicio" :@"Servicio no cancelado, intenta nuevamente"];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    NSArray *array = [self.app.dataLibrary getArray:@"canceloptions"];
    NSDictionary *dict = [array objectAtIndex:indexPath.row];
    
    @try {
        cell.textLabel.text = dict[@"razon"];
    } @catch (NSException *exception) {
        cell.textLabel.text = @"";
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  [self.app.dataLibrary getArray:@"canceloptions"].count;
}

- (void)showAlert:(NSString *)title :(NSString *)message {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self.app.drawerController.centerViewController presentViewController:errorAlert animated:YES completion:nil];
}

- (void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

@end
