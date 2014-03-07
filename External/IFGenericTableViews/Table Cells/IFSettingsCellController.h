//
//  IFSettingsCellController.h
//  FreshDocs
//
//  Created by bdt on 3/7/14.
//
//

#import <Foundation/Foundation.h>

#import "IFCellController.h"
#import "FDGenericTableViewController.h"

@interface IFSettingsCellController : NSObject <IFCellController, FDTargetActionProtocol>

@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *subLabel;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) id target;
@property (nonatomic, copy) NSString *userInfo;

- (id)initWithLabel:(NSString *)newLabel subLabel:(NSString*)newSubLabel withAction:(SEL)newAction onTarget:(id)newTarget;
@end
