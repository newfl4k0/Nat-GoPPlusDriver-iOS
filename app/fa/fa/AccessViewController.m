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
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) AppDelegate *app;
@end

@implementation AccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    singleTap.numberOfTapsRequired = 1;
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:singleTap];
    [self.userInput setDelegate:self];
    [self.passwordInput setDelegate:self];
    
    if ([self.app.dataLibrary existsKey:@"connection_id"] == YES) {
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"connection-status"] parameters:@{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"connection_id"]] } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSDictionary *response = responseObject;
            
            [self stopSpinner];
            
            if ([[response objectForKey:@"status"] boolValue] == YES) {
                if ([[[response objectForKey:@"data"] objectForKey:@"abierto"] integerValue] == 1) {
                    [self.app initDrawerWindow];
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self stopSpinner];
        }];
    } else {
        [self stopSpinner];
    }
}

- (void)stopSpinner {
    [self.spinner stopAnimating];
    [self.view setUserInteractionEnabled:YES];
}

- (IBAction)doVerifyCredentials:(id)sender {
    if (self.userInput.text.length == 0 || self.passwordInput.text.length == 0) {
        [self showAlert:@"Acceder" :@"Todos los campos son necesarios"];
        return;
    }
    
    [self.spinner startAnimating];
    [self.view setUserInteractionEnabled:NO];
    
    NSDictionary *parameters = @{@"user": [self.userInput text], @"password": [self.passwordInput text]};
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"login"]
                parameters:parameters
                  progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       [self stopSpinner];
                       
                       NSDictionary *response = responseObject;
                       
                       if ([[response valueForKey:@"status"] boolValue]) {
                           [self.app.dataLibrary saveInteger:1 :@"status"];
                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"id"] integerValue] :@"connection_id"];
                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"conductor_id"] integerValue] :@"driver_id"];
                           [self.app.dataLibrary saveInteger:[[response valueForKey:@"vehiculo_id"] integerValue] :@"vehicle_id"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"afiliado"] :@"affiliate_id"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"vehiculoconductor"] :@"vehicle_driver_id"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"nombre"] :@"driver_name"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"apellido"] :@"driver_surname"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"completo"] :@"driver_fullname"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"licencia"] :@"license"];
                           [self.app.dataLibrary saveDictionary:[response valueForKey:@"tarifa"] :@"fare"];
                           [self.app.dataLibrary saveString:[response valueForKey:@"usuario_id"] :@"userid"];
                           
                           [self.app initDrawerWindow];
                       } else {
                           [self showAlert:@"Error al iniciar sesión" : [response valueForKey:@"message"]];
                       }
                   }
                   failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       NSLog(@"%@", error);
                       [self stopSpinner];
                       [self showAlert:@"Error" :@"Verifica tu usuario y contraseña"];
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

- (void)hideKeyboard {
    if ([self.userInput isFirstResponder]) {
        [self.userInput resignFirstResponder];
    }
    
    if ([self.passwordInput isFirstResponder]) {
        [self.passwordInput resignFirstResponder];
    }
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.userInput resignFirstResponder];
    [self.passwordInput resignFirstResponder];

    return NO;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}

-(void)animateTextField:(UITextField*)textField up:(BOOL)up {
    const int movementDistance = -130; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? movementDistance : -movementDistance);
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

@end
