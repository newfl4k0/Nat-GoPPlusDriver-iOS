//
//  HistoricDetailViewController.m
//  fa
//
//  Created by Cristina Avila on 09/12/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "HistoricDetailViewController.h"

@interface HistoricDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *dateText;
@property (weak, nonatomic) IBOutlet UILabel *clientText;
@property (weak, nonatomic) IBOutlet UILabel *startText;
@property (weak, nonatomic) IBOutlet UILabel *endText;
@property (weak, nonatomic) IBOutlet UIImageView *googleImage;

@end

@implementation HistoricDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goBack:(id)sender {
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
