#import <UIKit/UIKit.h>

enum {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};
typedef NSUInteger SMCalloutArrowDirection;

// when delaying our popup in order to scroll content into view, you can use this amount to match the
// animation duration of UIScrollView when using -setContentOffset:animated.
extern NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView;

@protocol SMCalloutViewDelegate;
@class SMCalloutViewBackground;

//
// Callout view.
//

@interface SMCalloutView : UIView

@property (nonatomic, unsafe_unretained) id<SMCalloutViewDelegate> delegate;
@property (nonatomic, copy) NSString *title, *subtitle; // title/titleView relationship mimics UINavigationBar.
@property (nonatomic, retain) UIView *titleView, *subtitleView; // if these are set, the respective title/subtitle properties will be ignored
@property (nonatomic, retain) UIView *leftAccessoryView, *rightAccessoryView;
@property (nonatomic, retain) SMCalloutViewBackground *background;

// calloutOffset is the offset in screen points from the top-middle of the annotation view, where the anchor of the callout should be shown.
@property (nonatomic, assign) CGPoint calloutOffset;

// Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
// Constrains the callout to the bounds of the given view. Optionally scrolls the given rect into view (plus margins)
// if -delegate is set and responds to -delayForRepositionWithSize.
- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissCalloutAnimated:(BOOL)animated;

@end

//
// Class for collating the various background images that are pieced together to form the overall background graphic with the pointy arrow.
//

@interface SMCalloutViewBackground : NSObject
@property (nonatomic, retain) UIImage *leftCapImage, *rightCapImage, *topAnchorImage, *bottomAnchorImage, *backgroundImage;
+ (SMCalloutViewBackground *)systemBackground;
@end

@protocol SMCalloutViewDelegate <NSObject>
@optional

// Called when the callout view detects that it will be outside the constrained view when it appears,
// or if the target rect was already outside the constrained view. You can implement this selector to
// respond to this situation by repositioning your content first in order to make everything visible. The
// CGSize passed is the calculated offset necessary to make everything visible (plus a nice margin).
// It expects you to return the amount of time you need to reposition things so the popup can be delayed.
// Typically you would return kSMCalloutViewRepositionDelayForUIScrollView if you're repositioning by
// calling [UIScrollView setContentOffset:animated:].
- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset;

@end