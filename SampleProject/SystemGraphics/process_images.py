#!/usr/bin/env python

import os
import base64

def main():
  for png in os.listdir("."):
      if png.endswith(".png"):
          #print "Processing %s" % png
          process(png)

def process(png):
  with open(png) as f:
    bytes = f.read()
    encoded = base64.b64encode(bytes)
    name = os.path.splitext(png)[0]
    name = name.replace('@','$')  # @2x -> $2x
    name = name.replace('UI','SM')

    print '+ (NSString *)%s { return @"%s"; }' % (name, encoded)

if __name__ == "__main__":
  main()