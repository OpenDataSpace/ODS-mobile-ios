//
//  IFWebCellController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/13/10.
//  Copyright 2010 City and County of Denver. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"
#import "IFWebViewController.h"

@interface IFWebCellController : NSObject <IFCellController>
{
	NSString *label;
	NSURL *url;
	NSURLRequest *request;
	
	UIColor *backgroundColor;
	UIColor *viewBackgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableViewController;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *viewBackgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) UITableViewController *tableViewController;

- (id)initWithLabel:(NSString *)newLabel andURL:(NSURL *)newURL;
- (id)initWithLabel:(NSString *)newLabel andURLRequest:(NSURLRequest *)newURLRequest;

@end
