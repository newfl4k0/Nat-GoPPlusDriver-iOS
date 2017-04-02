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
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation AccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        [self.app initDrawerWindow];
    } else {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.spinner setBackgroundColor:[UIColor blackColor]];
        self.spinner.center = CGPointMake(160, 240);
        self.spinner.tag = 1;
    }
}

- (void)stopSpinner {
    [[self.view viewWithTag:1] stopAnimating];
}

- (IBAction)doVerifyCredentials:(id)sender {
    if (self.userInput.text.length == 0 || self.passwordInput.text.length == 0) {
        [self showAlert:@"Acceder" :@"Todos los campos son necesarios"];
        return;
    }
    
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"status"] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([[responseObject objectForKey:@"data"] count] >0) {
            [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"estatus"];
            [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"cancel"] parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                
                if ([[responseObject objectForKey:@"data"] count] > 0) {
                    [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"canceloptions"];
                    NSDictionary *parameters = @{
                                                 @"user": [self.userInput text],
                                                 @"password": [self.passwordInput text]
                                                 };
                    
                     [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"login"]
                                parameters:parameters
                                  progress:nil
                                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                       [self stopSpinner];
                                       
                                       NSDictionary *response = responseObject;
                                       
                                       if ([[response valueForKey:@"status"] boolValue]) {
                                           [self.app.dataLibrary saveInteger:[self.app.dataLibrary getStatusIdForName:@"Libre"] :@"status"];
                                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"id"] integerValue] :@"connection_id"];
                                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"conductor_id"] integerValue] :@"driver_id"];
                                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"vehiculo_id"] integerValue] :@"vehicle_id"];
                                           [self.app.dataLibrary saveString:[response valueForKey:@"nombre"] :@"driver_name"];
                                           [self.app.dataLibrary saveString:[response valueForKey:@"afiliado"] :@"affiliate_id"];
                                           [self.app.dataLibrary saveString:[response valueForKey:@"vehiculoconductor"] :@"vehicle_driver_id"];
                                           [self.app initDrawerWindow];
                                           
                                       } else {
                                           [self showAlert:@"Error al iniciar sesión" : [response valueForKey:@"message"]];
                                       }
                                   }
                                   failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                       NSLog(@"%@", error);
                                       [self stopSpinner];
                                       [self showAlert:@"Error" :@"Verifica el estatus del servidor y datos ingresados"];
                                   }];
                } else {
                    [self stopSpinner];
                    [self showAlert:@"Error" :@"Verifica el estatus del servidor. Diccionario de Rechazos no enviado correctamente"];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self stopSpinner];
               [self showAlert:@"Error" :@"Verifica el estatus del servidor. Diccionario de Rechazos no enviado correctamente"];
            }];
        } else {
            [self stopSpinner];
            [self showAlert:@"Error" :@"Verifica el estatus del servidor. Diccionario de Estatus no enviado correctamente"];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self stopSpinner];
        [self showAlert:@"Error" :@"Verifica el estatus del servidor. Diccionario de Estatus no enviado correctamente"];
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
