//
//  ZZDownloadModel.m
//  ZZDownloadManagerDemo
//
//  Created by 小哲的dell on 2019/8/13.
//  Copyright © 2019 小哲的dell. All rights reserved.
//

#import "ZZDownloadModel.h"

@implementation ZZDownloadModel

- (void)openOutputStream {
    if (_outputStream) {
        [_outputStream open];
    }
}

- (void)closeOutputStream {
    if (_outputStream) {
        if (_outputStream.streamStatus > NSStreamStatusNotOpen && _outputStream.streamStatus < NSStreamStatusClosed) {
            [_outputStream close];
        }
        _outputStream = nil;
    }
}

@end
