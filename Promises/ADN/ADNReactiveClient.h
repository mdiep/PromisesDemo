//
//  ADNReactiveClient.h
//  Promises
//
//  Created by Matt Diephouse on 4/8/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "ADNClient.h"

@interface ADNReactiveClient : NSObject

- (id)initWithClient:(ADNClient *)client;

#pragma mark Users

// Fetch information about a user using their username.
//
// username - Name of the user with or without the leading "@".
//
// Returns a signal that sends an ADNUser that represents the user and completes.
- (RACSignal *)fetchUserWithUsername:(NSString *)username;

// Fetch the avatar for a user.
//
// user - The user whose avatar should be downloaded.
//
// Returns a signal that sends a NSImage of the avatar and completes.
- (RACSignal *)fetchAvatarForUser:(ADNUser *)user;

#pragma mark Following

// Fetch the list of users who are followed by a user.
//
// user - The user who is following.
//
// Returns a signal that sends a NSSet of ADNUser objects and completes.
- (RACSignal *)fetchFollowingForUser:(ADNUser *)user;


// Fetch the list of users who follow a user.
//
// user - The user who is followed.
//
// Returns a signal that sends a NSSet of ADNUser objects and completes.
- (RACSignal *)fetchFollowersForUser:(ADNUser *)user;

@end
