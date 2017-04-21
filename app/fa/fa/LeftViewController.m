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
@property (nonatomic) BOOL firstUpdate;
@property (weak, nonatomic) IBOutlet UIImageView *imageDriver;
@end

@implementation LeftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.firstUpdate = NO;
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        self.currentDate = [NSDate date];
        self.trackDate   = [NSDate date];
        [self initializeLocationManager];
        
        self.welcomeLabel.text = [NSString stringWithFormat:@"Bienvenido\n%@", [self.app.dataLibrary getString:@"driver_fullname"]];
        [self.app.drawerController setCenterViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"]];
        
        [self getImage];
        [self updateToken];
        
        [self syncStatus];
        [self syncCancelOptions];
        [self syncServices];
        [self syncVehicleData];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)updateToken {
    NSString *token = [self.app.dataLibrary getString:@"token"];
    
    if (token != nil) {
        NSDictionary *parameters = @{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                      @"token": token };
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"set-token"] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error: token not updated: %@", error);
        }];
    } else {
        NSLog(@"token is null");
    }
}

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

- (void)initializeLocationManager {
    if (self.app.locationManager == nil) {
        self.app.locationManager = [[CLLocationManager alloc] init];
        self.app.locationManager.delegate = self;
        self.app.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.app.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        [self.app.locationManager setAllowsBackgroundLocationUpdates:YES];
        
        if ([self.app.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.app.locationManager requestAlwaysAuthorization];
        }
        
        [self.app.locationManager startUpdatingLocation];
    } else {
        [self.app.locationManager setAllowsBackgroundLocationUpdates:YES];
        
        if ([self.app.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.app.locationManager requestAlwaysAuthorization];
        }
        
        [self.app.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = [NSDate date];
    self.app.selfLocation = location;
    
    if (self.firstUpdate == NO) {
        self.firstUpdate = YES;
        [self sendLocation:location];
        [self sendTrack:location];
    }
    
    if ([eventDate timeIntervalSince1970] - [self.currentDate timeIntervalSince1970] > 300.0) {
        self.currentDate = [NSDate date];
        [self sendLocation:location];
    }
    

    if ([eventDate timeIntervalSince1970] - [self.trackDate timeIntervalSince1970] > 10.0) {
        self.trackDate = [NSDate date];
        [self sendTrack:location];
    }
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


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager didFailWithError %@", error);
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self initializeLocationManager];
    }];
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

@end
