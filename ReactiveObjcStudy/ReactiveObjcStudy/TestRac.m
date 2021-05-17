//
//  TestRac.m
//  ReactiveObjcStudy
//
//  Created by liutong on 2021/5/14.
//

#import "TestRac.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACReturnSignal.h>

@implementation TestRac

- (void)execute {
    [self testFlattenMapAndMap02];
}

- (void)testBind01 {
    UITextField *text;
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        return nil;
    }];
    [[signal bind:^RACSignalBindBlock{
        return ^RACSignal * _Nullable(id _Nullable value, BOOL *stop) {
//            return [RACReturnSignal return:@222];
            return  [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                [subscriber sendNext:@222];
                return nil;
            }];
        };
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"bind订阅者---%@",x);
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者---%@",x);
    }];
}

- (void)testFlattenMapAndMap02 {
    
}

@end
