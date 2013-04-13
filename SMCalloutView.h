#import <UIKit/UIKit.h>

/*

SMCalloutView
-------------
Created by Nick Farina (nfarina@gmail.com)
Version 1.1

*/

// options for which directions the callout is allowed to "point" in.
enum {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};
typedef NSUInteger SMCalloutArrowDirection;

// options for the callout present/dismiss animation
enum {
    SMCalloutAnimationBounce, // the "bounce" animation we all know and love from UIAlertView
    SMCalloutAnimationFade, // a simple fade in or out
    SMCalloutAnimationStretch // grow or shrink linearly, like in the iPad Calendar app
};
typedef NSInteger SMCalloutAnimation;

// when delaying our popup in order to scroll content into view, you can use this amount to match the
// animation duration of UIScrollView when using -setContentOffset:animated.
extern NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView;

@protocol SMCalloutViewDelegate;
@class SMCalloutBackgroundView;

//
// Callout view.
//

@interface SMCalloutView : UIView

@property (nonatomic, unsafe_unretained) id<SMCalloutViewDelegate> delegate;
@property (nonatomic, copy) NSString *title, *subtitle; // title/titleView relationship mimics UINavigationBar.
@property (nonatomic, retain) UIView *leftAccessoryView, *rightAccessoryView;
@property (nonatomic, readonly) SMCalloutArrowDirection currentArrowDirection;
@property (nonatomic, retain) SMCalloutBackgroundView *backgroundView; // default is [SMCalloutDrawnBackgroundView new]

// Custom title/subtitle views. if these are set, the respective title/subtitle properties will be ignored.
// Keep in mind that SMCalloutView calls -sizeThatFits on titleView/subtitleView if defined, so your view
// may be resized as a result of that (especially if you're using UILabel/UITextField). You may want to subclass
// and override -sizeThatFits, or just wrap your view in a "generic" UIView if you do not want it to be auto-sized.
@property (nonatomic, retain) UIView *titleView, *subtitleView;

// Custom "content" view that can be any width/height. If this is set, title/subtitle/titleView/subtitleView are all ignored.
@property (nonatomic, retain) UIView *contentView;

// calloutOffset is the offset in screen points from the top-middle of the annotation view, where the anchor of the callout should be shown.
@property (nonatomic, assign) CGPoint calloutOffset;

@property (nonatomic, assign) SMCalloutAnimation presentAnimation, dismissAnimation; // default SMCalloutAnimationBounce, SMCalloutAnimationFade respectively

// Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
// Constrains the callout to the bounds of the given view. Optionally scrolls the given rect into view (plus margins)
// if -delegate is set and responds to -delayForRepositionWithSize.
- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

// Same as the view-based presentation, but inserts the callout into a CALayer hierarchy instead. Be aware that you'll have to direct
// your own touches to any accessory views, since CALayer doesn't relay touch events.
- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissCalloutAnimated:(BOOL)animated;

@end

//
// Classes responsible for drawing the background graphic with the pointy arrow.
//

// Abstract base class. Added to the SMCalloutView hierarchy as the lowest view.
@interface SMCalloutBackgroundView : UIView
@property (nonatomic, assign) CGPoint arrowPoint; // indicates where the tip of the arrow should be drawn, as a pixel offset
+ (SMCalloutBackgroundView *)systemBackgroundView; // returns the standard system background composed of prerendered images
@end

// Draws a background composed of stretched prerendered images that you can customize.
@interface SMCalloutImageBackgroundView : SMCalloutBackgroundView
@property (nonatomic, retain) UIImage *leftCapImage, *rightCapImage, *topAnchorImage, *bottomAnchorImage, *backgroundImage;
@end

// Draws a custom background matching the system background but can grow in height.
@interface SMCalloutDrawnBackgroundView : SMCalloutBackgroundView
@end

//
// Delegate methods
//

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

// Called before the callout view appears on screen, or before the appearance animation will start.
- (void)calloutViewWillAppear:(SMCalloutView*)calloutView;

// Called after the callout view appears on screen, or after the appearance animation is complete.
- (void)calloutViewDidAppear:(SMCalloutView *)calloutView;

// Called before the callout view is removed from the screen, or before the disappearance animation is complete.
- (void)calloutViewWillDisappear:(SMCalloutView*)calloutView;

// Called after the callout view is removed from the screen, or after the disappearance animation is complete.
- (void)calloutViewDidDisappear:(SMCalloutView *)calloutView;

@end
