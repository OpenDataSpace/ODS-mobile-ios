//
//  IFWebViewController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/13/10.
//  Copyright 2010 City and County of Denver. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellModel.h"

@interface IFWebViewController : UIViewController {
    UIWebView *webView;
	NSURLRequest *request;
    
	UIColor *backgroundColor;
}

@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) IBOutlet UIView *webView;
@property (nonatomic, retain) UIColor *backgroundColor;

@end
