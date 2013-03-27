//
// RCAlertDialogView.m
//
// Copyright (c) 2013 Rich Cameron (github.com/rcameron)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <QuartzCore/QuartzCore.h>
#import "RCAlertDialogView.h"

@implementation RCAlertDialogView
{
  CGGradientRef _gradient;
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Init
////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (!self) return nil;
  
  [self setOpaque:NO];
  
  self.cornerRadii = CGSizeMake(16.f, 16.f);
  
  return self;
}

- (void)dealloc
{
  CGGradientRelease(_gradient);
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Gradient
////////////////////////////////////////////////////////
- (CGGradientRef)gradient
{
  if(NULL == _gradient) {
    CGFloat colors[8] = {43.0 / 255.0, 61.0 / 255.0, 98.0 / 255.0, 1.0,
      49.0 / 255.0, 66.0 / 255.0, 105.0 / 255.0, 1.0 };
    
    CGFloat colorStops[2] = {0.0,1.0};

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    _gradient = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 2);
    CGColorSpaceRelease(colorSpace);
  }
  return _gradient;
}

- (void)drawGradient {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGPoint startPoint = {0.0, 0.0};
  CGPoint endPoint = {0.0, self.bounds.size.height};
  CGContextDrawLinearGradient(ctx, [self gradient], startPoint, endPoint,0);
}

- (void)drawRect:(CGRect)rect
{
  // Clip view
  UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                 byRoundingCorners:UIRectCornerAllCorners
                                                       cornerRadii:self.cornerRadii];
  [clipPath addClip];
  
  // Draw background gradient
  [self drawGradient];
    
  // Draw light line at top
  UIBezierPath *lightPath = [UIBezierPath bezierPath];
  [lightPath moveToPoint:CGPointMake(5.f, 4.f)];
  [lightPath addCurveToPoint:CGPointMake(4.f, 3.5f) controlPoint1:CGPointMake(3.5f, 10.f) controlPoint2:CGPointMake(10.f, 3.5f)];
  [lightPath addLineToPoint:CGPointMake(CGRectGetWidth(self.frame) - 4.f, 3.5f)];
  [lightPath addCurveToPoint:CGPointMake(CGRectGetWidth(self.frame) - 5.f, 4.f)
               controlPoint1:CGPointMake(CGRectGetWidth(self.frame) - 3.5f, 10.5f)
               controlPoint2:CGPointMake(CGRectGetWidth(self.frame) - 10.5f, 3.5f)];
  [lightPath setLineWidth:2];
  [[UIColor colorWithRed:106.f/255.f green:106.f/255.f blue:107.f/255.f alpha:1.0f] set];
  [lightPath strokeWithBlendMode:kCGBlendModeLighten alpha:0.5f];
  
  // Draw thick border
  [clipPath setLineWidth:4];
  [[UIColor colorWithRed:190.f/255.f green:195.f/255.f blue:207.f/255.f alpha:1.0f] setStroke];
  [clipPath stroke];
}


@end
