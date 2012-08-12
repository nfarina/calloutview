#import "AppDelegate.h"
#import "SMCalloutView.h"
#import <QuartzCore/QuartzCore.h>

@interface MapAnnotation : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString *title, *subtitle;
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
    capeCanaveral.subtitle = @"It's a great place to visit!";

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
    calloutView.subtitle = capeCanaveral.subtitle;
    calloutView.leftAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)]; // [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    calloutView.leftAccessoryView.backgroundColor = [UIColor redColor];
    calloutView.rightAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)]; // [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    calloutView.rightAccessoryView.backgroundColor = [UIColor redColor];

    //
    // Fill the bottom half of our window with a standard MKMapView with pin+callout for comparison
    //
    
    bottomPin = [[MKPinAnnotationView alloc] initWithAnnotation:capeCanaveral reuseIdentifier:@""];
    bottomPin.leftCalloutAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)]; // [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    bottomPin.leftCalloutAccessoryView.backgroundColor = [UIColor redColor];
    bottomPin.rightCalloutAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)]; // [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    bottomPin.rightCalloutAccessoryView.backgroundColor = [UIColor redColor];
    bottomPin.canShowCallout = YES;

    bottomMapView = [[MKMapView alloc] initWithFrame:CGRectOffset(half, 0, half.size.height)];
    bottomMapView.delegate = self;
    [bottomMapView addAnnotation:capeCanaveral];
    
    //
    // Put it all on the screen.
    //

    [self.window addSubview:topMapView];
    [self.window addSubview:bottomMapView];

    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(popup) withObject:nil afterDelay:0];
    [self performSelector:@selector(printHierarchy) withObject:nil afterDelay:5];
    
    return YES;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    return mapView == topMapView ? topPin : bottomPin;
}

- (void)pinTapped:(UITapGestureRecognizer *)recognizer {
    [calloutView presentCalloutFromRect:topPin.bounds
                                 inView:topPin
                      constrainedToRect:[topMapView convertRect:topMapView.bounds toView:topPin]
               permittedArrowDirections:SMCalloutArrowDirectionAny
                               animated:YES];
}

- (void)marsTapped {
    [calloutView dismissCalloutAnimated:YES];
}

- (void)popup {

    [calloutView presentCalloutFromRect:topPin.bounds
                                 inView:topPin
                      constrainedToRect:[topMapView convertRect:topMapView.bounds toView:topPin]
               permittedArrowDirections:SMCalloutArrowDirectionAny
                               animated:YES];
    
    [bottomMapView selectAnnotation:bottomPin.annotation animated:YES];
    
    [self performSelector:@selector(tweakPopup) withObject:nil afterDelay:1];
}

- (void)tweakPopup {
}

- (UIView *)findSubviewOf:(UIView *)view havingClass:(NSString *)className {
    if ([NSStringFromClass(view.class) isEqualToString:className])
        return view;
    
    for (UIView *subview in view.subviews) {
        UIView *found = [self findSubviewOf:subview havingClass:className];
        if (found) return found;
    }
    
    return nil;
}

- (void)printHierarchy {
//    UIView *callout = [self findSubviewOf:bottomMapView havingClass:@"UICalloutView"];
//
//    for (int x=0;x<400;x+=10) {
//        NSLog(@"Size that fits %i,100: %@", x, NSStringFromCGSize([callout sizeThatFits:CGSizeMake(x, 100)]));
//        NSLog(@"OUR Size that fits %i,100: %@", x, NSStringFromCGSize([calloutView sizeThatFits:CGSizeMake(x, 100)]));
//    }
    
    NSLog(@"%@", self.window.recursiveDescription);
    
//    CABasicAnimation *animation = (CABasicAnimation *)[callout.layer animationForKey:@"transform"];
//    NSLog(@"Callout: %@ duration:%f tx:%@", animation, animation.duration, NSStringFromCGAffineTransform(callout.transform));
//    if (animation)
//        [self performSelector:@selector(printHierarchy) withObject:nil afterDelay:0.01];
}

@end
