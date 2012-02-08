//
//  IFCenteredValueCellController.h
//  Denver311
//
//  Created by Jonathan Newell on 10/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCellController.h"


@interface IFCenteredValueCellController : NSObject <IFCellController> {

	
	UIColor		*backgroundColor;
	NSString	*value;
	UIFont		*cellFont;
	UIColor		*cellTextColor;
		
}


@property (nonatomic, retain) UIColor	*backgroundColor;
@property (nonatomic, retain) NSString	*value;
@property (nonatomic, retain) UIFont	*cellFont;
@property (nonatomic, retain) UIColor	*cellTextColor;


- (id) initWithValue:(NSString *) cellValue;

@end
