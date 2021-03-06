//
//  GACSocketModel.h
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension.h>

@interface GACSocketModel : NSObject

/**
 *  socket协议版本号
 */
@property (nonatomic, assign) NSInteger version;

/**
 *  socket请求类型
 */
@property (nonatomic, assign) NSInteger reqType;

/**
 *  根据时间戳生成的socket唯一请求ID
 */
@property (nonatomic, strong) NSString *reqId;

/**
 *  socket通道，支持单通道，多通道
 */
@property (nonatomic, strong) NSString *requestChannel;

/**
 *  socket请求体
 */
@property (nonatomic, strong) NSDictionary *body;

/**
 *  发送心跳时携带的接收到最新消息的ID
 */
@property (nonatomic, assign) NSInteger user_mid;

/**
 *  使用该方法对body对象进行两次转JSONString处理，如无body，请使用toJSONString方法直接转JSONString
 */
- (NSString *)socketModelToJSONString;

@end
