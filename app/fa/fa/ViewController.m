//
//  ViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;

@end

@implementation ViewController

NSString *server = @"http://192.168.15.100:9997/";
AFHTTPSessionManager *manager;

- (void)viewDidLoad {
    [super viewDidLoad];
    manager = [AFHTTPSessionManager manager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)doLogin:(id)sender {
    NSString *URLString = [server stringByAppendingString:@"login"];
    NSDictionary *parameters = @{@"user": [self.userInput text], @"password": [self.passwordInput text]};
    
    
    [manager POST:URLString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *response = responseObject;
        NSLog(@"response: %@", response);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
