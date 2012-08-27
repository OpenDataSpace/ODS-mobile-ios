//
//  Person.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 27/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *avatar;
@property (nonatomic, retain) NSString *email;

// Initialises the person information using a json response received from the server
- (Person *) initWithJsonDictionary:(NSDictionary *) json;

@end
