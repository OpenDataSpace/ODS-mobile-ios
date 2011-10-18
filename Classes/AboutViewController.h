//
//  AboutViewController.h
//  Alfresco
//
//  Created by Michael Muller on 10/2/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GradientView.h"


@interface AboutViewController : UIViewController {
	IBOutlet UILabel *buildTimeLabel;
	IBOutlet GradientView *gradientView;
	IBOutlet GradientView *aboutBorderedInfoView;
    IBOutlet GradientView *aboutClientBorderedInfoView;
}

@property (nonatomic, retain) UILabel *buildTimeLabel;
@property (nonatomic, retain) GradientView *gradientView;
@property (nonatomic, retain) GradientView *aboutBorderedInfoView;
@property (nonatomic, retain) GradientView *aboutClientBorderedInfoView;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)clientButtonPressed:(id)sender;

@end
