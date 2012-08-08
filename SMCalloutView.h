#import <UIKit/UIKit.h>

enum {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};
typedef NSUInteger SMCalloutArrowDirection;

@interface SMCalloutView : UIView

@property (nonatomic, copy) NSString *title;

- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)presentCalloutFromView:(UIView *)view permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)dismissCalloutAnimated:(BOOL)animated;

@end
