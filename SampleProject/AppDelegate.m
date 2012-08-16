#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation MapAnnotation @end

@implementation AppDelegate {
    UIScrollView *scrollView;
    UIImageView *marsView;
    MKPinAnnotationView *topPin;
    SMCalloutView *calloutView;
    MKMapView *bottomMapView;
    MKPinAnnotationView *bottomPin;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 20, 320, 460)];
    self.window.backgroundColor = [UIColor whiteColor];
    CGRect half = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height/2);
    
    //
    // Fill top half with a custom view (image) inside a scroll view along with a custom pin view that triggers our custom MTCalloutView.
    //
    
    scrollView = [[UIScrollView alloc] initWithFrame:half];
    scrollView.backgroundColor = [UIColor grayColor];
    
    marsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mars.jpg"]];
    marsView.userInteractionEnabled = YES;
    [marsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(marsTapped)]];
    
    [scrollView addSubview:marsView];
    scrollView.contentSize = marsView.frame.size;
    scrollView.contentOffset = CGPointMake(150, 50);
    
    topPin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
    topPin.center = CGPointMake(half.size.width/2 + 190, half.size.height/2 + 120);
    [topPin addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topPinTapped)]];
    [marsView addSubview:topPin];

    calloutView = [SMCalloutView new];
    calloutView.delegate = self;
    calloutView.title = @"Curiosity";
    calloutView.rightAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    calloutView.calloutOffset = topPin.calloutOffset;

    //
    // Fill the bottom half of our window with a standard MKMapView with pin+callout for comparison
    //
    
    MapAnnotation *capeCanaveral = [MapAnnotation new];
    capeCanaveral.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    capeCanaveral.title = @"Cape Canaveral";

    bottomPin = [[MKPinAnnotationView alloc] initWithAnnotation:capeCanaveral reuseIdentifier:@""];
    bottomPin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    bottomPin.canShowCallout = YES;

    bottomMapView = [[MKMapView alloc] initWithFrame:CGRectOffset(half, 0, half.size.height)];
    bottomMapView.delegate = self;
    [bottomMapView addAnnotation:capeCanaveral];
    
    //
    // Put it all on the screen.
    //

    [self.window addSubview:scrollView];
    [self.window addSubview:bottomMapView];
    [self.window makeKeyAndVisible];
    return YES;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // make sure to display our precreated pin that adds an accessory view.
    return bottomPin;
}

- (void)topPinTapped {
    // show our callout!
    [calloutView presentCalloutFromRect:topPin.bounds inView:topPin constrainedToView:scrollView permittedArrowDirections:SMCalloutArrowDirectionDown animated:YES];
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset {
    
    // We could cancel the popup here if we wanted to:
    // [calloutView dismissCalloutAnimated:NO];

    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x-offset.width, scrollView.contentOffset.y-offset.height) animated:YES];
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)marsTapped {
    [calloutView dismissCalloutAnimated:NO];
}

@end
