/*
 Copyright 2013 Robot Media SL (http://www.robotmedia.net)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
//
//  RMShapedImageView.m
//  RMShapedImageView
//
//  Created by Hermes Pique on 2/21/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMShapedImageView.h"

@implementation RMShapedImageView {
    CGPoint _previousPoint;
    BOOL _previousPointInsideResult;
}

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initHelper];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self initHelper];
    }
    return self;
}

- (void) initHelper
{
    _previousPoint = CGPointMake(CGFLOAT_MIN, CGFLOAT_MIN);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL superResult = [super pointInside:point withEvent:event];
    if (!superResult) return NO;
    
    if (!self.image) return NO;
    
    if (CGPointEqualToPoint(point, _previousPoint)) {
        return _previousPointInsideResult;
    } else {
        _previousPoint = point;
    }
    
    BOOL result = [self isAlphaVisibleAtPoint:point];
    _previousPointInsideResult = result;
    return result;
}

#pragma mark - UIImageView

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    [self resetPointInsideCache];
}

#pragma mark - Private

- (BOOL)isAlphaVisibleAtPoint:(CGPoint)point
{
    if (self.contentMode == UIViewContentModeScaleToFill)
    {
        CGSize imageSize = self.image.size;
        CGSize boundsSize = self.bounds.size;
        point.x *= (boundsSize.width != 0) ? (imageSize.width / boundsSize.width) : 1;
        point.y *= (boundsSize.height != 0) ? (imageSize.height / boundsSize.height) : 1;
    }
    
    return [self isAlphaVisibleAtImagePoint:point];
}

- (BOOL)isAlphaVisibleAtImagePoint:(CGPoint)point
{
    CGRect imageRect = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    NSInteger pointRectWidth = self.touchHitPixelTolerance * 2 + 1;
    CGRect pointRect = CGRectMake(point.x - self.touchHitPixelTolerance, point.y - self.touchHitPixelTolerance, pointRectWidth, pointRectWidth);
    CGRect queryRect = CGRectIntersection(imageRect, pointRect);
    if (CGRectIsNull(queryRect)) return NO;
    
    // TODO: Do we really need to get the whole color information? See: http://stackoverflow.com/questions/15008270/get-alpha-channel-from-uiimage-rectangle
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    NSUInteger pixelCount = queryRect.size.width * queryRect.size.height;
    unsigned char pixelData[pixelCount][4];
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 queryRect.size.width,
                                                 queryRect.size.height,
                                                 bitsPerComponent,
                                                 bytesPerRow * queryRect.size.width,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    CGContextTranslateCTM(context, -queryRect.origin.x, queryRect.origin.y-(CGFloat)self.image.size.height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)self.image.size.width, (CGFloat)self.image.size.height), self.image.CGImage);
    CGContextRelease(context);
    
    for (int i = 0; i < pixelCount; i++)
    {
        unsigned char *colors = pixelData[i];
        CGFloat alpha = colors[3] / 255.0;
        if (alpha > self.touchHitMinAlpha)
        {
            return YES;
        }
    }
    return NO;
}

- (void)resetPointInsideCache
{
    _previousPoint = CGPointMake(CGFLOAT_MIN, CGFLOAT_MIN);
    _previousPointInsideResult = NO;
}

@end
