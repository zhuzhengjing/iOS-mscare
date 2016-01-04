//
//  KMNetAPI.m
//  InstantCare
//
//  Created by bruce-zhu on 15/12/4.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "KMNetAPI.h"
#import "AFNetworking.h"

@interface KMNetAPI()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) KMRequestResultBlock requestBlock;

@end

@implementation KMNetAPI

+ (instancetype)manager
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }

    return self;
}

/**
 *  POST
 *
 *  @param url   url
 *  @param body  post body
 *  @param block 结果返回block
 */
- (void)postWithURL:(NSString *)url body:(NSString *)body block:(KMRequestResultBlock)block
{
    // debug
    DMLog(@"-> %@  %@", url, body);

    NSData *httpBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.timeoutInterval = 60;
    [request setURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:httpBody];
    
    self.requestBlock = block;
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

/**
 *  获取室内传感器数据
 */
- (void)getInsideDataFromServerWithBlock:(KMRequestResultBlock)block
{
    self.requestBlock = block;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;

    [manager GET:[NSString stringWithFormat:@"http://%@/api/get_status/G3-001", kHostAddress]
      parameters:nil
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                          encoding:NSUTF8StringEncoding];
             DMLog(@"<- %@", jsonString);
             if (self.requestBlock) {
                 self.requestBlock(0, [HBSensorModel mj_objectWithKeyValues:responseObject]);
             }
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             if (self.requestBlock) {
                 self.requestBlock((int)error.code, nil);
             }
             self.requestBlock = nil;
         }];
}

/**
 *  获取室外传感器数据
 */
- (void)getOutSideDataFromServerWithBlock:(KMRequestResultBlock)block
{
    self.requestBlock = block;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;

    [manager GET:[NSString stringWithFormat:@"http://%@/api/get_status/G3-002", kHostAddress]
      parameters:nil
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                          encoding:NSUTF8StringEncoding];
             DMLog(@"<- %@", jsonString);
             if (self.requestBlock) {
                 self.requestBlock(0, [HBSensorModel mj_objectWithKeyValues:responseObject]);
             }
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             if (self.requestBlock) {
                 self.requestBlock((int)error.code, nil);
             }
             self.requestBlock = nil;
         }];
}

/**
 *  获取空气过滤器的状态
 *
 *  @param block 结果返回的block
 */
- (void)getRelayStatus:(KMRequestResultBlock)block
{
    self.requestBlock = block;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    
    [manager GET:[NSString stringWithFormat:@"http://%@/api/gpio/relays", kHostAddress]
      parameters:nil
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                          encoding:NSUTF8StringEncoding];
             DMLog(@"<- %@", jsonString);
             if (self.requestBlock) {
                 self.requestBlock(0, [HBRelayModel mj_objectWithKeyValues:responseObject]);
             }
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             if (self.requestBlock) {
                 self.requestBlock((int)error.code, nil);
             }
             self.requestBlock = nil;
         }];
}

/**
 *  更新空气过滤器状态
 *
 *  @param newStatus 是否打开
 *  @param block     结果返回block
 */
- (void)updateRelaysStatus:(BOOL)newStatus
                     block:(KMRequestResultBlock)block
{
    self.requestBlock = block;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    
    [manager GET:[NSString stringWithFormat:@"http://%@/api/gpio/relays?value=%d", kHostAddress, newStatus]
      parameters:nil
         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
             NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                          encoding:NSUTF8StringEncoding];
             DMLog(@"<- %@", jsonString);
             if (self.requestBlock) {
                 self.requestBlock(0, [HBRelayModel mj_objectWithKeyValues:responseObject]);
             }
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             if (self.requestBlock) {
                 self.requestBlock((int)error.code, nil);
             }
             self.requestBlock = nil;
         }];
}

#pragma mark - 连接成功
- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)aResponse
{
    self.data.length = 0;
}

#pragma mark 存储数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData
{
    [self.data appendData:incomingData];
}

#pragma mark 完成加载
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *jsonData = [[NSString alloc] initWithData:self.data
                                               encoding:NSUTF8StringEncoding];

    // debug
    DMLog(@"<- %@", jsonData);

    if (self.requestBlock) {
        self.requestBlock(0, jsonData);
    }

    self.requestBlock = nil;
}

#pragma mark 连接错误
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.requestBlock) {
        self.requestBlock((int)error.code, nil);
    }

    self.requestBlock = nil;
}

@end
