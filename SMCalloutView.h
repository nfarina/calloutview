#import <UIKit/UIKit.h>

/*
 *
 * SMCalloutView
 * -------------
 * Created by Nick Farina (nfarina@gmail.com)
 * Version 1.1
 *
 */

@protocol SMCalloutViewDelegate;
@class SMCalloutBackgroundView;


#pragma mark - Constants

/**
 * options for which directions the callout is allowed to "point" in.
 */
typedef NS_ENUM(NSUInteger, SMCalloutArrowDirection) {
    SMCalloutArrowDirectionUp = 1UL << 0,
    SMCalloutArrowDirectionDown = 1UL << 1,
    SMCalloutArrowDirectionAny = SMCalloutArrowDirectionUp | SMCalloutArrowDirectionDown
};

/**
 * options for the callout present/dismiss animation
 */
typedef NS_ENUM(NSInteger, SMCalloutAnimation) {
    SMCalloutAnimationBounce,	// the "bounce" animation we all know and love from UIAlertView
    SMCalloutAnimationFade,		// a simple fade in or out
    SMCalloutAnimationStretch	// grow or shrink linearly, like in the iPad Calendar app
};

/**
 * when delaying our popup in order to scroll content into view, you can use this amount to match the
 * animation duration of UIScrollView when using -setContentOffset:animated.
 */
extern NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView;



#pragma mark - Callout

/**
 * The main callout view.
 */
@interface SMCalloutView : UIView

@property (nonatomic, unsafe_unretained) id<SMCalloutViewDelegate> delegate;
@property (nonatomic, copy) NSString *title, *subtitle; // title/titleView relationship mimics UINavigationBar.
@property (nonatomic, retain) UIView *leftAccessoryView, *rightAccessoryView;
@property (nonatomic, readonly) SMCalloutArrowDirection currentArrowDirection;
@property (nonatomic, retain) SMCalloutBackgroundView *backgroundView; // default is [SMCalloutDrawnBackgroundView new]

/**
 * Determines the type of callout style to draw.
 *
 * Defaults to NO on iOS 6 and below, YES on iOS 7+.
 */
@property (nonatomic, assign) BOOL shouldDrawiOS7UserInterface;

/**
 * Determies if the callout should highlight on user touch.
 *
 * Note: this only applies if shouldDrawiOS7UserInterface is YES.
 */
@property (nonatomic, assign) BOOL shouldHightlightOnTouch;

/**
 * Custom title/subtitle views.
 *
 * If these are set, the respective title/subtitle properties will be ignored.
 * Keep in mind that SMCalloutView calls -sizeThatFits on titleView/subtitleView if defined, so your view
 * may be resized as a result of that (especially if you're using UILabel/UITextField). You may want to subclass
 * and override -sizeThatFits, or just wrap your view in a "generic" UIView if you do not want it to be auto-sized.
 */
@property (nonatomic, retain) UIView *titleView, *subtitleView;

/**
 * Custom "content" view that can be any width/height. 
 *
 * If this is set, title/subtitle/titleView/subtitleView are all ignored.
 */
@property (nonatomic, retain) UIView *contentView;

/**
 * The offset in screen points from the top-middle of the annotation view, where the anchor of the callout should be shown.
 */
@property (nonatomic, assign) CGPoint calloutOffset;

/**
 * The animation style to use for presenting the callout.
 *
 * Defaults to SMCalloutAnimationBounce.
 */
@property (nonatomic, assign) SMCalloutAnimation presentAnimation;

/**
 * The animation style to use for dismissing the callout.
 *
 * Defaults to SMCalloutAnimationFade.
 */
@property (nonatomic, assign) SMCalloutAnimation dismissAnimation;

/**
 * Presents a callout view by adding it to "inView" and pointing at the given rect of inView's bounds.
 *
 * Constrains the callout to the bounds of the given view. Optionally scrolls the given rect into view (plus margins)
 * if -delegate is set and responds to -delayForRepositionWithSize.
 */
- (void)presentCalloutFromRect:(CGRect)rect
						inView:(UIView *)view
			 constrainedToView:(UIView *)constrainedView
	  permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
					  animated:(BOOL)animated;

/**
 * Same as the view-based presentation, but allows you to set the insets to use for the contrained view.
 *
 * This is mostly useful on iOS 7 where the view may extend under a navigation and/or status bar.
 */
- (void)presentCalloutFromRect:(CGRect)rect
						inView:(UIView *)view
			 constrainedToView:(UIView *)constrainedView
					withInsets:(UIEdgeInsets)constrainedInsets
	  permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
					  animated:(BOOL)animated;

/**
 * Same as the view-based presentation, but inserts the callout into a CALayer hierarchy instead. 
 *
 * Be aware that you'll have to direct your own touches to any accessory views, since CALayer doesn't relay touch events.
 */
- (void)presentCalloutFromRect:(CGRect)rect
					   inLayer:(CALayer *)layer
			constrainedToLayer:(CALayer *)constrainedLayer
	  permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
					  animated:(BOOL)animated;

/**
 * Same as the layer-based presentation, but allows you to set the insets to use for the contrained view.
 *
 * This is mostly useful on iOS 7 where the view may extend under a navigation and/or status bar.
 */
- (void)presentCalloutFromRect:(CGRect)rect
					   inLayer:(CALayer *)layer
			constrainedToLayer:(CALayer *)constrainedLayer
					withInsets:(UIEdgeInsets)constrainedInsets
	  permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
					  animated:(BOOL)animated;

/**
 * Hides the callout.
 */
- (void)dismissCalloutAnimated:(BOOL)animated;

@end


#pragma mark - Background drawing

/*
 * Classes responsible for drawing the background graphic with the pointy arrow.
 */

/**
 * Abstract base class. Added to the SMCalloutView hierarchy as the lowest view.
 */
@interface SMCalloutBackgroundView : UIView

/**
 * Indicates where the tip of the arrow should be drawn, as a pixel offset.
 */
@property (nonatomic, assign) CGPoint arrowPoint;

/**
 * Returns the standard system background composed of prerendered images.
 */
+ (SMCalloutBackgroundView *)systemBackgroundView;

/**
 * Indicates whether the background should draw its selected state.
 *
 * Note: this is only used when drawing the iOS 7 style.
 */
@property (nonatomic, assign) BOOL selected;

@end


#pragma mark

/**
 * Draws a background composed of stretched prerendered images that you can customize.
 */
@interface SMCalloutImageBackgroundView : SMCalloutBackgroundView

@property (nonatomic, retain) UIImage *leftCapImage, *rightCapImage, *topAnchorImage, *bottomAnchorImage, *backgroundImage;

@end


#pragma mark

/**
 * Draws a custom background matching the iOS 7 system background but can grow in height.
 */
@interface SMCalloutDrawnBackgroundView : SMCalloutBackgroundView
@end


#pragma mark

/**
 * Draws a custom background matching the iOS 6 system background but can grow in height.
 */
@interface SMCalloutDrawniOS6BackgroundView : SMCalloutDrawnBackgroundView
@end



#pragma mark - Delegates

@protocol SMCalloutViewDelegate <NSObject>
@optional

/**
 * Called when the callout view detects that it will be outside the constrained view when it appears,
 * or if the target rect was already outside the constrained view. 
 *
 * You can implement this selector to respond to this situation by repositioning your content first in 
 * order to make everything visible. The CGSize passed is the calculated offset necessary to make 
 * everything visible (plus a nice margin).  It expects you to return the amount of time you need to 
 * reposition things so the popup can be delayed.  Typically you would return 
 * kSMCalloutViewRepositionDelayForUIScrollView if you're repositioning by calling 
 * [UIScrollView setContentOffset:animated:].
 */
- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset;

/**
 * Called before the callout view appears on screen, or before the appearance animation will start.
 */
- (void)calloutViewWillAppear:(SMCalloutView*)calloutView;

/**
 * Called after the callout view appears on screen, or after the appearance animation is complete.
 */
- (void)calloutViewDidAppear:(SMCalloutView *)calloutView;

/**
 * Called before the callout view is removed from the screen, or before the disappearance animation is complete.
 */
- (void)calloutViewWillDisappear:(SMCalloutView*)calloutView;

/**
 * Called after the callout view is removed from the screen, or after the disappearance animation is complete.
 */
- (void)calloutViewDidDisappear:(SMCalloutView *)calloutView;

/**
 * Called after the user touches the callout view.
 *
 * Note: this is only invoked if the callout is drawn with an iOS 7 style.
 */
- (void)calloutViewWasSelected:(SMCalloutView*)calloutView;

@end
