//
//  StatsDetailViewController.m
//  fa
//
//  Created by Cristina Avila on 18/08/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "StatsDetailViewController.h"

@interface StatsDetailViewController ()
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UILabel *total;
@property (weak, nonatomic) IBOutlet UILabel *ganancias;
@property (weak, nonatomic) IBOutlet UILabel *banco;
@property (weak, nonatomic) IBOutlet UILabel *efectivo;
@property (weak, nonatomic) IBOutlet UILabel *gfa;
@property (weak, nonatomic) IBOutlet UILabel *impuestos;
@property (weak, nonatomic) IBOutlet UILabel *fecha;
@property (weak, nonatomic) IBOutlet UILabel *encuesta;
@property (weak, nonatomic) IBOutlet UIButton *navBackButton;

@end

@implementation StatsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setBackgroundImage:[
                                     [UIImage imageNamed:@"bgnavbar"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                     resizingMode:UIImageResizingModeStretch]
                      forBarMetrics:UIBarMetricsDefault];
    
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"$0.##"];
    
    self.fecha.text = self.day;
    self.total.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total"] doubleValue]]];
    self.ganancias.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_Conductor"] doubleValue]]];
    self.banco.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_Conductor_Banco"] doubleValue]]];
    self.efectivo.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_Conductor_Efectivo"] doubleValue]]];
    self.gfa.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_GFA"] doubleValue]]];
    self.impuestos.text = [fmt stringFromNumber: [NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_Impuesto"] doubleValue]]];
    self.encuesta.text =  [[NSNumber numberWithDouble:[[self.stats objectForKey:@"Total_Encuesta"] doubleValue]] stringValue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callCloseMyself:) name:@"closeStatsDetails" object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)quitView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)callCloseMyself: (NSNotification *) notification  {
    [self.navBackButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end
