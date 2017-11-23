//
//  SettingsViewController.m
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"

@interface SettingsViewController ()
@property (weak, nonatomic) AppDelegate *app;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UILabel *carModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *carBrandLabel;
@property (weak, nonatomic) IBOutlet UILabel *carPlatesLabel;
@property (weak, nonatomic) IBOutlet UILabel *carCardLabel;
@property (weak, nonatomic) IBOutlet UILabel *carMagazineLabel;
@property (weak, nonatomic) IBOutlet UILabel *carLicenseLabel;
@property (weak, nonatomic) IBOutlet UILabel *carColorLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;


@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch] forBarMetrics:UIBarMetricsDefault];
    [self syncVehicleData];
    [self.spinner stopAnimating];
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)doCloseSession:(id)sender {
    
    if (self.app.hasService == 0) {
        UIAlertController *confirmController = [UIAlertController
                                                alertControllerWithTitle:@"GoPPlus Driver"
                                                message:@"Cerrar Sesión"
                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [confirmController dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Aceptar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSDictionary *parameters = @{ @"connection": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]] };
            
            [self.spinner startAnimating];
            
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"logout"]
                        parameters:parameters
                          progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self.spinner stopAnimating];
                               
                               if (self.app.locationManager!=nil) {
                                   [self.app.locationManager stopUpdatingLocation];
                               }
                               
                               [self.app.dataLibrary deleteAll];
                               [self.app initLoginWindow];
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               [self.spinner stopAnimating];
                               [self showAlert:@"Cerrar Sesión" :@"Error, intenta nuevamente"];
                           }];
        }];
        
        [confirmController addAction:cancel];
        [confirmController addAction:ok];
        [self presentViewController:confirmController animated:YES completion:nil];
    } else {
        [self showAlert:@"Cerrar Sesión" :@"Tienes un servicio en curso"];
    }

}

- (IBAction)doInitManualSync:(id)sender {
    [self SyncData];
}

- (void)reloadVehicleData {
    @try {
        NSDictionary *carData = [self.app.dataLibrary getDictionary:@"vehicleData"];

        self.carModelLabel.text    = [carData valueForKey:@"modelo"];
        self.carBrandLabel.text    = [carData valueForKey:@"marca"];
        self.carPlatesLabel.text   = [carData valueForKey:@"matricula"];
        self.carCardLabel.text     = [carData valueForKey:@"tarjeton"];
        self.carMagazineLabel.text = [[carData valueForKey:@"revista"] stringValue];
        self.carLicenseLabel.text  = [self.app.dataLibrary getString:@"license"];
        self.carColorLabel.text    = [carData valueForKey:@"color"];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
}


- (void)syncConfiguration {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"sync"] parameters:@{} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count] > 0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"settings"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"settings"];
                      }
                      
                      [self syncDriver];
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      [self.spinner stopAnimating];
                      [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
}

- (void)syncVehicleData {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"getVehicleInfo"] parameters:@{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"vehicle_id"]]  } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
            [self.app.dataLibrary saveDictionary:[responseObject objectForKey:@"data"] : @"vehicleData"];
            [self reloadVehicleData];
        } else {
            [self showAlert:@"Datos del vehículo" :@"Error: servicio no disponible. Intenta nuevamente."];
        }
        
        
        [self syncConfiguration];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.spinner stopAnimating];
        [self showAlert:@"Datos del vehículo" :@"Error: servicio no disponible. Intenta nuevamente."];
    }];
}

- (void)syncServices {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count] > 0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"vc-services"];
                      }
                      
                      [self syncVehicleData];
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      [self.spinner stopAnimating];
                      [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
}

- (void)SyncData {
    [self.spinner startAnimating];
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"cancel"] parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([[responseObject objectForKey:@"data"] count] > 0) {
            [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"canceloptions"];
        }
        
        [self syncServices];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.spinner stopAnimating];
        [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
    }];
}

- (void)syncDriver {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"driverdata"] parameters:@{@"id": [self.app.dataLibrary getString:@"driver_id"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([[responseObject objectForKey:@"data"] count] > 0) {
            NSDictionary *driverData = [[responseObject objectForKey:@"data"] objectAtIndex:0];
            [self.app.dataLibrary saveString:[driverData objectForKey:@"nombre"] :@"driver_name"];
            [self.app.dataLibrary saveString:[driverData objectForKey:@"apellido"] :@"driver_surname"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"driverData" object:nil];
        }
        
        [self.spinner stopAnimating];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.spinner stopAnimating];
        [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
        [self.spinner stopAnimating];
    }];
}

- (void)showAlert:(NSString *)title :(NSString *)message {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (void)dissmissAlert:(UIAlertController *) alert {
    [alert dismissViewControllerAnimated:true completion:nil];
}

@end
