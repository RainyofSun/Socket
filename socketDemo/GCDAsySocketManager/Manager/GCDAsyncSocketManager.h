//
//  GCDAsyncSocketManager.h
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDAsyncSocketManager : NSObject

/**
 * 连接状态：1 已连接 0 连接中 -1 未连接
 */
@property(nonatomic,assign)NSInteger connectionStatus;
/**
 * 建联失败重练次数
 */
@property(nonatomic,assign)NSInteger reconnectionCount;

/**
 * 获取单例对象
 * @return 单例对象
 */
+(instancetype)shareInstance;

/**
 * 连接socket
 * @param delegate          delegate
 */
-(void)connectSocketWithDelegate:(id) delegate;

/**
 * socket 连接成功后发送心跳的操作
 */
-(void)socketDidConnectBeginSendBeat:(NSString*)beatBody;

/**
 * socket 连接失败之后重新连接的操作
 */
-(void)socketDidDisconnectBeginSendReconnect:(NSString*)reconnectBody;

/**
 * 向服务器发送数据
 */
-(void)socketWriteData:(NSString*)data;

/**
 * 读取数据
 */
-(void)socketBeginReadData;

/**
 * socekt 主动断开连接
 */
-(void)disconnectSocket;

/**
 * 重设心跳次数
 */
-(void)resetBeatCount;

/**
 * 设置连接的host和port
 */
-(void)changeHost:(NSString*)host port:(NSInteger)port;

@end
