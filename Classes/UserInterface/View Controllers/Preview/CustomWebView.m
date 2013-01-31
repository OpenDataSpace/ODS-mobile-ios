//
//  CustomWebView.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 21/01/2013.
//
//

#import "CustomWebView.h"
#import "AlfrescoMDMLite.h"

@implementation CustomWebView

@synthesize isRestrictedDocument = _isRestrictedDocument;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    
    if(self.isRestrictedDocument)
    {
        if (action == @selector(copy:) ||
            action == @selector(paste:)||
            action == @selector(cut:)) {
            return NO;
        }
    }
    
    return [super canPerformAction:action withSender:sender];
}

@end
