![](http://cl.ly/image/2a2j1p3U243P/Image%202012.09.02%2010:04:58%20AM.png)

### Overview

SMCalloutView aims to be an exact replica of the private UICalloutView system control.

We all love those "bubbles" you get when clicking pins in MKMapView. But sadly, it's impossible to present this bubble-style "Callout" UI anywhere outside MKMapView. Phooey! So this class _painstakingly_ recreates this handy control for your pleasure.

### Usage

To use SMCalloutView in your own projects, simply copy the files `SMCalloutView.h` and `SMCalloutView.m`.

The comments in `SMCalloutView.h` do a lot of explaining on how to use the class, but the main function you'll need is `presentCalloutFromRect:`. You'll specify the view you'd like to add the callout to, as well as the rect defining the "target" that the popup should point at. The target rect should be _in the coordinate system of the target view_ (just like the similarly-named `UIPopover` method). Most likely this will be `target.frame` if you're adding the callout view as a sibling of the target view, or it would be `target.bounds` if you're adding the callout view to the target itself.

You can study the included project's `AppDelegate.m` for a working example.

### More Info

You can read more info if you wish in the [blog post][].

  [blog post]: http://nfarina.com/post/29883229869/callout-view

### Adjustable-Height Version

Check out the [custom_drawn_bg][] branch for a version of SMCalloutView that draws its background dynamically and supports flexible heights. This will be unified with the master branch in the future, but in the meantime I'd love any feedback on it. Thanks to [u10int][] for contributing this code!

  [custom_drawn_bg]: https://github.com/nfarina/calloutview/tree/custom_drawn_bg
  [u10int]: https://github.com/u10int

### ARC Support

This class requires LLVM 4.0 with [Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html), enabled by default in modern Xcode projects.
