//
//  ADNUser.h
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADNUser : NSObject

@property (strong, nonatomic, readonly) NSString *userID;
@property (strong, nonatomic, readonly) NSString *username;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *avatarURL;

+ (id)userWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
