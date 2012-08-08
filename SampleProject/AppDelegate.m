#import "AppDelegate.h"
#import "SMCalloutView.h"

@interface MapAnnotation : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end
@implementation MapAnnotation
@end

@interface NSObject (RecursiveDescription)
- (NSString *)recursiveDescription;
@end

@implementation AppDelegate {
//    UIScrollView *scrollView;
//    UIImageView *marsView;
    MKMapView *topMapView, *bottomMapView;
    MKPinAnnotationView *topPin, *bottomPin;
    SMCalloutView *calloutView;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    CGRect half = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height/2);
    
    MapAnnotation *capeCanaveral = [MapAnnotation new];
    capeCanaveral.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    capeCanaveral.title = @"Cape Canaveral";

    //
    // Fill top half with a custom view (image) inside a scroll view along with a custom pin view that triggers our custom MTCalloutView.
    //
    
//    scrollView = [[UIScrollView alloc] initWithFrame:half];
//    
//    marsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mars.jpg"]];
//    marsView.userInteractionEnabled = YES;
//    [marsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(marsTapped)]];
//    
//    [scrollView addSubview:marsView];
//    scrollView.contentSize = marsView.frame.size;
//    
//    pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
//    pin.center = CGPointMake(half.size.width/2, half.size.height/2 + 50);
//    [pin addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pinTapped)]];
//    [marsView addSubview:pin];

    //
    // Fill top half with an MKMapView with a pin view that triggers our custom MTCalloutView.
    //

    topPin = [[MKPinAnnotationView alloc] initWithAnnotation:capeCanaveral reuseIdentifier:@""];
    topPin.canShowCallout = NO;
    [topPin addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pinTapped:)]];

    topMapView = [[MKMapView alloc] initWithFrame:half];
    topMapView.delegate = self;
    [topMapView addAnnotation:capeCanaveral];

    calloutView = [SMCalloutView new];
    calloutView.title = capeCanaveral.title;

    //
    // Fill the bottom half of our window with a standard MKMapView with pin+callout for comparison
    //
    
    bottomPin = [[MKPinAnnotationView alloc] initWithAnnotation:capeCanaveral reuseIdentifier:@""];

    bottomMapView = [[MKMapView alloc] initWithFrame:CGRectOffset(half, 0, half.size.height)];
    [bottomMapView addAnnotation:capeCanaveral];
        
    //
    // Put it all on the screen.
    //

    [self.window addSubview:topMapView];
    [self.window addSubview:bottomMapView];

    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(popup) withObject:nil afterDelay:2];
    [self performSelector:@selector(printHierarchy) withObject:nil afterDelay:5];
    
    return YES;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    return topPin;
}

- (void)pinTapped:(UITapGestureRecognizer *)recognizer {
    [calloutView presentCalloutFromView:recognizer.view permittedArrowDirections:SMCalloutArrowDirectionDown animated:YES];
}

- (void)marsTapped {
    [calloutView dismissCalloutAnimated:YES];
}

- (void)popup {
    [calloutView presentCalloutFromView:topPin permittedArrowDirections:SMCalloutArrowDirectionDown animated:YES];
    [bottomMapView selectAnnotation:bottomPin.annotation animated:YES];
}

- (void)printHierarchy {
    NSLog(@"%@", self.window.recursiveDescription);
}

@end
