#import "ScrollViewController.h"
#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

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
    }
    return self;
}

- (void)loadView {
    
    self.marsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mars.jpg"]];
    self.marsView.userInteractionEnabled = YES;
    [self.marsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(marsTapped)]];

    self.scrollView = [UIScrollView new];
    self.scrollView.contentSize = self.marsView.image.size;
    self.scrollView.contentOffset = CGPointMake(40, 40);
    self.scrollView.bounces = NO;
    [self.scrollView addSubview:self.marsView];
    
    self.pinView = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
    self.pinView.center = CGPointMake(230, 200);
    [self.pinView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pinTapped)]];
    [self.marsView addSubview:self.pinView];
    
    self.calloutView = [SMCalloutView new];
    self.calloutView.delegate = self;
    self.calloutView.title = @"Curiosity";
    
    // create a little accessory view to match the little car that Maps.app shows
    UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44+30)];
    blueView.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
    UIImageView *carView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Driving"]];
    carView.frame = CGRectMake(11, 14, carView.image.size.width, carView.image.size.height);
    [blueView addSubview:carView];
    
    self.calloutView.leftAccessoryView = blueView;
    
    self.view = self.scrollView;
}

- (void)pinTapped {

    // Apply the MKAnnotationView's desired calloutOffset (from the top-middle of the view)
    self.calloutView.calloutOffset = self.pinView.calloutOffset;
    
    // Apply any scroll view edge insets
    self.calloutView.constrainedInsets = self.scrollView.contentInset;
    
    // This does all the magic.
    [self.calloutView presentCalloutFromRect:self.pinView.bounds inView:self.pinView constrainedToView:self.view animated:YES];
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

@end
