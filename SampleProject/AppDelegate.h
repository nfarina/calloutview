#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MKMapViewDelegate, SMCalloutViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UITabBarController *tabBarController;

@end
