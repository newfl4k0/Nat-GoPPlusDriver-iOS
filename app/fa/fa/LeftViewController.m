//
//  LeftViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//
#import "AFNetworking.h"
#import "LeftViewController.h"


@interface LeftViewController ()
@property (weak, nonatomic) AppDelegate *app;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (strong, nonatomic) NSDate *currentDate;
@property (strong, nonatomic) NSDate *trackDate;
@property (strong, nonatomic) NSDate *connectionDate;
@property (strong, nonatomic) NSDate *locationUpdate;
@property (strong, nonatomic) NSDate *serviceUpdate;
@property (strong, nonatomic) NSNumber *id_connection;
@property int id_last_service;
@property (nonatomic) BOOL firstUpdate;
@property (weak, nonatomic) IBOutlet UIImageView *imageDriver;
@property double trueHeading;
@end

@implementation LeftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.firstUpdate = NO;
    self.trueHeading = -1;
    self.id_last_service = 0;
    
    self.id_connection = [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]];
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        self.currentDate    = [NSDate date];
        self.connectionDate = [NSDate date];
        
        [self initializeLocationManager];
        [self lastLocationUpdate];
        
        self.welcomeLabel.text = [NSString stringWithFormat:@"Bienvenido\n%@ %@", [self.app.dataLibrary getString:@"driver_name"], [self.app.dataLibrary getString:@"driver_surname"]];
        [self.app.drawerController setCenterViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"]];
        
        [self getImage];
        [self syncStatus];
        [self syncCancelOptions];
        [self syncServices];
        [self syncVehicleData];
        [self syncConfiguration];
        [self updateToken];
        [self detectLocationStatus];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDriverData:) name:@"driverData" object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

/**
 * Window Manager
 **/

- (void) updateCenterView:(NSString*)newCenterWindowName {
    [self.app.drawerController setCenterViewController:[self.storyboard instantiateViewControllerWithIdentifier:newCenterWindowName]];
    [self.app.drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)doOpenMapView:(id)sender {
    [self updateCenterView:@"MapViewController"];
}

- (IBAction)doOpenNextView:(id)sender {
    [self updateCenterView:@"NextViewController"];
}

- (IBAction)doOpenHistoricView:(id)sender {
    [self updateCenterView:@"HistoricViewController"];
}

- (IBAction)doOpenChatView:(id)sender {
    [self updateCenterView:@"ChatViewController"];
}

- (IBAction)doOpenSettingsView:(id)sender {
    [self updateCenterView:@"SettingsViewController"];
}

/**
 * Timers
 **/

- (void)initializeLocationManager {
    if (self.app.locationManager == nil) {
        self.app.locationManager = [[CLLocationManager alloc] init];
        self.app.locationManager.delegate = self;
        self.app.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.app.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        [self.app.locationManager setAllowsBackgroundLocationUpdates:YES];
        
        if ([self.app.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.app.locationManager requestAlwaysAuthorization];
        }
        
        [self.app.locationManager startUpdatingLocation];
        [self.app.locationManager startUpdatingHeading];
        
    } else {
        [self.app.locationManager setAllowsBackgroundLocationUpdates:YES];
        
        if ([self.app.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.app.locationManager requestAlwaysAuthorization];
        }
        
        [self.app.locationManager startUpdatingLocation];
        [self.app.locationManager startUpdatingHeading];
    }
}

- (void)detectLocationStatus {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [self showAlert:@"GoPPlus" :@"Para evitar una desconexión permite el acceso a la ubicación"];
    } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways){
       [self showAlert:@"GoPPlus" :@"Es preferible permitir el acceso a ubicación siempre"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = [NSDate date];
    self.app.selfLocation = location;
    self.locationUpdate = eventDate;
    
    if (self.firstUpdate == NO) {
        self.firstUpdate = YES;
        [self sendLocation:location];
        [self sendTrack:location];
    }
    
    if ([eventDate timeIntervalSince1970] - [self.currentDate timeIntervalSince1970] > 300.0) {
        //NSLog(@"sendLocation");
        self.currentDate = [NSDate date];
        [self sendLocation:location];
        [self updateToken];
    }
    
    if (self.trackDate == nil || ([eventDate timeIntervalSince1970] - [self.trackDate timeIntervalSince1970] > 15.0)) {
        //NSLog(@"sendTrack");
        self.trackDate = [NSDate date];
        [self sendTrack:location];
    }
    
    if ([eventDate timeIntervalSince1970] - [self.connectionDate timeIntervalSince1970] > 60.0) {
        //NSLog(@"verifyConnection");
        self.connectionDate = [NSDate date];
        [self verifyConnection];
    }
    
    if (self.serviceUpdate == nil || ([eventDate timeIntervalSince1970] - [self.serviceUpdate timeIntervalSince1970] > 5.0)) {
        self.serviceUpdate = [NSDate date];
        [self getService];
    }
}

- (void)getService {
    if ([self.app noInternetConnection]) {
        [self showAlert:@"GoPPlus" :@"No tienes acceso a internet"];
    }
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"service"] parameters:@{ @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]] } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *data = [responseObject objectForKey:@"data"];
        
        if (data.count > 0) {
            int current_id_service = [[[data objectAtIndex:0] objectForKey:@"idd"] intValue];
            
            if (self.id_last_service != current_id_service) {
                NSString *controllerName = NSStringFromClass([[self.app.drawerController centerViewController] class]);
                
                if ([controllerName isEqualToString:@"MapViewController"] == NO) {
                    [self.app.drawerController setCenterViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MapViewController"]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeStatsDetails" object:nil userInfo:@{}];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeUpperViews" object:nil userInfo:@{}];
                    });
                }
                
                [self.app showLocalNotification:@"Tienes un nuevo servicio asignado. Para aceptar ó rechazar entra a la ventana del mapa. Si ya aceptaste el servcio ignora esta alerta."];
            }
            
            self.id_last_service = current_id_service;
        } else {
            self.id_last_service = 0;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"serviceDataNotification" object:nil userInfo:@{@"service": data}];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error %@", error);
    }];
    
}

- (void)sendTrack:(CLLocation* )location {
    NSDictionary *currentService = [self.app.dataLibrary getDictionary:@"service"];
    NSMutableDictionary *parameters = [NSMutableDictionary
                                       dictionaryWithDictionary:@{
                                                                  @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]],
                                                                  @"af_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"affiliate_id"]],
                                                                  @"status_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"status"]],
                                                                  @"lat": [NSNumber numberWithFloat:location.coordinate.latitude],
                                                                  @"lng": [NSNumber numberWithFloat:location.coordinate.longitude]}];
    
    if (currentService != nil) {
        [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lat_origen"] floatValue]] forKey:@"lat_o"];
        [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lng_origen"] floatValue]] forKey:@"lng_o"];
        [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lat_destino"] floatValue]] forKey:@"lat_d"];
        [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lng_destino"] floatValue]] forKey:@"lng_d"];
    }
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"track"] parameters:parameters progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       NSLog(@"Error, track not saved: %@", error);
                   }];
}

- (void)sendLocation:(CLLocation *)location {
    NSDictionary *parameters = @{@"connection": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]],
                                 @"lat": [NSNumber numberWithFloat:location.coordinate.latitude],
                                 @"lng": [NSNumber numberWithFloat:location.coordinate.longitude],
                                 @"status": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"status"]]};
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"location"] parameters:parameters progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       NSLog(@"Error, location not saved: %@", error);
                   }];
}

- (void)verifyConnection {
    NSNumber *id_connection = [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]];
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"connection-status"] parameters:@{ @"id": id_connection } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
            if ([[[responseObject objectForKey:@"data"] objectForKey:@"abierto"] integerValue] == 0) {
                
                if (self.app.locationManager!=nil) {
                    [self.app.locationManager stopUpdatingLocation];
                    [self.app.locationManager stopUpdatingHeading];
                    self.app.locationManager = nil;
                }
                
                [self.app.dataLibrary deleteAll];
                [self.app initLoginWindow];
                [self.app showLocalNotification:@"Se ha detectado el cierre de tu sesión de forma remota"];
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error connection-status %@", error);
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self initializeLocationManager];
}

- (void)lastLocationUpdate {
    if (self.app.locationManager!=nil) {
        
        if ([self.locationUpdate timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970] > 30.0) {
            [self initializeLocationManager];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self lastLocationUpdate];
        });
    }
}

/**
 * Mostrar Alerta
 **/
- (void)showAlert:(NSString *)title :(NSString *)message {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

/**
 * Sync Data
 **/

- (void) getImage {
    @try {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[[self.app.serverUrl stringByAppendingString:@"images/?id="] stringByAppendingString:[self.app.dataLibrary getString:@"driver_id"]] stringByAppendingString:@".jpg"]]];
        
        [self.imageDriver setImage:[UIImage imageWithData:data]];
        self.imageDriver.layer.cornerRadius = self.imageDriver.frame.size.width / 2;
        self.imageDriver.clipsToBounds = YES;
        [self.app.dataLibrary saveDriverImage:[UIImage imageWithData:data]];
    } @catch (NSException *exception) {
        NSLog(@"[getImage] exception: %@", exception);
        self.imageDriver.image = [UIImage imageNamed:@"avatar.png"];
        [self.app.dataLibrary saveDriverImage:[UIImage imageNamed:@"avatar.png"]];
    }
}

- (void)setDriverData: (NSNotification *) notification {
    [self.imageDriver setImage:[self.app.dataLibrary getDriverImage]];
    self.welcomeLabel.text = [NSString stringWithFormat:@"Bienvenido\n%@ %@", [self.app.dataLibrary getString:@"driver_name"], [self.app.dataLibrary getString:@"driver_surname"]];
}

- (void)syncStatus {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"status"] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"estatus"];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[syncStatus] %@", error);
    }];
}

- (void)syncCancelOptions {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"cancel"] parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"canceloptions"];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[syncCancelOptions] %@", error);
    }];
}

- (void)syncServices {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count]>0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"vc-services"];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"[syncServices] %@", error);
                  }];
}

- (void)syncVehicleData {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"getVehicleInfo"] parameters:@{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_id"]]  } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
            [self.app.dataLibrary saveDictionary:[responseObject objectForKey:@"data"] : @"vehicleData"];
        } else {
            NSLog(@"[getVehicleInfo] error: %@", responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[getVehicleInfo] %@", error);
    }];
}

- (void)syncConfiguration {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"sync"] parameters:@{} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count] > 0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"settings"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"settings"];
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
}

- (void)updateToken {
    NSString *token = [self.app getDeviceToken];
    
    if ((token != nil) && [token isEqualToString:@""]== NO) {
        NSDictionary *parameters = @{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]], @"token": token };
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"set-token"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error: token not updated: %@", error);
        }];
    } else {
        [self.app playNotificationSound];
        [self showAlert:@"GoPPlus" :@"Verifica los permisos para recibir Notificaciones. Las notificaciones son indispensables para el correcto funcionamiento de la aplicación"];
    }
}


@end
