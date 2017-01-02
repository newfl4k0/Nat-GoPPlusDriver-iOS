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
@end

@implementation AccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
}

- (IBAction)doVerifyCredentials:(id)sender {
    NSDictionary *parameters = @{
                                 @"user": [self.userInput text],
                                 @"password": [self.passwordInput text]
                                };
    
    [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"login"]
                parameters:parameters
                progress:nil
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSDictionary *response = responseObject;
                    NSLog(@"response: %@", response);
                }
                failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"Error: %@", error);
                }];
}

@end
