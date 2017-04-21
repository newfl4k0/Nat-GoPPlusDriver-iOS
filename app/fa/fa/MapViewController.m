//
//  MapViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet UILabel *clientLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UIButton *endServiceButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIView *ServiceView;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) NSDictionary *currentService;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic) NSInteger connection_id;
@property (nonatomic) NSInteger status;
@property (nonatomic) NSInteger newStatus;
@property (strong, nonatomic) NSTimer *timerMap;
@property (strong, nonatomic) NSTimer *timerService;
@property (strong, nonatomic) NSTimer *timerServicesAndVehicles;
@property (nonatomic) BOOL isOnService;
@property (nonatomic) BOOL isNotified;
@property (nonatomic) BOOL needsConfirm;
@property (nonatomic) BOOL accepted;
@property (nonatomic) BOOL shouldCleanMap;
@property (nonatomic) BOOL locationUpdated;
@property (nonatomic) int serviceStatus;
@property (weak, nonatomic) IBOutlet GMSMapView *gmap;
@property (strong, nonatomic) GMSMarker *startServiceMarker;
@property (strong, nonatomic) GMSMarker *endServiceMarker;
@property (weak, nonatomic) IBOutlet UILabel *driverStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *startAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *endAddressLabel;
@property (strong, nonatomic) NSMutableArray *gmsmarkerArray;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.isOnService = NO;
    self.locationUpdated = NO;
    self.isNotified = NO;
    self.accepted = NO;
    self.shouldCleanMap = YES;
    self.needsConfirm = YES;
    self.connection_id = [self.app.dataLibrary getInteger:@"connection_id"];
    self.status = 0;
    self.newStatus = 1;
    self.gmsmarkerArray = [[NSMutableArray alloc] init];
    [self changeStatus];
    [self initTimer];
    [self.statusButton setTitle:@"Cambiar a Ausente" forState:UIControlStateNormal];
    self.driverStatusLabel.text = @"Libre";
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setBackgroundColor:[UIColor blackColor]];
    self.spinner.center = CGPointMake(160, 240);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                            resizingMode:UIImageResizingModeStretch]
                             forBarMetrics:UIBarMetricsDefault];
    [self initGoogleMap];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timerMap invalidate];
    [self.timerService invalidate];
    self.timerMap = nil;
    self.timerService = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self setGoogleMapLatestLocation];
    [self initializeServiceData];
    
}

//Handle Timers
- (void)initTimer {
    self.timerMap = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self setGoogleMapLatestLocation];
    }];
    
    self.timerService = [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self initializeServiceData];
    }];
    
    self.timerServicesAndVehicles = [NSTimer scheduledTimerWithTimeInterval:30.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self getServicesAndVehicles];
    }];
}

- (void)initGoogleMap {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:0 longitude:0 zoom:17];
    self.gmap.camera = camera;
    self.gmap.myLocationEnabled = YES;
    self.gmap.settings.myLocationButton = YES;
    self.gmap.mapType = kGMSTypeNormal;
    self.gmap.padding = UIEdgeInsetsMake(0, 0, self.gmap.frame.size.height / 4, 0);
    
    [self getServicesAndVehicles];
}

- (void)setGoogleMapCenter:(CLLocation *)location {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude zoom:17];
    self.gmap.camera = camera;
}

- (void)removeStartServiceMarker {
    if (self.startServiceMarker != nil) {
        self.startServiceMarker.map = nil;
        self.startServiceMarker = nil;
    }
}

- (void)removeEndServiceMarker {
    if (self.endServiceMarker != nil) {
        self.endServiceMarker.map = nil;
        self.endServiceMarker = nil;
    }
}

- (void)setGoogleMapLatestLocation {
    if (self.app.locationManager != nil) {
        CLLocation* location = [self.app.locationManager location];

        if (location != nil && self.locationUpdated == NO) {
            [self setGoogleMapCenter:location];
            self.locationUpdated = YES;
        }
    }
    
    if (self.isOnService) {
        NSDictionary *serviceLocation = [self.app.dataLibrary getDictionary:@"service"];
        
        if (serviceLocation != nil) {
            if (self.serviceStatus == 4) {
                if (self.startServiceMarker == nil) {
                    self.startServiceMarker = [[GMSMarker alloc] init];
                    self.startServiceMarker.title = [serviceLocation objectForKey:@"origen"];
                    self.startServiceMarker.position = CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_origen"] doubleValue], [[serviceLocation objectForKey:@"lng_origen"] doubleValue]);
                    self.startServiceMarker.icon = [UIImage imageNamed:@"pinstart.png"];
                    self.startServiceMarker.map = self.gmap;
                }
            }
            
            if (self.serviceStatus == 5) {
                [self removeStartServiceMarker];
                
                if (self.endServiceMarker == nil) {
                    self.endServiceMarker = [[GMSMarker alloc] init];
                    self.endServiceMarker.title = [serviceLocation objectForKey:@"destino"];
                    self.endServiceMarker.position = CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_destino"] doubleValue], [[serviceLocation objectForKey:@"lng_destino"] doubleValue]);
                    self.endServiceMarker.icon = [UIImage imageNamed:@"pinend.png"];
                    self.endServiceMarker.map = self.gmap;
                }
            }
        } else {
            NSLog(@"Error. The app is on service and there's no service dictionary");
        }
    } else {
        [self removeStartServiceMarker];
        [self removeEndServiceMarker];
    }
}

- (void)playSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound" ofType:@"mp3"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    AudioServicesPlaySystemSound(soundID);
}

- (void)getServicesAndVehicles {
    if (self.currentService == nil && self.gmap!= nil) {
        [self clearServicesAndVehicles];
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"services"] parameters:@{ @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]] } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSDictionary *response = responseObject;
            
            if ([[response objectForKey:@"status"] boolValue] == YES) {
                self.shouldCleanMap = YES;
                NSArray *services = [response objectForKey:@"services"];
                NSArray *vehicles = [response objectForKey:@"vehicles"];
                
                for (NSDictionary *service in services) {
                    GMSMarker *marker = [[GMSMarker alloc] init];
                    marker.position = CLLocationCoordinate2DMake([[service objectForKey:@"Latitud_Origen"] doubleValue], [[service objectForKey:@"Longitud_Origen"] doubleValue]);
                    marker.icon = [UIImage imageNamed:@"dot.png"];
                    marker.map = self.gmap;
                    
                    [self.gmsmarkerArray addObject: marker];
                }
                
                for (NSDictionary *vehicle in vehicles) {
                    GMSMarker *marker = [[GMSMarker alloc] init];
                    marker.position = CLLocationCoordinate2DMake([[vehicle objectForKey:@"lat"] doubleValue], [[vehicle objectForKey:@"lng"] doubleValue]);
                    marker.icon = [UIImage imageNamed:@"car.png"];
                    marker.map = self.gmap;
                    
                    [self.gmsmarkerArray addObject: marker];
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self clearServicesAndVehicles];
        }];
    } else {
        [self clearServicesAndVehicles];
    }
}

- (void)clearServicesAndVehicles {
    if (self.shouldCleanMap == YES) {
        for (int x=0; x < [self.gmsmarkerArray count]; x++) {
            [[self.gmsmarkerArray objectAtIndex:x] setMap:nil];
        }
        
        [self.gmsmarkerArray removeAllObjects];
        self.shouldCleanMap = NO;
    }
}

- (void)initializeServiceData {
    NSDictionary *parameters = @{ @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]] };
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"service"] parameters:parameters progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      @try {
                          NSArray *responseArray = [responseObject objectForKey:@"data"];
            
                          if (responseArray.count>0) {
                              [self clearServicesAndVehicles];
                              NSDictionary *response =  [responseArray objectAtIndex:0];
                
                              self.currentService = response;
                              self.serviceStatus = [[self.currentService objectForKey:@"estatus_reserva"] intValue];
                              [self.app.dataLibrary saveDictionary:response :@"service"];
                              [self.clientLabel setText:[response objectForKey:@"nombre_cliente"]];
                
                              if (self.serviceStatus == 4) {
                                  self.chatButton.enabled = YES;
                                  [self.endServiceButton setTitle:[[response objectForKey:@"fecha_domicilio"] isEqualToString:@""] ? @"Avisar" : @"Ocupado" forState:UIControlStateNormal];
                                  self.newStatus = 3; //Asignado
                              } else if (self.serviceStatus == 5) {
                                  self.chatButton.enabled = NO;
                                  [self.endServiceButton setTitle: @"Finalizar" forState:UIControlStateNormal];
                                  self.newStatus = 11; //Ocupado
                              }
                
                              [self.app.dataLibrary saveInteger:[[response objectForKey:@"idd"] intValue] :@"despacho_id"];
                              //Set Address Labels
                              self.startAddressLabel.text = [response objectForKey:@"origen"];
                              self.endAddressLabel.text   = [response objectForKey:@"destino"];
                              self.dataLabel.text         = [response objectForKey:@"observaciones"];
                              
                              self.isOnService = YES;
                              self.ServiceView.hidden = NO;
                              self.statusButton.hidden = YES;
                              self.statusButton.enabled = NO;
                
                              if (self.isNotified == NO) {
                                  [self playSound];
                                  self.isNotified = YES;
                                  self.locationUpdated = NO;
                              }
                
                              if ([[response objectForKey:@"fecha_confirmacion"] isEqualToString:@""]) {
                                  if (self.needsConfirm) {
                                      [self showConfirmAlert];
                                      self.needsConfirm = NO;
                                  }
                              } else {
                                  self.accepted = YES;
                              }
                          } else {
                              self.currentService = nil;
                              self.isOnService = NO;
                              self.accepted = NO;
                              self.ServiceView.hidden = YES;
                              self.statusButton.enabled = YES;
                              self.statusButton.hidden = NO;
                              self.isNotified = NO;
                              self.needsConfirm = YES;
                              [self.app.dataLibrary deleteKey:@"despacho_id"];
                              [self.app.dataLibrary deleteKey:@"service"];
                              
                              if (self.status != 1 && self.status != 4) {
                                  self.locationUpdated = NO;
                                  self.newStatus = 1;
                              }
                          }
                          
                          [self changeStatus];
                      } @catch (NSException *exception) {
                          NSLog(@"exception: %@", exception);
                          [self.app.dataLibrary deleteKey:@"service"];
                          
                          if (self.status != 1 && self.status != 4) {
                              self.newStatus = 1;
                          }
                          
                          [self changeStatus];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"failure: %@", error);
                      [self.app.dataLibrary deleteKey:@"service"];
                      
                      if (self.status != 1 && self.status != 4) {
                          self.newStatus = 1;
                      }
                      
                      [self changeStatus];
                  }];
}

- (void)changeStatus {
    if (self.status != self.newStatus) {
        self.status = self.newStatus;
        [self forceEstatusUpdate];
    }
    
    if (self.status == 1) {
        self.driverStatusLabel.text = @"Libre";
    } else if (self.status == 4) {
        self.driverStatusLabel.text = @"Ausente";
    } else if (self.status == 3) {
        self.driverStatusLabel.text = @"Asignado";
    } else if (self.status == 11) {
        self.driverStatusLabel.text = @"Ocupado";
    }
    
    [self.app.dataLibrary saveInteger:self.status :@"status"];
}

- (void)forceEstatusUpdate {
    NSDictionary *parameters = @{@"connection": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]],
                                 @"lat": [NSNumber numberWithFloat:self.app.selfLocation.coordinate.latitude],
                                 @"lng": [NSNumber numberWithFloat:self.app.selfLocation.coordinate.longitude],
                                 @"status": [NSNumber numberWithInteger:self.status]};
    [self showSpinner];
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"location"] parameters:parameters progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       [self hideSpinner];
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       [self hideSpinner];
                   }];
    
    [self forceTrackUpdate];
}

- (void)forceTrackUpdate {
    NSMutableDictionary *parameters = [NSMutableDictionary
                                       dictionaryWithDictionary:@{
                                                                  @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]],
                                                                  @"af_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"affiliate_id"]],
                                                                  @"status_id": [NSNumber numberWithInteger:self.status],
                                                                  @"lat": [NSNumber numberWithFloat:self.app.selfLocation.coordinate.latitude],
                                                                  @"lng": [NSNumber numberWithFloat:self.app.selfLocation.coordinate.longitude]}];
    
    if (self.currentService != nil) {
        [parameters setObject:[NSNumber numberWithFloat:[self.currentService[@"lat_origen"] floatValue]] forKey:@"lat_o"];
        [parameters setObject:[NSNumber numberWithFloat:[self.currentService[@"lng_origen"] floatValue]] forKey:@"lng_o"];
        [parameters setObject:[NSNumber numberWithFloat:[self.currentService[@"lat_destino"] floatValue]] forKey:@"lat_d"];
        [parameters setObject:[NSNumber numberWithFloat:[self.currentService[@"lng_destino"] floatValue]] forKey:@"lng_d"];
    }
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"track"] parameters:parameters progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       NSLog(@"Error, track not saved: %@", error);
                   }];
}

- (void)showConfirmAlert {
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"GoPS"
                                                                          message:@"Confirmar el servicio"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Aceptar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self acceptService];
        [confirmAlert dismissViewControllerAnimated:true completion:nil];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Rechazar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cancelService];
        [confirmAlert dismissViewControllerAnimated:true completion:nil];
    }];
    
    [confirmAlert addAction:ok];
    [confirmAlert addAction:cancel];
    [self performSelector:@selector(automaticallyCancelService:) withObject:confirmAlert afterDelay:90.0];
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)cancelService {
    if (self.currentService != nil) {
        NSDictionary *parameters = @{
                                     @"r": [NSNumber numberWithInteger:[[self.currentService objectForKey:@"id"] intValue]],
                                     @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]],
                                     @"af_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"affiliate_id"]]};

        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"reject-service"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@", responseObject);
            self.accepted = YES;
            [self showAlert:@"Confirmar" :@"Servicio Rechazado"];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self showAlert:@"Confirmar" :@"Error. Intenta nuevamente"];
            NSLog(@"%@", error);
        }];
    }
}

- (void)acceptService {
    if (self.currentService != nil) {
        NSDictionary *parameters = @{@"d": [NSNumber numberWithInteger:[[self.currentService objectForKey:@"idd"] intValue]] };
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"confirm"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@", responseObject);
            self.accepted = YES;
            [self showAlert:@"Confirmar" :@"Servicio aceptado"];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self showAlert:@"Confirmar" :@"Error. Intenta nuevamente"];
            NSLog(@"%@", error);
        }];
    }
}

- (void)automaticallyCancelService:(UIAlertController *) alert{
    if (self.currentService != nil) {
        if (self.accepted == NO) {
            [self cancelService];
        }
    }
    
    [alert dismissViewControllerAnimated:true completion:nil];
}

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

- (IBAction)doToggleMenu:(id)sender {
    [self.app.drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)openChat:(id)sender {
}

- (IBAction)doEnd:(id)sender {
    NSDictionary *service = [self.app.dataLibrary getDictionary:@"service"];
    
    if (service != nil) {
        NSDictionary *parameters = @{
                                     @"idr": [service objectForKey:@"id"],
                                     @"idd": [service objectForKey:@"idd"]
                                    };
        
        if (self.serviceStatus == 4 &&  [[service objectForKey:@"fecha_domicilio"] isEqualToString:@""]) {
            [self showSpinner];
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-alert"] parameters:parameters progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self hideSpinner];
                               self.endServiceButton.titleLabel.text = @"Ocupado";
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               [self hideSpinner];
                               NSLog(@"%@", error);
                           }];
        } else if (self.serviceStatus == 4 && ![[service objectForKey:@"fecha_domicilio"] isEqualToString:@""]) {
            [self showSpinner];
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-occupy"] parameters:parameters progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self hideSpinner];
                               self.endServiceButton.titleLabel.text = @"Finalizar";
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               [self hideSpinner];
                               NSLog(@"%@", error);
                           }];
        } else if (self.serviceStatus == 5) {
            //Open
            
            UIAlertController *endAlert = [UIAlertController alertControllerWithTitle:@"Finalizar Servicio"
                                                                              message:@"Ingresa el monto y observaciones"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            
            [endAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.placeholder = @"Monto del viaje, Ej. 0.00";
                
                if ([service objectForKey:@"monto"]!=nil) {
                    textField.text = [[service objectForKey:@"monto"] stringValue];
                }
            }];
            
            [endAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.placeholder = @"Observaciones del viaje";
            }];
            
            UIAlertAction *sendEndAction = [UIAlertAction actionWithTitle:@"Finalizar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *price = endAlert.textFields[0].text;
                NSString *obs   = endAlert.textFields[1].text;
                
                if ([price isEqualToString:@""] || [obs isEqualToString:@""]) {
                    [self showAlert:@"Finalizar" :@"Ingresa monto y observaciones"];
                } else {
                    [self showSpinner];
                    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-end"]
                                parameters:@{@"idr": [service objectForKey:@"id"], @"idd": [service objectForKey:@"idd"], @"price": price, @"obs": obs} progress:nil
                                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                        [self hideSpinner];
                                       NSLog(@"%@", responseObject);
                                       self.newStatus = 1;
                                       [self changeStatus];
                                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                       [self hideSpinner];
                                       NSLog(@"%@", error);
                                   }];
                }
            }];
            
            UIAlertAction *cancelEndAction = [UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self dissmissAlert:endAlert];
            }];
            
            [endAlert addAction:sendEndAction];
            [endAlert addAction:cancelEndAction];
            [self presentViewController:endAlert animated:YES completion:nil];
        }
    }
}

- (IBAction)openMaps:(id)sender {
    if (self.app.locationManager != nil) {
        NSDictionary *service = [self.app.dataLibrary getDictionary:@"service"];
        
        if (service != nil) {
            CLLocation *location = [self.app.locationManager location];
            float lat = [[service objectForKey:@"lat_origen"] floatValue];
            float lng = [[service objectForKey:@"lng_origen"] floatValue];
            
            if (self.serviceStatus == 5) {
                lat = [[service objectForKey:@"lat_destino"] floatValue];
                lng = [[service objectForKey:@"lng_destino"] floatValue];
            }
            
            NSString *urlString = @"http://maps.google.com/maps?saddr=";
            urlString = [urlString stringByAppendingFormat:@"%f,%f&daddr=%f,%f",
                         location.coordinate.latitude, location.coordinate.longitude,lat, lng];
            
            NSURL *URL = [NSURL URLWithString:urlString];
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^(BOOL success) {
                NSLog(@"should open");
            }];
        }
    }
}

- (IBAction)doChangeStatus:(id)sender {
    if (self.status == 1) {
        [self.statusButton setTitle:@"Cambiar a Libre" forState:UIControlStateNormal];
        self.newStatus = 4;
    } else {
        [self.statusButton setTitle:@"Cambiar a Ausente" forState:UIControlStateNormal];
        self.newStatus = 1;
    }
    
    [self changeStatus];
}

//spinner - Methods
- (void)showSpinner {
    [self.spinner startAnimating];
}
- (void)hideSpinner {
    [self.spinner stopAnimating];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"segueChat"]) {
        if (self.currentService != nil) {
            if ([self.currentService objectForKey:@"idd"]!=nil && self.serviceStatus == 4) {
                return YES;
            }
        }
    }
    
    return NO;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueChat"]) {
        ((ChatViewController *)segue.destinationViewController).providesPresentationContextTransitionStyle = YES;
        ((ChatViewController *)segue.destinationViewController).definesPresentationContext = YES;
        ((ChatViewController *)segue.destinationViewController).modalPresentationStyle = UIModalPresentationOverFullScreen;
        ((ChatViewController *)segue.destinationViewController).did = [self.currentService objectForKey:@"idd"];
        ((ChatViewController *)segue.destinationViewController).isClient = YES;
    }
}

@end
