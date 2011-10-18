//
//  IFRequestAttributesCellController.h
//  Denver311
//
//  Created by Jonathan Newell on 10/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IFRequestAttributesCellController : NSObject {

	NSString			*label;
	NSString			*value;
	UIColor				*backgroundColor;
	UIColor				*labelTextColor;
	UIColor				*valueTextColor;
	UIFont				*labelFont;
	UIFont				*valueFont;
	NSInteger			indentationLevel;
	NSNumber			*labelPercentAllocation;
	NSNumber			*inset;
	NSNumber			*labelValueGap;
	NSNumber			*labelWidth;

}

@property	(nonatomic, retain)	NSString		*label;
@property	(nonatomic, retain)	NSString		*value;
@property	(nonatomic, retain)	UIColor			*backgroundColor;
@property	(nonatomic, retain)	UIColor			*labelTextColor;
@property	(nonatomic, retain)	UIColor			*valueTextColor;
@property	(nonatomic, retain)	UIFont			*labelFont;
@property	(nonatomic, retain)	UIFont			*valueFont;
@property						NSInteger		indentationLevel;
@property	(nonatomic, retain)	NSNumber		*labelPercentAllocation;
@property	(nonatomic, retain)	NSNumber		*inset;
@property	(nonatomic, retain)	NSNumber		*labelValueGap;
@property	(nonatomic, retain) NSNumber		*labelWidth;

- (id) initWithLabel:(NSString *) cellLabel value:(NSString *) cellValue atIndentationLevel:(NSInteger) level;

@end
