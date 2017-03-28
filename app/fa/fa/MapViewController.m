//
//  MapViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ChatViewController.h"

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UILabel *clientLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UIButton *endServiceButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIView *ServiceView;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) StartAnnotation *startAnnotation;
@property (strong, nonatomic) EndAnnotation *endAnnotation;
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) NSDictionary *currentService;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic) NSInteger connection_id;
@property (nonatomic) NSInteger status;
@property (nonatomic) NSInteger newStatus;
@property (strong, nonatomic) NSTimer *timerMap;
@property (strong, nonatomic) NSTimer *timerService;
@property (nonatomic) BOOL isOnService;
@property (nonatomic) BOOL isNotified;
@property (nonatomic) BOOL needsConfirm;
@property (nonatomic) BOOL accepted;
@property (nonatomic) BOOL locationUpdated;
@property (nonatomic) int serviceStatus;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.map.delegate = self;
    self.app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.isOnService = NO;
    self.locationUpdated = NO;
    self.isNotified = NO;
    self.accepted = NO;
    self.needsConfirm = YES;
    self.connection_id = [self.app.dataLibrary getInteger:@"connection_id"];
    self.status = 0;
    self.newStatus = 1;
    [self changeStatus];
    [self initializeServiceData];
    [self initTimer];
    [self.statusButton setTitle:@"Cambiar a Ausente" forState:UIControlStateNormal];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setBackgroundColor:[UIColor blackColor]];
    self.spinner.center = CGPointMake(160, 240);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                            resizingMode:UIImageResizingModeStretch]
                             forBarMetrics:UIBarMetricsDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timerMap invalidate];
    [self.timerService invalidate];
    self.timerMap = nil;
    self.timerService = nil;
}

- (void)playSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound" ofType:@"mp3"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    AudioServicesPlaySystemSound(soundID);
}

- (void)initializeServiceData {
    NSDictionary *parameters = @{ @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]] };
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"service"] parameters:parameters progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      @try {
                          NSArray *responseArray = [responseObject objectForKey:@"data"];
            
                          if (responseArray.count>0) {
                              NSDictionary *response =  [responseArray objectAtIndex:0];
                
                              self.currentService = response;
                              self.serviceStatus = [[self.currentService objectForKey:@"estatus_reserva"] intValue];
                              [self.app.dataLibrary saveDictionary:response :@"service"];
                              [self.clientLabel setText:[response objectForKey:@"nombre_cliente"]];
                              [self.statusLabel setText:[response objectForKey:@"estatus_reserva_nombre"]];
                
                              NSString *dataReserva = [NSString stringWithString:[response objectForKey:@"origen"]];
                              dataReserva = [dataReserva stringByAppendingString:@"\n"];
                              dataReserva = [dataReserva stringByAppendingString:[response objectForKey:@"destino"]];
                              dataReserva = [dataReserva stringByAppendingString:@"\n"];
                              dataReserva = [dataReserva stringByAppendingString:[response objectForKey:@"observaciones"]];
                
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
                              [self.dataLabel setText:dataReserva];
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

- (void)initTimer {
    self.timerMap = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self updateMapWithLatestLocation];
    }];
    
    self.timerService = [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self initializeServiceData];
    }];
}

- (void)updateMapWithLatestLocation {
    if (self.isOnService) {
        NSDictionary *serviceLocation = [self.app.dataLibrary getDictionary:@"service"];
        
        if (serviceLocation != nil) {
            if (self.serviceStatus  == 4) {
                if (self.startAnnotation == nil) {
                    self.startAnnotation = [[StartAnnotation alloc] initWithTitle:[serviceLocation objectForKey:@"origen"]
                                                                         Location:CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_origen"] doubleValue], [[serviceLocation objectForKey:@"lng_origen"] doubleValue])];
                    
                    [self.map addAnnotation:self.startAnnotation];
                }
                
                if (self.endAnnotation != nil) {
                    [self.map removeAnnotation:self.endAnnotation];
                    self.endAnnotation = nil;
                }
                
                if (self.locationUpdated == NO) {
                    [self.map setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_origen"] doubleValue], [[serviceLocation objectForKey:@"lng_origen"] doubleValue]), MKCoordinateSpanMake(0.05, 0.05))];
                    self.locationUpdated = YES;
                }
            } else if (self.serviceStatus  == 5) {
                if (self.endAnnotation == nil) {
                    self.endAnnotation = [[EndAnnotation alloc] initWithTitle:[serviceLocation objectForKey:@"destino"]
                                                                     Location:CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_destino"] doubleValue], [[serviceLocation objectForKey:@"lng_destino"] doubleValue])];
                    
                    [self.map addAnnotation:self.endAnnotation];
                }
                
                if (self.startAnnotation != nil) {
                    [self.map removeAnnotation:self.startAnnotation];
                    self.startAnnotation = nil;
                }
                
                if (self.locationUpdated == NO) {
                    [self.map setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake([[serviceLocation objectForKey:@"lat_destino"] doubleValue], [[serviceLocation objectForKey:@"lng_destino"] doubleValue]), MKCoordinateSpanMake(0.05, 0.05))];
                    self.locationUpdated = YES;
                }
            }
        }
    } else {
        if (self.app.locationManager != nil) {
            CLLocation* location = [self.app.locationManager location];
            
            if (location!=nil && self.locationUpdated==NO) {
                [self.map setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), MKCoordinateSpanMake(0.05, 0.05))];
                self.locationUpdated = YES;
            }
        }
        
        if (self.startAnnotation != nil) {
            [self.map removeAnnotation:self.startAnnotation];
            self.startAnnotation = nil;
        }
        
        if (self.endAnnotation != nil) {
            [self.map removeAnnotation:self.endAnnotation];
            self.endAnnotation = nil;
        }
    }
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[StartAnnotation class]]) {
        StartAnnotation *customAnnotation = (StartAnnotation *)annotation;
        MKAnnotationView *customAnnotationView = [self.map dequeueReusableAnnotationViewWithIdentifier:@"StartAnnotation"];
        
        if (customAnnotationView == nil) {
            customAnnotationView = customAnnotation.annotationView;
        } else {
            customAnnotationView.annotation = annotation;
        }
        
        return customAnnotationView;
    } else if([annotation isKindOfClass:[EndAnnotation class]]) {
        EndAnnotation *customAnnotation = (EndAnnotation *)annotation;
        MKAnnotationView *customAnnotationView = [self.map dequeueReusableAnnotationViewWithIdentifier:@"EndAnnotation"];
        
        if (customAnnotationView == nil) {
            customAnnotationView = customAnnotation.annotationView;
        } else {
            customAnnotationView.annotation = annotation;
        }
        
        return customAnnotationView;
    } else {
        return nil;
    }
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
