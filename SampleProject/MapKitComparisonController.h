#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

//
// This controller demonstrates how to use SMCalloutView with MKMapView. It is a bit more complex
// than using SMCalloutView with a simple UIScrollView. We need to subclass MKMapView in order
// to provide all our features such as allowing touches on our callout.
//

@class CustomMapView;

@interface MapKitComparisonController : UIViewController <MKMapViewDelegate, SMCalloutViewDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) CustomMapView *mapKitWithSMCalloutView;
@property (nonatomic, strong) MKMapView *mapKitWithUICalloutView;
@property (nonatomic, strong) SMCalloutView *calloutView;
@property (nonatomic, strong) MKPointAnnotation *annotationForSMCalloutView, *annotationForUICalloutView;

@end
