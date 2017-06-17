//
//  CocoaAsyncSocketManager.m
//  socketDemo
//
//  Created by 刘冉 on 2017/6/16.
//  Copyright © 2017年 刘冉. All rights reserved.
//

#import "CocoaAsyncSocketManager.h"
#import <GCDAsyncSocket.h>
#import "GCKeyChainManager.h"
#import "GCDAsyncSocketManager.h"
#import "GACErrorManager.h"
#import "GACSocketModel.h"
#import <AFNetworkReachabilityManager.h>

static CocoaAsyncSocketManager* manager = nil;
/**默认通信协议版本号*/
static NSInteger PROTOCOL_VERISON = 7;

@interface CocoaAsyncSocketManager ()<GCDAsyncSocketDelegate>

@property(nonatomic,strong)NSString* socketAuthAppraisalChannel;//socket验证通道，支持多通道
@property(nonatomic,strong)NSMutableDictionary* requestMap;
@property(nonatomic,strong)GCDAsyncSocketManager* socketManager;
@property(nonatomic,assign)NSTimeInterval interval;//服务器与本地的时间差
@property(nonatomic,strong,nonnull)GACConnectConfig* connectConfig;


@end

@implementation CocoaAsyncSocketManager

+(instancetype)shareInstanceSocketManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CocoaAsyncSocketManager alloc] init];
    });
    return manager;
}

-(instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.socketManager = [GCDAsyncSocketManager shareInstance];
    self.requestMap = [NSMutableDictionary dictionary];
    [self startMonitoringNetwork];
    return self;
}

#pragma mark - socket actions
-(void)createSocketWithConfig:(GACConnectConfig *)config{
    if (!config.token.length || ! config.channels.length || !config.host.length) {
        return;
    }
    
    self.connectConfig = config;
    self.socketAuthAppraisalChannel = config.channels;
    [GCKeyChainManager sharedInstance].token = config.token;
    [self.socketManager changeHost:config.host port:config.port];
    PROTOCOL_VERISON = config.socketVerison;
    [self.socketManager connectSocketWithDelegate:self];
}

-(void)createSocketWithToken:(NSString *)token channel:(NSString *)reqeustChannel{
    if (!token || !reqeustChannel) {
        return;
    }
    
    self.socketAuthAppraisalChannel = reqeustChannel;
    [GCKeyChainManager sharedInstance].token = token;
    [self.socketManager changeHost:@"online socket address" port:7070];
    
    [self.socketManager connectSocketWithDelegate:self];
}

-(void)disconnectSocket{
    [self.socketManager disconnectSocket];
}

-(void)socketWriteDataWithReqeustType:(GACReqeustType)type reqeustBody:(NSDictionary *)body completion:(SocketDidReadBlock)callback{
    if (self.socketManager.connectionStatus == -1) {
        NSLog(@"socket 未连接");
        if (callback) {
            callback([GACErrorManager errorWithErrorCode:2003],nil);
        }
        return;
    }
    
    NSString* blockReqeustID = [self createRequestID];
    if (callback) {
        [self.requestMap setObject:callback forKey:blockReqeustID];
    }
    
    GACSocketModel* socketModel = [[GACSocketModel alloc] init];
    socketModel.version = PROTOCOL_VERISON;
    socketModel.reqType = type;
    socketModel.reqId = blockReqeustID;
    socketModel.requestChannel = self.currentCommunicationChannel;
    socketModel.body = body;
    
    NSString* requestBody = [socketModel socketModelToJSONString];
    [self.socketManager socketWriteData:requestBody];
}

#pragma mark - GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    GACSocketModel* socketModel = [[GACSocketModel alloc] init];
    socketModel.version = PROTOCOL_VERISON;
    socketModel.reqType = GACReqeustType_ConnectionAuthAppraisal;
    socketModel.reqId = [self createRequestID];
    socketModel.requestChannel = self.socketAuthAppraisalChannel;
    socketModel.body = @{@"token":[GCKeyChainManager sharedInstance].token ?: @"",
                         @"endpoint":@"ios"};
    
    [self.socketManager socketWriteData:[socketModel socketModelToJSONString]];
    
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", socket, host, port);
    NSLog(@"Cool, I'm connected! That was easy.");
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    GACSocketModel* socketModel = [[GACSocketModel alloc] init];
    socketModel.version = PROTOCOL_VERISON;
    socketModel.reqType = GACReqeustType_ConnectionAuthAppraisal;
    socketModel.reqId = [self createRequestID];
    socketModel.requestChannel = self.socketAuthAppraisalChannel;
    socketModel.body = @{
                         @"token":[GCKeyChainManager sharedInstance].token == nil ? @"" : [GCKeyChainManager sharedInstance].token,
                         @"endpoint":@"ios"};
    NSString* requestBody = [socketModel socketModelToJSONString];
    [self.socketManager socketDidDisconnectBeginSendReconnect:requestBody];
    NSLog(@"socketDidDisconnect:%p withError: %@", socket, err);
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError* jsonError;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
    NSLog(@"socket - receive data %@",json);
    
    if (jsonError) {
        [self.socketManager socketBeginReadData];
        NSLog(@"json 解析错误 error:%@",jsonError);
        return;
    }
    
    NSInteger requestType = [json[@"reqType"] integerValue];
    NSInteger errorCode = [json[@"status"] integerValue];
    NSDictionary* body = @{};
    NSString* requestID = json[@"reqID"];
    NSString* requestChannel = nil;
    if ([[json allKeys] containsObject:@"requestChannel"]) {
        requestChannel = json[@"requestChannel"];
    }
    
    SocketDidReadBlock didReadBlock = self.requestMap[requestID];
    
    if (errorCode != 0) {
        NSError* error = [GACErrorManager errorWithErrorCode:errorCode];
        if (requestType == GACReqeustType_ConnectionAuthAppraisal && [self.socketDelegate respondsToSelector:@selector(connectionAuthappraisalFailedWithError:)]) {
            [self.socketDelegate connectionAuthappraisalFailedWithError:[GACErrorManager errorWithErrorCode:1005]];
        }
        if (didReadBlock) {
            didReadBlock(error,body);
        }
        return;
    }
    switch (requestType) {
        case GACReqeustType_ConnectionAuthAppraisal:{
            [self didConnectionAuthAppraisal];
            NSDictionary* systemTimeDic = [body mutableCopy];
            [self differentOfLocalTimeAndServerTime:[systemTimeDic[@"system_time"] longLongValue]];
        }break;
        case GACRequestType_Beat: {
            [self.socketManager resetBeatCount];
        }break;
        case GACReqeustType_GetConversationList:{
            if (didReadBlock) {
                didReadBlock(nil,body);
            }
        }break;
        default:{
            if ([self.socketDelegate respondsToSelector:@selector(socketReadedData:forType:)]) {
                [self.socketDelegate socketReadedData:body forType:requestType];
            }
        }
            break;
    }
}

#pragma mark - private methods

-(void)differentOfLocalTimeAndServerTime:(long long)serverTime{
    if (serverTime == 0) {
        self.interval = 0;
        return;
    }
    
    NSTimeInterval localTimeInterval = [NSDate date].timeIntervalSince1970 * 1000;
    self.interval = serverTime = localTimeInterval;
}

-(long long)simulateServerCreateTime{
    NSTimeInterval localTimeInterval = [NSDate date].timeIntervalSince1970 * 1000;
    localTimeInterval += 3600 * 8;
    localTimeInterval += self.interval;
    return localTimeInterval;
}

-(void)didConnectionAuthAppraisal{
    if ([self.socketDelegate respondsToSelector:@selector(socketDidConnect)]) {
        [self.socketDelegate socketDidConnect];
    }
    GACSocketModel* socketModel = [[GACSocketModel alloc] init];
    socketModel.version = PROTOCOL_VERISON;
    socketModel.reqType = GACRequestType_Beat;
    socketModel.user_mid = 0;
    
    NSString* beatBody = [NSString stringWithFormat:@"%@\r\n",[socketModel mj_JSONString]];
    [self.socketManager socketDidConnectBeginSendBeat:beatBody];
}

-(NSString*)createRequestID{
    NSInteger timeInterval = [NSDate date].timeIntervalSince1970* 1000000;
    NSString* randomRequestID = [NSString stringWithFormat:@"%ld%u",timeInterval,arc4random()%100000];
    return randomRequestID;
}

-(void)startMonitoringNetwork{
    AFNetworkReachabilityManager* netManager = [AFNetworkReachabilityManager sharedManager];
    [netManager startMonitoring];
    __weak __typeof(&*self) weakSelf = self;
    [netManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                if (weakSelf.socketManager.connectionStatus != -1) {
                    [weakSelf disconnectSocket];
                }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                if (weakSelf.socketManager.connectionStatus == -1) {
                    [weakSelf createSocketWithToken:[GCKeyChainManager sharedInstance].token channel:weakSelf.socketAuthAppraisalChannel];
                }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - getter
-(GACSocketConnectionStatus)connectStatus{
    return self.socketManager.connectionStatus;
}

@end
