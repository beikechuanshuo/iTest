//
//  QIYIGifImage.h
//  reliao
//
//  Created by liyanjun on 2017/2/8.
//
//

#import <UIKit/UIKit.h>

@interface QIYIGifImage : UIImage


@property (nonatomic,readonly) NSTimeInterval *frameDurations;
@property (nonatomic,readonly) NSUInteger loopCount;
@property (nonatomic,readonly) NSTimeInterval totalDuratoin;

- (UIImage *)getFrameWithIndex:(NSUInteger)idx;

@end
