//
//  Created by admin on 16/1/28.
//
//

#import "Gouxin.h"

//QQ分享
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>
#import <TencentOpenAPI/TencentOAuth.h>

//支付
#import "payRequsestHandler.h"

#import "AliOrder.h"
#import "DataSigner.h"
#import "Constant.h"
#import <AlipaySDK/AlipaySDK.h>
#import "AppDelegate.h"
#import "WeiboSDK.h"

@implementation Gouxin


@synthesize wbAppKey;
@synthesize wbtoken;
@synthesize wbCurrentUserID;
@synthesize wbRefreshToken;

#pragma mark 初始化
- (void)pluginInitialize{
    NSString* appId = @"这里是申请的微信appId";
    if(appId){
        self.wechatAppId = appId;
        [WXApi registerApp: appId];
    }
}

- (void)isWXAppInstalled:(CDVInvokedUrlCommand *)command
{
    self.currentCallbackId = command.callbackId;
    
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[WXApi isWXAppInstalled]];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

#pragma mark "WXApiDelegate"
/**
 * Not implemented
 */
 - (void)onReq:(BaseReq *)req
 {
     NSLog(@"%@", req);
 }
 
 - (void)onResp:(BaseResp *)resp
 {
     BOOL success = NO;
     NSString *message = @"Unknown";
     NSDictionary *response = nil;
     
     switch (resp.errCode)
     {
     case WXSuccess:
     success = YES;
     break;
     
     case WXErrCodeCommon:
     message = @"普通错误类型";
     break;
     
     case WXErrCodeUserCancel:
     message = @"用户点击取消并返回";
     break;
     
     case WXErrCodeSentFail:
     message = @"发送失败";
     break;
     
     case WXErrCodeAuthDeny:
     message = @"授权失败";
     break;
     
     case WXErrCodeUnsupport:
     message = @"微信不支持";
     break;
     }
     
     if (success)
     {
         if ([resp isKindOfClass:[SendAuthResp class]])
         {
         // fix issue that lang and country could be nil for iPhone 6 which caused crash.
         SendAuthResp* authResp = (SendAuthResp*)resp;
         response = @{
         @"code": authResp.code != nil ? authResp.code : @"",
         @"state": authResp.state != nil ? authResp.state : @"",
         @"lang": authResp.lang != nil ? authResp.lang : @"",
         @"country": authResp.country != nil ? authResp.country : @"",
     };
     
     CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
     [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
    
     }
     else
     {
         [self successWithCallbackID:self.currentCallbackId];
     }
     }
     else
     {
         [self failWithCallbackID:self.currentCallbackId withMessage:message];
     }
     
     self.currentCallbackId = nil;
 }


#pragma mark - 考虑到项目后期可能会有很大的改动和扩展，所以分开处理
#pragma mark 微信朋友分享
- (void)shareToWeiChatFriends:(CDVInvokedUrlCommand*)command{
    [self shareMethodHandle:command];
    
}
#pragma mark 微信朋友圈 分享
- (void)shareToWeiChatFriendsCircle:(CDVInvokedUrlCommand*)command{
    [self shareMethodHandle:command];
}

- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{

    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(void)shareMethodHandle:(CDVInvokedUrlCommand *)command{
    
    if ([command.arguments count] <= 0) return;
    NSDictionary *pluginParam = [command.arguments objectAtIndex:0];
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = [pluginParam objectForKey:@"title"];
    message.description = [pluginParam objectForKey:@"summary"];
    message.thumbData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[pluginParam objectForKey:@"image_url"]]];
    
    if (message.thumbData.length > 16380) {
        NSLog(@"传递过来的图片已经大于 32k == %ld",message.thumbData.length);
        UIImage *image = [[UIImage alloc] initWithData:message.thumbData ];
        image = [self scaleToSize:image size:CGSizeMake(100, 100)];
        message.thumbData = UIImageJPEGRepresentation(image, 1);
    }
    
    WXAppExtendObject *ext = [WXAppExtendObject object];
    ext.extInfo = @"<xml>extend info</xml>";
    ext.url = [pluginParam objectForKey:@"target_url"];
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = 0;
    if ([command.methodName  isEqual:@"shareToWeiChatFriends"]) { //微信朋友分享
        req.scene = WXSceneSession;
    }
    if([command.methodName  isEqual:@"shareToWeiChatFriendsCircle"]){ //微信朋友圈分享
        req.scene = WXSceneTimeline;
    }
    [WXApi sendReq:req];
}


#pragma mark QQ分享
- (void)shareToQQ:(CDVInvokedUrlCommand *)command{
    
    NSDictionary *pluginParam = [command.arguments objectAtIndex:0];
    
    NSString *title = [pluginParam objectForKey:@"title"];
    NSString *summary = [pluginParam objectForKey:@"summary"];
    NSString *target_url = [pluginParam objectForKey:@"target_url"];
    NSString *image_url = [pluginParam objectForKey:@"image_url"];

    QQApiNewsObject* img = [QQApiNewsObject objectWithURL:[NSURL URLWithString:target_url] title:title description:summary previewImageURL:[NSURL URLWithString:image_url]];
    
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
    
    //将内容分享到qq
    if ([command.methodName isEqual:@"shareToQQ"]) {
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [self handleSendResult:sent];
    }
    //将内容分享到qzone
    if ([command.methodName isEqual:@"shaerToQQqzone"]) {
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sent];
    }
}

#pragma mark 分享到QQ的结果回调
- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"App未注册" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送参数错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"未安装手Q" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"API接口不支持" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        case EQQAPISENDFAILD:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送失败" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        default:
        {
            //这里还没有测试回调是否是正确的
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[WXApi isWXAppInstalled]];
            [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
            break;
        }
    }
}


#pragma mark 微博分享
- (void)shareToWeibo:(CDVInvokedUrlCommand *)command{
    
    self.wbAppKey = @"这里是申请的微博App Key";
    
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = kRedirectURI;
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:[self messageToShare:command] authInfo:authRequest access_token:self.wbtoken];
    request.userInfo = @{@"ShareMessageFrom": @"SendMessageToWeiboViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
    
}

- (WBMessageObject *)messageToShare:(CDVInvokedUrlCommand *)command{
    
    NSDictionary *pluginParam = [command.arguments objectAtIndex:0];
    
    WBMessageObject *message = [WBMessageObject message];
    
    NSString *title = [NSString stringWithFormat:@"%@ %@ %@",[pluginParam objectForKey:@"title"],[pluginParam objectForKey:@"summary"],[pluginParam objectForKey:@"target_url"]];
    
    message.text = title;
    
    WBImageObject *webImage = [WBImageObject object];
    webImage.imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[pluginParam objectForKey:@"image_url"]]];
    message.imageObject = webImage;
    
//    消息中图片内容和多媒体内容不能共存
    /*
    WBWebpageObject *webpage = [WBWebpageObject object];
    webpage.objectID = @"identifier1";
    webpage.title =[pluginParam objectForKey:@"title"];
    webpage.description = [pluginParam objectForKey:@"summary"];
    webpage.thumbnailData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[pluginParam objectForKey:@"image_url"]]];
    webpage.scheme = [pluginParam objectForKey:@"target_url"];
    webpage.webpageUrl = [pluginParam objectForKey:@"target_url"];
    message.mediaObject = webpage;
     */

    return message;
}

#pragma mark 微博 返回的结果
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class])
    {
        NSString *title = NSLocalizedString(@"发送结果", nil);
        NSString *message = [NSString stringWithFormat:@"%@: %d\n%@: %@\n%@: %@", NSLocalizedString(@"响应状态", nil), (int)response.statusCode, NSLocalizedString(@"响应UserInfo数据", nil), response.userInfo, NSLocalizedString(@"原请求UserInfo数据", nil),response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
        WBSendMessageToWeiboResponse* sendMessageToWeiboResponse = (WBSendMessageToWeiboResponse*)response;
        NSString* accessToken = [sendMessageToWeiboResponse.authResponse accessToken];
        if (accessToken)
        {
            self.wbtoken = accessToken;
        }
        NSString* userID = [sendMessageToWeiboResponse.authResponse userID];
        if (userID) {
            self.wbCurrentUserID = userID;
        }
//        [alert show];
    }
    else if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
        NSString *title = NSLocalizedString(@"认证结果", nil);
        NSString *message = [NSString stringWithFormat:@"%@: %d\nresponse.userId: %@\nresponse.accessToken: %@\n%@: %@\n%@: %@", NSLocalizedString(@"响应状态", nil), (int)response.statusCode,[(WBAuthorizeResponse *)response userID], [(WBAuthorizeResponse *)response accessToken],  NSLocalizedString(@"响应UserInfo数据", nil), response.userInfo, NSLocalizedString(@"原请求UserInfo数据", nil), response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
        
        self.wbtoken = [(WBAuthorizeResponse *)response accessToken];
        self.wbCurrentUserID = [(WBAuthorizeResponse *)response userID];
        self.wbRefreshToken = [(WBAuthorizeResponse *)response refreshToken];
//        [alert show];
    }
    
    //这里是回调
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[WXApi isWXAppInstalled]];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];

    /* 这里是支付返回的结果
    else if ([response isKindOfClass:WBPaymentResponse.class])
    {
        NSString *title = NSLocalizedString(@"支付结果", nil);
        NSString *message = [NSString stringWithFormat:@"%@: %d\nresponse.payStatusCode: %@\nresponse.payStatusMessage: %@\n%@: %@\n%@: %@", NSLocalizedString(@"响应状态", nil), (int)response.statusCode,[(WBPaymentResponse *)response payStatusCode], [(WBPaymentResponse *)response payStatusMessage], NSLocalizedString(@"响应UserInfo数据", nil),response.userInfo, NSLocalizedString(@"原请求UserInfo数据", nil), response.requestUserInfo];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
//        [alert show];
    }
     */
    
    /*
     else if([response isKindOfClass:WBSDKAppRecommendResponse.class])
     {
     NSString *title = NSLocalizedString(@"邀请结果", nil);
     NSString *message = [NSString stringWithFormat:@"accesstoken:\n%@\nresponse.StatusCode: %d\n响应UserInfo数据:%@\n原请求UserInfo数据:%@",[(WBSDKAppRecommendResponse *)response accessToken],(int)response.statusCode,response.userInfo,response.requestUserInfo];
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
     message:message
     delegate:nil
     cancelButtonTitle:NSLocalizedString(@"确定", nil)
     otherButtonTitles:nil];
     [alert show];
     }else if([response isKindOfClass:WBShareMessageToContactResponse.class])
     {
     NSString *title = NSLocalizedString(@"发送结果", nil);
     NSString *message = [NSString stringWithFormat:@"%@: %d\n%@: %@\n%@: %@", NSLocalizedString(@"响应状态", nil), (int)response.statusCode, NSLocalizedString(@"响应UserInfo数据", nil), response.userInfo, NSLocalizedString(@"原请求UserInfo数据", nil),response.requestUserInfo];
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
     message:message
     delegate:nil
     cancelButtonTitle:NSLocalizedString(@"确定", nil)
     otherButtonTitles:nil];
     WBShareMessageToContactResponse* shareMessageToContactResponse = (WBShareMessageToContactResponse*)response;
     NSString* accessToken = [shareMessageToContactResponse.authResponse accessToken];
     if (accessToken)
     {
     self.wbtoken = accessToken;
     }
     NSString* userID = [shareMessageToContactResponse.authResponse userID];
     if (userID) {
     self.wbCurrentUserID = userID;
     }
     [alert show];
     }
     */
}

#pragma mark - "CDVPlugin Overrides"回调URL之后需要做的事情

- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:self.wechatAppId])
    {
        [WXApi handleOpenURL:url delegate:self];
    }
    
    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:self.wbAppKey])
    {
       [WeiboSDK handleOpenURL:url delegate:self];
    }
    
    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:@"QQ分享appkey"]) //QQ分享
    {
    }
    
    //跳转支付宝钱包进行支付，处理支付结果
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        //        NSLog(@"reslut = %@",resultDic);
        //解析返回状态码
        int resultSuccess = [[resultDic objectForKey:@"resultStatus"] intValue];
        //是9000代表支付成功
        if (resultSuccess==9000) {
            [self successWithCallbackID:self.currentCallbackId];
        }else {
            [self failWithCallbackID:self.currentCallbackId withMessage:@"支付失败"];
        }
        self.currentCallbackId = nil;
    }];
}


#pragma mark 微信支付
-(void)weiChatToPay:(CDVInvokedUrlCommand *)command {
    // save the callback id
    self.currentCallbackId = command.callbackId;
    //本实例只是演示签名过程， 请将该过程在商户服务器上实现
    //创建支付签名对象
    //    payRequsestHandler *req = [[payRequsestHandler alloc] autorelease];
    payRequsestHandler *req = [[payRequsestHandler alloc] init];
    //初始化支付签名对象
    [req init:APP_ID mch_id:MCH_ID];
    //设置密钥
    [req setKey:PARTNER_ID];
    NSDictionary * weixinPayPara = nil;
    if ([command.arguments count] > 0)
    {
        weixinPayPara =[command.arguments  objectAtIndex:0];
    }
    //    //获取到实际调起微信支付的参数后，在app端调起支付
    NSMutableDictionary *dict = [req sendWexinPay:weixinPayPara];
    
    if(dict == nil){
        //错误提示
        NSString *debug = [req getDebugifo];
        //[self alert:@"提示信息" msg:debug];
        //NSLog(@"%@\n\n",debug);
    }else{
        //NSLog(@"%@\n\n",[req getDebugifo]);
        //[self alert:@"确认" msg:@"下单成功，点击OK后调起支付！"];
        NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
        
        //调起微信支付
        PayReq* req             = [[PayReq alloc] init];
        req.openID              = [dict objectForKey:@"appid"];
        req.partnerId           = [dict objectForKey:@"partnerid"];
        req.prepayId            = [dict objectForKey:@"prepayid"];
        req.nonceStr            = [dict objectForKey:@"noncestr"];
        req.timeStamp           = stamp.intValue;
        req.package             = [dict objectForKey:@"package"];
        req.sign                = [dict objectForKey:@"sign"];
        
        [WXApi sendReq:req];
    }
}

#pragma mark 支付宝支付
-(void)aliToPay:(CDVInvokedUrlCommand *)command {
    
    self.currentCallbackId = command.callbackId;
    AliOrder *order = [[AliOrder alloc] init];
    // 签约成功后 支付宝自动分配
    order.partner = PartnerID;
    order.seller = SellerID;
    if ([command.arguments count] > 0)
    {
        NSDictionary *aliPayPara =[command.arguments  objectAtIndex:0];
        order.tradeNO = [NSString stringWithFormat:@"%d",1000000000-arc4random()%10000];//随机订单号
        //order.tradeNO = [aliPayPara objectForKey:@"outTradeNo"];
        //order.productName = @"购信订单";
        order.productName = [aliPayPara objectForKey:@"productName"];//商品标题////
        order.productDescription = [aliPayPara objectForKey:@"productDescribe"];//商品描述
        // 支付宝服务器主动通知商户网站里指定的页面http路径
        order.notifyURL =  [aliPayPara objectForKey:@"notify_url"];//"http://www.baidu.com";
        
        double total = [[aliPayPara objectForKey:@"total_fee"] doubleValue];
        NSString *total_fee = [NSString stringWithFormat:@"%.2f",total]; //可以在这里修改成测试金额
        order.amount = total_fee;
        
        // order.amount = total_fee;
        // 订单ID（由商家自行制定）
    }
    
    //order.subject = @"购信订单";
    // 固定值
    order.service = @"mobile.securitypay.pay";
    // 默认为1 商品购买
    order.paymentType = @"1";
    // 字符编码
    order.inputCharset = @"utf-8";
    // 未付款交易的超时时间 超时交易自动关闭 m分 h时 d天
    order.itBPay = @"30m";
    order.showUrl = @"m.alipay.com";
    
    // 支付宝回调App
    NSString *appScheme = @"gouxin";
    
    // 将商品信息拼接成字符串
    /*
     orderSpec = partner="xxxxxx"&seller_id="xxxxxxx@sina.com"&out_trade_no="xxxxxx"&subject="商品标题"&body="商品描述"&total_fee="0.01"&notify_url="http://www.baidu.com"&service="mobile.securitypay.pay"&payment_type="1"&_input_charset="utf-8"&it_b_pay="30m"&show_url="m.alipay.com"
     */
    NSString *orderSpec = [order description];

    // 获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(PartnerPrivKey);
    NSString *signedString = [signer signString:orderSpec];
    
    // 将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",orderSpec, signedString, @"RSA"];
        //NSLog(@"signedString = %@",signedString);
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            
            //解析返回状态码
            int resultSuccess = [[resultDic objectForKey:@"resultStatus"] intValue];
            //是9000代表支付成功
            //NSLog(@"支付宝返回的状态码%d",resultSuccess);
            if (resultSuccess==9000) {
                [self successWithCallbackID:self.currentCallbackId];
            }else {
                [self failWithCallbackID:self.currentCallbackId withMessage:@"支付失败"];
            }
            self.currentCallbackId = nil;
        }];
    }
}

#pragma mark - 成功和失败的回调方法

- (void)successWithCallbackID:(NSString *)callbackID
{
    [self successWithCallbackID:callbackID withMessage:@"OK"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error
{
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID]; //Gouxin1508925531
}


@end
