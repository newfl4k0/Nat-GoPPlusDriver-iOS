//
//  UITableTouch.m
//  fa
//
//  Created by Cristina Avila on 09/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "UITableTouch.h"

@implementation UITableTouch

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.nextResponder touchesBegan:touches withEvent:event];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
