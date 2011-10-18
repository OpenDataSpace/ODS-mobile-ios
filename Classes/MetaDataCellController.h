//
//  MetaDataCellController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/18/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

@interface MetaDataCellController : NSObject <IFCellController>
{
	NSString *label;   
	id<IFCellModel> model;
	NSString *key;
	
	NSInteger indentationLevel;
    NSString *propertyType;
}

@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) NSString *propertyType;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey withURL:(NSURL *)newURL inModel:(id<IFCellModel>)newModel;

@end
