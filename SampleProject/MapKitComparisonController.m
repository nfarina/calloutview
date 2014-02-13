#import "MapKitComparisonController.h"

// We need a custom subclass of MKMapView in order to allow touches on UIControls in our custom callout view.
@interface CustomMapView : MKMapView
@property (strong, nonatomic) SMCalloutView *calloutView;
@end

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
    annotation.subtitle = @"Launchpad";
    
    UIButton *bottomDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [bottomDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
    
    self.mapKitWithSMCalloutView = [[CustomMapView alloc] initWithFrame:self.view.bounds];
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
    self.calloutView.subtitle = @"Launchpad";
    
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

//
// MKMapView delegate methods
//

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
        
        // Apply the MKAnnotationView's desired calloutOffset (from the top-middle of the view)
        self.calloutView.calloutOffset = view.calloutOffset;
        
        // This does all the magic.
        [self.calloutView presentCalloutFromRect:view.bounds
                                     inView:view
                          constrainedToView:self.view
                                   animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    [self.calloutView dismissCalloutAnimated:YES];
}

//
// SMCalloutView delegate methods
//

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset {
    
    CGFloat pixelsPerDegreeLat = self.mapKitWithSMCalloutView.frame.size.height / self.mapKitWithSMCalloutView.region.span.latitudeDelta;
    CGFloat pixelsPerDegreeLon = self.mapKitWithSMCalloutView.frame.size.width / self.mapKitWithSMCalloutView.region.span.longitudeDelta;
    
    CLLocationDegrees latitudinalShift = offset.height / pixelsPerDegreeLat;
    CLLocationDegrees longitudinalShift = -(offset.width / pixelsPerDegreeLon);
    
    CGFloat lat = self.mapKitWithSMCalloutView.region.center.latitude + latitudinalShift;
    CGFloat lon = self.mapKitWithSMCalloutView.region.center.longitude + longitudinalShift;
    
    CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D){lat, lon};

    if (fabsf(newCenterCoordinate.latitude) <= 90 && fabsf(newCenterCoordinate.longitude <= 180))
        [self.mapKitWithSMCalloutView setCenterCoordinate:newCenterCoordinate animated:YES];
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)mapKitDisclosureTapped {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the disclosure button."
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [alert show];
}

@end

//
// Custom Map View
//
// We need to subclass MKMapView in order to present an SMCalloutView that contains interactive
// elements.
//

@interface MKMapView (UIGestureRecognizer)

// this tells the compiler that MKMapView actually implements this method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end

@implementation CustomMapView

// override UIGestureRecognizer's delegate method so we can prevent MKMapView's recognizer from firing
// when we interact with UIControl subclasses inside our callout view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]])
        return NO;
    else
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}

// Allow touches to be sent to our calloutview.
// See this for some discussion of why we need to override this: https://github.com/nfarina/calloutview/pull/9
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *calloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    if (calloutMaybe) return calloutMaybe;
    
    return [super hitTest:point withEvent:event];
}

@end
