//
//  DocumentItem.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 14/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DocumentItem : NSObject

@property (nonatomic, retain) NSString *nodeRef;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSDate *modifiedDate;
@property (nonatomic, retain) NSString *modifiedBy;

- (DocumentItem *) initWithJsonDictionary:(NSDictionary *) json;

@end
