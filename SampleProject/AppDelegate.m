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
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
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
    topPin.center = CGPointMake(half.size.width/2 + 230, half.size.height/2 + 100);
    [topPin addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topPinTapped)]];
    [marsView addSubview:topPin];
	
    UIButton *topDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [topDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
    
    calloutView = [SMCalloutView new];
    calloutView.delegate = self;
    calloutView.title = @"Curiosity";
    calloutView.rightAccessoryView = topDisclosure;
    calloutView.calloutOffset = topPin.calloutOffset;
	
	// custom view to be used in our callout
	UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	customView.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:.6];
	// if you provide a custom view for the callout content, the title and subtitle will not be displayed
	calloutView.contentView = customView;
	
    //
    // Fill the bottom half of our window with a standard MKMapView with pin+callout for comparison
    //
    
    MapAnnotation *capeCanaveral = [MapAnnotation new];
    capeCanaveral.coordinate = (CLLocationCoordinate2D){28.388154, -80.604200};
    capeCanaveral.title = @"Cape Canaveral";
	
    UIButton *bottomDisclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [bottomDisclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
	
    bottomPin = [[MKPinAnnotationView alloc] initWithAnnotation:capeCanaveral reuseIdentifier:@""];
	
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

- (void)topPinTapped {
    // show our callout if it's not already shown!
    // now in this example we're going to introduce an artificial delay in order to make our popup feel identical to MKMapView.
    // MKMapView has a delay after tapping so that it can intercept a double-tap for zooming. We don't need that delay but we'll
    // add it just so things feel the same.
    if (!calloutView.window)
        [self performSelector:@selector(popupCalloutView) withObject:nil afterDelay:1.0/3.0];
}

#pragma mark - MKMapView

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // make sure to display our precreated pin that adds an accessory view.
    return bottomPin;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	// show our callout if it's not already shown!
    // now in this example we're going to introduce an artificial delay in order to make our popup feel identical to MKMapView.
    // MKMapView has a delay after tapping so that it can intercept a double-tap for zooming. We don't need that delay but we'll
    // add it just so things feel the same.
    if (!calloutView.window)
        [self performSelector:@selector(popupMapCalloutView) withObject:nil afterDelay:1.0/3.0];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	// again, we'll introduce an artifical delay to feel more like MKMapView for this demonstration.
    [calloutView performSelector:@selector(dismissCalloutAnimated:) withObject:nil afterDelay:1.0/3.0];
}

#pragma mark - SMCalloutView

- (void)popupCalloutView {
	
	// This does all the magic.
    [calloutView presentCalloutFromRect:topPin.frame
                                 inView:marsView
                      constrainedToView:scrollView
               permittedArrowDirections:SMCalloutArrowDirectionUp
                               animated:YES];
    
    // Here's an alternate method that adds the callout *inside* the pin view. This may seem strange, but it's how MKMapView
    // does it. It brings the selected pin to the front, then pops up the callout inside the pin's view. This way, the callout
    // is "anchored" to the pin itself. Visually, there's no difference; the callout still looks like it's floating outside the pin.
    
    // Note that this technique will require overriding -hitTest:withEvent inside the view containing the callout view, in order
    // to send touches to any accessory views of the callout. See this thread for more discussion: https://github.com/nfarina/calloutview/issues/9
    
    // You'll notice this example won't let you click on the blue disclosure button because we're not overriding -hitTest.

//    [calloutView presentCalloutFromRect:topPin.bounds
//                                 inView:topPin
//                      constrainedToView:scrollView
//               permittedArrowDirections:SMCalloutArrowDirectionDown
//                               animated:YES];
}

- (void)popupMapCalloutView {
	[calloutView presentCalloutFromRect:bottomPin.bounds
                                 inView:bottomPin
                      constrainedToView:bottomMapView
               permittedArrowDirections:SMCalloutArrowDirectionAny
                               animated:YES];
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset {
    
    // Uncomment this to cancel the popup
    // [calloutView dismissCalloutAnimated:NO];
	
	// if annotation view is coming from MKMapView, it's contained within a MKAnnotationContainerView instance
	// so we need to adjust the map position so that the callout will be completely visible when displayed
	if ([NSStringFromClass([calloutView.superview.superview class]) isEqualToString:@"MKAnnotationContainerView"]) {
		CGFloat pixelsPerDegreeLat = bottomMapView.frame.size.height / bottomMapView.region.span.latitudeDelta;
		CGFloat pixelsPerDegreeLon = bottomMapView.frame.size.width / bottomMapView.region.span.longitudeDelta;
		
		CLLocationDegrees latitudinalShift = offset.height / pixelsPerDegreeLat;
		CLLocationDegrees longitudinalShift = -(offset.width / pixelsPerDegreeLon);
		
		CGFloat lat = bottomMapView.region.center.latitude + latitudinalShift;
		CGFloat lon = bottomMapView.region.center.longitude + longitudinalShift;
		CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D){lat, lon};
		if (fabsf(newCenterCoordinate.latitude) <= 90 && fabsf(newCenterCoordinate.longitude <= 180)) {
			[bottomMapView setCenterCoordinate:newCenterCoordinate animated:YES];
		}
	}
	else {
		[scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x-offset.width, scrollView.contentOffset.y-offset.height) animated:YES];
	}
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)disclosureTapped {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the disclosure button."
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Whatevs",nil];
    [alert show];
}

- (void)marsTapped {
    // again, we'll introduce an artifical delay to feel more like MKMapView for this demonstration.
    [self performSelector:@selector(dismissCallout) withObject:nil afterDelay:1.0/3.0];
}

- (void)dismissCallout {
    [calloutView dismissCalloutAnimated:NO];
}

@end
