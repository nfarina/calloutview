#import "ScrollViewController.h"
#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

// We need a custom subclass of UIScrollView to allow cancelling touches in our callout
@interface CustomScrollView : UIScrollView
@end

@interface ScrollViewController () <UIGestureRecognizerDelegate, SMCalloutViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *marsView;
@property (nonatomic, strong) MKPinAnnotationView *pinView;
@property (nonatomic, strong) SMCalloutView *calloutView;
@end

@implementation ScrollViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
        self.title = @"ScrollView";
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

- (void)loadView {
    
    self.marsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mars.jpg"]];
    self.marsView.userInteractionEnabled = YES;
    [self.marsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(marsTapped)]];

    self.scrollView = [CustomScrollView new];
    self.scrollView.contentSize = self.marsView.image.size;
    self.scrollView.contentOffset = CGPointMake(40, 40);
    self.scrollView.bounces = NO;
    self.scrollView.delaysContentTouches = NO; // allow touches on the callout to highlight immediately
    [self.scrollView addSubview:self.marsView];
    
    self.pinView = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
    self.pinView.center = CGPointMake(230, 200);
    [self.pinView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pinTapped)]];
    [self.marsView addSubview:self.pinView];
    
    self.calloutView = [SMCalloutView platformCalloutView];
    self.calloutView.delegate = self;
    self.calloutView.title = @"Curiosity";
    
    // create a little accessory view to mimic the little car that Maps.app shows
    UIImageView *carView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Driving"]];

    if ([self.calloutView.backgroundView isKindOfClass:[SMCalloutMaskedBackgroundView class]]) {

        // wrap it in a blue background on iOS 7+
        UIButton *blueView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44+30)];
        blueView.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
        [blueView addTarget:self action:@selector(carClicked) forControlEvents:UIControlEventTouchUpInside];
        
        carView.frame = CGRectMake(11, 14, carView.image.size.width, carView.image.size.height);
        [blueView addSubview:carView];
        
        self.calloutView.leftAccessoryView = blueView;

        // create a little disclosure indicator since our callout is tappable
        UIButton *disclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [disclosure addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disclosureTapped)]];
        self.calloutView.rightAccessoryView = disclosure;

    }
    else {
        // "inset" the car graphic to match the callout's title on iOS 6-
        carView.layer.shadowOffset = CGSizeMake(0, -1);
        carView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        carView.layer.shadowOpacity = 1;
        carView.layer.shadowRadius = 0;
        carView.clipsToBounds = NO;
        self.calloutView.leftAccessoryView = carView;
    }
    
    // if we're on iOS 7+, the callout can be clicked - add a disclosure image to indicate this to the user!
    if ([self.calloutView.backgroundView isKindOfClass:[SMCalloutMaskedBackgroundView class]]) {
        self.calloutView.rightAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableNext"]];
        self.calloutView.rightAccessoryView.alpha = 0.2;
    }
    
    self.view = self.scrollView;
}

- (void)pinTapped {

    // Apply the MKAnnotationView's desired calloutOffset (from the top-middle of the view)
    self.calloutView.calloutOffset = self.pinView.calloutOffset;
    
    // Apply any scroll view edge insets
    self.calloutView.constrainedInsets = self.scrollView.contentInset;
    
    // This does all the magic.
    [self.calloutView presentCalloutFromRect:self.pinView.frame inView:self.marsView constrainedToView:self.view animated:YES];
    
    // Here's an alternate method that adds the callout *inside* the pin view. This may seem strange, but it's how MKMapView
    // does it. It brings the selected pin to the front, then pops up the callout inside the pin's view. This way, the callout
    // is "anchored" to the pin itself. Visually, there's no difference; the callout still looks like it's floating outside the pin.
    // The only catch is that you will need to override -hitTest in your view to deliver touches to the callout, since the callout
    // will technically be outside the bounds of the pin which is its parent.
   
    //[self.calloutView presentCalloutFromRect:self.pinView.bounds inView:self.pinView constrainedToView:self.view animated:YES];
}

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset {
    
    // the callout is telling us we need to move the scroll view such that the callout will be completely visible when it appears.
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.x -= offset.width;
    contentOffset.y -= offset.height;
    
    [self.scrollView setContentOffset:contentOffset animated:YES];
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

- (void)marsTapped {
    [self.calloutView dismissCalloutAnimated:YES];
}

- (void)disclosureTapped {
    [[[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the disclosure button."
                               delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil] show];
}

- (void)carClicked {
    [[[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the car button."
                               delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Vroom Vroom!",nil] show];
}

- (void)calloutViewClicked:(SMCalloutView *)calloutView {
    [[[UIAlertView alloc] initWithTitle:@"Tap!" message:@"You tapped the callout view."
                               delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil] show];
}

@end

@implementation CustomScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view { return YES; }

@end
