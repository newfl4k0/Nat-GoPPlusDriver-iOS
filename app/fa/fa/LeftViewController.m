//
//  LeftViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "LeftViewController.h"


@interface LeftViewController ()
@property (weak, nonatomic) AppDelegate *app;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (strong, nonatomic) NSDate *currentDate;
@property (strong, nonatomic) NSDate *trackDate;
@end

@implementation LeftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        self.currentDate = [NSDate date];
        self.trackDate   = [NSDate date];
        [self initializeLocationManager];
        [self getVehicleDriverServices];
    }
    
    self.welcomeLabel.text = [NSString stringWithFormat:@"Bienvenido, %@", [self.app.dataLibrary getString:@"driver_name"]];
    [self.app.drawerController setCenterViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"]];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
        //NSLog(@"Initialize locationManager");
        self.app.locationManager = [[CLLocationManager alloc] init];
        self.app.locationManager.delegate = self;
        self.app.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.app.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        [self.app.locationManager setAllowsBackgroundLocationUpdates:YES];
        
        if ([self.app.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.app.locationManager requestAlwaysAuthorization];
        }
        
        [self.app.locationManager startUpdatingLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations{
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = [NSDate date];
    
    if ([eventDate timeIntervalSince1970] - [self.currentDate timeIntervalSince1970] > 60.0) {
        self.currentDate = [NSDate date];
        NSDictionary *parameters = @{@"connection": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]],
                                     @"lat": [NSNumber numberWithFloat:location.coordinate.latitude],
                                     @"lng": [NSNumber numberWithFloat:location.coordinate.longitude],
                                     @"status": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"status"]]};
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"location"] parameters:parameters progress:nil
                       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                           //NSLog(@"Location Saved!");
                       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                           NSLog(@"Error, not saved");
                       }];
    }
    
    if ([eventDate timeIntervalSince1970] - [self.trackDate timeIntervalSince1970] > 15.0) {
        self.trackDate = [NSDate date];
        
        NSDictionary *currentService = [self.app.dataLibrary getDictionary:@"service"];
        NSMutableDictionary *parameters = [NSMutableDictionary
                                           dictionaryWithDictionary:@{
                                                                      @"vc_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_driver_id"]],
                                                                      @"af_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"affiliate_id"]],
                                                                      @"status_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"status"]],
                                                                      @"lat": [NSNumber numberWithFloat:location.coordinate.latitude],
                                                                      @"lng": [NSNumber numberWithFloat:location.coordinate.longitude]}];
        
        if (currentService != nil) {
            [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lat_o"] floatValue]] forKey:@"lat_o"];
            [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lng_o"] floatValue]] forKey:@"lng_o"];
            [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lat_d"] floatValue]] forKey:@"lat_d"];
            [parameters setObject:[NSNumber numberWithFloat:[currentService[@"lng_d"] floatValue]] forKey:@"lng_d"];
        }
        
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"track"] parameters:parameters progress:nil
                       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                           //NSLog(@"Track Saved!");
                       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                           NSLog(@"%@", error);
                       }];

    }
}


- (void)getVehicleDriverServices {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count]>0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"vc-services"];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"%@", error);
                      [self showAlert:@"Sincronización" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
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

-(void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

@end
