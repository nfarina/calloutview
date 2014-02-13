#import <UIKit/UIKit.h>
#import "SMCalloutView.h"

/*
 
 SMClassicCalloutView
 --------------------
 Created by Nick Farina (nfarina@gmail.com)
 Version 1.1
 
 */

@protocol SMCalloutViewDelegate;
@class SMCalloutBackgroundView;

//
// Classic Callout view.
//

@interface SMClassicCalloutView : UIView

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

@interface SMCalloutBackgroundView (SMClassicCalloutView)
+ (SMCalloutBackgroundView *)systemBackgroundView; // returns the standard pre-iOS 7 system background composed of prerendered images
@end

// Draws a background composed of stretched prerendered images that you can customize.
@interface SMCalloutImageBackgroundView : SMCalloutBackgroundView
@property (nonatomic, retain) UIImage *leftCapImage, *rightCapImage, *topAnchorImage, *bottomAnchorImage, *backgroundImage;
@end

// Draws a custom background matching the system background but can grow in height.
@interface SMCalloutDrawnBackgroundView : SMCalloutBackgroundView
@end

