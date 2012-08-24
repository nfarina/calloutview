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
#define ANCHOR_MARGIN 37 // the smallest possible distance from the edge of our control to the "tip" of the anchor, from either left or right
#define TOP_ANCHOR_MARGIN 13 // all the above measurements assume a bottom anchor! if we're pointing "up" we'll need to add this top margin to everything.
#define BOTTOM_ANCHOR_MARGIN 10 // if using a bottom anchor, we'll need to account for the shadow below the "tip"
#define CONTENT_MARGIN 10 // when we try to reposition content to be visible, we'll consider this margin around your target rect
#define BOUNCE_ANIMATION_DURATION (1.0/3.0) // the official bounce animation duration adds up to 0.3 seconds; but there is a bit of delay introduced by Apple using a sequence of callback-based CABasicAnimations rather than a single CAKeyframeAnimation. So we bump it up to 0.33333 to make it feel identical on the device.

@implementation SMCalloutView {
    UILabel *titleLabel, *subtitleLabel;
    UIImageView *leftCap, *rightCap, *topAnchor, *bottomAnchor, *leftBackground, *rightBackground;
    BOOL popupCancelled;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        leftCap = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 17, 57)];
        rightCap = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 17, 57)];
        topAnchor = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 41, 70)];
        bottomAnchor = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 41, 70)];
        leftBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1, 57)];
        rightBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1, 57)];
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

- (SMCalloutViewBackground *)background {
    // create our default background on first access only if it's nil, since you might have set your own background anyway.
    return _background ?: (_background = [SMCalloutViewBackground systemBackground]);
}

- (void)rebuildSubviews {
    // remove and re-add our appropriate subviews in the appropriate order
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self addSubview:leftCap];
    [self addSubview:rightCap];
    [self addSubview:topAnchor];
    [self addSubview:bottomAnchor];
    [self addSubview:leftBackground];
    [self addSubview:rightBackground];
    if (self.titleViewOrDefault) [self addSubview:self.titleViewOrDefault];
    if (self.subtitleViewOrDefault) [self addSubview:self.subtitleViewOrDefault];
    if (self.leftAccessoryView) [self addSubview:self.leftAccessoryView];
    if (self.rightAccessoryView) [self addSubview:self.rightAccessoryView];
}

- (CGFloat)titleMarginLeft {
    if (self.leftAccessoryView)
        return ACCESSORY_MARGIN + self.leftAccessoryView.$width + TITLE_ACCESSORY_MARGIN;
    else
        return TITLE_MARGIN;
}

- (CGFloat)titleMarginRight {
    if (self.rightAccessoryView)
        return ACCESSORY_MARGIN + self.rightAccessoryView.$width + TITLE_ACCESSORY_MARGIN;
    else
        return TITLE_MARGIN;
}

- (CGSize)sizeThatFits:(CGSize)size {
    
    // odd behavior, but mimicking UICalloutView
    if (size.width < CALLOUT_MIN_WIDTH)
        return CGSizeMake(CALLOUT_DEFAULT_WIDTH, CALLOUT_HEIGHT);
    
    // calculate how much non-negotiable space we need to reserve for margin and accessories
    CGFloat margin = self.titleMarginLeft + self.titleMarginRight;
    
    // how much room is left for text?
    CGFloat availableWidthForText = size.width - margin;

    // no room for text? then we'll have to squeeze into the given size somehow.
    if (availableWidthForText < 0)
        availableWidthForText = 0;

    CGSize preferredTitleSize = [self.titleViewOrDefault sizeThatFits:CGSizeMake(availableWidthForText, TITLE_HEIGHT)];
    CGSize preferredSubtitleSize = [self.subtitleViewOrDefault sizeThatFits:CGSizeMake(availableWidthForText, SUBTITLE_HEIGHT)];
    
    // total width we'd like
    CGFloat preferredWidth = fmaxf(preferredTitleSize.width, preferredSubtitleSize.width) + margin;
    
    // ask to be smaller if we have space, otherwise we'll fit into what we have by truncating the title/subtitle.
    return CGSizeMake(fminf(preferredWidth, size.width), CALLOUT_HEIGHT);
}

- (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect {
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - CGRectGetMinX(innerRect));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - CGRectGetMaxX(innerRect));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - CGRectGetMinY(innerRect));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - CGRectGetMaxY(innerRect));
    return CGSizeMake(nudgeLeft ?: nudgeRight, nudgeTop ?: nudgeBottom);
}

- (void)presentCalloutFromRect:(CGRect)rect inView:(UIView *)view constrainedToView:(UIView *)constrainedView permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections animated:(BOOL)animated {

    // figure out the constrained view's rect in our popup view's coordinate system
    CGRect constrainedRect = [constrainedView convertRect:constrainedView.bounds toView:view];

    // form our subviews based on our content set so far
    [self rebuildSubviews];
    
    // apply title/subtitle (if present
    titleLabel.text = self.title;
    subtitleLabel.text = self.subtitle;
        
    // size the callout to fit the width constraint as best as possible
    self.$size = [self sizeThatFits:CGSizeMake(constrainedRect.size.width, CALLOUT_HEIGHT)];
    
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
    if (arrowDirections == SMCalloutArrowDirectionAny && topSpace < CALLOUT_HEIGHT && bottomSpace > topSpace)
        bestDirection = SMCalloutArrowDirectionUp;

    // show the correct anchor based on our decision
    topAnchor.hidden = (bestDirection == SMCalloutArrowDirectionDown);
    bottomAnchor.hidden = (bestDirection == SMCalloutArrowDirectionUp);
    
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

    // add the callout to the given view
    [view addSubview:self];

    CGPoint calloutOrigin = {
        .x = calloutX + adjustX,
        .y = bestDirection == SMCalloutArrowDirectionDown ? (anchorY - CALLOUT_HEIGHT + BOTTOM_ANCHOR_MARGIN) : anchorY
    };
    
    self.$origin = calloutOrigin;
    
    // now set the *actual* anchor point for our layer so that our "popup" animation starts from this point.
    CGPoint anchorPoint = [view convertPoint:CGPointMake(anchorX, anchorY) toView:self];
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
    
    self.alpha = 1; // in case it's zero from fading out in -dismissCalloutAnimated
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    bounceAnimation.beginTime = CACurrentMediaTime() + delay;
    bounceAnimation.values = @[@0.05, @1.11245, @0.951807, @1.0];
    bounceAnimation.keyTimes = @[@0, @(4.0/9.0), @(4.0/9.0+5.0/18.0), @1.0];
    bounceAnimation.duration = animated ? BOUNCE_ANIMATION_DURATION : 0;
    bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut];
    bounceAnimation.delegate = self;
    
    [self.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)animationDidStart:(CAAnimation *)anim {
    // ok, animation is on, let's make ourselves visible!
    self.hidden = NO;
}

- (void)dismissCalloutAnimated:(BOOL)animated {
    [self.layer removeAnimationForKey:@"bounce"];
    
    popupCancelled = YES;
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.0/3.0];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        self.alpha = 0;
        [UIView commitAnimations];
    }
    else [self removeFromSuperview];
}

- (CGFloat)centeredPositionOfView:(UIView *)view ifSmallerThan:(CGFloat)height {
    return view.$height < height ? floorf(height/2 - view.$height/2) : 0;
}

- (void)layoutSubviews {

    // apply our background graphics
    leftCap.image = self.background.leftCapImage;
    rightCap.image = self.background.rightCapImage;
    topAnchor.image = self.background.topAnchorImage;
    bottomAnchor.image = self.background.bottomAnchorImage;
    leftBackground.image = self.background.backgroundImage;
    rightBackground.image = self.background.backgroundImage;
    
    // if we're pointing up, we'll need to push almost everything down a bit
    CGFloat dy = !topAnchor.hidden ? TOP_ANCHOR_MARGIN : 0;
    leftCap.$y = rightCap.$y = leftBackground.$y = rightBackground.$y = dy;
    
    leftCap.$x = 0;
    rightCap.$x = self.$width - rightCap.$width;
    
    // move both anchors, only one will have been made visible in our -popup method
    CGFloat anchorX = roundf(self.layer.anchorPoint.x * self.$width - bottomAnchor.$width / 2);
    topAnchor.$origin = CGPointMake(anchorX, 0);
    
    // make sure the anchor graphic isn't overlapping with an endcap
    if (topAnchor.$left < leftCap.$right) topAnchor.$x = leftCap.$right;
    if (topAnchor.$right > rightCap.$left) topAnchor.$x = rightCap.$left - topAnchor.$width; // don't stretch it

    bottomAnchor.$origin = topAnchor.$origin; // match

    leftBackground.$left = leftCap.$right;
    leftBackground.$right = topAnchor.$left;
    rightBackground.$left = topAnchor.$right;
    rightBackground.$right = rightCap.$left;
    
    self.titleViewOrDefault.$x = self.titleMarginLeft;
    self.titleViewOrDefault.$y = (self.subtitleView || self.subtitle.length ? TITLE_SUB_TOP : TITLE_TOP) + dy;
    self.titleViewOrDefault.$width = self.$width - self.titleMarginLeft - self.titleMarginRight;
    
    self.subtitleViewOrDefault.$x = self.titleViewOrDefault.$x;
    self.subtitleViewOrDefault.$y = SUBTITLE_TOP + dy;
    self.subtitleViewOrDefault.$width = self.titleViewOrDefault.$width;
    
    self.leftAccessoryView.$x = ACCESSORY_MARGIN;
    self.leftAccessoryView.$y = ACCESSORY_TOP + [self centeredPositionOfView:self.leftAccessoryView ifSmallerThan:ACCESSORY_HEIGHT] + dy;
    
    self.rightAccessoryView.$x = self.$width-ACCESSORY_MARGIN-self.rightAccessoryView.$width;
    self.rightAccessoryView.$y = ACCESSORY_TOP + [self centeredPositionOfView:self.rightAccessoryView ifSmallerThan:ACCESSORY_HEIGHT] + dy;
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

//
// Callout View background.
//

@implementation SMCalloutViewBackground

+ (SMCalloutViewBackground *)systemBackground {
    SMCalloutViewBackground *background = [SMCalloutViewBackground new];
    background.leftCapImage = [self embeddedImageNamed:@"UICalloutViewLeftCap"];
    background.rightCapImage = [self embeddedImageNamed:@"UICalloutViewRightCap"];
    background.topAnchorImage = [self embeddedImageNamed:@"UICalloutViewTopAnchor"];
    background.bottomAnchorImage = [self embeddedImageNamed:@"UICalloutViewBottomAnchor"];
    background.backgroundImage = [self embeddedImageNamed:@"UICalloutViewBackground"];
    return background;
}

+ (NSData *)dataWithBase64EncodedString:(NSString *)string {
    //
    //  NSData+Base64.m
    //
    //  Version 1.0.2
    //
    //  Created by Nick Lockwood on 12/01/2012.
    //  Copyright (C) 2012 Charcoal Design
    //
    //  Distributed under the permissive zlib License
    //  Get the latest version from here:
    //
    //  https://github.com/nicklockwood/Base64
    //
    //  This software is provided 'as-is', without any express or implied
    //  warranty.  In no event will the authors be held liable for any damages
    //  arising from the use of this software.
    //
    //  Permission is granted to anyone to use this software for any purpose,
    //  including commercial applications, and to alter it and redistribute it
    //  freely, subject to the following restrictions:
    //
    //  1. The origin of this software must not be misrepresented; you must not
    //  claim that you wrote the original software. If you use this software
    //  in a product, an acknowledgment in the product documentation would be
    //  appreciated but is not required.
    //
    //  2. Altered source versions must be plainly marked as such, and must not be
    //  misrepresented as being the original software.
    //
    //  3. This notice may not be removed or altered from any source distribution.
    //
    const char lookup[] = {
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 62, 99, 99, 99, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 99, 99, 99, 99, 99, 99,
        99,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 99, 99, 99, 99, 99,
        99, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 99, 99, 99, 99, 99
    };
    
    NSData *inputData = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    long long inputLength = [inputData length];
    const unsigned char *inputBytes = [inputData bytes];
    
    long long maxOutputLength = (inputLength / 4 + 1) * 3;
    NSMutableData *outputData = [NSMutableData dataWithLength:maxOutputLength];
    unsigned char *outputBytes = (unsigned char *)[outputData mutableBytes];
    
    int accumulator = 0;
    long long outputLength = 0;
    unsigned char accumulated[] = {0, 0, 0, 0};
    for (long long i = 0; i < inputLength; i++) {
        unsigned char decoded = lookup[inputBytes[i] & 0x7F];
        if (decoded != 99) {
            accumulated[accumulator] = decoded;
            if (accumulator == 3) {
                outputBytes[outputLength++] = (accumulated[0] << 2) | (accumulated[1] >> 4);
                outputBytes[outputLength++] = (accumulated[1] << 4) | (accumulated[2] >> 2);
                outputBytes[outputLength++] = (accumulated[2] << 6) | accumulated[3];
            }
            accumulator = (accumulator + 1) % 4;
        }
    }
    
    //handle left-over data
    if (accumulator > 0) outputBytes[outputLength] = (accumulated[0] << 2) | (accumulated[1] >> 4);
        if (accumulator > 1) outputBytes[++outputLength] = (accumulated[1] << 4) | (accumulated[2] >> 2);
            if (accumulator > 2) outputLength++;
    
    //truncate data to match actual output length
    outputData.length = outputLength;
    return outputLength? outputData: nil;
}

+ (UIImage *)embeddedImageNamed:(NSString *)name {
    if ([UIScreen mainScreen].scale == 2)
        name = [name stringByAppendingString:@"$2x"];
    
    SEL selector = NSSelectorFromString(name);
    
    if (![(id)self respondsToSelector:selector]) {
        NSLog(@"Could not find an embedded image. Ensure that you've added a category method to UIImage named +%@", name);
        return nil;
    }
    
    // We need to hush the compiler here - but we know what we're doing!
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *base64String = [(id)self performSelector:selector];
    #pragma clang diagnostic pop
    
    UIImage *rawImage = [UIImage imageWithData:[self dataWithBase64EncodedString:base64String]];
    return [UIImage imageWithCGImage:rawImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
}

//
// I didn't want this class to require adding any images to your Xcode project. So instead the images needed are embedded below.
// These images were extracted using the amazing UIKit-Artwork-Extractor by @0xced: https://github.com/0xced/UIKit-Artwork-Extractor/
//

+ (NSString *)UICalloutViewLeftCap { return @"iVBORw0KGgoAAAANSUhEUgAAABEAAAA5CAYAAADQksChAAAAHGlET1QAAAACAAAAAAAAAB0AAAAoAAAAHQAAABwAAAKS6krCNQAAAl5JREFUSA2klNmKGkEUhs0yM9nIglnctQc3zKioqOCKwQVXFBRUcLnxwvtci88gPkpeIlATEshVSM2rmP9UUo3dajuQi49TVX3OZ3mquk273c50DpPJ9OAID7H2l2MCXYFMfoT1xzouML842MU/gabQ4XAUo9Ho10KhcFcqlbgejWRPIH/10ul0fq7X67/X6/X3zWZzu91umR5VohPQNq/MZvOndrv9a7VafVssFmw+n7PZbKYi50JyTIC1Zz6f78tyufwxnU7ZZDI5iV5CjbsiAXiZy+V+jsfjW8BGo9FJ9iXUh0vwlATAnEwm74bDIRsMBoZICZ2G3MULjN8ASzgc5v1+n3W73QN6vR4j6BlyxUUiCTVT7uIdxo5QKMQpqdPpaGi1WmIuI3KFRP6V55iLXSAqgUCAUyKOmDWbTdZoNESUY5oT+xJqKP0VM7ADL06HU0GtVlOpVqtMIteRK3ZC/XgCqKFvgRMEvF4vp4JyuWwIcg8k77HmBiFFUXilUmG45oaQRJ4MNfUV+AA84KPH46H3hBWLRZbP50WUY5pLkKuRvMbcAhRwQxIqwqUzBLlCQsdLt1QjcblcnASZTEZDNptV5zQ+JbnGgxuSUFI6nTbESBLGZ4DTLlKplGBfJtconpVQId4hVUTj/flZCb5oPBaLsXg8LkgkEuwYhjux2+0cF06VkExKZaS1sxJcOOb3+0UxFR7DUGK1WjlJcEqMYjAYZPg8sEgkouGsxO12M5wSQ380kdYk95KQwIj/kthsNiE3lFgsFk79oGRZIMcy0g7vJUGDVZEslpGe/QEAAP//KqClBgAAAfBJREFU7ZTRatNQHIfjdFaj1El1prW2Sbti2aZeKEMFB+pAEFREFAa79d5n8YF8gkzUi93M7VXq9x08I82y7QH04iNpOP34/37nJEmSJAuwCCksQQYjuJdl2cFgMCh7vV6g2+2WVXzub9aeLan+sen+v2S+3H+12Hioms7IWZ2ss+AwntiTBKdJCk6hkr08z3f7/f7cca8L44m9wM1liO9OkHQ6nW/j8fjncDgsFZ0Uqy65xoNbkMNamqafEexPJpPvo9GoNFoTrE3OgZNcgjYswxBWYaPdbn9lmt/T6fQH7EJZh3XHJDd4dgfuwkPYbLVaX4jyqyiKQ4QHdVgTJOe5tuAqdOA2rMADeAov4DW8h0+wDTsVjiQXeXgFroMfJstdg0fwDLZA0Tv4AB9BoQRJ/Lq5Q/ZyE/owgfuwAYpewitQ9gbeBmazGdfwdbPcGClOY8F2o8iJjLYJz0Gh020lfyXukL0YKU5jN11Q5ERGsyPLdrLH8CRQkRgpTpNybyxF9mM0O1oBJ1sFpeuBmsRp/PIbK4qMZkfK3DW33+lyUFyEOKeIjOa2O5UyJ1O4DJ5sxdmRpEFkNDvyJCtz+6NQqa+I79rSnKQmsiPjKTOiQmMqjWLl6TFJReSOibKqUGlE+WKjRFEVFkZh9RrlC38A3S8C8jPZQY0AAAAASUVORK5CYII="; }
+ (NSString *)UICalloutViewLeftCap$2x { return @"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"; }
+ (NSString *)UICalloutViewRightCap { return @"iVBORw0KGgoAAAANSUhEUgAAABEAAAA5CAYAAADQksChAAAAHGlET1QAAAACAAAAAAAAAB0AAAAoAAAAHQAAABwAAAKdevXfpAAAAmlJREFUSA2UlNlqWlEUhredJzpgB41zcAi2JiRiBE0UiwNxQsGACibeeJH7XovPEPIofYnCSmmhV6XJq6T/f3SfHg/xmF58rH22rm+vvfY+Ryml7llwYbzEzc2NWgdy1MMFDxCt3MezXsAU3yZUpVLpyk6hULje2dn55vf7iwvxktAuUhcXF2Ln/Pz8cjab/Tg6OvoTCAS+QPTIJnNZRer09FTG47Ewavg8mUxkOp1+b7Vav91u92dIHgNuXVdlitRoNJJVnJycyNnZ2c9YLPYVyc9WidRgMJBVDIdDAZcHBwe/IHhpEfEA2HSjGnV8fCxO9Pt9yWQy10hwA4qeAvaI25pLOp2OdLtdA47t9Ho9SaVSV0jwgDfgBWB/jGrYYNVut6XZbIo1cqyhNJlMUuIH74Cuhk02tqTq9bpoGo2GED4z4oiNBRKJBCURoKt5jrG5JVWr1YRUq1UTPcdIGU6HkijwAfZGb8noiyqXy+IE5dFolJIECIC3gFt6AtgXF6+9OFGpVCQSiVCSBCHwHixLDg8PxUqxWBTCOUYuEA6HKfkIwuADeAV41PP7goskTlC0kHxCkm7u6yVJPp+XXC5nYB3rOS4QDAZZiV3C12B+zNlsVpyg2CLZRCKPmZX8k+zv74vGKtNzrAifA1aSAusleEf4nphSjileK0mn03Ibe3t7QnZ3dwVfOOdKrH/WSXqOERdNfD6fs4QrrSIej/OirZdsb2+LFbz2srW1ZSTjVIzo9XqdK0HT2DgT7N8Y6xgKhWSthH924s6SjY2NlaL/klCkYWV6zL54PB7nnmC/ZoJO1JG/3UXyFwAA//9HuzCQAAAB80lEQVTtlc1qU1EURk9iNXqVqERrEmNykzQY/B0oooKCPyAIbRGpIDh17rP4QD7BragDJ9q+SlwrZsd7NRQFhx0szulhf9/Z+7uHJnU6naLb7RauZTyTfr9ftNvtvZTSdRhBG85ABkehnsrCVftDk2q4ZnSYSTWT//LYwoSA93mZ1+DfX2yv1yvyPN/F5OvCZMj6d8/eDjQYDAbFeDz+3Gq1PqwwOcHZGtST72AVo9GomEwmHzH6lmXZW4qvQg4X4DT8MplOp8UKdjn7RBffm83mewR34AoMYB2acBzspJYo3Pud4XC4z0hfGo3GO4oewi24DJfgHFRNOHhT4jX7V/ACnsNjuA83YQMuQgtOQQOOQA3mIoU78BK2QYOn8ABug3nElznL/iQcg6XJFn/IJih+Bk9AA7O4ARPowXlwFEP9+V9t0Yk3isJHYAaOYAcamIWB+j7sIkZZY1+fzWYsKd1bcJfVmw3RDBzBDjTogFlEF8tRwsTnLIr8jN68AWbgCHYQBhl7A513wVoLE4slB2/1M/oVFJuBI9hBGJiFgdZhaWKx+BLXQaE3h9gMDNIO/jCITvwNEZ+yN4pCP6NiX6YZOEKlAw3CxDYtDoEib1XozWXxcoQwCBMLo1hBELfOhZzXpCyOPefzgCysFCuQKDxo/QHd3ALyX+9lLwAAAABJRU5ErkJggg=="; }
+ (NSString *)UICalloutViewRightCap$2x { return @"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"; }
+ (NSString *)UICalloutViewTopAnchor { return @"iVBORw0KGgoAAAANSUhEUgAAACkAAABGCAYAAABRwr15AAAAHGlET1QAAAACAAAAAAAAACMAAAAoAAAAIwAAACMAAAQYDCloiwAAA+RJREFUaAXMVslKHFEUfSaaaPIFunDaulJj2/QQBxxwVtCFC9GFCxVRUHHAARVx1pWf9QKVNCGb5FvMPUWf5vazqu0qFVwc7nTuvaeedr0yj4+P5qUwxlQoVCq/4qWz0R9boBLyQXwfzc3N31paWn7CMpe3/kPEFRxLZF4gxX2UuLKpqSkxOTn56/T09DcsYuQFqJMb62Qji5SFOBUs9cWJ/dTY2JiEsPv7e+/s7OwHLGLkURdosZGFRhIpyygQS6sE1Q0NDampqakchMkpWgIx8qiDl+ejDw8YSWjZIjE4vwCLcDrV9fX1aQi5u7vzBZ6cnBREQiyFggd+vi+y0LJEynBXYI0szsif1BcIccfHx0+APB4APPBlTk0coc+KDBM4MTGRu7299SDk6OgoFKiDB35coSVFhgkcGxvLXV1deRB3eHhoDw4OiixyGjjlm5sbD31xhIaKDBM4Ojqau7y89AXu7+/bvb09C/sc8EDoQ39UoYEiwwQODw/nLi4uPJzc7u5uZKAP/SMjI5GEPhEZJnBoaCh3fn7uQdzW1pbd3t72resjZg4cgnn0Yw7mlXuiRSKDBNbV1WUwUF4p3s7Ojt3Y2CjC5uamH8NqHzzmXIs5mIe5mC97S/7qpV64svQt8lnyX2pra7MDAwO+QCxaW1vzsb6+bgk3FxSTqy3myS/fw3zswT4B9uI9qq9S6PJvDtweeEGDhKf6Ko3f+/v7c/LL9DB8dXX11YG5mI892Ie9+f3QAT3QVWV6enr+uejt7f07PT39R14j3srKil1aWirC8vJyUezW3bgUH/OxB/uw19WC2Dw8PNggXF9f+0IWFxftWwMPhX1BOpAzCwsL1sX8/LwFmKdPyzxsGJecoB7Wwix7aM3c3Jx97zCzs7P2vcPMzMxY+ae1sHERpd/lunGQBiOfUVa+CS2si7C85mlOmB+2o1y+GR8ft4Bc/EXWzSOWz60iDnuCuMwFWfbBBvnoYR6+kY8GqyGXvx/D0medsVuT660wgxy3h7Fr2cs+WvJQN3It2cHBQR/wCZ2DX4rHGnvd2J3lztN13Uue6evrs4C87X0bFjP/mtbdGTYb16Iluru7C36pHGvavqRXz6Gv55lsNmuJrq4uq4E8YteSwz7WycUCnWMeljW3l3zWdY/JZDL2vcOkUikbhGQyWcin0+mCH8SNmtPz6Ot97jzT2dlpCRDpw7qxrr2l7+41iUTCamA5Y/raUhw5sMyR59Y0R9eYD8txXpHIjo4OXyCtbg7K6Tr953il6m6NsWlvb7floq2trWyunhm3jzMMBgShtbXVAlFq5MfpxR7dz73I/QcAAP//R6Pt0AAAASZJREFU7VK7asNAEBwCblKltISkImrUWEhl+tQuU+WT7xfyL94TjNksdzIkZ7yGMwyzj9m9YWWs6xpuYVmWm5rcjhKzmOc55BAfYE/HrO2x1ut4b4Y9rY8x+r4PFl3XhQjWGVtmX/M9ZsGlnnkz2bbtdjkaZU5mPcVWY/PUDGvUWmafjCjQIuY5joO2l6pZTcxTulTNzl5NNk0TiCjKxXaB1sYZndv4r7PQi/VSmiTzAeZkzpBZ1/zf2c0kF+49RE2O7zn7y2TOwKPr1WSpL1AvWS9Z6gKl9tT/ZL1kqQuU2oNhGIJ3YJqm4B0Yx/HHOyC/7ycAvsSkd+AsJr0Dn2LSO/AhJr0DJzHpHXgXk96Bo5j0DryJSe/Aq5j0DhzEpHfgRUy6xgX1iUkAQX47jAAAAABJRU5ErkJggg=="; }
+ (NSString *)UICalloutViewTopAnchor$2x { return @"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"; }
+ (NSString *)UICalloutViewBottomAnchor { return @"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"; }
+ (NSString *)UICalloutViewBottomAnchor$2x { return @"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"; }
+ (NSString *)UICalloutViewBackground { return @"iVBORw0KGgoAAAANSUhEUgAAAAEAAAA5CAYAAAD3PEFJAAAAHGlET1QAAAACAAAAAAAAAB0AAAAoAAAAHQAAABwAAACkF8Y1LgAAAHBJREFUGBlMy6ENQyEARdGXJh2CBEZAgAABhoQgEASDQBCWYqy3wt/lt80XFfe4CwCvT3gjpXThnEPsvYm1FjHnJMYYRO+daK0RtVailELknPndiBjjQwiB8N4TzrkHay3xwxhDaK0JpRQhpfxHCMEbAAD//2TbkE8AAAA9SURBVGOQlJQ8w0AJIScnd4ZBQ0PjDIOysvJdBiCIARFhIMIPRLiACEsQoQMiFEGEBIgQABFcIIIVRDABAL6ePTfutWY6AAAAAElFTkSuQmCC"; }
+ (NSString *)UICalloutViewBackground$2x { return @"iVBORw0KGgoAAAANSUhEUgAAAAIAAAByCAYAAAB5lADlAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAHGlET1QAAAACAAAAAAAAADkAAAAoAAAAOQAAADkAAAD3bjNTjgAAAMNJREFUOBGkz72JhGAAhOGpwyZUVESFVfAPFFRcFfypwmJsa4KNtxaPucAvuuiCZ3jTwX3fkN/5I7Iso2Acx4/guq6v4DzPj+A4Dgr2faeY2LaNgifWdaVgWRYK5nmmmJimiYL3+03BMAwU9H1PMdF1HQVt21LQNA3FRF3XFFRVRUFZlhQURUFBnucUPJfTNKXgidfrRUGSJBTEcUwxEUURBWEYUhAEAcWE7/sUeJ5HMeG6LgWO41Bg2zbFhGVZFPwvfgAAAP//7zgpOQAAAGxJREFU5cYhCkJBAEXRqyAYLJOECTLFaDXafjNZDIKgLniWNL73eXxwDYZzudRau/HP01rrxjKllG4sA3yCt8Z4BU+N8QjuGuMWXDXGFFw0xjk4aYxjcNAY+6BojF2w1RibYK0xVrMxBjbnZ75mdyKsdyBPxAAAAABJRU5ErkJggg=="; }

@end
