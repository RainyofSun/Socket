//
//  GCKeyChainManager.m
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import "GCKeyChainManager.h"

static GCKeyChainManager* keyManger = nil;
@implementation GCKeyChainManager

+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyManger = [[GCKeyChainManager alloc] init];
    });
    return keyManger;
}

-(void)setToken:(NSString *)token{
    _token = token;
}

@end
