//
//  ADNPromiseClient.h
//  Promises
//
//  Created by Matt Diephouse on 4/8/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Promise.h"

#import "ADNClient.h"
#import "ADNUser.h"

@interface ADNPromiseClient : NSObject

- (id)initWithClient:(ADNClient *)client;

#pragma mark Users

// Fetch information about a user using their username.
//
// username - Name of the user with or without the leading "@".
//
// Returns a ADNUser that represents the user.
- (Promise *)fetchUserWithUsername:(NSString *)username;

// Fetch the avatar for a user.
//
// user - The user whose avatar should be downloaded.
//
// Returns a promise of a NSImage of the avatar.
- (Promise *)fetchAvatarForUser:(ADNUser *)user;

#pragma mark Following

// Fetch the list of users who are followed by a user.
//
// user - The user who is following.
//
// Returns a promise of a NSSet of ADNUser objects.
- (Promise *)fetchFollowingForUser:(ADNUser *)user;


// Fetch the list of users who follow a user.
//
// user - The user who is followed.
//
// Returns a promise of a NSSet of ADNUser objects.
- (Promise *)fetchFollowersForUser:(ADNUser *)user;

@end
