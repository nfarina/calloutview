#import "MapKitComparisonController.h"

@implementation MapKitComparisonController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
        self.title = @"MapKit";
        
        // create a segmented control to switch between MapKit and our custom map image
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"SMCalloutView", @"UICalloutView"]];
        self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.segmentedControl.selectedSegmentIndex = 0;
        [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];

        self.navigationItem.titleView = self.segmentedControl;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    annotation.title = @"Cape Canaveral";
    //annotation.subtitle = @"A Nice Place";
    
    UIButton *bottomDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [bottomDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
    
    self.mapKitWithSMCalloutView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapKitWithSMCalloutView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapKitWithSMCalloutView.delegate = self;
    [self.mapKitWithSMCalloutView addAnnotation:annotation];
    [self.view addSubview:self.mapKitWithSMCalloutView];

    self.mapKitWithUICalloutView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapKitWithUICalloutView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapKitWithUICalloutView.delegate = self;
    [self.mapKitWithUICalloutView addAnnotation:annotation];
    [self.view addSubview:self.mapKitWithUICalloutView];
    
    // create our custom callout view
    self.calloutView = [SMCalloutView platformCalloutView];
    self.calloutView.delegate = self;
    self.calloutView.title = @"Cape Canaveral";
    
    UIButton *topDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [topDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
    //self.calloutView.rightAccessoryView = topDisclosure;

    [self segmentedControlChanged];
}

- (void)segmentedControlChanged {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self.view bringSubviewToFront:self.mapKitWithSMCalloutView];
    }
    else {
        [self.view bringSubviewToFront:self.mapKitWithUICalloutView];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // create a proper annotation view, be lazy and don't use the reuse identifier
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
    
    UIButton *bottomDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [bottomDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapKitDisclosureTapped)]];

    if (mapView == self.mapKitWithUICalloutView) {
        //view.rightCalloutAccessoryView = bottomDisclosure;
        UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 35)];
        grayView.backgroundColor = [UIColor grayColor];
        //view.leftCalloutAccessoryView = grayView;
        view.canShowCallout = YES;
    }
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if (mapView == self.mapKitWithSMCalloutView) {
        
        self.calloutView.calloutOffset = view.calloutOffset;
        
        // This does all the magic.
        [self.calloutView presentCalloutFromRect:view.bounds
                                     inView:view
                          constrainedToView:self.view
                   permittedArrowDirections:SMCalloutArrowDirectionDown
                                   animated:YES];
    }
    else {
        NSLog(@"Selected mapkit annotation view!");
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    [self.calloutView dismissCalloutAnimated:YES];
}

- (void)mapKitDisclosureTapped {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the disclosure button."
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [alert show];
}

@end
