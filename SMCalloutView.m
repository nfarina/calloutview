#import "SMCalloutView.h"
#import <QuartzCore/QuartzCore.h>

//
// UIView frame helpers - we do a lot of UIView frame fiddling in this class; these functions help keep things readable.
//

@interface UIView (SMFrameAdditions)
@property (nonatomic, assign) CGPoint $origin;
@property (nonatomic, assign) CGSize $size;
@property (nonatomic, assign) CGFloat $x, $y, $width, $height; // normal rect properties
@property (nonatomic, assign) CGFloat $left, $top, $right, $bottom; // these will stretch/shrink the rect
@end

//
// Callout View.
//

NSTimeInterval kSMCalloutViewRepositionDelayForUIScrollView = 1.0/3.0;

#define CALLOUT_MIN_WIDTH 75 // our background graphics limit us to this minimum width...
#define CALLOUT_HEIGHT 70 // ...and allow only for this exact height.
#define CALLOUT_DEFAULT_WIDTH 153 // default "I give up" width when we are asked to present in a space less than our min width
#define TITLE_MARGIN 17 // the title view's normal horizontal margin from the edges of our callout view
#define TITLE_TOP 11 // the top of the title view when no subtitle is present
#define TITLE_SUB_TOP 3 // the top of the title view when a subtitle IS present
#define TITLE_HEIGHT 22 // title height, fixed
#define SUBTITLE_TOP 25 // the top of the subtitle, when present
#define SUBTITLE_HEIGHT 16 // subtitle height, fixed
#define TITLE_ACCESSORY_MARGIN 6 // the margin between the title and an accessory if one is present (on either side)
#define ACCESSORY_MARGIN 14 // the accessory's margin from the edges of our callout view
#define ACCESSORY_TOP 8 // the top of the accessory "area" in which accessory views are placed
#define ACCESSORY_HEIGHT 32 // the "suggested" maximum height of an accessory view. shorter accessories will be vertically centered
#define BETWEEN_ACCESSORIES_MARGIN 7 // if we have no title or subtitle, but have two accessory views, then this is the space between them
#define ANCHOR_MARGIN 37 // the smallest possible distance from the edge of our control to the "tip" of the anchor, from either left or right
#define TOP_ANCHOR_MARGIN 13 // all the above measurements assume a bottom anchor! if we're pointing "up" we'll need to add this top margin to everything.
#define BOTTOM_ANCHOR_MARGIN 10 // if using a bottom anchor, we'll need to account for the shadow below the "tip"
#define CONTENT_MARGIN 10 // when we try to reposition content to be visible, we'll consider this margin around your target rect

#define TOP_SHADOW_BUFFER 2 // height offset buffer to account for top shadow
#define BOTTOM_SHADOW_BUFFER 5 // height offset buffer to account for bottom shadow
#define OFFSET_FROM_ORIGIN 5 // distance to offset vertically from the rect origin of the callout
#define ANCHOR_HEIGHT 14 // height to use for the anchor
#define ANCHOR_MARGIN_MIN 24 // the smallest possible distance from the edge of our control to the edge of the anchor, from either left or right

@implementation SMCalloutView {
    UILabel *titleLabel, *subtitleLabel;
    UIImageView *leftCap, *rightCap, *topAnchor, *bottomAnchor, *leftBackground, *rightBackground;
    SMCalloutArrowDirection arrowDirection;
    BOOL popupCancelled;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _presentAnimation = SMCalloutAnimationBounce;
        _dismissAnimation = SMCalloutAnimationFade;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (UIView *)titleViewOrDefault {
    if (self.titleView)
        // if you have a custom title view defined, return that.
        return self.titleView;
    else {
        if (!titleLabel) {
            // create a default titleView
            titleLabel = [UILabel new];
            titleLabel.$height = TITLE_HEIGHT;
            titleLabel.opaque = NO;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = [UIFont boldSystemFontOfSize:17];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
            titleLabel.shadowOffset = CGSizeMake(0, -1);
        }
        return titleLabel;
    }
}

- (UIView *)subtitleViewOrDefault {
    if (self.subtitleView)
        // if you have a custom subtitle view defined, return that.
        return self.subtitleView;
    else {
        if (!subtitleLabel) {
            // create a default subtitleView
            subtitleLabel = [UILabel new];
            subtitleLabel.$height = SUBTITLE_HEIGHT;
            subtitleLabel.opaque = NO;
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.font = [UIFont systemFontOfSize:12];
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
            subtitleLabel.shadowOffset = CGSizeMake(0, -1);
        }
        return subtitleLabel;
    }
}

- (void)rebuildSubviews {
    // remove and re-add our appropriate subviews in the appropriate order
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];  
    [self setNeedsDisplay];
    
    if (self.contentView) {
        [self addSubview:self.contentView];
    }
    else {
        if (self.titleViewOrDefault) [self addSubview:self.titleViewOrDefault];
        if (self.subtitleViewOrDefault) [self addSubview:self.subtitleViewOrDefault];
    }
    if (self.leftAccessoryView) [self addSubview:self.leftAccessoryView];
    if (self.rightAccessoryView) [self addSubview:self.rightAccessoryView];
}

- (CGFloat)innerContentMarginLeft {
    if (self.leftAccessoryView)
        return ACCESSORY_MARGIN + self.leftAccessoryView.$width + TITLE_ACCESSORY_MARGIN;
    else
        return TITLE_MARGIN;
}

- (CGFloat)innerContentMarginRight {
    if (self.rightAccessoryView)
        return ACCESSORY_MARGIN + self.rightAccessoryView.$width + TITLE_ACCESSORY_MARGIN;
    else
        return TITLE_MARGIN;
}

- (CGFloat)calloutHeight {
    CGFloat height = CALLOUT_HEIGHT;
    if (self.contentView) {
        height = self.contentView.$height + TITLE_TOP * 2;
        // account for anchor that's also part of the view
        height += ANCHOR_HEIGHT + BOTTOM_ANCHOR_MARGIN;
    }
    return height;
}

- (CGSize)sizeThatFits:(CGSize)size {
    
    // odd behavior, but mimicking the system callout view
    if (size.width < CALLOUT_MIN_WIDTH)
        return CGSizeMake(CALLOUT_DEFAULT_WIDTH, self.calloutHeight);
    
    // calculate how much non-negotiable space we need to reserve for margin and accessories
    CGFloat margin = self.innerContentMarginLeft + self.innerContentMarginRight;
    
    // how much room is left for text?
    CGFloat availableWidthForText = size.width - margin;

    // no room for text? then we'll have to squeeze into the given size somehow.
    if (availableWidthForText < 0)
        availableWidthForText = 0;

    CGSize preferredTitleSize = [self.titleViewOrDefault sizeThatFits:CGSizeMake(availableWidthForText, TITLE_HEIGHT)];
    CGSize preferredSubtitleSize = [self.subtitleViewOrDefault sizeThatFits:CGSizeMake(availableWidthForText, SUBTITLE_HEIGHT)];
    
    // total width we'd like
    CGFloat preferredWidth;
    
    if (self.contentView) {
        
        // if we have a content view, then take our preferred size directly from that
        preferredWidth = self.contentView.$width + margin;
    }
    else if (preferredTitleSize.width >= 0.000001 || preferredSubtitleSize.width >= 0.000001) {
        
        // if we have a title or subtitle, then our assumed margins are valid, and we can apply them
        preferredWidth = fmaxf(preferredTitleSize.width, preferredSubtitleSize.width) + margin;
    }
    else {
        // ok we have no title or subtitle to speak of. In this case, the system callout would actually not display
        // at all! But we can handle it.
        preferredWidth = self.leftAccessoryView.$width + self.rightAccessoryView.$width + ACCESSORY_MARGIN*2;
        
        if (self.leftAccessoryView && self.rightAccessoryView)
            preferredWidth += BETWEEN_ACCESSORIES_MARGIN;
    }
    
    // ensure we're big enough to fit our graphics!
    preferredWidth = fmaxf(preferredWidth, CALLOUT_MIN_WIDTH);
    
    // ask to be smaller if we have space, otherwise we'll fit into what we have by truncating the title/subtitle.
    return CGSizeMake(fminf(preferredWidth, size.width), self.calloutHeight);
}

- (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect {
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - CGRectGetMinX(innerRect));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - CGRectGetMaxX(innerRect));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - CGRectGetMinY(innerRect));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - CGRectGetMaxY(innerRect));
    return CGSizeMake(nudgeLeft ?: nudgeRight, nudgeTop ?: nudgeBottom);
}

- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentCalloutFromRect:rect inLayer:view.layer ofView:view constrainedToLayer:constrainedView.layer permittedArrowDirections:arrowDirections animated:animated];
}

- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    [self presentCalloutFromRect:rect inLayer:layer ofView:nil constrainedToLayer:constrainedLayer permittedArrowDirections:arrowDirections animated:animated];
}

// this private method handles both CALayer and UIView parents depending on what's passed.
- (void)presentCalloutFromRect:(CGRect)rect inLayer:(CALayer *)layer ofView:(UIView *)view constrainedToLayer:(CALayer *)constrainedLayer permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {
    
    // Sanity check: dismiss this callout immediately if it's displayed somewhere
    if (self.layer.superlayer) [self dismissCalloutAnimated:NO];

    // figure out the constrained view's rect in our popup view's coordinate system
    CGRect constrainedRect = [constrainedLayer convertRect:constrainedLayer.bounds toLayer:layer];
    
    // form our subviews based on our content set so far
    [self rebuildSubviews];
    
    // apply title/subtitle (if present
    titleLabel.text = self.title;
    subtitleLabel.text = self.subtitle;
    
    // size the callout to fit the width constraint as best as possible
    self.$size = [self sizeThatFits:CGSizeMake(constrainedRect.size.width, self.calloutHeight + 10)];
    
    // how much room do we have in the constraint box, both above and below our target rect?
    CGFloat topSpace = CGRectGetMinY(rect) - CGRectGetMinY(constrainedRect);
    CGFloat bottomSpace = CGRectGetMaxY(constrainedRect) - CGRectGetMaxY(rect);
    
    // we prefer to point our arrow down.
    SMCalloutArrowDirection bestDirection = SMCalloutArrowDirectionDown;
    
    // we'll point it up though if that's the only option you gave us.
    if (arrowDirections == SMCalloutArrowDirectionUp)
        bestDirection = SMCalloutArrowDirectionUp;
    
    // or, if we don't have enough space on the top and have more space on the bottom, and you
    // gave us a choice, then pointing up is the better option.
    if (arrowDirections == SMCalloutArrowDirectionAny && topSpace < self.calloutHeight && bottomSpace > topSpace)
        bestDirection = SMCalloutArrowDirectionUp;
    
    // show the correct anchor based on our decision
    topAnchor.hidden = (bestDirection == SMCalloutArrowDirectionDown);
    bottomAnchor.hidden = (bestDirection == SMCalloutArrowDirectionUp);
    arrowDirection = bestDirection;
    
    // we want to point directly at the horizontal center of the given rect. calculate our "anchor point" in terms of our
    // target view's coordinate system. make sure to offset the anchor point as requested if necessary.
    CGFloat anchorX = self.calloutOffset.x + CGRectGetMidX(rect);
    CGFloat anchorY = self.calloutOffset.y + (bestDirection == SMCalloutArrowDirectionDown ? CGRectGetMinY(rect) : CGRectGetMaxY(rect));
    
    // we prefer to sit in the exact center of our constrained view, so we have visually pleasing equal left/right margins.
    CGFloat calloutX = roundf(CGRectGetMidX(constrainedRect) - self.$width / 2);
    
    // what's the farthest to the left and right that we could point to, given our background image constraints?
    CGFloat minPointX = calloutX + ANCHOR_MARGIN;
    CGFloat maxPointX = calloutX + self.$width - ANCHOR_MARGIN;
    
    // we may need to scoot over to the left or right to point at the correct spot
    CGFloat adjustX = 0;
    if (anchorX < minPointX) adjustX = anchorX - minPointX;
    if (anchorX > maxPointX) adjustX = anchorX - maxPointX;
    
    // add the callout to the given layer (or view if possible, to receive touch events)
    if (view)
        [view addSubview:self];
    else
        [layer addSublayer:self.layer];
    
    CGPoint calloutOrigin = {
        .x = calloutX + adjustX,
        .y = bestDirection == SMCalloutArrowDirectionDown ? (anchorY - self.calloutHeight + BOTTOM_ANCHOR_MARGIN) : anchorY
    };
    
    self.$origin = calloutOrigin;
    
    // now set the *actual* anchor point for our layer so that our "popup" animation starts from this point.
    CGPoint anchorPoint = [layer convertPoint:CGPointMake(anchorX, anchorY) toLayer:self.layer];
    anchorPoint.x /= self.$width;
    anchorPoint.y /= self.$height;
    self.layer.anchorPoint = anchorPoint;
    
    // setting the anchor point moves the view a bit, so we need to reset
    self.$origin = calloutOrigin;
    
    // layout now so we can immediately start animating to the final position if needed
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // if we're outside the bounds of our constraint rect, we'll give our delegate an opportunity to shift us into position.
    // consider both our size and the size of our target rect (which we'll assume to be the size of the content you want to scroll into view.
    CGRect contentRect = CGRectUnion(self.frame, CGRectInset(rect, -10, -10));
    CGSize offset = [self offsetToContainRect:contentRect inRect:constrainedRect];
    
    NSTimeInterval delay = 0;
    popupCancelled = NO; // reset this before calling our delegate below
    
    if ([self.delegate respondsToSelector:@selector(calloutView:delayForRepositionWithSize:)] && !CGSizeEqualToSize(offset, CGSizeZero))
        delay = [self.delegate calloutView:self delayForRepositionWithSize:offset];
    
    // there's a chance that user code in the delegate method may have called -dismissCalloutAnimated to cancel things; if that
    // happened then we need to bail!
    if (popupCancelled) return;
    
    // if we need to delay, we don't want to be visible while we're delaying, so hide us in preparation for our popup
    self.hidden = YES;
    
    // create the appropriate animation, even if we're not animated
    CAAnimation *animation = [self animationWithType:self.presentAnimation presenting:YES];
    
    // nuke the duration if no animation requested - we'll still need to "run" the animation to get delays and callbacks
    if (!animated)
        animation.duration = 0.0000001; // can't be zero or the animation won't "run"
    
    animation.beginTime = CACurrentMediaTime() + delay;
    animation.delegate = self;
    
    [self.layer addAnimation:animation forKey:@"present"];
}

- (void)animationDidStart:(CAAnimation *)anim {
    BOOL presenting = [[anim valueForKey:@"presenting"] boolValue];

    if (presenting)
        // ok, animation is on, let's make ourselves visible!
        self.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished {
    BOOL presenting = [[anim valueForKey:@"presenting"] boolValue];
    
    if (presenting) {
        if ([_delegate respondsToSelector:@selector(calloutViewDidAppear:)])
            [_delegate calloutViewDidAppear:self];
    }
    else if (!presenting) {
        
        [self removeFromParent];
        [self.layer removeAnimationForKey:@"dismiss"];

        if ([_delegate respondsToSelector:@selector(calloutViewDidDisappear:)])
            [_delegate calloutViewDidDisappear:self];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // we want to match the system callout view, which doesn't "capture" touches outside the accessory areas. This way you can click on other pins and things *behind* a translucent callout.
    return
        [self.leftAccessoryView pointInside:[self.leftAccessoryView convertPoint:point fromView:self] withEvent:nil] ||
        [self.rightAccessoryView pointInside:[self.rightAccessoryView convertPoint:point fromView:self] withEvent:nil] ||
        [self.titleView pointInside:[self.titleView convertPoint:point fromView:self] withEvent:nil] ||
        [self.subtitleView pointInside:[self.subtitleView convertPoint:point fromView:self] withEvent:nil];
}

- (void)dismissCalloutAnimated:(BOOL)animated {
    [self.layer removeAnimationForKey:@"present"];
    
    popupCancelled = YES;
    
    if (animated) {
        CAAnimation *animation = [self animationWithType:self.dismissAnimation presenting:NO];
        animation.delegate = self;
        [self.layer addAnimation:animation forKey:@"dismiss"];
    }
    else [self removeFromParent];
}

- (void)removeFromParent {
    if (self.superview)
        [self removeFromSuperview];
    else {
        // removing a layer from a superlayer causes an implicit fade-out animation that we wish to disable.
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self.layer removeFromSuperlayer];
        [CATransaction commit];
    }
}

- (CAAnimation *)animationWithType:(SMCalloutAnimation)type presenting:(BOOL)presenting {
    CAAnimation *animation = nil;
    
    if (type == SMCalloutAnimationBounce) {
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        bounceAnimation.values = @[@0.05, @1.11245, @0.951807, @1.0];
        bounceAnimation.keyTimes = @[@0, @(4.0/9.0), @(4.0/9.0+5.0/18.0), @1.0];
        bounceAnimation.duration = 1.0/3.0; // the official bounce animation duration adds up to 0.3 seconds; but there is a bit of delay introduced by Apple using a sequence of callback-based CABasicAnimations rather than a single CAKeyframeAnimation. So we bump it up to 0.33333 to make it feel identical on the device
        bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut];
        
        if (!presenting)
            bounceAnimation.values = [[bounceAnimation.values reverseObjectEnumerator] allObjects]; // reverse values
        
        animation = bounceAnimation;
    }
    else if (type == SMCalloutAnimationFade) {
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.duration = 1.0/3.0;
        fadeAnimation.fromValue = presenting ? @0.0 : @1.0;
        fadeAnimation.toValue = presenting ? @1.0 : @0.0;
        animation = fadeAnimation;
    }
    else if (type == SMCalloutAnimationStretch) {
        CABasicAnimation *stretchAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        stretchAnimation.duration = 0.1;
        stretchAnimation.fromValue = presenting ? @0.0 : @1.0;
        stretchAnimation.toValue = presenting ? @1.0 : @0.0;
        animation = stretchAnimation;
    }
    
    // CAAnimation is KVC compliant, so we can store whether we're presenting for lookup in our delegate methods
    [animation setValue:@(presenting) forKey:@"presenting"];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    return animation;
}

- (CGFloat)centeredPositionOfView:(UIView *)view ifSmallerThan:(CGFloat)height {
    return view.$height < height ? floorf(height/2 - view.$height/2) : 0;
}

- (CGFloat)centeredPositionOfView:(UIView *)view relativeToView:(UIView *)parentView {
    return (parentView.$height - view.$height) / 2;
}

- (void)layoutSubviews {
    
    // if we're pointing up, we'll need to push almost everything down a bit
    CGFloat dy = arrowDirection == SMCalloutArrowDirectionUp ? TOP_ANCHOR_MARGIN : 0;
    
    self.titleViewOrDefault.$x = self.innerContentMarginLeft;
    self.titleViewOrDefault.$y = (self.subtitleView || self.subtitle.length ? TITLE_SUB_TOP : TITLE_TOP) + dy;
    self.titleViewOrDefault.$width = self.$width - self.innerContentMarginLeft - self.innerContentMarginRight;
    
    self.subtitleViewOrDefault.$x = self.titleViewOrDefault.$x;
    self.subtitleViewOrDefault.$y = SUBTITLE_TOP + dy;
    self.subtitleViewOrDefault.$width = self.titleViewOrDefault.$width;
    
    self.leftAccessoryView.$x = ACCESSORY_MARGIN;
    if (self.contentView)
        self.leftAccessoryView.$y = TITLE_TOP + [self centeredPositionOfView:self.leftAccessoryView relativeToView:self.contentView] + dy;
    else
        self.leftAccessoryView.$y = ACCESSORY_TOP + [self centeredPositionOfView:self.leftAccessoryView ifSmallerThan:ACCESSORY_HEIGHT] + dy;
    
    self.rightAccessoryView.$x = self.$width-ACCESSORY_MARGIN-self.rightAccessoryView.$width;
    if (self.contentView)
        self.rightAccessoryView.$y = TITLE_TOP + [self centeredPositionOfView:self.rightAccessoryView relativeToView:self.contentView] + dy;
    else
        self.rightAccessoryView.$y = ACCESSORY_TOP + [self centeredPositionOfView:self.rightAccessoryView ifSmallerThan:ACCESSORY_HEIGHT] + dy;
    
    
    if (self.contentView) {
        self.contentView.$x = self.innerContentMarginLeft;
        self.contentView.$y = TITLE_TOP + dy;
    }
}

- (void)drawRect:(CGRect)rect {
    
    // AMAZING CoreGraphics-based replica of the system callout graphics by Nicholas Shipes: https://github.com/u10int
    
    // We used to embed the system callout graphics as base64-encoded PNGs directly in this file, which was neat, but
    // that limited our control the same way as the system callout - i.e. the height was always fixed. Now we can draw
    // the callout at whatever size we want!
    
    CGSize anchorSize = CGSizeMake(27, ANCHOR_HEIGHT);
    CGFloat anchorX = roundf(self.layer.anchorPoint.x * self.$width - anchorSize.width / 2);
    CGRect anchorRect = CGRectMake(anchorX, 0, anchorSize.width, anchorSize.height);

    // make sure the anchor is not too close to the end caps
    if (anchorRect.origin.x < ANCHOR_MARGIN_MIN)
        anchorRect.origin.x = ANCHOR_MARGIN_MIN;
    
    else if (anchorRect.origin.x + anchorRect.size.width > self.$width - ANCHOR_MARGIN_MIN)
        anchorRect.origin.x = self.$width - anchorRect.size.width - ANCHOR_MARGIN_MIN;
    
    // determine size
    CGFloat stroke = 1.0;
    CGFloat radius = [UIScreen mainScreen].scale == 1 ? 4.5 : 6.0;
    
    rect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + TOP_SHADOW_BUFFER, self.bounds.size.width, self.bounds.size.height - ANCHOR_HEIGHT);
    rect.size.width -= stroke + 14;
    rect.size.height -= stroke * 2 + TOP_SHADOW_BUFFER + BOTTOM_SHADOW_BUFFER + OFFSET_FROM_ORIGIN;
    rect.origin.x += stroke / 2.0 + 7;
    rect.origin.y += (arrowDirection == SMCalloutArrowDirectionUp) ? ANCHOR_HEIGHT - stroke / 2.0 : stroke / 2.0;
    
    
    // General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Color Declarations
    UIColor* fillBlack = [UIColor colorWithRed: 0.11 green: 0.11 blue: 0.11 alpha: 1];
    UIColor* shadowBlack = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.47];
    UIColor* glossBottom = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.2];
    UIColor* glossTop = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.85];
    UIColor* strokeColor = [UIColor colorWithRed: 0.199 green: 0.199 blue: 0.199 alpha: 1];
    UIColor* innerShadowColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.4];
    UIColor* innerStrokeColor = [UIColor colorWithRed: 0.821 green: 0.821 blue: 0.821 alpha: 0.04];
    UIColor* outerStrokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.35];
    
    // Gradient Declarations
    NSArray* glossFillColors = [NSArray arrayWithObjects:
                                (id)glossBottom.CGColor,
                                (id)glossTop.CGColor, nil];
    CGFloat glossFillLocations[] = {0, 1};
    CGGradientRef glossFill = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)glossFillColors, glossFillLocations);
    
    // Shadow Declarations
    UIColor* baseShadow = shadowBlack;
    CGSize baseShadowOffset = CGSizeMake(0.1, 6.1);
    CGFloat baseShadowBlurRadius = 6;
    UIColor* innerShadow = innerShadowColor;
    CGSize innerShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat innerShadowBlurRadius = 1;
    
    CGFloat backgroundStrokeWidth = 1;
    CGFloat outerStrokeStrokeWidth = 1;
    
    // Frames
    CGRect frame = rect;
    CGRect innerFrame = CGRectMake(frame.origin.x + backgroundStrokeWidth, frame.origin.y + backgroundStrokeWidth, frame.size.width - backgroundStrokeWidth * 2, frame.size.height - backgroundStrokeWidth * 2);
    CGRect glossFrame = CGRectMake(frame.origin.x - backgroundStrokeWidth / 2, frame.origin.y - backgroundStrokeWidth / 2, frame.size.width + backgroundStrokeWidth, frame.size.height / 2 + backgroundStrokeWidth + 0.5);
    
    //// CoreGroup ////
    {
        CGContextSaveGState(context);
        CGContextSetAlpha(context, 0.83);
        CGContextBeginTransparencyLayer(context, NULL);
        
        // Background Drawing
        UIBezierPath* backgroundPath = [UIBezierPath bezierPath];
        [backgroundPath moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - radius)]; // left
        [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI endAngle:M_PI / 2 clockwise:NO]; // bottom-left corner
        
        // pointer down
        if (arrowDirection == SMCalloutArrowDirectionDown) {
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMaxY(frame))];
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMaxY(frame) + anchorRect.size.height)];
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMaxY(frame))];
        }
        
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame))]; // bottom
        [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI / 2 endAngle:0.0f clockwise:NO]; // bottom-right corner
        [backgroundPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame) + radius)]; // right
        [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:0.0f endAngle:-M_PI / 2 clockwise:NO]; // top-right corner
        
        // pointer up
        if (arrowDirection == SMCalloutArrowDirectionUp) {
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMinY(frame))];
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMinY(frame) - anchorRect.size.height)];
            [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMinY(frame))];
        }
        
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame))]; // top
        [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:-M_PI / 2 endAngle:M_PI clockwise:NO]; // top-left corner
        [backgroundPath closePath];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, baseShadowOffset, baseShadowBlurRadius, baseShadow.CGColor);
        [fillBlack setFill];
        [backgroundPath fill];
        
        // Background Inner Shadow
        CGRect backgroundBorderRect = CGRectInset([backgroundPath bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
        backgroundBorderRect = CGRectOffset(backgroundBorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
        backgroundBorderRect = CGRectInset(CGRectUnion(backgroundBorderRect, [backgroundPath bounds]), -1, -1);
        
        UIBezierPath* backgroundNegativePath = [UIBezierPath bezierPathWithRect: backgroundBorderRect];
        [backgroundNegativePath appendPath: backgroundPath];
        backgroundNegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            CGFloat xOffset = innerShadowOffset.width + round(backgroundBorderRect.size.width);
            CGFloat yOffset = innerShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        innerShadowBlurRadius,
                                        innerShadow.CGColor);
            
            [backgroundPath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(backgroundBorderRect.size.width), 0);
            [backgroundNegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [backgroundNegativePath fill];
        }
        CGContextRestoreGState(context);
        
        CGContextRestoreGState(context);
        
        [strokeColor setStroke];
        backgroundPath.lineWidth = backgroundStrokeWidth;
        [backgroundPath stroke];
        
        
        // Inner Stroke Drawing
        CGFloat innerRadius = radius - 1.0;
        CGRect anchorInnerRect = anchorRect;
        anchorInnerRect.origin.x += backgroundStrokeWidth / 2;
        anchorInnerRect.origin.y -= backgroundStrokeWidth / 2;
        anchorInnerRect.size.width -= backgroundStrokeWidth;
        anchorInnerRect.size.height -= backgroundStrokeWidth / 2;
        
        UIBezierPath* innerStrokePath = [UIBezierPath bezierPath];
        [innerStrokePath moveToPoint:CGPointMake(CGRectGetMinX(innerFrame), CGRectGetMinY(innerFrame) + innerRadius)];
        [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(innerFrame), CGRectGetMaxY(innerFrame) - innerRadius)]; // left
        [innerStrokePath addArcWithCenter:CGPointMake(CGRectGetMinX(innerFrame) + innerRadius, CGRectGetMaxY(innerFrame) - innerRadius) radius:innerRadius startAngle:M_PI endAngle:M_PI / 2 clockwise:NO]; // bottom-left corner
        
        // pointer down
        if (arrowDirection == SMCalloutArrowDirectionDown) {
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorInnerRect), CGRectGetMaxY(innerFrame))];
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorInnerRect) + anchorInnerRect.size.width / 2, CGRectGetMaxY(innerFrame) + anchorInnerRect.size.height)];
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorInnerRect), CGRectGetMaxY(innerFrame))];
        }
        
        [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(innerFrame) - innerRadius, CGRectGetMaxY(innerFrame))]; // bottom
        [innerStrokePath addArcWithCenter:CGPointMake(CGRectGetMaxX(innerFrame) - innerRadius, CGRectGetMaxY(innerFrame) - innerRadius) radius:innerRadius startAngle:M_PI / 2 endAngle:0.0f clockwise:NO]; // bottom-right corner
        [innerStrokePath addLineToPoint: CGPointMake(CGRectGetMaxX(innerFrame), CGRectGetMinY(innerFrame) + innerRadius)]; // right
        [innerStrokePath addArcWithCenter:CGPointMake(CGRectGetMaxX(innerFrame) - innerRadius, CGRectGetMinY(innerFrame) + innerRadius) radius:innerRadius startAngle:0.0f endAngle:-M_PI / 2 clockwise:NO]; // top-right corner
        
        // pointer up
        if (arrowDirection == SMCalloutArrowDirectionUp) {
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorInnerRect), CGRectGetMinY(innerFrame))];
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorInnerRect) + anchorRect.size.width / 2, CGRectGetMinY(innerFrame) - anchorInnerRect.size.height)];
            [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorInnerRect), CGRectGetMinY(innerFrame))];
        }
        
        [innerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(innerFrame) + innerRadius, CGRectGetMinY(innerFrame))]; // top
        [innerStrokePath addArcWithCenter:CGPointMake(CGRectGetMinX(innerFrame) + innerRadius, CGRectGetMinY(innerFrame) + innerRadius) radius:innerRadius startAngle:-M_PI / 2 endAngle:M_PI clockwise:NO]; // top-left corner
        [innerStrokePath closePath];
        
        [innerStrokeColor setStroke];
        innerStrokePath.lineWidth = backgroundStrokeWidth;
        [innerStrokePath stroke];
        
        
        //// GlossGroup ////
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, 0.45);
            CGContextBeginTransparencyLayer(context, NULL);
            
            CGFloat glossRadius = radius + 0.5;
            
            // Gloss Drawing
            UIBezierPath* glossPath = [UIBezierPath bezierPath];
            [glossPath moveToPoint:CGPointMake(CGRectGetMinX(glossFrame), CGRectGetMinY(glossFrame))];
            [glossPath addLineToPoint:CGPointMake(CGRectGetMinX(glossFrame), CGRectGetMaxY(glossFrame) - glossRadius)]; // left
            [glossPath addArcWithCenter:CGPointMake(CGRectGetMinX(glossFrame) + glossRadius, CGRectGetMaxY(glossFrame) - glossRadius) radius:glossRadius startAngle:M_PI endAngle:M_PI / 2 clockwise:NO]; // bottom-left corner
            [glossPath addLineToPoint:CGPointMake(CGRectGetMaxX(glossFrame) - glossRadius, CGRectGetMaxY(glossFrame))]; // bottom
            [glossPath addArcWithCenter:CGPointMake(CGRectGetMaxX(glossFrame) - glossRadius, CGRectGetMaxY(glossFrame) - glossRadius) radius:glossRadius startAngle:M_PI / 2 endAngle:0.0f clockwise:NO]; // bottom-right corner
            [glossPath addLineToPoint: CGPointMake(CGRectGetMaxX(glossFrame), CGRectGetMinY(glossFrame) - glossRadius)]; // right
            [glossPath addArcWithCenter:CGPointMake(CGRectGetMaxX(glossFrame) - glossRadius, CGRectGetMinY(glossFrame) + glossRadius) radius:glossRadius startAngle:0.0f endAngle:-M_PI / 2 clockwise:NO]; // top-right corner
            
            // pointer up
            if (arrowDirection == SMCalloutArrowDirectionUp) {
                [glossPath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMinY(glossFrame))];
                [glossPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + roundf(anchorRect.size.width / 2), CGRectGetMinY(glossFrame) - anchorRect.size.height)];
                [glossPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMinY(glossFrame))];
            }
            
            [glossPath addLineToPoint:CGPointMake(CGRectGetMinX(glossFrame) + glossRadius, CGRectGetMinY(glossFrame))]; // top
            [glossPath addArcWithCenter:CGPointMake(CGRectGetMinX(glossFrame) + glossRadius, CGRectGetMinY(glossFrame) + glossRadius) radius:glossRadius startAngle:-M_PI / 2 endAngle:M_PI clockwise:NO]; // top-left corner
            [glossPath closePath];
            
            CGContextSaveGState(context);
            [glossPath addClip];
            CGRect glossBounds = glossPath.bounds;
            CGContextDrawLinearGradient(context, glossFill,
                                        CGPointMake(CGRectGetMidX(glossBounds), CGRectGetMaxY(glossBounds)),
                                        CGPointMake(CGRectGetMidX(glossBounds), CGRectGetMinY(glossBounds)),
                                        0);
            CGContextRestoreGState(context);
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    // Outer Stroke Drawing
    UIBezierPath* outerStrokePath = [UIBezierPath bezierPath];
    [outerStrokePath moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];
    [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - radius)]; // left
    [outerStrokePath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI endAngle:M_PI / 2 clockwise:NO]; // bottom-left corner
    
    // pointer down
    if (arrowDirection == SMCalloutArrowDirectionDown) {
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMaxY(frame))];
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMaxY(frame) + anchorRect.size.height)];
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMaxY(frame))];
    }
    
    [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame))]; // bottom
    [outerStrokePath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI / 2 endAngle:0.0f clockwise:NO]; // bottom-right corner
    [outerStrokePath addLineToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame) + radius)]; // right
    [outerStrokePath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:0.0f endAngle:-M_PI / 2 clockwise:NO]; // top-right corner
    
    // pointer up
    if (arrowDirection == SMCalloutArrowDirectionUp) {
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMinY(frame))];
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMinY(frame) - anchorRect.size.height)];
        [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMinY(frame))];
    }
    
    [outerStrokePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame))]; // top
    [outerStrokePath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:-M_PI / 2 endAngle:M_PI clockwise:NO]; // top-left corner
    [outerStrokePath closePath];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, baseShadowOffset, baseShadowBlurRadius, baseShadow.CGColor);
    CGContextRestoreGState(context);
    
    [outerStrokeColor setStroke];
    outerStrokePath.lineWidth = outerStrokeStrokeWidth;
    [outerStrokePath stroke];
    
    //// Cleanup
    CGGradientRelease(glossFill);
    CGColorSpaceRelease(colorSpace);
}

@end

//
// Our UIView frame helpers implementation
//

@implementation UIView (SMFrameAdditions)

- (CGPoint)$origin { return self.frame.origin; }
- (void)set$origin:(CGPoint)origin { self.frame = (CGRect){ .origin=origin, .size=self.frame.size }; }

- (CGFloat)$x { return self.frame.origin.x; }
- (void)set$x:(CGFloat)x { self.frame = (CGRect){ .origin.x=x, .origin.y=self.frame.origin.y, .size=self.frame.size }; }

- (CGFloat)$y { return self.frame.origin.y; }
- (void)set$y:(CGFloat)y { self.frame = (CGRect){ .origin.x=self.frame.origin.x, .origin.y=y, .size=self.frame.size }; }

- (CGSize)$size { return self.frame.size; }
- (void)set$size:(CGSize)size { self.frame = (CGRect){ .origin=self.frame.origin, .size=size }; }

- (CGFloat)$width { return self.frame.size.width; }
- (void)set$width:(CGFloat)width { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=width, .size.height=self.frame.size.height }; }

- (CGFloat)$height { return self.frame.size.height; }
- (void)set$height:(CGFloat)height { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=self.frame.size.width, .size.height=height }; }

- (CGFloat)$left { return self.frame.origin.x; }
- (void)set$left:(CGFloat)left { self.frame = (CGRect){ .origin.x=left, .origin.y=self.frame.origin.y, .size.width=fmaxf(self.frame.origin.x+self.frame.size.width-left,0), .size.height=self.frame.size.height }; }

- (CGFloat)$top { return self.frame.origin.y; }
- (void)set$top:(CGFloat)top { self.frame = (CGRect){ .origin.x=self.frame.origin.x, .origin.y=top, .size.width=self.frame.size.width, .size.height=fmaxf(self.frame.origin.y+self.frame.size.height-top,0) }; }

- (CGFloat)$right { return self.frame.origin.x + self.frame.size.width; }
- (void)set$right:(CGFloat)right { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=fmaxf(right-self.frame.origin.x,0), .size.height=self.frame.size.height }; }

- (CGFloat)$bottom { return self.frame.origin.y + self.frame.size.height; }
- (void)set$bottom:(CGFloat)bottom { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=self.frame.size.width, .size.height=fmaxf(bottom-self.frame.origin.y,0) }; }

@end
