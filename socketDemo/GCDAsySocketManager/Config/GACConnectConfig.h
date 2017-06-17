//
//  GACConnectConfig.h
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GACConnectConfig : NSObject

/**
 * socket 配置
 */
@property(nonatomic,strong)NSString* token;
/**
 * 建联时的通道
 */
@property(nonatomic,strong)NSString* channels;
/**
 * 当前使用的通道
 */
@property(nonatomic,strong)NSString* currentChnanel;
/**
 * 通信地址
 */
@property(nonatomic,strong)NSString* host;
/**
 * 通信端口号
 */
@property(nonatomic,assign)uint16_t port;
/**
 * 通信协议版本号
 */
@property(nonatomic,assign)NSInteger socketVerison;

@end
