//
//  Promise.m
//  Promises
//
//  Created by Matt Diephouse on 4/6/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "Promise.h"


@interface Promise ()
@property (assign, nonatomic, getter=isResolved) BOOL resolved;
@property (assign, nonatomic, getter=isRejected) BOOL rejected;

@property (copy, nonatomic) id (^block)(id);

@property (strong, nonatomic) NSArray *promises;
@property (strong, nonatomic) NSArray *values;

@property (strong, nonatomic) NSArray *toExecute;
@property (strong, nonatomic) NSArray *toResolve;
@property (strong, nonatomic) NSArray *doBlocks;
@property (strong, nonatomic) id result;
@end

@implementation Promise

#pragma mark Creation

+ (instancetype)when:(NSArray *)promises
{
    Promise *when = [self new];
    when.promises = [promises copy];
    when.values   = @[ ];
    
    [promises enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        Promise *promise = obj;
        
        when.values = [when.values arrayByAddingObject:[NSNull null]];
        
        [promise finally:^(id result, NSError *error) {
            @synchronized(when)
            {
                if (when.isRejected)
                {
                    return;
                }
                else if (error)
                {
                    [result reject:error];
                }
                else
                {
                    NSMutableArray *promises = [when.promises mutableCopy];
                    [promises removeObject:promise];
                    when.promises = promises;
                    
                    NSMutableArray *values = [when.values mutableCopy];
                    values[idx] = result;
                    when.values = values;
                    
                    if (promises.count == 0)
                    {
                        [when resolve:when.values];
                    }
                }
            }
        }];
    }];
    
    return when;
}

+ (instancetype)map:(NSArray *)inputs
              limit:(NSUInteger)limit
          withBlock:(Promise *(^)(id object))block
{
    Promise *result = [Promise new];
    
    dispatch_semaphore_t limitSemaphore = dispatch_semaphore_create(limit);
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue    = dispatch_get_main_queue();
    
    dispatch_group_t group = dispatch_group_create();
    
    for (id input in inputs)
    {
        dispatch_group_async(group, defaultQueue, ^{
            dispatch_semaphore_wait(limitSemaphore, DISPATCH_TIME_FOREVER);
            
            @synchronized(result)
            {
                if (result.isRejected)
                {
                    dispatch_semaphore_signal(limitSemaphore);
                    return;
                }
            }
            
            [block(input) finally:^(id result, NSError *error) {
                if (error)
                {
                    @synchronized(result)
                    {
                        [result reject:error];
                    }
                }
                
                dispatch_semaphore_signal(limitSemaphore);
            }];
        });
    }
    
    dispatch_group_notify(group, mainQueue, ^{
        if (!result.isRejected)
        {
            [result resolve:@YES];
        }
    });
    
    return result;
}

+ (instancetype)of:(id (^)())block
{
    Promise *promise = [self new];
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue    = dispatch_get_main_queue();
    
    dispatch_async(defaultQueue, ^{
        id result = block();
        dispatch_async(mainQueue, ^{
            [promise resolve:result];
        });
    });
    
    return promise;
}

+ (instancetype)value:(id)object
{
    Promise *promise = [self new];
    [promise resolve:object];
    return promise;
}

+ (instancetype)error:(NSError *)error
{
    Promise *promise = [self new];
    [promise reject:error];
    return promise;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.toExecute = @[ ];
        self.toResolve = @[ ];
        self.doBlocks  = @[ ];
    }
    
    return self;
}

#pragma mark Handlers

- (instancetype)then:(id (^)(id result))block
{
    if (self.isResolved)
    {
        id result = block(self.result);
        if ([result isKindOfClass:[Promise class]])
            return result;
        return [Promise value:result];
    }
    else if (self.isRejected)
    {
        return [Promise error:self.result];
    }
    else
    {
        Promise *promise = [Promise new];
        promise.block = block;
        
        self.toExecute = [self.toExecute arrayByAddingObject:promise];
        
        return promise;
    }
}

- (instancetype)thenPromise:(id (^)(id result))block
{
    return [self then:^(id result) {
        return [Promise of:^{
            return block(result);
        }];
    }];
}

- (instancetype)finally:(void (^)(id result, NSError *error))block
{
    if (self.isResolved)
    {
        block(self.result, nil);
    }
    else if (self.isRejected)
    {
        block(nil, self.result);
    }
    else
    {
        self.doBlocks = [self.doBlocks arrayByAddingObject:[block copy]];
    }
    
    return self;
}

#pragma mark Fulfillment

- (void)execute:(id)argument
{
    assert(!(self.isResolved || self.isRejected));
    assert(self.block);
    
    id result = self.block(argument);
    self.block = nil;
    
    if ([result isKindOfClass:[Promise class]])
    {
        Promise *promise = result;
        promise.toResolve = [promise.toResolve arrayByAddingObject:self];
    }
    else
    {
        [self resolve:result];
    }
}

- (void)reject:(NSError *)error
{
    assert(!(self.isResolved || self.isRejected));
    
    self.result     = error;
    self.rejected   = YES;
    
    for (Promise *promise in self.toExecute)
    {
        [promise reject:error];
    }
    
    for (Promise *promise in self.toResolve)
    {
        [promise reject:error];
    }
    
    for (void (^block)(id result, NSError *error) in self.doBlocks)
    {
        block(nil, error);
    }
    
    self.toExecute = nil;
    self.toResolve = nil;
    self.doBlocks  = nil;
}

- (void)resolve:(id)object
{
    assert(!(self.isResolved || self.isRejected));
    
    self.result     = object;
    self.resolved   = YES;
    
    for (Promise *promise in self.toExecute)
    {
        [promise execute:object];
    }
    
    for (Promise *promise in self.toResolve)
    {
        [promise resolve:object];
    }
    
    for (void (^block)(id result, NSError *error) in self.doBlocks)
    {
        block(object, nil);
    }
    
    self.toExecute = nil;
    self.toResolve = nil;
    self.doBlocks = nil;
}

@end
