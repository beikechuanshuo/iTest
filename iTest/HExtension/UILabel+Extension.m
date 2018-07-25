//
//  UILabel+Extension.m
//  reliao
//
//  Created by liyanjun on 16/8/9.
//
//

#import "UILabel+Extension.h"
#import <CoreText/CoreText.h>

@implementation UILabel (Extension)

- (CFIndex)characterIndexAtPoint:(CGPoint)point
{
    NSMutableAttributedString* optimizedAttributedText = [self.attributedText mutableCopy];
    
    if (!CGRectContainsPoint(self.bounds, point))
    {
        return NSNotFound;
    }
    
    CGRect textRect = [self textRect];
    
    if (!CGRectContainsPoint(textRect, point))
    {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    point = CGPointMake(point.x - textRect.origin.x, point.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    point = CGPointMake(point.x, textRect.size.height - point.y);
    
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)optimizedAttributedText);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    
    if (frame == NULL)
    {
        CFRelease(path);
        return NSNotFound;
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    
    if (numberOfLines == 0)
    {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }
    
    NSUInteger idx = NSNotFound;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++)
    {
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CGFloat ascent, descent, leading, width;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);
        
        if (point.y > yMax)
        {
            break;
        }
        
        // Check if the point is within this line vertically
        if (point.y >= yMin)
        {
            
            // Check if the point is within this line horizontally
            if (point.x >= lineOrigin.x && point.x <= lineOrigin.x + width)
            {
                
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                
                break;
            }
        }
    }
    
    CFRelease(frame);
    CFRelease(path);
    
    return idx;
}

#pragma mark --

- (CGRect)textRect
{
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    textRect.origin.y = (self.bounds.size.height - textRect.size.height)/2;
    
    if (self.textAlignment == NSTextAlignmentCenter)
    {
        textRect.origin.x = (self.bounds.size.width - textRect.size.width)/2;
    }
    else if (self.textAlignment == NSTextAlignmentRight)
    {
        textRect.origin.x = self.bounds.size.width - textRect.size.width;
    }
    
    return textRect;
}

@end
