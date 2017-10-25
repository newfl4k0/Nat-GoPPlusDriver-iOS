//
//  StatsViewController.m
//  fa
//
//  Created by Cristina Avila on 17/08/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "StatsViewController.h"
#import "DSBarChart.h"
#import "AppDelegate.h"
#import "StatsDetailViewController.h"

@interface StatsViewController ()
@property (weak, nonatomic) AppDelegate *app;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UIView *chartContainer;
@property (strong, nonatomic) DSBarChart *chrt;
@property (weak, nonatomic) IBOutlet UIDatePicker *datepicker;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) NSNumber *conductor_id;
@property (weak, nonatomic) IBOutlet UILabel *dayAmount;
@property (strong, nonatomic) NSDictionary *stats;
@property (strong, nonatomic) NSNumberFormatter *fmt;
@end

@implementation StatsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.navBar setBackgroundImage:[
                                     [UIImage imageNamed:@"bgnavbar"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                     resizingMode:UIImageResizingModeStretch]
                      forBarMetrics:UIBarMetricsDefault];
    
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setDateFormat:@"YYYY-MM-dd"];
    self.datepicker.maximumDate = [[NSDate alloc] init];
    self.datepicker.minimumDate =  [self.datepicker.maximumDate dateByAddingTimeInterval:(-86400 * 365)];
    self.conductor_id = [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]];
    
    self.fmt = [[NSNumberFormatter alloc] init];
    [self.fmt setPositiveFormat:@"0.##"];
    
    [self setChart];
}


- (void)setChart {
    [self deleteChart];
    
    
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"statsDriverByWeek"] parameters:@{@"id": self.conductor_id, @"day": [self.formatter stringFromDate:self.datepicker.date] } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *data = [responseObject objectForKey:@"data"];
        NSMutableArray *vals = [[NSMutableArray alloc] init];
        NSMutableArray *ref = [[NSMutableArray alloc] init];
        
        self.stats = [data objectForKey:@"stats"];
        
        for (NSDictionary *day in [data objectForKey:@"week"]) {
            [vals addObject:[NSNumber numberWithDouble:[[day objectForKey:@"Monto"] doubleValue]]];
            [ref addObject:[day objectForKey:@"Dia"]];
        }
        
        self.dayAmount.text = [NSString stringWithFormat:@"$%@", [self.fmt stringFromNumber:[NSNumber numberWithDouble:[[[data objectForKey:@"driver"] objectForKey:@"Total_Conductor"] doubleValue]]]];
        self.chrt = [[DSBarChart alloc] initWithFrame:self.chartContainer.bounds
                                                color:[UIColor redColor]
                                           references:ref
                                            andValues:vals];
        self.chrt.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.chrt.bounds = self.chartContainer.bounds;
        [self.chartContainer addSubview:self.chrt];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error : %@", error);
        self.stats = nil;
    }];
}


- (void)deleteChart {
    if (self.chrt != nil) {
        [self.chrt removeFromSuperview];
        self.chrt = nil;
    }
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"segueDetail"]) {
        if (self.stats != nil) {
            return YES;
        }
    }
    
    return NO;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueDetail"]) {
        ((StatsDetailViewController *)segue.destinationViewController).providesPresentationContextTransitionStyle = YES;
        ((StatsDetailViewController *)segue.destinationViewController).definesPresentationContext = YES;
        ((StatsDetailViewController *)segue.destinationViewController).modalPresentationStyle = UIModalPresentationOverFullScreen;
        ((StatsDetailViewController *)segue.destinationViewController).stats = self.stats;
        ((StatsDetailViewController *)segue.destinationViewController).day = [self.formatter stringFromDate:self.datepicker.date];
    }
}


- (IBAction)pickerChanged:(id)sender {
    [self setChart];
}

- (IBAction)quitSegue:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
