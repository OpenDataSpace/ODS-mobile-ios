//
//  MetaDataDatePicker.h
//  FreshDocs
//
//  Created by Michael Muller on 5/15/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MetaDataDatePicker : UIViewController {
	UIDatePicker *datePicker;
	UIDatePicker *timePicker;
}

@property (nonatomic, retain) UIDatePicker *datePicker;
@property (nonatomic, retain) UIDatePicker *timePicker;

- (void)layout;

@end
