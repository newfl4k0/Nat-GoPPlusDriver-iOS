//
//  ProfileViewController.m
//  fa
//
//  Created by Cristina Avila on 11/04/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UITextField *surnameText;
@property (weak, nonatomic) IBOutlet UITextField *passText;
@property (weak, nonatomic) IBOutlet UITextField *confirmPassText;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setBackgroundImage:[
                                     [UIImage imageNamed:@"bgnavbar"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                     resizingMode:UIImageResizingModeStretch]
                      forBarMetrics:UIBarMetricsDefault];
}

- (IBAction)updateName:(id)sender {
}

- (IBAction)updatePassword:(id)sender {
}

- (IBAction)quitSegue:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
