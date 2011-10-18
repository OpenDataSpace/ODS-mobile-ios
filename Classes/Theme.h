//
//  Theme.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+Theme.h"

@interface Theme : NSObject {
}

+ (void)setThemeForUINavigationBar:(UINavigationBar *)navBar;
+ (void)setThemeForUIViewController:(UIViewController *)viewController;
+ (void)setThemeForUITableViewController:(UITableViewController *)tableViewController;
@end
