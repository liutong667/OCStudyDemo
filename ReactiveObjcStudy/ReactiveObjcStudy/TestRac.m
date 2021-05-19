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

//参考：https://www.jianshu.com/p/e10e5ca413b7

- (void)testBind01 {
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
    // flattenMap作用:把源信号的内容映射成一个新的信号，信号可以是任意类型
    RACSubject *signalOfsignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    [[signalOfsignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return value;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅信号的信号---%@",x);
    }];
    [[signal map:^id _Nullable(id  _Nullable value) {
        return [NSString stringWithFormat:@"map后：%@",value];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者---%@",x);
    }];
    [signalOfsignals sendNext:signal];
    [signal sendNext:@111];
}

- (void)testConcat03 {
    RACSignal *signal01 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendNext:@111111];
        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return nil;;
    }];
    RACSignal *signal02 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@222];
        [subscriber sendCompleted];
        return nil;;
    }];
    RACSignal *signal03 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@333];
        [subscriber sendCompleted];
        return nil;;
    }];
    
    //第一个信号必须发送完成(发送error不行)，第二个信号才会被激活
    RACSignal *concatSignal = [signal01 concat:signal02];
    concatSignal = [concatSignal concat:signal03];
    [concatSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者----%@",x);
    }];
}

- (void)testThenAndMerge04 {
    //then:用于连接两个信号，当第一个信号完成，才会连接then返回的信号
    // 注意使用then，之前信号的值会被忽略掉.
    // 底层实现：1、先过滤掉之前的信号发出的值。2.使用concat连接then返回的信号
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return nil;
    }] then:^RACSignal * _Nonnull{
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@222];
            [subscriber sendCompleted];
            return nil;
        }];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"then的订阅者---%@",x);
    }];
    
    // merge:把多个信号合并成一个信号
    //1、多个信号都sendCompleted，最终会收到completed；2、前面有信号sendError，就不会再收到信号的Next
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendError:nil];
//        [subscriber sendCompleted];
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@2];
        [subscriber sendError:nil];
        [subscriber sendCompleted];
        [subscriber sendNext:@3];
        return nil;
    }];
    RACSignal *mergeSignal = [signalA merge:signalB];
    [mergeSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"merge订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"merge订阅者---错误：%@",error);
    } completed:^{
        NSLog(@"merge订阅者---完成");
    }];
    
}

- (void)testZipWith05 {
    RACSignal *signal01 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendNext:@111111];
        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return nil;;
    }];
    RACSignal *signal02 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@222];
        [subscriber sendNext:@222222];
//        [subscriber sendCompleted];
        return nil;;
    }];
    
    RACSignal *zipSignal= [signal01 zipWith:signal02];
    [zipSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"zip订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"zip订阅者---错误：%@",error);
    } completed:^{
        NSLog(@"zip订阅者---完成");
    }];
    ///zipWith:把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件
    // 底层实现:
    // 1.定义压缩信号，内部就会自动订阅signalA，signalB
    // 2.每当signalA或者signalB发出信号，就会判断signalA，signalB有没有发出个信号，有就会把最近发出的信号都包装成元组发出。
}

- (void)testCombineLatest06 {
    RACSignal *signal01 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendNext:@111111];
//        [subscriber sendCompleted];
        [subscriber sendError:nil];
        return nil;;
    }];
    RACSignal *signal02 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@222];
        [subscriber sendNext:@222222];
        [subscriber sendCompleted];
        return nil;;
    }];
    
    RACSignal *combineSignal = [signal01 combineLatestWith:signal02];
    [combineSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"com订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"com订阅者---错误：%@",error);
    } completed:^{
        NSLog(@"com订阅者---完成");
    }];
    
    [[RACSignal combineLatest:@[signal01, signal02] reduce:^id(NSNumber *num1 ,NSNumber *num2){
        return [NSString stringWithFormat:@"---%@----%@",num1,num2] ;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"com订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"com订阅者---错误：%@",error);
    } completed:^{
        NSLog(@"com订阅者---完成");
    }];
}

- (void)testRACOperation07 {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendNext:@222];
        [subscriber sendNext:@222];
        [subscriber sendNext:@333333];
        [subscriber sendError:nil];
        [subscriber sendNext:@222];
        [subscriber sendNext:@6666666];
//        [subscriber sendError:nil];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[signal filter:^BOOL(NSNumber *value) {
        return value.stringValue.length > 3;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"filter订阅者---%@",x);
    }];
    
    [[signal ignore:@111] subscribeNext:^(id  _Nullable x) {
        NSLog(@"ignore订阅者---%@",x);
    }];
    
    [[signal distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        NSLog(@"distinct订阅者---%@",x);
    }];
    //take:从开始一共取N次的信号
    [[signal take:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"take订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"take订阅者error");
    } completed:^{
        NSLog(@"take订阅者done");
    }];
    //takeLast:取最后N次的信号,前提条件，订阅者必须调用完成，因为只有完成，就知道总共有多少信号
    [[signal takeLast:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"takeLast订阅者---%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"takeLast订阅者error");
    } completed:^{
        NSLog(@"takeLast订阅者done");
    }];
    
    [[signal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        NSLog(@"willDealloc订阅者---%@",x);
    }];
    
    [[signal skip:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"skip订阅者---%@",x);
    }];
}

- (void)testSwitchToLatest08 {
    // 获取信号中信号最近发出信号，订阅最近发出的信号。
    // 注意switchToLatest：只能用于信号中的信号
    RACSubject *signalOfSignal = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    [[signalOfSignal switchToLatest] subscribeNext:^(id  _Nullable x) {
        NSLog(@"switchToLatest订阅者----%@",x);
    }];
    
    [signalOfSignal sendNext:signal];
    [signal sendNext:@111];
}

- (void)testDoNextAndDoCompleted09 {
    //doNext: 执行Next之前，会先执行这个Block
    //doCompleted: 执行sendCompleted之前，会先执行这个Block
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendNext:@222];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[[signal doNext:^(id  _Nullable x) {
        NSLog(@"doNext----%@",x);
    }] doCompleted:^{
        NSLog(@"doCompleted----");
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者----%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"订阅者error----%@",error);
    } completed:^{
        NSLog(@"订阅者done----");
    }];
    
}

- (void)testTherad10 {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@111];
        [subscriber sendCompleted];
        return nil;
    }] timeout:1 onScheduler:[RACScheduler currentScheduler]];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者----%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"订阅者error----%@",error);
    } completed:^{
        NSLog(@"订阅者done----");
    }];
}
- (void)execute {
    [self testTherad10];
}
@end
