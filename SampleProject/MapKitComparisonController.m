#import "MapKitComparisonController.h"

// We need a custom subclass of MKMapView in order to allow touches on UIControls in our custom callout view.
@interface CustomMapView : MKMapView
@property (nonatomic, strong) SMCalloutView *calloutView;
@end

@implementation MapKitComparisonController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
        self.title = @"MapKit";
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
        
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
    
    self.annotationForSMCalloutView = [MKPointAnnotation new];
    self.annotationForSMCalloutView.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    self.annotationForSMCalloutView.title = @"Cape Canaveral";
    self.annotationForSMCalloutView.subtitle = @"Launchpad";

    self.annotationForUICalloutView = [MKPointAnnotation new];
    self.annotationForUICalloutView.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    self.annotationForUICalloutView.title = @"Cape Canaveral";
    self.annotationForUICalloutView.subtitle = @"Launchpad";

    self.mapKitWithSMCalloutView = [[CustomMapView alloc] initWithFrame:self.view.bounds];
    self.mapKitWithSMCalloutView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapKitWithSMCalloutView.delegate = self;
    [self.mapKitWithSMCalloutView addAnnotation:self.annotationForSMCalloutView];
    [self.view addSubview:self.mapKitWithSMCalloutView];

    self.mapKitWithUICalloutView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapKitWithUICalloutView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapKitWithUICalloutView.delegate = self;
    [self.mapKitWithUICalloutView addAnnotation:self.annotationForUICalloutView];
    [self.view addSubview:self.mapKitWithUICalloutView];
    
    // create our custom callout view
    self.calloutView = [SMCalloutView platformCalloutView];
    self.calloutView.delegate = self;
    
    // tell our custom map view about the callout so it can send it touches
    self.mapKitWithSMCalloutView.calloutView = self.calloutView;
    
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
    
    // create a disclosure button for map kit
    UIButton *disclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [disclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
    view.rightCalloutAccessoryView = disclosure;
    
    // if we're using SMCalloutView, we don't want MKMapView to create its own callout!
    if (annotation == self.annotationForSMCalloutView)
        view.canShowCallout = NO;
    else
        view.canShowCallout = YES;
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView {
    
    if (mapView == self.mapKitWithSMCalloutView) {

        // apply the MKAnnotationView's basic properties
        self.calloutView.title = annotationView.annotation.title;
        self.calloutView.subtitle = annotationView.annotation.subtitle;

        // Apply the MKAnnotationView's desired calloutOffset (from the top-middle of the view)
        self.calloutView.calloutOffset = annotationView.calloutOffset;
        
        // create a disclosure button for comparison
        UIButton *disclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [disclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
        self.calloutView.rightAccessoryView = disclosure;

        // iOS 7 only: Apply our view controller's edge insets to the allowable area in which the callout can be displayed.
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
            self.calloutView.constrainedInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);
        
        // This does all the magic.
        [self.calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.view animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
    [self.calloutView dismissCalloutAnimated:YES];
}

//
// SMCalloutView delegate methods
//

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset {
    
    // When the callout is being asked to present in a way where it or its target will be partially offscreen, it asks us
    // if we'd like to reposition our surface first so the callout is completely visible. Here we scroll the map into view,
    // but it takes some math because we have to deal in lon/lat instead of the given offset in pixels.

    CLLocationCoordinate2D coordinate = self.mapKitWithSMCalloutView.centerCoordinate;
    
    // where's the center coordinate in terms of our view?
    CGPoint center = [self.mapKitWithSMCalloutView convertCoordinate:coordinate toPointToView:self.view];
    
    // move it by the requested offset
    center.x -= offset.width;
    center.y -= offset.height;
    
    // and translate it back into map coordinates
    coordinate = [self.mapKitWithSMCalloutView convertPoint:center toCoordinateFromView:self.view];

    // move the map!
    [self.mapKitWithSMCalloutView setCenterCoordinate:coordinate animated:YES];
    
    // tell the callout to wait for a while while we scroll (we assume the scroll delay for MKMapView matches UIScrollView)
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)disclosureTapped {
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
