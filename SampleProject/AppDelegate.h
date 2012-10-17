#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MKMapViewDelegate, SMCalloutViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

// We need a trivial concrete class that implements MKAnnotation in order to put a pin on our sample MKMapView.
@interface MapAnnotation : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString *title, *subtitle;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end
