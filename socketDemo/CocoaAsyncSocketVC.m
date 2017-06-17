//
//  CocoaAsyncSocketVC.m
//  socketDemo
//
//  Created by 刘冉 on 2017/6/13.
//  Copyright © 2017年 刘冉. All rights reserved.


#import "CocoaAsyncSocketVC.h"
#import "CocoaAsyncSocketManager.h"
#import "GACConnectConfig.h"

#define KDefaultChannel @"dkf"

@interface CocoaAsyncSocketVC ()

@property(nonatomic,strong)GACConnectConfig* conectConfig;
@property(nonatomic,strong)UIButton* connection;

@end

@implementation CocoaAsyncSocketVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.connection];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //连接环境2选一
    //使用默认的连接环境
    [[CocoaAsyncSocketManager shareInstanceSocketManager] createSocketWithToken:@"f14c4e6f6c89335ca5909031d1a6efa9" channel:KDefaultChannel];
    //自定义配置连接环境
    [[CocoaAsyncSocketManager shareInstanceSocketManager] createSocketWithConfig:self.conectConfig];
}

-(void)connection:(UIButton*)sender{
    NSDictionary* requestBody = @{};
    [[CocoaAsyncSocketManager shareInstanceSocketManager] socketWriteDataWithReqeustType:GACReqeustType_GetConversationList reqeustBody:requestBody completion:^(NSError * _Nullable error, id  _Nullable date) {
        if (error) {
            
        } else {
            
        }
    }];
}

-(GACConnectConfig *)conectConfig{
    if (!_conectConfig) {
        _conectConfig = [[GACConnectConfig alloc] init];
        _conectConfig.channels = KDefaultChannel;
        _conectConfig.currentChnanel = KDefaultChannel;
        _conectConfig.host = @"online socket address";
        _conectConfig.port = 7070;
        _conectConfig.socketVerison = 5;
    }
    _conectConfig.token = @"f14c4e6f6c89335ca5909031d1a6efa9";
    return _conectConfig;
}

-(UIButton *)connection{
    if (!_connection) {
        _connection = [UIButton buttonWithType:UIButtonTypeCustom];
        _connection.frame = CGRectMake(100, 100, 80, 60);
        [_connection setTitle:@"connection" forState:UIControlStateNormal];
        [_connection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_connection addTarget:self action:@selector(connection:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _connection;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
