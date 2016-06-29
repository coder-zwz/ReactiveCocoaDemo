//
//  ViewController.m
//  ReactiveCocoa
//
//  Created by zuweizhong  on 16/6/29.
//  Copyright © 2016年 Hefei JiuYi Network Technology Co.,Ltd. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACDelegateProxy.h>
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif


@interface ViewController ()

@property(nonatomic,strong)NSString * controlName;

@property(nonatomic,strong)UITextField * textField;

@property(nonatomic,strong)UIButton * btn;

@property(nonatomic,strong)RACDisposable * loadingDispose;

@property(nonatomic,strong)RACDelegateProxy * proxy;

@property(nonatomic,strong)RACDisposable * btnDispose;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];

    [self kvoDemo];
    
    [self delegateDemo];
    
    [self notificationDemo];
    
    [self targetDemo];

}
-(void)kvoDemo
{
    
    //例1. 监听对象的成员变量变化，当成员变量值被改变时，触发做一些事情。
    
    /*
     [RACObserve(self, controlName) subscribeNext:^(id x) {
     
     NSString *newValue = (NSString *)x;
     
     NSLog(@"%@",newValue);
     
     }];
     */
    
    self.controlName = @"ViewController";
    
    //例2. 在上面场景中，当用户输入的值以2开头时，才发请求.
    /*
     [[RACObserve(self, controlName) filter:^BOOL(id value) {
     
     NSString *newValue = (NSString *)value;
     
     if ([newValue hasPrefix:@"ViewController2"]) {
     return YES;
     }
     else
     {
     return NO;
     
     }
     }] subscribeNext:^(id x) {
     
     NSString *newValue = (NSString *)x;
     
     NSLog(@"%@",newValue);
     
     }];
     */
    
    //例3 上面场景是监听自己的成员变量，如果想监听UITextField输入值变化，框架也做了封装可以代替系统回调
    
    [self.textField.rac_textSignal subscribeNext:^(id x) {
        
        
        NSString *newValue = (NSString *)x;
        
        NSLog(@"%@",newValue);
        
        [self showLoading];
        
        
        
    }];
    
    //例4. 同时监听多个变量变化，当这些变量满足一定条件时，使button为可点击状态
    
    //    RAC(self.btn,userInteractionEnabled) = [RACSignal combineLatest:@[self.textField.rac_textSignal] reduce:^id(NSString *text){
    //
    //        return @(text.length > 5);
    //
    //
    //    }];
    
    //    RAC(self.btn,backgroundColor) = [RACSignal combineLatest:@[self.textField.rac_textSignal] reduce:^id(NSString *text){
    //
    //        return text.length > 5?[UIColor blueColor]:[UIColor redColor];
    //
    //
    //    }];
    
    
    //例5. 同时监听多个变量变化,当这些变量满足一定条件时，直接发送请求
    
    //    [[RACSignal combineLatest:@[self.textField.rac_textSignal,RACObserve(self.btn,  userInteractionEnabled)] reduce:^id(NSString *text,NSNumber *userInteractionEnabled){
    //        return @(text.length > 5&& [userInteractionEnabled boolValue]==YES);
    //
    //    }] subscribeNext:^(NSNumber * x) {
    //
    //        if ([x boolValue]) {
    //
    //            NSLog(@"request start");
    //
    //        }
    //
    //    }];

}
-(void)targetDemo
{
    
    [self.btnDispose dispose];;//上次信号还没处理，取消它(距离上次生成还不到1秒)
    
    [[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        NSLog(@"btn clicked");
        
    }];
    
}
/*代理方法
 #pragma -mark 代理方法/**
 * 5、验证此函：nameText的输入字符时，输入回撤或者点击键盘的回车键使passWordText变为第一响应者（即输入光标移动到passWordText处）
 */
- (void)delegateDemo {
    
    @weakify(self) // 1. 定义代理
    
    self.proxy = [[RACDelegateProxy alloc] initWithProtocol:@protocol(UITextFieldDelegate)];
    
    // 2. 代理去注册文本框的监听方法
    [[self.proxy rac_signalForSelector:@selector(textFieldShouldReturn:)]
     subscribeNext:^(id x) {
         @strongify(self);
         if (self.textField.hasText) {//文本框有内容
             
             [self.textField becomeFirstResponder];
             
         }
         else//文本框无内容
         {
             
             [self.textField resignFirstResponder];
         
         
         }
     }];
    
    self.textField.delegate = (id<UITextFieldDelegate>)self.proxy;
    
    
}
/*
 系统键盘会发送通知，打印出通知的内容
*/
- (void)notificationDemo
{
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillChangeFrameNotification object:nil] subscribeNext:^(id x) {
        
        NSLog(@"notificationDemo : %@",x);

    }];

    
}

//例3. 类似于生产-消费
//场景：用户每次在TextField中输入一个字符，1秒内没有其它输入时，去发一个请求。TextField中字符改变触发事件已在例1中展示，这里实现一下它触法的方法，把1秒延时在此方法中实现。
-(void)showLoading
{
    
    [self.loadingDispose dispose];;//上次信号还没处理，取消它(距离上次生成还不到1秒)
    
    @weakify(self);

    self.loadingDispose = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendCompleted];
        return nil;
    }] delay:3.0] subscribeCompleted:^{
        @strongify(self);
        
        NSLog(@"request Start");
        
        
        self.loadingDispose = nil;  // 局域定义了一个__strong的self指针指向self_weak
    }];


}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    self.controlName = @"ViewController2";
    
    self.textField.text = @"textFieldTest";


}
-(void)createUI
{
    UITextField *textField = [[UITextField alloc]init];
    
    self.textField = textField;
    
    textField.frame = CGRectMake(10, 100, 300, 30);
    
    textField.borderStyle = UITextBorderStyleRoundedRect;
    
    [self.view addSubview:textField];
    
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    btn.frame = CGRectMake(10, 200, 80, 40);
    
   self.btnDispose =  [[btn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
       
       NSLog(@"btn click");
       
   }];
    
    self.btn = btn;
    
    self.btn.backgroundColor = [UIColor redColor];
    
    btn.userInteractionEnabled = YES;
    
    [self.view addSubview:self.btn];
    
    

}

@end
