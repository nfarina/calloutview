
These are the official graphics extracted using @0xced's excellent [UIKit Artwork Extractor][extractor].

  [extractor]: https://github.com/0xced/UIKit-Artwork-Extractor

It turns out that the "UICalloutViewTopAnchor@2x.png" as found in iOS is actually incorrect. It's a bit darker than it should be, and is obvious when lined up with the other pieces of the background graphic. I can only wonder if this happened because they don't actually use the "upward-pointing" version of the callout anywhere in iOS. So they probably didn't notice that graphic was incorrect.

So `SMCalloutView` uses a version of this graphic that I adjusted in Photoshop to match up with the others. You can see how it was done by inspecting the PSD in this folder.