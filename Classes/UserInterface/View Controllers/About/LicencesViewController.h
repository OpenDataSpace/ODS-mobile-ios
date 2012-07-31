//
//  LicencesViewController.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 27/07/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LicencesViewController : UIViewController


@property (nonatomic, retain) IBOutlet UILabel *package;
@property (nonatomic, retain) IBOutlet UITextView *details;

-(void) showLicenceFor:(NSString*)pack;

@end
