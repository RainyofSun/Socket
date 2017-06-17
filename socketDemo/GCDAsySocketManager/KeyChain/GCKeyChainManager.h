//
//  GCKeyChainManager.h
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCKeyChainManager : NSObject

@property(nonatomic,strong)NSString* token;

+(instancetype)sharedInstance;

@end
