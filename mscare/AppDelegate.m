//
//  AppDelegate.m
//  mscare
//
//  Created by MissionHealth on 15/8/25.
//  Copyright (c) 2015年 kangmei. All rights reserved.
//

#import "AppDelegate.h"
#import "IQKeyboardManager.h"
#import "Reachability.h"
#import "HKSlideMenu3DController.h"
#import "SNLoginVC.h"
#import "SNAboutVC.h"
#import "KMNetAPI.h"

@interface AppDelegate ()

@property (nonatomic, strong) UITabBarController *mainTabBarVC;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    self.window.rootViewController = self.slideMenuVC;
    [self.window makeKeyAndVisible];

    [self configRemotePush];
    [self checkRemotePushMsg:launchOptions];

    // 配置键盘
    [self configIQKeyBoardManager];
    // 配置HUD
    [self configSVHUD];
    // 注册网络通知
    [self configReachability];

    return YES;
}

- (HKSlideMenu3DController *)slideMenuVC
{
    if (_slideMenuVC == nil) {
        [self configSlideMenu];
    }

    return _slideMenuVC;
}

#pragma mark - 首页配置侧滑功能
- (void)configSlideMenu
{
    _slideMenuVC = [[HKSlideMenu3DController alloc] init];
    _slideMenuVC.view.frame =  [[UIScreen mainScreen] bounds];
    [SNAboutVC shareInstance].view.frame = [[UIScreen mainScreen] bounds];
    _slideMenuVC.menuViewController = [SNAboutVC shareInstance];

    SNLoginVC *loginVC = [[SNLoginVC alloc] init];
    loginVC.view.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
    _slideMenuVC.mainViewController = loginVC;
    _slideMenuVC.enablePan = YES;
    _slideMenuVC.view.backgroundColor = [UIColor whiteColor];
}

+ (AppDelegate *)mainDelegate
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - 配置键盘样式
- (void)configIQKeyBoardManager
{
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    manager.enable = YES;
    manager.shouldResignOnTouchOutside = YES;
    manager.shouldToolbarUsesTextFieldTintColor = YES;
    manager.enableAutoToolbar = YES;
    manager.shouldShowTextFieldPlaceholder = YES;
    manager.toolbarManageBehaviour = IQAutoToolbarByPosition;
}

#pragma mark - 配置HUD
- (void)configSVHUD
{
    [SVProgressHUD setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
}

#pragma mark - 注册网络状态通知
- (void)configReachability
{
    // 使用百度测试网络是否正常
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [reach startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *reach = [note object];

    NetworkStatus status = [reach currentReachabilityStatus];
    NSLog(@"reachabilityChanged: %d", (int)status);

    memberShare.currentNetworkStatus = status;
}

- (void)configRemotePush
{
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    UIUserNotificationSettings *set = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge |
                                                                                    UIUserNotificationTypeSound |
                                                                                    UIUserNotificationTypeAlert)
                                                                        categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:set];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // 去掉空格和<>
    NSString *str = [NSString stringWithFormat:@"%@", deviceToken];
    NSString *newString = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"<" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@">" withString:@""];
    DMLog(@"## deviceToken: %@", newString);

    // deviceToken变化上传服务器
    if ([newString isEqualToString:memberShare.deviceToken] == NO) {
        memberShare.deviceToken = newString;
        // update server deviceToken
        [[KMNetAPI manager] uploadDeviceTokenWithUser:@"Bruce"
                                          deviceToken:newString
                                                block:^(int code, id resModel) {
                                                    HBNetResModel *model = resModel;
                                                    if (code != 0 || model.state != 1) {
                                                        [SVProgressHUD showErrorWithStatus:@"deviceToken上传失败"];
                                                    }
                                                }];
    }
}

#pragma mark - 收到推送消息
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DMLog(@"-> userInfo: %@", userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveRemoteNotification"
                                                        object:userInfo];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

/**
 *  检查用户是否点击推送消息进入APP，如果是则保存为pushNotificationKey
 *  在ViewController中进行统一处理
 *
 *  @param launchOptions launchOptions
 */
- (void)checkRemotePushMsg:(NSDictionary *)launchOptions
{
    // 检查用户是否通过通知进入程序
    if (launchOptions) {
        NSDictionary* pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (pushNotificationKey) {
            // 先保存，登录成功后在KMMainVC中处理推送消息
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:pushNotificationKey forKey:@"pushNotificationKey"];
        }
    }
}

@end
