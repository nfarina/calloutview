#import <UIKit/UIKit.h>

enum {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};
typedef NSUInteger SMCalloutArrowDirection;

@interface SMCalloutView : UIView

@property (nonatomic, copy) NSString *title, *subtitle;
@property (nonatomic, retain) UIView *leftAccessoryView, *rightAccessoryView;

// Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
// Constrains the callout to the given rect, also in the coordinate system of inView.
- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToRect:(CGRect)constrainedRect permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissCalloutAnimated:(BOOL)animated;

@end
