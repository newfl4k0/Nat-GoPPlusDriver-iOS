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


@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch] forBarMetrics:UIBarMetricsDefault];
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)doCloseSession:(id)sender {
    UIAlertController *confirmController = [UIAlertController
                                            alertControllerWithTitle:@"GoPPlus Driver"
                                            message:@"Cerrar Sesión"
                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [confirmController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Aceptar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSDictionary *parameters = @{ @"connection": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]] };
        
        [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"logout"]
                    parameters:parameters
                      progress:nil
                       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                           if (self.app.locationManager!=nil) {
                               [self.app.locationManager stopUpdatingLocation];
                           }
                           
                           [self.app.dataLibrary deleteAll];
                           [self.app initLoginWindow];
                       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                           [self showAlert:@"Cerrar Sesión" :@"Error, intenta nuevamente"];
                       }];
    }];
    
    [confirmController addAction:cancel];
    [confirmController addAction:ok];
    [self presentViewController:confirmController animated:YES completion:nil];
}

- (IBAction)doInitManualSync:(id)sender {
    [self SyncData];
}

- (void)SyncData {
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if ([[responseObject objectForKey:@"data"] count]>0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                          [self showAlert:@"Sincronización Manual" :@"Servicios Actualizados"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"vc-services"];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
    
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"cancel"] parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([[responseObject objectForKey:@"data"] count] > 0) {
            [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"canceloptions"];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self showAlert:@"Sincronización Manual" :@"Error: servicio no disponible. Intenta nuevamente."];
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

@end
