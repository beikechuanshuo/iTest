//
//  UIBarButtonItem+Extension.h
//  reliao
//
//  Created by liyanjun on 2017/3/17.
//
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Extension)

+ (UIBarButtonItem *)barButtonItemTaget:(id)taget action:(SEL)action imageNormal:(NSString *)imageNormal imageHighlighted:(NSString *)imageHighlighted;

@end
