//
//  ViewController.m
//  socketDemo
//
//  Created by 刘冉 on 2017/6/13.
//  Copyright © 2017年 刘冉. All rights reserved.
/*
 使用苹果原生socket进行数据的通信
 */

#import "ViewController.h"
#import <sys/socket.h> //socket相关
#import <netinet/in.h>  //internet相关
#import <arpa/inet.h>   //地址解析协议相关

@interface ViewController ()

@property(nonatomic,strong)UITextField* ip;
@property(nonatomic,strong)UITextField* port;

@property(nonatomic,strong)UIButton* connection;
@property(nonatomic,strong)UITextField* msg;

@property(nonatomic,strong)UIButton* send;

@property(nonatomic,strong)UILabel* receiveMsg;

@property(nonatomic,strong)UIButton* closeConnection;
//client Socket
@property(nonatomic,assign)int clientSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.ip];
    [self.view addSubview:self.port];
    [self.view addSubview:self.connection];
    [self.view addSubview:self.msg];
    [self.view addSubview:self.send];
    [self.view addSubview:self.receiveMsg];
    [self.view addSubview:self.closeConnection];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    for (UIView* view in self.view.subviews) {
        if ([view isKindOfClass:[UITextField class]] && [view becomeFirstResponder]) {
            [view resignFirstResponder];
        }
    }
}

#pragma mark - 创建socket
-(BOOL)connection:(NSString*)hostText port:(int)port{
    /**
     参数
     domain:    协议域，AF_INET（IPV4的网络开发）
     type:      Socket 类型，SOCK_STREAM(TCP)/SOCK_DGRAM(UDP，报文)
     protocol:  IPPROTO_TCP，协议，如果输入0，可以根据第二个参数，自动选择协议
     
     返回值
     socket，如果 > 0 就表示成功
     */
    self.clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (self.clientSocket > 0) {
        NSLog(@"socket create sucess %d",self.clientSocket);
    } else {
        NSLog(@"socket create error");
    }
    //connection 连接到“服务器”
    /**
     参数
     1> 客户端socket
     2> 指向数据结构sockaddr的指针，其中包括目的端口和IP地址
     服务器的"结构体"地址，C语言没有对象
     3> 结构体数据长度
     返回值
     0 成功/其他 错误代号，非0即真
     */
    struct sockaddr_in serverAddress;
    //IPv4- 协议
    serverAddress.sin_family = AF_INET;
    //inet_addr函数可以把IP地址转换成一个整数
    serverAddress.sin_addr.s_addr = inet_addr(hostText.UTF8String);
    //端口小端存储
    serverAddress.sin_port = htons(port);
    int result = connect(self.clientSocket, (const struct sockaddr*)&serverAddress, sizeof(serverAddress));
    //如果链接成功，返回YES
    return (result == 0);
}

//发送和接收字符串
-(NSString*)sendAndReceiveMsg:(NSString*)msg{
    /**
     参数
     1> 客户端socket
     2> 发送内容地址 void * == id
     3> 发送内容长度
     4> 发送方式标志，一般为0
     返回值
     如果成功，则返回发送的字节数，失败则返回SOCKET_ERROR
     */
    ssize_t sendLen = send(self.clientSocket, msg.UTF8String, sizeof(msg.UTF8String), 0);
    NSLog(@"%ld",sendLen);
    if (sendLen > 0) {
        self.msg.text = @"";
    }
    // recv 接收 - 几乎所有的网络访问，都是有来有往的
    /**
     参数
     第一个int :创建的socket
     void *：接收内容的地址
     size_t：接收内容的长度
     第二个int.：接收数据的标记 0，就是阻塞式，一直等待服务器的数据
     返回值 接收到的数据长度
     */
    // unsigned char，字符串的数组
    uint8_t buffer[1024];
    ssize_t receLen = recv(self.clientSocket, buffer, sizeof(buffer), 0);
    //从buffer中读取服务器反馈回来的数据
    //按照服务器反馈回来的长度进行解析，从buffer中读取二进制数据，建立NsdData对象
    NSData* data = [NSData dataWithBytes:buffer length:receLen];
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

//断开链接
-(void)disConnection{
    __weak typeof(self) weakSelf = self;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"是否要断开链接?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* sure = [UIAlertAction actionWithTitle:@"sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        close(weakSelf.clientSocket);
        weakSelf.send.enabled = NO;
    }];
    [alert addAction:sure];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)connection:(UIButton*)sender{
    if (self.ip.text.length == 0 || self.port.text.length == 0) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请填写ip、端口号" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* sure = [UIAlertAction actionWithTitle:@"sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:sure];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if ([self connection:self.ip.text port:self.port.text.intValue]) {
        self.receiveMsg.text = @"connection sucess";
        self.send.enabled = YES;
    } else {
        self.receiveMsg.text = @"connection error";
    }
}

-(void)sendMsg:(UIButton*)sender{
    if (self.msg.text.length == 0) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示信息" message:@"不可发送空消息" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* sure = [UIAlertAction actionWithTitle:@"sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:sure];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    self.receiveMsg.text = [self sendAndReceiveMsg:self.msg.text];
}

-(void)closeConnection:(UIButton*)sender{
    [self disConnection];
}

#pragma mark - getter
-(UITextField *)ip{
    if (!_ip) {
        _ip = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, 120, 50)];
        _ip.placeholder = @"ip地址";
    }
    return _ip;
}

-(UITextField *)port{
    if (!_port) {
        _port = [[UITextField alloc] initWithFrame:CGRectMake(140, 100, 90, 50)];
        _port.placeholder = @"端口号";
    }
    return _port;
}

-(UITextField *)msg{
    if (!_msg) {
        _msg = [[UITextField alloc] initWithFrame:CGRectMake(10, 170, self.view.bounds.size.width/3*2, 50)];
        _msg.placeholder = @"请输入要发送的信息";
    }
    return _msg;
}

-(UIButton *)connection{
    if (!_connection) {
        _connection = [UIButton buttonWithType:UIButtonTypeCustom];
        _connection.frame = CGRectMake(250, 100, 100, 50);
        [_connection setTitle:@"connection" forState:UIControlStateNormal];
        [_connection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_connection addTarget:self action:@selector(connection:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _connection;
}

-(UIButton *)send{
    if (!_send) {
        _send = [UIButton buttonWithType:UIButtonTypeCustom];
        _send.frame = CGRectMake(self.view.bounds.size.width/3*2 + 30, 170, 80, 50);
        [_send setTitle:@"sendMsg" forState:UIControlStateNormal];
        [_send setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_send addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _send;
}

-(UIButton *)closeConnection{
    if (!_closeConnection) {
        _closeConnection = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeConnection.frame = CGRectMake(10, 320, 200, 40);
        [_closeConnection setTitle:@"closeConnection" forState:UIControlStateNormal];
        [_closeConnection setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_closeConnection addTarget:self action:@selector(closeConnection:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeConnection;
}

-(UILabel *)receiveMsg{
    if (!_receiveMsg) {
        _receiveMsg = [[UILabel alloc] initWithFrame:CGRectMake(10, 250, self.view.bounds.size.width - 20, 50)];
        _receiveMsg.backgroundColor = [UIColor yellowColor];
        _receiveMsg.textColor = [UIColor redColor];
    }
    return _receiveMsg;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
