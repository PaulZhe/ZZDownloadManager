//
//  ZZDownloadModel.h
//  ZZDownloadManagerDemo
//
//  Created by 小哲的dell on 2019/8/13.
//  Copyright © 2019 小哲的dell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZZDownloadState) {
    ZZDownloadStateWaiting,
    ZZDownloadStateRunning,
    ZZDownloadStateSuspended,
    ZZDownloadStateCanceled,
    ZZDownloadStateCompleted,
    ZZDownloadStateFailed
};

//为几个下载回调的block重命名
typedef void(^DownloadStateHandle)(ZZDownloadState);
typedef void(^DownloadProgressHandle)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);
typedef void(^DownloadCompletionHandle)(BOOL isSuccess, NSString * _Nullable filePath,  NSError * _Nullable error);

@interface ZZDownloadModel : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSOutputStream *outputStream; // For write datas to file.
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic, copy) DownloadStateHandle downloadStateBlock;
@property (nonatomic, copy) DownloadProgressHandle downloadProgressBlock;
@property (nonatomic, copy) DownloadCompletionHandle downloadCompletionBlock;

- (void)openOutputStream;
- (void)closeOutputStream;

@end

NS_ASSUME_NONNULL_END
