//
//  MapViewController.m
//  fa
//
//  Created by Cristina Avila on 31/12/16.
//  Copyright © 2016 Cristina Avila. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UILabel *clientLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) AppDelegate *app;
@property (nonatomic) NSInteger connection_id;
@property (nonatomic) NSInteger status;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.status = 1;
    self.connection_id = [self.app.dataLibrary getInteger:@"connection_id"];
    [self initializeServiceData];
    [self initTimer];
}

- (void)initializeServiceData {
    [self.clientLabel setText:@"Cliente: Juan Perez"];
    [self.statusLabel setText:@"En curso"];
    [self.dataLabel setText:@"De: Fresno #123 Colonia El Moral \nA: Plaza Mayor \nInicio del viaje: 09 Ene 2017 10:10am \nObservaciones: Esperar en cafetería"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doToggleMenu:(id)sender {
    [self.app.drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)initTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self updateMapWithLatestLocation];
    }];
}

-(void)updateMapWithLatestLocation {
    if (self.app.locationManager != nil) {
        CLLocation* location = [self.app.locationManager location];
        
        if (location!=nil) {
            [self.map setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), MKCoordinateSpanMake(0.05, 0.05))];
        }
    }
}

-(void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)openChat:(id)sender {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Abrir chat" message:@"Preparar link a chat" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (IBAction)doCancel:(id)sender {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Cancelar Servicio" message:@"¿Seguro de cancelar el servicio?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (IBAction)doEnd:(id)sender {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Finalizar Servicio" message:@"¿Seguro de finalizar el servicio?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
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
