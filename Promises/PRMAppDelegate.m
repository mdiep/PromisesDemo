//
//  PRMAppDelegate.m
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "PRMAppDelegate.h"

#import "ADNClient.h"
#import "Promise.h"

@interface PRMAppDelegate ()
@property (strong, nonatomic) IBOutlet NSTextField *usernameField;
@property (strong, nonatomic) IBOutlet NSArrayController *doNotFollowYou;
@property (strong, nonatomic) IBOutlet NSArrayController *youDoNotFollow;

@property (strong, nonatomic) ADNClient *client;
@end

@implementation PRMAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *token = NSProcessInfo.processInfo.environment[@"ADNACCESSTOKEN"];
    self.client = [[ADNClient alloc] initWithAccessToken:token];
}

#pragma mark Actions

- (IBAction)loadUser:(id)sender
{
    //[self loadUserSynchronously];
    //[self loadUserWithGCD];
    [self loadUserWithPromises];
}

#pragma mark Private Methods

- (NSSet *)objectsInSet:(NSSet *)set1 notInSet:(NSSet *)set2
{
    NSMutableSet *result = [set1 mutableCopy];
    [result minusSet:set2];
    return result;
}

- (void)showDifferencesBetweenFollowers:(NSSet *)followers following:(NSSet *)following
{
    NSSet *doNotFollowYou = [self objectsInSet:following notInSet:followers];
    NSSet *youDoNotFollow = [self objectsInSet:followers notInSet:following];
    
    NSArray *descriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES] ];
    self.doNotFollowYou.content = [[doNotFollowYou allObjects] sortedArrayUsingDescriptors:descriptors];
    self.youDoNotFollow.content = [[youDoNotFollow allObjects] sortedArrayUsingDescriptors:descriptors];
    
}

#pragma mark Concurrency

- (void)loadUserSynchronously
{
    ADNUser *user = [self.client fetchUserWithUsername:self.usernameField.stringValue];
    
    NSSet *followers = [self.client fetchFollowersForUser:user];
    NSSet *following = [self.client fetchFollowingForUser:user];
    
    [self showDifferencesBetweenFollowers:followers following:following];
}

- (void)loadUserWithGCD
{
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue    = dispatch_get_main_queue();
    
    dispatch_async(defaultQueue, ^{
        ADNUser *user = [self.client fetchUserWithUsername:self.usernameField.stringValue];
        
        __block NSSet *followers = nil;
        __block NSSet *following = nil;
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, defaultQueue, ^{
            followers = [self.client fetchFollowersForUser:user];
        });
        dispatch_group_async(group, defaultQueue, ^{
            following = [self.client fetchFollowingForUser:user];
        });
        
        dispatch_group_notify(group, mainQueue, ^{
            [self showDifferencesBetweenFollowers:followers following:following];
        });
    });
}

- (void)loadUserWithPromises
{
    Promise *fetchUser = [Promise of:^{ return [self.client fetchUserWithUsername:self.usernameField.stringValue]; }];
    
    [[Promise
        when:@[
            [fetchUser thenPromise:^(id user) { return [self.client fetchFollowersForUser:user]; }],
            [fetchUser thenPromise:^(id user) { return [self.client fetchFollowingForUser:user]; }],
        ]]
        finally:^(id result, NSError *error) {
            NSSet *followers = result[0];
            NSSet *following = result[1];
            [self showDifferencesBetweenFollowers:followers following:following];
        }];
}

@end
