![Example Screenshot](http://cl.ly/image/2a2j1p3U243P/Image%202012.09.02%2010:04:58%20AM.png)


Overview
========

SMCalloutView aims to be an exact replica of the private UICalloutView system control.

We all love those "bubbles" you get when clicking pins in MKMapView. But sadly, it's impossible to present this bubble-style "Callout" UI anywhere outside MKMapView. Phooey! So this class _painstakingly_ recreates this handy control for your pleasure.


Usage
=====

To use SMCalloutView in your own projects, simply copy the files `SMCalloutView.h` and `SMCalloutView.m`.

The comments in `SMCalloutView.h` do a lot of explaining on how to use the class, but the main function you'll need is `presentCalloutFromRect:`. You'll specify the view you'd like to add the callout to, as well as the rect defining the "target" that the popup should point at. The target rect should be _in the coordinate system of the target view_ (just like the similarly-named `UIPopover` method). Most likely this will be `target.frame` if you're adding the callout view as a sibling of the target view, or it would be `target.bounds` if you're adding the callout view to the target itself.

You can study the included project's `AppDelegate.m` for a working example.


Questions
=========

#### How do I change the height of the callout?

If you use only the `title/titleView/subtitle/subtitleView` properties, the callout will always be the "system standard" height. If you assign the `contentView` property however, then the callout will size to fit the `contentView` and the other properties are ignored.

  [#29]: https://github.com/nfarina/calloutview/issues/29


#### Can I use the callout with the Google Maps iOS SDK?

Check out [ryanmaxwell's demo proejct][googlemaps] for an example of one way to do this. [More discussion on this topic][#25]

  [googlemaps]: https://github.com/ryanmaxwell/GoogleMapsCalloutView
  [#25]: https://github.com/nfarina/calloutview/issues/25


#### Have you recreated more of MapKit? 

No, but you might be interested in [MapBox's iOS SDK](https://github.com/mapbox/mapbox-ios-sdk), which uses SMCalloutView as part of its custom open source variation of MapKit. 


More Info
=========

You can read more info if you wish in the [blog post][].

  [blog post]: http://nfarina.com/post/29883229869/callout-view


ARC Support
===========

This class requires LLVM 4.0 with [Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html), enabled by default in modern Xcode projects.
