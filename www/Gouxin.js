
var cordova = require('cordova');

var Gouxin = function() {};

/**
 * 实现分享的功能
 * @param success 成功的回调
 * @param error   失败的回调
 * @param classname  调起的OC中类的名字
 * @param method    调起OC中类中的方法名
 * @param message    传递过去的数据
 */
Gouxin.prototype.share = function(success, error,classname,method,message) {
    cordova.exec(success, error, classname, method, [message]);
};

/**
 *  实现支付的功能
 */
Gouxin.prototype.sendPayRequest = function(success, error,classname,method,message) {

    cordova.exec(success, error, classname, method, [message]);
};

var gouxin = new Gouxin();

module.exports = gouxin;
