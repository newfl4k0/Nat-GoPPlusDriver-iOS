//
//  ProfileViewController.m
//  fa
//
//  Created by Cristina Avila on 11/04/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()
@property (weak, nonatomic) AppDelegate *app;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UITextField *surnameText;
@property (weak, nonatomic) IBOutlet UITextField *passText;
@property (weak, nonatomic) IBOutlet UITextField *confirmPassText;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(weak, nonatomic) id<UINavigationControllerDelegate, UIImagePickerControllerDelegate> delegate;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.navBar setBackgroundImage:[
                                     [UIImage imageNamed:@"bgnavbar"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                     resizingMode:UIImageResizingModeStretch]
                      forBarMetrics:UIBarMetricsDefault];
    
    [self.nameText setText:[self.app.dataLibrary getString:@"driver_name"]];
    [self.surnameText setText:[self.app.dataLibrary getString:@"driver_surname"]];
    
    self.passText.delegate = self;
    self.confirmPassText.delegate = self;
    
    [self initializeImageProfile];
    [self getImage];
    [self.spinner stopAnimating];
}


- (IBAction)updateName:(id)sender {
    NSString *name = self.nameText.text;
    NSString *surname = self.surnameText.text;
    
    if ([name isEqualToString:@""] || [surname isEqualToString:@""]) {
        [self showAlert:@"GoPPlus Driver" :@"Ingresa el nuevo nombre y apellido"];
        return;
    }

    [self.spinner startAnimating];
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"save-name"] parameters:@{ @"id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]], @"name": name, @"surname": surname } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.spinner stopAnimating];
        [self showAlert:@"GoPPlus Driver": [responseObject objectForKey:@"message"]];
        
        if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
            [self.app.dataLibrary saveString:name :@"driver_name"];
            [self.app.dataLibrary saveString:surname :@"driver_surname"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"driverData" object:nil];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.spinner stopAnimating];
        [self showAlert:@"GoPPlus Driver" :@"Error al actualizar. Intenta nuevamente"];
    }];
}

- (IBAction)updatePassword:(id)sender {
    NSString *pass = self.passText.text;
    NSString *pass2 = self.confirmPassText.text;
    
    if ([pass isEqualToString:@""] || ![pass isEqualToString:pass2]) {
        [self showAlert:@"GoPPlus Driver" :@"Verifica la contraseña ingresada"];
        return;
    }
    
    [self.spinner startAnimating];
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"save-pass"] parameters:@{ @"id": [self.app.dataLibrary getString:@"userid"], @"pass": pass } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self.spinner stopAnimating];
        [self showAlert:@"GoPPlus Driver": [responseObject objectForKey:@"message"]];
        
        if ([[responseObject objectForKey:@"status"] boolValue] == YES) {
            self.passText.text = @"";
            self.confirmPassText.text = @"";
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.spinner stopAnimating];
        [self showAlert:@"GoPPlus Driver" :@"Error al actualizar. Intenta nuevamente"];
    }];
}

- (IBAction)quitSegue:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 * Handle Image tap
 **/

- (void)initializeImageProfile {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    [self.image setUserInteractionEnabled:YES];
    [self.image addGestureRecognizer:singleTap];
    
    #if TARGET_IPHONE_SIMULATOR
        NSLog(@"This is simulator mode....");
    #else
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsEditing = YES;
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    #endif
}

- (void)tapDetected {
    #if TARGET_IPHONE_SIMULATOR
        NSLog(@"Simulator, prevent ");
    #else
        [self presentViewController:self.imagePickerController animated:YES completion:NULL];
    #endif
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    NSData *imageData = UIImageJPEGRepresentation(chosenImage, 0.5);
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self.image setImage:chosenImage];
    [self.spinner startAnimating];
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"upload"]
                parameters:@{ @"id": [self.app.dataLibrary getString:@"driver_id"]  }
 constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imageData name:@"theImage" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    }
                  progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       [self.app.dataLibrary saveDriverImage:chosenImage];
                       [self.spinner stopAnimating];
                       [[NSNotificationCenter defaultCenter] postNotificationName:@"driverData" object:nil];
                   }
                   failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       [self.spinner stopAnimating];
                       [self showAlert:@"GoPPlus Driver" :@"Error al subir imagen"];
                   }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) getImage {
    @try {
        NSString *urlImage = [[[self.app.serverUrl stringByAppendingString:@"images/?id="] stringByAppendingString:[self.app.dataLibrary getString:@"driver_id"]] stringByAppendingString:@".jpg"];
        NSURL *url = [NSURL URLWithString:urlImage];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [self.image setImage:[UIImage imageWithData:data]];
        self.image.layer.cornerRadius = self.image.frame.size.width / 2;
        self.image.clipsToBounds = YES;
    } @catch (NSException *exception) {
        NSLog(@"[getImage] exception: %@", exception);
    }
}

//Alerts
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
