//
//  ExtraInfo.h
//
//
//  Created by admin on 16/1/28.
//
//

#import <Cordova/CDV.h>
#import "WXApi.h"
#import "WXApiObject.h"

#import "WeiboSDK.h"

enum  WechatSharingType {
    WXSharingTypeApp = 1,
    WXSharingTypeEmotion,
    WXSharingTypeFile,
    WXSharingTypeImage,
    WXSharingTypeMusic,
    WXSharingTypeVideo,
    WXSharingTypeWebPage
};

@protocol sendMsgToWeChatViewDelegate <NSObject>
- (void) changeScene:(NSInteger)scene;
- (void) sendTextContent;
- (void) sendImageContent;
- (void) sendPay;
- (void) sendWexinPay;
@end


@interface Gouxin : CDVPlugin<WXApiDelegate,WeiboSDKDelegate>


- (void)pluginInitialize;

@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) NSString *wechatAppId;


@property (strong, nonatomic) NSString *wbAppKey;
@property (strong, nonatomic) NSString *wbtoken;
@property (strong, nonatomic) NSString *wbRefreshToken;
@property (strong, nonatomic) NSString *wbCurrentUserID;

//微信朋友分享
- (void)shareToWeiChatFriends:(CDVInvokedUrlCommand*)command;
//微信朋友圈 分享
- (void)shareToWeiChatFriendsCircle:(CDVInvokedUrlCommand*)command;
//QQ分享
- (void)shareToQQ:(CDVInvokedUrlCommand *)command;
//微博分享
- (void)shareToWeibo:(CDVInvokedUrlCommand *)command;

//微信支付
- (void)weiChatToPay:(CDVInvokedUrlCommand*)command;
//支付宝支付
- (void)aliToPay:(CDVInvokedUrlCommand*)command;

@end







