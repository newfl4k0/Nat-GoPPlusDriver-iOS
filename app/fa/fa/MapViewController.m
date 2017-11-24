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
@property (strong, nonatomic) NSMutableDictionary *endServiceEmail;
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
@property (strong, nonatomic) GMSMarker *geofenceMarker;
@property (strong, nonatomic) GMSCircle *circ;
@property (weak, nonatomic) IBOutlet UILabel *driverStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *startAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *endAddressLabel;
@property (strong, nonatomic) NSMutableArray *gmsmarkerArray;
@property (weak, nonatomic) IBOutlet UIWebView *webController;
@property (strong, nonatomic) NSString *lastStoredLocation;
@property (strong, nonatomic) NSNumberFormatter *fmt;
@property double trueHeading;

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
    self.status = [self.app.dataLibrary getInteger:@"status"];
    self.newStatus = [self.app.dataLibrary getInteger:@"status"];
    self.gmsmarkerArray = [[NSMutableArray alloc] init];
    [self changeStatus];
    [self initTimer];
    
    self.fmt = [[NSNumberFormatter alloc] init];
    [self.fmt setPositiveFormat:@"0.##"];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setBackgroundColor:[UIColor blackColor]];
    self.spinner.center = CGPointMake(160, 240);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self initGoogleMap];
    
    if (self.status == 1) {
        [self.statusButton setTitle:@"Cambiar a Ausente" forState:UIControlStateNormal];
        self.driverStatusLabel.text = @"Libre";
    } else {
        [self.statusButton setTitle:@"Cambiar a Libre" forState:UIControlStateNormal];
        self.driverStatusLabel.text = @"Ausente";
    }
    
    self.webController.delegate = self;
    self.app.isAlertOpen = YES;
}


- (NSDictionary*)decodeURL:(NSString*)urlString {
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [urlString componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key           = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value         = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [queryStringDictionary setObject:value forKey:key];
    }
    
    return queryStringDictionary;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *currentUrl = request.URL.absoluteString;
    
    if ([currentUrl rangeOfString:[self.app.payworksUrl stringByAppendingString:@"postauth-service-end"] options:NSRegularExpressionSearch].location != NSNotFound) {
        NSDictionary *params = [self decodeURL:currentUrl];
        
        if ([[params objectForKey:@"RESULTADO_PAYW"] isEqualToString:@"A"]) {
            [self sendServiceEmail];
            [self.view sendSubviewToBack:self.webController];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                self.newStatus = 1;
                [self.statusButton setTitle:@"Cambiar a Ausente" forState:UIControlStateNormal];
                [self changeStatus];
                [self hideSpinner];
                self.endServiceButton.enabled = YES;
            });
            
        } else {
            [self showAlert:@"Error en el pago" : [[params objectForKey:@"TEXTO"] stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
            [self hideSpinner];
            [self.view sendSubviewToBack:self.webController];
            self.endServiceButton.enabled = YES;
        }
    }
    
    return YES;
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

- (void)initTimeriOS9 {
    [self setGoogleMapLatestLocation];
    [self initializeServiceData];
    [self getServicesAndVehicles];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self initTimeriOS9];
    });
}

//Handle Timers
- (void)initTimer {
    if ([[[UIDevice currentDevice] systemVersion] intValue] >= 10) {
        self.timerMap = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self setGoogleMapLatestLocation];
        }];
        
        self.timerService = [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self initializeServiceData];
        }];
        
        self.timerServicesAndVehicles = [NSTimer scheduledTimerWithTimeInterval:30.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self getServicesAndVehicles];
        }];
    } else {
        [self initTimeriOS9];
    }
}

- (void)initGoogleMap {
    self.gmap.delegate = self;
    self.gmap.camera = [GMSCameraPosition cameraWithLatitude:0 longitude:0 zoom:18];
    self.gmap.myLocationEnabled = YES;
    self.gmap.settings.myLocationButton = YES;
    self.gmap.mapType = kGMSTypeNormal;
    self.gmap.padding = UIEdgeInsetsMake(0, 0, self.gmap.frame.size.height / 2.2, 0);
}

- (void)setGoogleMapCenter:(CLLocation *)location {
    self.gmap.camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude zoom:17];
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
        
        if (location != nil) {
            NSNumber *lat = [NSNumber numberWithFloat:self.app.selfLocation.coordinate.latitude];
            NSNumber *lng = [NSNumber numberWithFloat:self.app.selfLocation.coordinate.longitude];
            
            if (self.lastStoredLocation != nil) {
                NSArray *lastLatLng = [self.lastStoredLocation componentsSeparatedByString:@","];
                double currentDistance = [self.app.selfLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[lastLatLng objectAtIndex:0] doubleValue] longitude:[[lastLatLng objectAtIndex:1] doubleValue]]];
                
                if (currentDistance > 20) {
                    self.lastStoredLocation = [[[lat stringValue] stringByAppendingString:@","] stringByAppendingString:[lng stringValue]];
                    [self setGoogleMapCenter:location];
                }
            } else {
                self.lastStoredLocation = [[[lat stringValue] stringByAppendingString:@","] stringByAppendingString:[lng stringValue]];
                [self setGoogleMapCenter:location];
                [self getServicesAndVehicles];
            }
        }
    }
    
    if (self.isOnService) {
        NSDictionary *serviceLocation = [self.app.dataLibrary getDictionary:@"service"];
        NSData *imageStart = UIImagePNGRepresentation([UIImage imageNamed:@"pinstart.png"]);
        NSData *imageEnd = UIImagePNGRepresentation([UIImage imageNamed:@"pinend.png"]);
        
        if (serviceLocation != nil) {
            if (self.serviceStatus == 4) {
                if (self.startServiceMarker == nil) {
                    self.startServiceMarker = [[GMSMarker alloc] init];
                    self.startServiceMarker.title = [serviceLocation objectForKey:@"origen"];
                    self.startServiceMarker.position = CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_origen"] doubleValue], [[serviceLocation objectForKey:@"lng_origen"] doubleValue]);
                    self.startServiceMarker.icon = [UIImage imageWithData:imageStart scale:3];
                    
                    self.startServiceMarker.map = self.gmap;
                }
            }
            
            if (self.serviceStatus == 5) {
                [self removeStartServiceMarker];
                
                if (self.endServiceMarker == nil) {
                    self.endServiceMarker = [[GMSMarker alloc] init];
                    self.endServiceMarker.title = [serviceLocation objectForKey:@"destino"];
                    self.endServiceMarker.position = CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_destino"] doubleValue], [[serviceLocation objectForKey:@"lng_destino"] doubleValue]);
                    self.endServiceMarker.icon = [UIImage imageWithData:imageEnd scale:3];
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
        //[self clearServicesAndVehicles];
        self.geofenceMarker.title = @"Espere un momento";
        [self drawGeofence];
        
        if (self.circ != nil) {
            NSDictionary *params = @{
                                     @"lat": [NSNumber numberWithFloat:self.circ.position.latitude],
                                     @"lng": [NSNumber numberWithFloat:self.circ.position.longitude],
                                     @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]]
                                     };
            
            
            [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"services"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *response = responseObject;
                
                if ([[response objectForKey:@"status"] boolValue] == YES) {
                    NSString *totalValue = @"";
                    
                    for (NSDictionary *total in [response objectForKey:@"data"]) {
                        totalValue = [totalValue stringByAppendingString: [total objectForKey:@"total"]];
                        totalValue = [totalValue stringByAppendingString:@" "];
                    }
                    
                    self.geofenceMarker.title = totalValue;
                    
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                //[self clearServicesAndVehicles];
            }];

        }
    } else {
        //[self clearServicesAndVehicles];
        [self removeGeofence];
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
                              self.app.hasService = 1;
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
                              
                              [self removeGeofence];
                          } else {
                              self.app.hasService = 0;
                              
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
                          [self trackService];
                      } @catch (NSException *exception) {
                          NSLog(@"exception: %@", exception);
                          
                          self.app.hasService = 0;
                          
                          [self.app.dataLibrary deleteKey:@"service"];
                          
                          if (self.status != 1 && self.status != 4) {
                              self.newStatus = 1;
                          }
                          
                          [self changeStatus];
                          [self trackService];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"failure: %@", error);
                      self.app.hasService = 0;
                      [self.app.dataLibrary deleteKey:@"service"];
                      
                      if (self.status != 1 && self.status != 4) {
                          self.newStatus = 1;
                      }
                      
                      [self changeStatus];
                      [self trackService];
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
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self acceptService];
        [confirmAlert dismissViewControllerAnimated:true completion:nil];
        self.app.isAlertOpen = NO;
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Rechazar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self cancelService];
        [confirmAlert dismissViewControllerAnimated:true completion:nil];
        self.app.isAlertOpen = NO;
    }];
    
    [confirmAlert addAction:ok];
    [confirmAlert addAction:cancel];
    
    [self performSelector:@selector(automaticallyCancelService:) withObject:confirmAlert afterDelay:90.0];
    [self presentViewController:confirmAlert animated:YES completion:nil];
    
    self.app.isAlertOpen = YES;
}

- (void)cancelService {
    
    if (self.currentService != nil) {
        NSDictionary *parameters = @{
                                     @"r_id": [NSNumber numberWithInteger:[[self.currentService objectForKey:@"id"] intValue]],
                                     @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]]};

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
            [self trackService];
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
            
            self.endServiceEmail = [self endServiceData];
            NSDictionary *params = @{@"id": [self.endServiceEmail objectForKey:@"id"]};
            
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"validate-code"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

                NSDictionary *data = [responseObject objectForKey:@"data"];
                
                if ([[data objectForKey:@"status"] boolValue] == YES) {
                    double creditos_cl = [[data objectForKey:@"creditos_cliente"] doubleValue];
                    double descuento   = [[data objectForKey:@"descuento_codigo"] doubleValue];
                    double abono_us    = [[data objectForKey:@"nuevo_abono_usuario"] doubleValue];
                    double n_total     = [[self.endServiceEmail objectForKey:@"total_viaje"] doubleValue] - (descuento + creditos_cl);
                    int id_us          = [[data objectForKey:@"id_usuario"] intValue];
                    NSString *codigo   = [data objectForKey:@"motivo_descuento"];
                    
                    
                    if (n_total < 0) {
                        n_total = 0;
                    }
                    
                    if (id_us > 0 && abono_us > 0) {
                        [self.endServiceEmail setObject:[NSNumber numberWithDouble:abono_us] forKey:@"n_cred_usr"];
                        [self.endServiceEmail setObject:[NSNumber numberWithInt:id_us] forKey:@"id_cred_usr"];
                    }
                    
                    [self.endServiceEmail setObject:codigo forKey:@"codigo"];
                    [self.endServiceEmail setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:descuento]] forKey:@"codigo_monto"];
                    [self.endServiceEmail setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:creditos_cl]] forKey:@"creditos"];
                    [self.endServiceEmail setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:n_total]] forKey:@"total"];

                } else {
                    //Normal, no descuento
                    [self.endServiceEmail setObject:[self.endServiceEmail objectForKey:@"total_viaje"] forKey:@"total"];
                }
                
                //Open
                UIAlertController *endAlert = [UIAlertController alertControllerWithTitle:@"Finalizar Servicio" message:@"Ingresa el monto y observaciones" preferredStyle:UIAlertControllerStyleAlert];
                
                [endAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.keyboardType = UIKeyboardTypeDecimalPad;
                    //textField.enabled = NO;
                    textField.text = [self.fmt stringFromNumber:[NSNumber numberWithDouble:[[self.endServiceEmail objectForKey:@"total"] doubleValue]]];
                }];
                 
                [endAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.keyboardType = UIKeyboardTypeDefault;
                    textField.placeholder = @"Observaciones del viaje";
                }];
                 
                UIAlertAction *sendEndAction = [UIAlertAction actionWithTitle:@"Finalizar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *price = endAlert.textFields[0].text;
                    NSString *obs   = endAlert.textFields[1].text;
                  
                    [self.endServiceEmail setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:[price doubleValue]]] forKey:@"total"];
                    
                    //update
                    
                    if ([price isEqualToString:@""]) {
                        [self showAlert:@"Finalizar" :@"Ingresa el monto del servicio"];
                    } else if (![self isTextValid:obs]) {
                        [self showAlert:@"Finalizar" :@"Ingresa las observaciones del viaje. Solo se permiten números, letras, espacios y los siguientes caracteres especiales ,.:?¡¿!"];
                    } else {
                        [self showSpinner];
                        
                        self.endServiceButton.enabled = NO;
                        
                        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"send-obs"] parameters:@{@"id": [service objectForKey:@"id"], @"obs": obs } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

                            NSString *url = [[[[[[self.app.payworksUrl stringByAppendingString:@"postauth-service-start"] stringByAppendingString:@"?id="] stringByAppendingString:[[service objectForKey:@"id"] stringValue]] stringByAppendingString:@"&monto="] stringByAppendingString:price] stringByAppendingString:@"&act=END"];

                            NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: url] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 60000];
                            
                            [self.webController loadRequest: request];
                            [self.view bringSubviewToFront:self.webController];

                        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                            [self showAlert:@"Finalizar" :@"Error. Comentario no enviado"];
                        }];
                    }
                }];
                
                UIAlertAction *cancelEndAction = [UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                     [self dissmissAlert:endAlert];
                }];
                
                [endAlert addAction:sendEndAction];
                [endAlert addAction:cancelEndAction];
                [self presentViewController:endAlert animated:YES completion:nil];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self showAlert:@"Finalizar" :@"Error. Intenta nuevamente"];
            }];
        }
    }
}

- (BOOL)isTextValid:(NSString *) textToValidate {
    NSString *pattern = @"([A-Z\u00E0-\u00FC]*[A-Za-z0-9 .,:?!¿¡])";
    NSError  *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [regex matchesInString:textToValidate options:0 range: NSMakeRange(0, [textToValidate length])];
    
    return [matches count] > 0;
}

- (void)sendServiceEmail {
    if (self.endServiceEmail != nil) {
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"service-email"]
                                         parameters:self.endServiceEmail progress:nil
                                            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                                 [self hideSpinner];
                                                self.newStatus = 1;
                                                [self changeStatus];
                                            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                [self hideSpinner];
                                                NSLog(@"%@", error);
                                            }];
        self.endServiceEmail = nil;
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

//Save locally the service
- (void)trackService {
    if (self.isOnService && [[self.currentService objectForKey:@"estatus_reserva"] intValue] == 5) {
        NSArray *trackLocation = [NSArray alloc];
        NSNumber *lat = [NSNumber numberWithDouble:self.app.selfLocation.coordinate.latitude];
        NSNumber *lng = [NSNumber numberWithDouble:self.app.selfLocation.coordinate.longitude];
        self.trueHeading = [self.app.locationManager.heading trueHeading];
        double last_heading = [self.app.dataLibrary getDouble:@"heading"];
        double diff_heading = 0;
        
        if (last_heading != self.trueHeading) {
            diff_heading = last_heading - self.trueHeading;
            
            if (diff_heading < 0) {
                diff_heading = diff_heading * -1;
            }
            
            if (diff_heading > 15) {
                [self.app.dataLibrary saveDouble:self.trueHeading :@"heading"];
            }
        }
        
        
        NSString *currentLocation = [[[lat stringValue] stringByAppendingString:@","] stringByAppendingString:[lng stringValue]];
        double distance = 0;
        double minMts = 50;
        
        if (self.app.selfLocation != nil && lat > 0 && lng >0) {
            if ([self.app.dataLibrary existsKey:@"track"]) {
                NSArray *currentTrackLocation = [[self.app.dataLibrary getDictionary:@"track"] objectForKey:@"location"];
                NSMutableArray *trackServiceLocation = [[NSMutableArray alloc] initWithArray:currentTrackLocation];
                NSString *lastLocation = [currentTrackLocation objectAtIndex:[currentTrackLocation count] - 1];
                NSArray *lastLatLng = [lastLocation componentsSeparatedByString:@","];
                
                double currentDistance = [self.app.selfLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[lastLatLng objectAtIndex:0] doubleValue] longitude:[[lastLatLng objectAtIndex:1] doubleValue]]];
                
                distance = [[[self.app.dataLibrary getDictionary:@"track"] objectForKey:@"distance"] doubleValue];
                
                //if (![currentLocation isEqualToString:lastLocation] && currentDistance > minMts ) {
                
                if (![currentLocation isEqualToString:lastLocation] && currentDistance > minMts ) {
                    [trackServiceLocation addObject:currentLocation];
                    distance = distance + currentDistance;
                }
                
                trackLocation = trackServiceLocation;
            } else {
                trackLocation = [[NSArray alloc] initWithObjects:currentLocation, nil];
            }
            
            NSDictionary *trackService = @{ @"id": [self.currentService objectForKey:@"idd"], @"location": trackLocation, @"distance": [NSNumber numberWithDouble: distance] };
            [self.app.dataLibrary saveDictionary:trackService :@"track"];
        }
    } else {
        [self.app.dataLibrary deleteKey:@"track"];
    }
}

- (NSString*) setPrice {
    NSDictionary *fare = [self.app.dataLibrary getDictionary:@"fare"];
    NSDictionary *track = [self.app.dataLibrary getDictionary:@"track"];

    double distance = [[track objectForKey:@"distance"] doubleValue];
    double totalTime = [[self.currentService objectForKey:@"minutos"] doubleValue];
    
    double fareTime = totalTime * ([[fare objectForKey:@"minuto"] doubleValue]);
    double fareDistance = (distance / 1000) * ([[fare objectForKey:@"km"] doubleValue]);
    double fareStart = [[fare objectForKey:@"base"] doubleValue];
    double fareMin = [[fare objectForKey:@"minimo"] doubleValue];
    
    double fareTotal = fareStart + fareDistance + fareTime;
    
    if (fareTotal < fareMin) {
        fareTotal = fareMin;
    }
    
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.##"];
    
    return [fmt stringFromNumber:[NSNumber numberWithFloat:fareTotal]];
}

- (NSMutableDictionary *) endServiceData {
    NSDictionary *fare  = [self.app.dataLibrary getDictionary:@"fare"];
    NSDictionary *track = [self.app.dataLibrary getDictionary:@"track"];
    NSArray *locations = [track objectForKey:@"location"];
    
    
    double distance = [[track objectForKey:@"distance"] doubleValue];
    double totalTime = [[self.currentService objectForKey:@"minutos"] doubleValue];
    
    double fareTime = totalTime * ([[fare objectForKey:@"minuto"] doubleValue]);
    double fareDistance = (distance / 1000) * ([[fare objectForKey:@"km"] doubleValue]);
    double fareStart = [[fare objectForKey:@"base"] doubleValue];
    double fareMin = [[fare objectForKey:@"minimo"] doubleValue];
    
    double fareTotal = fareStart + fareDistance + fareTime;
    
    if (fareTotal < fareMin) {
        fareTotal = fareMin;
    }
    
    NSString *cleanLocations = [[locations componentsJoinedByString:@"|"] stringByReplacingOccurrencesOfString:@"0,0|" withString:@""];
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    
    [fmt setPositiveFormat:@"0.##"];
    
    NSMutableDictionary *end = [NSMutableDictionary new];
    
    [end setObject:[NSNumber numberWithInt:[[self.currentService objectForKey:@"id"] intValue]] forKey:@"id"];
    [end setObject:[self.app.dataLibrary getString:@"driver_fullname"] forKey:@"chofer"];
    [end setObject:[self.currentService objectForKey:@"usuario_id"] forKey:@"usuario_id"];
    [end setObject:[NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]] forKey:@"chofer_id"];
    [end setObject:[self.currentService objectForKey:@"origen"] forKey:@"origen"];
    [end setObject:[self.currentService objectForKey:@"destino"] forKey:@"destino"];
    [end setObject:[NSNumber numberWithDouble:[[self.currentService objectForKey:@"lat_origen"] doubleValue]] forKey:@"lat_o"];
    [end setObject:[NSNumber numberWithDouble:[[self.currentService objectForKey:@"lng_origen"] doubleValue]] forKey:@"lng_o"];
    [end setObject:[NSNumber numberWithDouble:[[self.currentService objectForKey:@"lat_destino"] doubleValue]] forKey:@"lat_d"];
    [end setObject:[NSNumber numberWithDouble:[[self.currentService objectForKey:@"lng_destino"] doubleValue]] forKey:@"lng_d"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithInt:[[fare objectForKey:@"base"] intValue]]] forKey:@"precio_base"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithInt:[[fare objectForKey:@"minimo"] intValue]]] forKey:@"precio_minimo"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:fareDistance]] forKey:@"precio_km"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:fareTime]] forKey:@"precio_minuto"];
    [end setObject:cleanLocations forKey:@"path"];
    [end setObject:[NSNumber numberWithDouble:totalTime] forKey:@"tiempo"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithDouble:(distance / 1000)]] forKey:@"km"];
    [end setObject:[self.fmt stringFromNumber:[NSNumber numberWithFloat:fareTotal]] forKey:@"total_viaje"];
    
    return end;
}


//Geofence

- (void) drawGeofence {
    if (self.circ == nil) {
        self.circ = [[GMSCircle alloc] init];
        self.circ.position = [self.gmap.camera target];
        self.circ.radius = 1000;
        self.circ.fillColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
        self.circ.strokeColor = [UIColor redColor];
        self.circ.strokeWidth = 1;
        self.circ.map = self.gmap;
        
        self.geofenceMarker = [[GMSMarker alloc] init];
        self.geofenceMarker.title = @"Espere un momento";
        self.geofenceMarker.position = self.circ.position;
        self.geofenceMarker.map = self.gmap;
        self.gmap.selectedMarker = self.geofenceMarker;
    } else {
        self.circ.position = [self.gmap.camera target];
        self.geofenceMarker.position = self.circ.position;
    }
}

- (void) removeGeofence {
    if (self.circ != nil) {
        self.circ.map = nil;
        self.geofenceMarker.map = nil;
        self.circ = nil;
        self.geofenceMarker = nil;
    }
}

- (void) mapView:(GMSMapView *) mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self.circ != nil) {
        self.circ.position = coordinate;
        self.geofenceMarker.position = self.circ.position;
        self.geofenceMarker.title = @"Espere un momento";
        self.gmap.selectedMarker = self.geofenceMarker;
    }
}


@end
