//
//  CocoaAsyncSocketManager.h
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GACConnectConfig.h"

/**
 * 业务类型
 */
typedef NS_ENUM(NSInteger, GACReqeustType) {
    GACRequestType_Beat = 1,                    //心跳
    GACReqeustType_GetConversationList,         //获取会话列表
    GACReqeustType_ConnectionAuthAppraisal = 7, //连接鉴权
};

/**
 * socket连接状态
 */
typedef NS_ENUM(NSInteger, GACSocketConnectionStatus) {
    GACSocketConnectionStatusDisconnected = -1,     //未连接
    GACSocketConnectionStatusConnecting = 0,        //连接中
    GACSocketConnectionStatusConnected = 1          //已连接
};

typedef void(^SocketDidReadBlock)(NSError* __nullable error,id __nullable date);

@protocol GACSocketDelegate <NSObject>

@optional
/**
 * 监听到服务器发送过来的消息
 * @param data          数据
 * @param type          类型 目前就三种情况（receive message / kick out / default / ConnectionAuthAppraisal）
 */
-(void)socketReadedData:(nullable id)data forType:(NSInteger)type;

/**
 * 连上时
 */
-(void)socketDidConnect;

/**
 * 建联时检测到token无效
 */
-(void)connectionAuthappraisalFailedWithError:(nonnull NSError*)error;

@end

@interface CocoaAsyncSocketManager : NSObject

//连接状态
@property(nonatomic,assign,readonly) GACSocketConnectionStatus connectStatus;
//当前请求通道
@property(nonatomic,strong,readonly) NSString* _Nullable currentCommunicationChannel;
//socket 回调
@property(nonatomic,weak,nullable) id<GACSocketDelegate> socketDelegate;

/**
 * 获取socket单例
 * @return 单例对象
 */
+(instancetype _Nullable )shareInstanceSocketManager;

/**
 * 初始化socket
 * @param config    初始化socket的配置信息
 */
-(void)createSocketWithConfig:(GACConnectConfig*_Nullable)config;

/**
 * 初始化socket
 * @param token             token
 * @param reqeustChannel    请求参数
 */
-(void)createSocketWithToken:(NSString*_Nullable)token channel:(NSString*_Nullable)reqeustChannel;

/**
 * socket断开链接
 */
-(void)disconnectSocket;

/**
 * 与服务器进行通信
 * @param type      请求类型
 * @param body      请求体
 */
-(void)socketWriteDataWithReqeustType:(GACReqeustType)type reqeustBody:(NSDictionary*_Nullable)body completion:(SocketDidReadBlock _Nullable )callback;

@end
