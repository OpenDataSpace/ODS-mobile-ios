/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  ToggleBarButtonItemDecorator.m
//

#import "ToggleBarButtonItemDecorator.h"

@implementation ToggleBarButtonItemDecorator

@synthesize finalAction;
@synthesize finalTarget;
@synthesize toggleOffImage;
@synthesize toggleOnImage;
@synthesize barButton;
@synthesize toggleState;



- (void) dealloc {
    [finalTarget release];
    [toggleOnImage release];
    [toggleOffImage release];
    [barButton release];
    [super dealloc];
}

- (void) setTarget: (id)newTarget {
    self.finalTarget = newTarget;
}

- (void) setAction: (SEL)newAction {
    self.finalAction = newAction;
}

- (id) target {
    return self.finalTarget;
}

- (SEL) action {
    return self.finalAction;
}


- (ToggleBarButtonItemDecorator *)  initWithOffImage:(UIImage *)newToggleOffImage onImage:  (UIImage *)newToggleOn 
             style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    self = [super init];
    if (self) {
        barButton = [[UIBarButtonItem alloc] initWithImage:newToggleOffImage style:style target:self action:@selector(toggleAndContinue:)];
        self.toggleOnImage = newToggleOn;
        self.toggleOffImage = newToggleOffImage;
        self.finalAction = action;
        self.finalTarget = target;
        toggleState = NO;
    }
    
    return self;
}

- (void) toggleImage {
    if(toggleState) {
        toggleState = NO;
        self.barButton.image = self.toggleOffImage;
    } else {
        toggleState = YES;
        self.barButton.image = self.toggleOnImage;
    }
}

- (IBAction)toggleAndContinue:(id)sender {
	[self toggleImage];
    
    if([self.finalTarget respondsToSelector:self.finalAction]) {
        [self.finalTarget performSelector:self.finalAction withObject:sender];
    }
}



@end
