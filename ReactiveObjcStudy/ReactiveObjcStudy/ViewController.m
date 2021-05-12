//
//  ViewController.m
//  ReactiveObjcStudy
//
//  Created by liutong on 2021/5/10.
//

#import "ViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self testRACLiftSelector06];
}

- (void)testRACSinal01 {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"1发送信号");
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"4信号销毁");
        }];
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"2接受信号----%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"3.2信号发生error----%@",error);
    } completed:^{
        NSLog(@"3.1信号完成");
    }];
}

- (void)testRACSubject02 {
    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第1个订阅者 接受subject信号---%@",x);
    }];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第2个订阅者 接受subject信号---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"第2个订阅者 error---%@", error);
    } completed:^{
        NSLog(@"第2个订阅者完成");
    }];
    [subject sendNext:@1];
    [subject sendError:nil];
    [subject sendCompleted];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第3个订阅者 接受subject信号---%@",x);
    }];
    [subject sendNext:@2];
}

- (void)testRACReplaySubject03 {
    RACReplaySubject *replaySubject = [RACReplaySubject subject];
    [replaySubject sendNext:@1];
    [replaySubject sendNext:@2];
    [replaySubject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第1个订阅者------%@",x);
    }];
    [replaySubject sendCompleted];
    [replaySubject subscribeNext:^(id  _Nullable x) {
        NSLog(@"第2个订阅者------%@",x);
    }];
    [replaySubject sendNext:@3];
}

- (void)testRACCommand04 {
    static RACCommand *command_;
    if (command_) {
        [command_ execute:@22];
        return;
    }
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"开始执行命令--%@",input);
//        return [RACSignal empty];
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [subscriber sendNext:@1];
                [subscriber sendCompleted];
//                [subscriber sendError:nil];
            });
            return nil;
        }];
    }];
    command_ = command;
    [command.executionSignals subscribeNext:^(id  _Nullable x) {
        NSLog(@"executionSignals订阅者---%@",x);
        [x subscribeNext:^(id  _Nullable x) {
            NSLog(@"订阅者1---%@",x);
        }];
    }];
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者2---%@",x);
    }];
    [[command.executing skip:0] subscribeNext:^(NSNumber * _Nullable x) {
        if (x.boolValue == YES) {
            NSLog(@"执行中ing");
        } else {
            NSLog(@"执行完成done");
        }
    }];
    [command execute:@11];
    [command execute:@22];
}

- (void)testRACMulticastConnection05 {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@111];
        return nil;
    }];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者1---%@",x);
    }];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者2---%@",x);
    }];
    
    RACSignal *signalMulti = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@222];
        return nil;
    }];
    RACMulticastConnection *connect = [signalMulti publish];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"muti订阅者1---%@",x);
    }];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"muti订阅者2---%@",x);
    }];
    [connect connect];
}

- (void)testRACLiftSelector06 {
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"请求111");
        [subscriber sendNext:@111];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"请求222");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@222];
        });
        return nil;
    }];
    [self rac_liftSelector:@selector(handleAllSignalWithR1:r2:) withSignalsFromArray:@[signal1,signal2]];
}
- (void)handleAllSignalWithR1:(id)r1 r2:(id)r2 {
    NSLog(@"处理数据---%@----%@",r1, r2);
}

@end
