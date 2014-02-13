#import "AppDelegate.h"
#import "ScrollViewController.h"
#import "MapKitComparisonController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // this tab demonstrates how to use SMCalloutView with UIScrollView
    ScrollViewController *scrollViewController = [ScrollViewController new];
    
    // this tab demonstrates how to use SMCalloutView with MKMapView
    MapKitComparisonController *mapKitController = [MapKitComparisonController new];
    
    // wrap it all up in a tab bar controller
    self.tabBarController = [UITabBarController new];
    self.tabBarController.viewControllers = @[
      [[UINavigationController alloc] initWithRootViewController:scrollViewController],
      [[UINavigationController alloc] initWithRootViewController:mapKitController]];
    
    // create the main window and display it
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
