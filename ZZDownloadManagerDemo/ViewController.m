//
//  ViewController.m
//  ZZDownloadManagerDemo
//
//  Created by 小哲的dell on 2019/8/13.
//  Copyright © 2019 小哲的dell. All rights reserved.
//

#import "ViewController.h"
#import "ZZDownloadManager.h"

NSString * const downloadURLString1 = @"http://yxfile.idealsee.com/9f6f64aca98f90b91d260555d3b41b97_mp4.mp4";
NSString * const downloadURLString2 = @"http://yxfile.idealsee.com/31f9a479a9c2189bb3ee6e5c581d2026_mp4.mp4";
NSString * const downloadURLString3 = @"http://yxfile.idealsee.com/d3c0d29eb68dd384cb37f0377b52840d_mp4.mp4";

#define kDownloadURL1 [NSURL URLWithString:downloadURLString1]
#define kDownloadURL2 [NSURL URLWithString:downloadURLString2]
#define kDownloadURL3 [NSURL URLWithString:downloadURLString3]

@interface ViewController ()

@property (strong, nonatomic) UIButton *downloadButton1;
@property (strong, nonatomic) UIButton *downloadButton2;
@property (strong, nonatomic) UIButton *downloadButton3;

@property (strong, nonatomic) UIProgressView *progressView1;
@property (strong, nonatomic) UIProgressView *progressView2;
@property (strong, nonatomic) UIProgressView *progressView3;

@property (strong, nonatomic) UILabel *progressLabel1;
@property (strong, nonatomic) UILabel *progressLabel2;
@property (strong, nonatomic) UILabel *progressLabel3;

@property (strong, nonatomic) UILabel *totalSizeLabel1;
@property (strong, nonatomic) UILabel *totalSizeLabel2;
@property (strong, nonatomic) UILabel *totalSizeLabel3;

@property (strong, nonatomic) UILabel *currentSizeLabel1;
@property (strong, nonatomic) UILabel *currentSizeLabel2;
@property (strong, nonatomic) UILabel *currentSizeLabel3;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createChildView];
    
}

- (void)createChildView {
    [ZZDownloadManager sharedManager].maxConcurrentDownloadCount = 2;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"ZZDownloadManager";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAllFiles:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAllDownloads:)];
    
    self.downloadButton1 = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, 80, 30)];
    [self.downloadButton1 addTarget:self action:@selector(downloadFile1:) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton1 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:_downloadButton1];
    
    self.downloadButton2 = [[UIButton alloc] initWithFrame:CGRectMake(20, 200, 80, 30)];
    [self.downloadButton2 addTarget:self action:@selector(downloadFile2:) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton2 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:_downloadButton2];
    
    self.downloadButton3 = [[UIButton alloc] initWithFrame:CGRectMake(20, 300, 80, 30)];
    [self.downloadButton3 addTarget:self action:@selector(downloadFile3:) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton3 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:_downloadButton3];
    
    UIButton *deleteButton1 = [[UIButton alloc] initWithFrame:CGRectMake(334, 100, 60, 30)];
    [deleteButton1 addTarget:self action:@selector(deleteFile1:) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton1 setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:deleteButton1];
    
    UIButton *deleteButton2 = [[UIButton alloc] initWithFrame:CGRectMake(334, 200, 60, 30)];
    [deleteButton2 addTarget:self action:@selector(deleteFile2:) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton2 setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton2 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:deleteButton2];
    
    UIButton *deleteButton3 = [[UIButton alloc] initWithFrame:CGRectMake(334, 300, 60, 30)];
    [deleteButton3 addTarget:self action:@selector(deleteFile3:) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton3 setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton3 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:deleteButton3];
    
    UIButton *suspendALLButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 500, 100, 30)];
    [suspendALLButton addTarget:self action:@selector(suspendAllDownloads:) forControlEvents:UIControlEventTouchUpInside];
    [suspendALLButton setTitle:@"Suspend All" forState:UIControlStateNormal];
    [suspendALLButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:suspendALLButton];
    
    UIButton *resumeALLButton = [[UIButton alloc] initWithFrame:CGRectMake(234, 500, 100, 30)];
    [resumeALLButton addTarget:self action:@selector(resumeAllDownloads:) forControlEvents:UIControlEventTouchUpInside];
    [resumeALLButton setTitle:@"Resume All" forState:UIControlStateNormal];
    [resumeALLButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:resumeALLButton];
    
    CGFloat progress1 = [[ZZDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL1];
    CGFloat progress2 = [[ZZDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL2];
    CGFloat progress3 = [[ZZDownloadManager sharedManager] fileHasDownloadedProgressOfURL:kDownloadURL3];
    
    self.progressView1 = [[UIProgressView alloc] initWithFrame:CGRectMake(90, 100, 200, 10)];
    self.progressView1.progress = progress1;
    [self.view addSubview:_progressView1];
    
    self.progressView2 = [[UIProgressView alloc] initWithFrame:CGRectMake(90, 200, 200, 10)];
    self.progressView2.progress = progress1;
    [self.view addSubview:_progressView2];
    
    self.progressView3 = [[UIProgressView alloc] initWithFrame:CGRectMake(90, 300, 200, 10)];
    self.progressView3.progress = progress1;
    [self.view addSubview:_progressView3];
    
    self.progressLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(285, 100, 50, 30)];
    self.progressLabel1.text = [NSString stringWithFormat:@"%.f%%", progress1 * 100];
    [self.view addSubview:_progressLabel1];
    
    self.progressLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(285, 200, 50, 30)];
    self.progressLabel2.text = [NSString stringWithFormat:@"%.f%%", progress2 * 100];
    [self.view addSubview:_progressLabel2];
    
    self.progressLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(285, 300, 50, 30)];
    self.progressLabel3.text = [NSString stringWithFormat:@"%.f%%", progress3 * 100];
    [self.view addSubview:_progressLabel3];
    
    self.currentSizeLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(185, 80, 50, 20)];
    self.currentSizeLabel1.text = @"0";
    [self.view addSubview:_currentSizeLabel1];
    
    self.currentSizeLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(185, 180, 50, 20)];
    self.currentSizeLabel2.text = @"0";
    [self.view addSubview:_currentSizeLabel2];
    
    self.currentSizeLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(185, 280, 50, 20)];
    self.currentSizeLabel3.text = @"0";
    [self.view addSubview:_currentSizeLabel3];
    
    self.totalSizeLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(185, 120, 50, 20)];
    self.totalSizeLabel1.text = @"0";
    [self.view addSubview:_totalSizeLabel1];
    
    self.totalSizeLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(185, 220, 50, 20)];
    self.totalSizeLabel2.text = @"0";
    [self.view addSubview:_totalSizeLabel2];
    
    self.totalSizeLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(185, 320, 50, 20)];
    self.totalSizeLabel3.text = @"0";
    [self.view addSubview:_totalSizeLabel3];
}

#pragma mark - Actions

- (void)download:(NSURL *)URL
  totalSizeLabel:(UILabel *)totalSizeLabel
currentSizeLabel:(UILabel *)currentSizeLabel
   progressLabel:(UILabel *)progressLabel
    progressView:(UIProgressView *)progressView
          button:(UIButton *)button {
    
    if ([button.currentTitle isEqualToString:@"Start"]) {
        [[ZZDownloadManager sharedManager] downloadFileWithURL:URL state:^(ZZDownloadState state) {
            
            [button setTitle:[self titleWithDownloadState:state] forState:UIControlStateNormal];
        } progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
            
            currentSizeLabel.text = [NSString stringWithFormat:@"%zdMB", receivedSize / 1024 / 1024];
            totalSizeLabel.text = [NSString stringWithFormat:@"%zdMB", expectedSize / 1024 / 1024];
            progressLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
            progressView.progress = progress;
        } completion:^(BOOL isSuccess, NSString * _Nullable filePath, NSError * _Nullable error) {
            if (isSuccess) {
                NSLog(@"FilePath: %@", filePath);
            } else {
                NSLog(@"Error: %@", error);
            }
        }];
    } else if ([button.currentTitle isEqualToString:@"Waiting"]) {
        [[ZZDownloadManager sharedManager] cancelDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Pause"]) {
        [[ZZDownloadManager sharedManager] suspendDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Resume"]) {
        [[ZZDownloadManager sharedManager] resumeDownloadOfURL:URL];
    } else if ([button.currentTitle isEqualToString:@"Finish"]) {
        NSLog(@"File has been downloaded! File path: ");
    }
}

- (void)downloadFile1:(UIButton *)sender {
    [self download:kDownloadURL1
    totalSizeLabel:self.totalSizeLabel1
  currentSizeLabel:self.currentSizeLabel1
     progressLabel:self.progressLabel1
      progressView:self.progressView1
            button:sender];
}

- (void)downloadFile2:(UIButton *)sender {
    [self download:kDownloadURL2
    totalSizeLabel:self.totalSizeLabel2
  currentSizeLabel:self.currentSizeLabel2
     progressLabel:self.progressLabel2
      progressView:self.progressView2
            button:sender];
}

- (void)downloadFile3:(UIButton *)sender {
    [self download:kDownloadURL3
    totalSizeLabel:self.totalSizeLabel3
  currentSizeLabel:self.currentSizeLabel3
     progressLabel:self.progressLabel3
      progressView:self.progressView3
            button:sender];
}

- (void)deleteAllFiles:(UIBarButtonItem *)sender {
    
    [[ZZDownloadManager sharedManager] deleteAllFiles];
    
    self.progressView1.progress = 0.0;
    self.progressView2.progress = 0.0;
    self.progressView3.progress = 0.0;
    
    self.currentSizeLabel1.text = @"0";
    self.currentSizeLabel2.text = @"0";
    self.currentSizeLabel3.text = @"0";
    
    self.totalSizeLabel1.text = @"0";
    self.totalSizeLabel2.text = @"0";
    self.totalSizeLabel3.text = @"0";
    
    self.progressLabel1.text = @"0%";
    self.progressLabel2.text = @"0%";
    self.progressLabel3.text = @"0%";
    
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)deleteFile1:(UIButton *)sender {
    [[ZZDownloadManager sharedManager] deleteFileOfURL:kDownloadURL1];
    
    self.progressView1.progress = 0.0;
    self.currentSizeLabel1.text = @"0";
    self.totalSizeLabel1.text = @"0";
    self.progressLabel1.text = @"0%";
    [self.downloadButton1 setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)deleteFile2:(UIButton *)sender {
    [[ZZDownloadManager sharedManager] deleteFileOfURL:kDownloadURL2];
    
    self.progressView2.progress = 0.0;
    self.currentSizeLabel2.text = @"0";
    self.totalSizeLabel2.text = @"0";
    self.progressLabel2.text = @"0%";
    [self.downloadButton2 setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)deleteFile3:(UIButton *)sender {
    [[ZZDownloadManager sharedManager] deleteFileOfURL:kDownloadURL3];
    
    self.progressView3.progress = 0.0;
    self.currentSizeLabel3.text = @"0";
    self.totalSizeLabel3.text = @"0";
    self.progressLabel3.text = @"0%";
    [self.downloadButton3 setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)suspendAllDownloads:(UIButton *)sender {
    
    [[ZZDownloadManager sharedManager] suspendAllDownloads];
}

- (void)resumeAllDownloads:(UIButton *)sender {
    
    [[ZZDownloadManager sharedManager] resumeAllDownloads];
}

- (void)cancelAllDownloads:(UIBarButtonItem *)sender {
    
    [[ZZDownloadManager sharedManager] cancelAllDownloads];
}

- (NSString *)titleWithDownloadState:(ZZDownloadState)state {
    switch (state) {
        case ZZDownloadStateWaiting:
            return @"Waiting";
        case ZZDownloadStateRunning:
            return @"Pause";
        case ZZDownloadStateSuspended:
            return @"Resume";
        case ZZDownloadStateCanceled:
            return @"Start";
        case ZZDownloadStateCompleted:
            return @"Finish";
        case ZZDownloadStateFailed:
            return @"Start";
    }
}

@end
