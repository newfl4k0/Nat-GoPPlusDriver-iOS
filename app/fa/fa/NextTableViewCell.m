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

- (void)initAppAndService:(AppDelegate *)app :(int)service_id :(float) lat_o :(float) lng_o :(float)lat_d :(float)lng_d {
    self.app = app;
    self.serviceId = service_id;
    self.lat_o = lat_o;
    self.lng_o = lng_o;
    self.lat_d = lat_d;
    self.lng_d = lng_d;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)doCancelService:(id)sender {
    if (self.serviceId != 0 && self.app != nil) {
        [self createTableAlert];
    }
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
                                  alertControllerWithTitle:@"Próximo Servicio"
                                  message:@"Mapa del servicio"
                                  preferredStyle:UIAlertControllerStyleAlert];
    [alertMap setValue:controller forKey:@"contentViewController"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }];
    [alertMap addAction:cancelAction];
    [self.app.drawerController.centerViewController presentViewController:alertMap animated:YES completion:nil];
}

- (void)createTableAlert {
    UIViewController *controller = [[UIViewController alloc]init];
    NSInteger rowsCount = [self.app.dataLibrary getArray:@"canceloptions"].count;
    CGRect rect;
    
    if (rowsCount < 4) {
        rect = CGRectMake(0, 0, 272, 100);
        [controller setPreferredContentSize:rect.size];
        
    } else if (rowsCount < 6){
        rect = CGRectMake(0, 0, 272, 150);
        [controller setPreferredContentSize:rect.size];
    } else if (rowsCount < 8){
        rect = CGRectMake(0, 0, 272, 200);
        [controller setPreferredContentSize:rect.size];
        
    } else {
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
    NSDictionary *dict = [[self.app.dataLibrary getArray:@"canceloptions"] objectAtIndex:indexPath.row];
    NSDictionary *parameters = @{
                                 @"idr": [NSNumber numberWithInteger:self.serviceId],
                                 @"idc": [NSNumber numberWithInteger:[dict[@"id"] integerValue]],
                                 @"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]
                                };
    
    [self dissmissAlert:self.alertController];
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-cancel"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([[responseObject objectForKey:@"data"] count]>0) {
                [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
            } else {
                [self.app.dataLibrary deleteKey:@"vc-services"];
            }
            
            [self triggerNotification];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self showAlert:@"Próximos Servicios" :@"Error al sincronizar servicios, vuelve a intentarlo."];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self showAlert:@"Próximos Servicios" :@"Error al rechazar servicio, vuelve a intentarlo."];
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
    alert = nil;
}

- (void)triggerNotification {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"eventReload"
     object:nil ];
}

@end
