#import "AppDelegate.h"
#import "MapKitComparisonController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // this tab demonstrates
    MapKitComparisonController *mapKitController = [MapKitComparisonController new];
    
    // wrap it all up in a tab bar controller
    self.tabBarController = [UITabBarController new];
    self.tabBarController.viewControllers = @[
      [[UINavigationController alloc] initWithRootViewController:mapKitController]];
    
    // create the main window and display it
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end


// Automatically loads the Reveal dynamic library if it exists and if we're running in the simulator in debug mode.

#if DEBUG && TARGET_IPHONE_SIMULATOR

#import <dlfcn.h>

// We only bother wrapping our load method in a "class" so we can implement the magic +load method that
// the Cocoa runtime calls on every class that exists in a binary.

@interface IARRevealAutoLoader : NSObject
@end

@implementation IARRevealAutoLoader

+ (void)load {
    NSString *dyLibPath = @"/Applications/Reveal.app/Contents/SharedSupport/iOS-Libraries/libReveal.dylib";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dyLibPath]) {
        
        NSLog(@"Loading dynamic library: %@", dyLibPath);
        
        void *revealLib = dlopen([dyLibPath cStringUsingEncoding:NSUTF8StringEncoding], RTLD_NOW);
        
        if (revealLib == NULL) {
            char *error = dlerror();
            NSLog(@"dlopen error: %s", error);
        }
    }
}

@end

#endif