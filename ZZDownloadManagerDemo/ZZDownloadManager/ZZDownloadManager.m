//
//  ZZDownloadManager.m
//  ZZDownloadManagerDemo
//
//  Created by 小哲的dell on 2019/8/13.
//  Copyright © 2019 小哲的dell. All rights reserved.
//

#import "ZZDownloadManager.h"

#define ZZWhereDownloadFilesSaved self.whereDownloadFilesSaved ? self.whereDownloadFilesSaved : [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] \
stringByAppendingPathComponent:NSStringFromClass([self class])]

#define ZZFileName(URL) [URL lastPathComponent] //用URL路径最后一个组件名作为文件到名字

#define ZZFilePath(URL) [ZZWhereDownloadFilesSaved stringByAppendingPathComponent:ZZFileName(URL)]

#define ZZFilesTotalLengthPlistPath [ZZWhereDownloadFilesSaved stringByAppendingPathComponent:@"ZZFilesTotalLength.plist"]

@interface ZZDownloadManager () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
// Mutable dictionary which includes downloading and waiting models.
@property (nonatomic, strong) NSMutableDictionary *downloadModelsDic;
// Models which are downloading.
@property (nonatomic, strong) NSMutableArray *downloadingModels;
// Models which are waiting to download.
@property (nonatomic, strong) NSMutableArray *waitingModels;

@end

@implementation ZZDownloadManager

+ (instancetype)sharedManager
{
    static ZZDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        downloadManager = [[self alloc] init];
        downloadManager.maxConcurrentDownloadCount = -1;
    });
    return downloadManager;
}

- (NSURLSession *)urlSession
{
    if (!_urlSession) {
        self.urlSession = [NSURLSession sessionWithConfiguration:
                           [NSURLSessionConfiguration defaultSessionConfiguration]
                                                        delegate:self
                                                   delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _urlSession;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *downloadDirectory = ZZWhereDownloadFilesSaved;
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
    //第二个参数就是说传入一个bool类型的指针，执行该方法后这个参数的值是yes的话就是路径（文件夹），反之是文件。
        //返回值的作用是判断沙盒文件或者目录是否存在
        BOOL isExists = [fileManager fileExistsAtPath:downloadDirectory isDirectory:&isDirectory];
        if (!isExists || !isDirectory) {
            [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

#pragma mark - Lazy Load

- (NSMutableDictionary *)downloadModelsDic
{
    if (!_downloadModelsDic) {
        self.downloadModelsDic = [NSMutableDictionary dictionary];
    }
    return _downloadModelsDic;
}

- (NSMutableArray *)downloadingModels
{
    if (!_downloadingModels) {
        self.downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

- (NSMutableArray *)waitingModels
{
    if (!_waitingModels) {
        self.waitingModels = [NSMutableArray array];
    }
    return _waitingModels;
}

#pragma mark - Assist Methods

- (NSInteger)totalLengthWithURL:(NSURL *)URL
{
    NSDictionary *filesTotalLenth = [NSDictionary dictionaryWithContentsOfFile:ZZFilesTotalLengthPlistPath];
    if (!filesTotalLenth) {
        return 0;
    }
    if (!filesTotalLenth[ZZFileName(URL)]) {
        return 0;
    }
    return [filesTotalLenth[ZZFileName(URL)] integerValue];
}

- (NSInteger)hasDownloadedLengthWithURL:(NSURL *)URL
{
    //attributesOfItemAtPath:方法的功能是获取文件的大小、文件的内容等属性
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:ZZFilePath(URL) error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

- (void)resumeNextDownloadModel {
    if (self.maxConcurrentDownloadCount == -1) {
        return;
    }
    if (self.waitingModels.count == 0) {
        return;
    }
    
    ZZDownloadModel *downloadModel;
    downloadModel = self.waitingModels.firstObject;
    [self.waitingModels removeObject:downloadModel];
    
    ZZDownloadState downloadState;
    if ([self canResumeNewDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadState = ZZDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = ZZDownloadStateWaiting;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (downloadModel.downloadStateBlock) {
            downloadModel.downloadStateBlock(downloadState);
        }
    });
}

#pragma mark - Files

- (BOOL)isDownloadCompletedOfURL:(NSURL *)URL
{
    NSInteger totalLength = [self totalLengthWithURL:URL];
    if (totalLength != 0) {
        if (totalLength == [self hasDownloadedLengthWithURL:URL]) {
            return YES;
        }
    }
    return NO;
}

- (CGFloat)fileHasDownloadedProgressOfURL:(NSURL *)URL {
    if ([self isDownloadCompletedOfURL:URL]) {
        return 1.0;
    }
    if ([self totalLengthWithURL:URL] == 0) {
        return 0.0;
    }
    return 1.0 * [self hasDownloadedLengthWithURL:URL] / [self totalLengthWithURL:URL];
}

- (void)deleteFileOfURL:(NSURL *)URL {
    [self cancelDownloadOfURL:URL];
    
    NSMutableDictionary *filesTotalLenth = [NSMutableDictionary dictionaryWithContentsOfFile:ZZFilesTotalLengthPlistPath];
    [filesTotalLenth removeObjectForKey:ZZFileName(URL)];
    [filesTotalLenth writeToFile:ZZFilesTotalLengthPlistPath atomically:YES];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = ZZFilePath(URL);
    NSLog(@"%@", filePath);
    if (![fileManager fileExistsAtPath:filePath]) {
        return;
    }
    if ([fileManager removeItemAtPath:filePath error:nil]) {
        return;
    }
    NSLog(@"removeItemAtPath Failed: %@", filePath);
}

- (void)deleteAllFiles {
    [self cancelAllDownloads];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:ZZWhereDownloadFilesSaved error:nil];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [ZZWhereDownloadFilesSaved stringByAppendingPathComponent:fileName];
        if ([fileManager removeItemAtPath:filePath error:nil]) {
            continue;
        }
        NSLog(@"removeItemAtPath Failed: %@", filePath); //如果沙盒cache中还要其他文件也不会移除，会执行这条打印
    }
}

- (void)setDownloadedFilesDirectory:(NSString *)downloadedFilesDirectory {
    
    _whereDownloadFilesSaved = downloadedFilesDirectory;
    
    if (!downloadedFilesDirectory) {
        return;
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:downloadedFilesDirectory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:downloadedFilesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


#pragma mark - Download

- (void)downloadFileWithURL:(NSURL *)URL
                      state:(DownloadStateHandle)state
                   progress:(DownloadProgressHandle)progress
                 completion:(DownloadCompletionHandle)completion
{
    if (!URL) {
        return;
    }
    if ([self isDownloadCompletedOfURL:URL]) {
        if (state) {
            state(ZZDownloadStateCompleted);
        }
        if (completion) {
            completion(YES, ZZFilePath(URL), nil);
        }
        return;
    }
    
    ///初始化该URL对应的downloadModelsDic中的downloadModel，并将其加入到dic中
    ZZDownloadModel *downloadModel = self.downloadModelsDic[ZZFileName(URL)];
    if (downloadModel) { //如果这个URL对应的downloadModel已经被加入到了downloadModelsDic中
        return;
    }
    
    ///设置dataTask
    // @"bytes=x-y" ==  x byte ~ y byte
    // @"bytes=x-"  ==  x byte ~ end
    // @"bytes=-y"  ==  head ~ y byte
    NSMutableURLRequest *requst = [NSMutableURLRequest requestWithURL:URL];
    [requst setValue:[NSString stringWithFormat:@"bytes=%lld-", (long long int)[self hasDownloadedLengthWithURL:URL]] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:requst];
    dataTask.taskDescription = ZZFileName(URL);
    
    downloadModel = [[ZZDownloadModel alloc] init];
    downloadModel.dataTask = dataTask;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:ZZFilePath(URL) append:YES];
    downloadModel.URL = URL;
    downloadModel.downloadStateBlock = state;
    downloadModel.downloadProgressBlock = progress;
    downloadModel.downloadCompletionBlock = completion;
    
    self.downloadModelsDic[dataTask.taskDescription] = downloadModel;
    
    ZZDownloadState downloadState;
    if ([self canResumeNewDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [dataTask resume];
        downloadState = ZZDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = ZZDownloadStateWaiting;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (downloadModel.downloadStateBlock) {
            downloadModel.downloadStateBlock(downloadState);
        }
    });
}

//判断当前下载任务数是否超过最大允许下载数
- (BOOL)canResumeNewDownload {
    if (self.maxConcurrentDownloadCount == -1) {
        return YES;
    }
    if (self.downloadingModels.count >= self.maxConcurrentDownloadCount) {
        return NO;
    }
    return YES;
}

#pragma mark - NSURLSessionDataDelegate

///任务刚响应时调用此委托方法，此后再不会收到任何消息（在退出程序再下载时也会调用）
//将下载任务大小写入plist文件中
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    //先取出相应任务的model
    ZZDownloadModel *downloadModel = _downloadModelsDic[dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    [downloadModel openOutputStream];
    
    // 还需下载的length
    NSInteger thisTotalLength = response.expectedContentLength;
    //任务的总大小
    NSInteger totalLength = thisTotalLength + [self hasDownloadedLengthWithURL:downloadModel.URL];
    downloadModel.totalLength = totalLength;
    //获取辅助plist文件转换成字典，如果还没有初始化则创建一个
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:ZZFilesTotalLengthPlistPath] ?: [NSMutableDictionary dictionary];
    filesTotalLength[ZZFileName(downloadModel.URL)] = @(totalLength);
    //第二个参数：如果标志为YES，则将字典写入辅助文件，然后将辅助文件重命名为path。如果flag为NO，则直接将字典写入path。YES选项保证，即使系统在编写过程中崩溃，即使存在路径，也不会损坏它。
    [filesTotalLength writeToFile:ZZFilesTotalLengthPlistPath atomically:YES];
    
    completionHandler(NSURLSessionResponseAllow);
}

///告诉代理该数据任务已经收到了一些预期的数据。因为是下载任务，则不断调用该委托方法
//此委托方法可能被多次调用，并且每次调用仅提供自上次调用后收到的数据。 如果需要，该应用负责积累这些数据。
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    //先取出相应任务的model
    ZZDownloadModel *downloadModel = _downloadModelsDic[dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
   
    //将 buffer 中的数据写入流中，返回实际写入的字节数。
    //data.bytes : 字节方法返回一个指针，指向由接收方管理的内存的连续区域。
    //outputStream在调用下载方法初始化model时已经初始化路径了
    [downloadModel.outputStream write:data.bytes maxLength:data.length];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (downloadModel.downloadProgressBlock) {
            downloadModel.downloadProgressBlock([self hasDownloadedLengthWithURL:downloadModel.URL], downloadModel.totalLength, [self fileHasDownloadedProgressOfURL:downloadModel.URL]);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && error.code == -999) { // Cancelled!
        return;
    }
    
    //先取出相应任务的model
    ZZDownloadModel *downloadModel = _downloadModelsDic[task.taskDescription];
    if (!downloadModel) {
        return;
    }
    
    [downloadModel closeOutputStream];
    
    [self.downloadModelsDic removeObjectForKey:task.taskDescription];
    [self.downloadingModels removeObject:downloadModel];
    
    //回到主线程调用相应model的过程、状态、完成block，更新界面
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isDownloadCompletedOfURL:downloadModel.URL]) {
            if (downloadModel.downloadStateBlock) {
                downloadModel.downloadStateBlock(ZZDownloadStateCompleted);
            }
            if (downloadModel.downloadCompletionBlock) {
                downloadModel.downloadCompletionBlock(YES, ZZFilePath(downloadModel.URL), error);
            }
        } else {
            if (downloadModel.downloadStateBlock) {
                downloadModel.downloadStateBlock(ZZDownloadStateFailed);
            }
            if (downloadModel.downloadCompletionBlock) {
                downloadModel.downloadCompletionBlock(NO, nil, error);
            }
        }
    });
    
    [self resumeNextDownloadModel];
}

#pragma mark - Downloads

- (void)suspendDownloadOfURL:(NSURL *)URL {
    ZZDownloadModel *downloadModel = _downloadModelsDic[ZZFileName(URL)];
    if (!downloadModel) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (downloadModel.downloadStateBlock) {
            downloadModel.downloadStateBlock(ZZDownloadStateSuspended);
        }
    });
    if ([self.waitingModels containsObject:downloadModel]) {
        [self.waitingModels removeObject:downloadModel];
    } else {
        [downloadModel.dataTask suspend];
        [self.downloadingModels removeObject:downloadModel];
    }
    
    [self resumeNextDownloadModel];
}

- (void)suspendAllDownloads {
    if (_downloadModelsDic.count == 0) {
        return;
    }
    //将等待队列的任务全部取消，变为暂停状态
    if (_waitingModels.count > 0) {
        for (NSInteger i = 0; i < self.waitingModels.count; i++) {
            ZZDownloadModel *downloadModel = self.waitingModels[i];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (downloadModel.downloadStateBlock) {
                    downloadModel.downloadStateBlock(ZZDownloadStateSuspended);
                }
            });
        }
        [self.waitingModels removeAllObjects];
    }
    //将下载中的队列的任务全部取消，变为暂停状态
    if (_downloadingModels.count > 0) {
        for (NSInteger i = 0; i < _downloadingModels.count; i++) {
            ZZDownloadModel *downloadModel = _downloadingModels[i];
            [downloadModel.dataTask suspend];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (downloadModel.downloadStateBlock) {
                    downloadModel.downloadStateBlock(ZZDownloadStateSuspended);
                }
            });
        }
        [self.downloadingModels removeAllObjects];
    }
}

- (void)resumeDownloadOfURL:(NSURL *)URL {
    ZZDownloadModel *downloadModel = _downloadModelsDic[ZZFileName(URL)];
    if (!downloadModel) {
        return;
    }
    
    ZZDownloadState downloadState;
    if ([self canResumeNewDownload]) {
        [self.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadState = ZZDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = ZZDownloadStateWaiting;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (downloadModel.downloadStateBlock) {
            downloadModel.downloadStateBlock(downloadState);
        }
    });
}

- (void)resumeAllDownloads {
    if (self.downloadModelsDic.count == 0) {
        return;
    }
    
    NSArray *downloadModels = self.downloadModelsDic.allValues;
    for (ZZDownloadModel *downloadModel in downloadModels) {
        ZZDownloadState downloadState;
        if ([self canResumeNewDownload]) {
            [self.downloadingModels addObject:downloadModel];
            [downloadModel.dataTask resume];
            downloadState = ZZDownloadStateRunning;
        } else {
            [self.waitingModels addObject:downloadModel];
            downloadState = ZZDownloadStateWaiting;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (downloadModel.downloadStateBlock) {
                downloadModel.downloadStateBlock(downloadState);
            }
        });
    }
}

- (void)cancelDownloadOfURL:(NSURL *)URL {
    ZZDownloadModel *downloadModel = _downloadModelsDic[ZZFileName(URL)];
    if (!downloadModel) {
        return;
    }
    
    [downloadModel closeOutputStream];
    [downloadModel.dataTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.downloadStateBlock) {
            downloadModel.downloadStateBlock(ZZDownloadStateCanceled);
        }
    });
    if ([self.waitingModels containsObject:downloadModel]) {
        [self.waitingModels removeObject:downloadModel];
    } else {
        [self.downloadingModels removeObject:downloadModel];
    }
    [self.downloadModelsDic removeObjectForKey:ZZFileName(URL)];
    
    [self resumeNextDownloadModel];
}

- (void)cancelAllDownloads {
    if (self.downloadModelsDic.count == 0) {
        return;
    }
    NSArray *downloadModels = _downloadModelsDic.allValues;
    for (ZZDownloadModel *downloadModel in downloadModels) {
        [downloadModel closeOutputStream];
        [downloadModel.dataTask cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (downloadModel.downloadStateBlock) {
                downloadModel.downloadStateBlock(ZZDownloadStateCanceled);
            }
        });
    }
    [self.waitingModels removeAllObjects];
    [self.downloadingModels removeAllObjects];
    [self.downloadModelsDic removeAllObjects];
}

@end
