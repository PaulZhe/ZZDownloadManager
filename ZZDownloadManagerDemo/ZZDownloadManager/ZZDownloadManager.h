//
//  ZZDownloadManager.h
//  ZZDownloadManagerDemo
//
//  Created by 小哲的dell on 2019/8/13.
//  Copyright © 2019 小哲的dell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZDownloadManager : NSObject

/**
 决定下载文件在哪里存储，默认是.../Library/Caches/ZZDownloadManager
  */
@property (nonatomic, copy) NSString *whereDownloadFilesSaved;

/**
 最大下载数，默认是 -1 代表没有限制数
 */
@property (nonatomic, assign) NSInteger maxConcurrentDownloadCount;

+ (instancetype)sharedManager;

/**
 Download a file and provide state、progress、completion callback.
 
 @param URL        下载的URL
 @param state      下载状态改变时回调block
 @param progress   下载过程改变时回调block
 @param completion 下载状态完成时回调block
 */
- (void)downloadFileWithURL:(NSURL *)URL
                      state:(DownloadStateHandle)state
                   progress:(DownloadProgressHandle)progress
                 completion:(DownloadCompletionHandle)completion;

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL;

#pragma mark - Files

//- (NSString *)fileFullPathOfURL:(NSURL *)URL;

- (CGFloat)fileHasDownloadedProgressOfURL:(NSURL *)URL;

- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;

#pragma mark - Downloads

- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

@end

NS_ASSUME_NONNULL_END
