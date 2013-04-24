#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MKMapViewDelegate, SMCalloutViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

//
// Custom subclasses for using SMCalloutView with MKMapView
//

// We need a trivial concrete class that implements MKAnnotation in order to put a pin on our sample MKMapView.
@interface MapAnnotation : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString *title, *subtitle;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end

// We need a custom subclass of MKMapView in order to allow touches on UIControls in our callout view.
@interface CustomMapView : MKMapView
@property (strong, nonatomic) SMCalloutView *calloutView;
@end
