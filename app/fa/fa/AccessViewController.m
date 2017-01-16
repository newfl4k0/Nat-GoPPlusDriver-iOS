//
//  AccessViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "AccessViewController.h"
#import "AppDelegate.h"

@interface AccessViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UITextField *vehicleInput;
@property (weak, nonatomic) AppDelegate *app;
@end

@implementation AccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        [self.app initDrawerWindow];
    }
}

- (IBAction)doVerifyCredentials:(id)sender {
    NSDictionary *parameters = @{
                                 @"user": [self.userInput text],
                                 @"password": [self.passwordInput text],
                                 @"vehicle": [self.vehicleInput text]
                                };
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"login"]
                parameters:parameters
                progress:nil
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSDictionary *response = responseObject;
                    
                    if ([[response valueForKey:@"status"] boolValue]) {
                        [self.app.dataLibrary saveInteger:1 :@"status"];
                        [self.app.dataLibrary saveInteger:[[response valueForKey:@"id"] integerValue] :@"connection_id"];
                        [self.app.dataLibrary saveInteger:[[self.userInput text] integerValue] :@"driver_id"];
                        [self.app.dataLibrary saveInteger:[[self.vehicleInput text] integerValue] :@"vehicle_id"];
                        [self.app.dataLibrary saveString:[response valueForKey:@"nombre"] :@"driver_name"];
                        [self.app initDrawerWindow];
                    } else {
                        [self showAlert:@"Error al iniciar sesión" :@"Verifica la información"];
                    }
                }
                failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"%@", error);
                    [self showAlert:@"Error" :@"Verifica el estatus del servidor y datos ingresados"];
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

-(void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}


@end
