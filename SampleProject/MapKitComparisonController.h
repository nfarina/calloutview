#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface MapKitComparisonController : UIViewController <MKMapViewDelegate, SMCalloutViewDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) MKMapView *mapKitWithSMCalloutView, *mapKitWithUICalloutView;
@property (nonatomic, strong) SMCalloutView *calloutView;

@end
