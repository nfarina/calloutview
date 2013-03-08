
# SampleAssets Folder Contents

This folder contains some assets that you may find useful, but that aren't
necessary to use SMCalloutView:


## SystemGraphics

These are the official graphics extracted using @0xced's excellent [UIKit
Artwork Extractor][1].

  [1]: https://github.com/0xced/UIKit-Artwork-Extractor

It turns out that the "UICalloutViewTopAnchor@2x.png" as found in iOS is
actually incorrect. It's a bit darker than it should be, and is obvious when
lined up with the other pieces of the background graphic. I can only wonder if
this happened because they don't actually use the "upward-pointing" version of
the callout anywhere in iOS. So they probably didn't notice that graphic was
incorrect.

So `SMCalloutView` uses a version of this graphic that I adjusted in Photoshop
to match up with the others. You can see how it was done by inspecting the PSD
in this folder.


## CalloutView.pcvd

This is a [PaintCode][1] file contributed by [Nicholas Shipes][2] containing a
reproduction of the system UICalloutView. I'll let him explain:

> The initial base drawing code was done using PaintCode to get the core
> structure and layering down, but my final code was modified quite a bit
> afterwards in order to tweak the visuals and get it closer to Apple's
> callout and PaintCode is limited in some respects. So not sure how useful it
> may be as it's not a 1:1 copy and paste from PaintCode and it's probably
> better that most customizations come from tweaking the code itself (colors,
> radius, etc).

  [1]: http://www.paintcodeapp.com
  [2]: https://github.com/u10int