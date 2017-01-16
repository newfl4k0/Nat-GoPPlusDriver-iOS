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
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)doCloseSession:(id)sender {
    NSDictionary *parameters = @{ @"connection": [NSNumber numberWithInt:[self.app.dataLibrary getInteger:@"connection_id"]] };
    
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
}

- (IBAction)doCheckServerStatus:(id)sender {
}

- (IBAction)doInitManualSync:(id)sender {
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
