/*

    File: EWCacheManager.m
 Version: 1.3
 Created: 2013-12-06
 Updated: 2014-06-23
  Author: Eric Bailey <eric@ericb.me>
          Electric Wizardry, LLC <http://electric-wizardry.com>


 Copyright (c) 2014 Electric Wizardry, LLC

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 */

#import "EWCacheManager.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

@implementation EWCacheManager
@synthesize baseURL = _baseURL;
@synthesize fileProgress = _fileProgress;
@synthesize queueProgress = _queueProgress;

+ (id)sharedManager {
  static EWCacheManager *manager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ manager = [[self alloc] init]; });
  return manager;
}

- (id)init {
  if (self = [super init]) {
    path = [NSSearchPathForDirectoriesInDomains(
                NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    _fileProgress = 0.0f;
    _requestedFilesCount = 0;
  }
  return self;
}

- (void)downloadFileWithRequest:(NSURLRequest *)request
                       filename:(NSString *)filename
                        success:(void (^)(AFHTTPRequestOperation *operation,
                                          id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation,
                                          NSError *error))failure {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.requestedFilesCount++;
    AFHTTPRequestOperation *operation =
        [[AFHTTPRequestOperation alloc] initWithRequest:request];

    operation.outputStream =
        [NSOutputStream outputStreamToFileAtPath:
                [[EWCacheManager sharedManager] pathForFilename:filename]
                                          append:NO];

            [operation setDownloadProgressBlock: ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
              if (![filename isEqualToString:currentDownloadFilename]) {
                currentDownloadFilename = filename;
              }
              _fileProgress = (float)totalBytesRead / totalBytesExpectedToRead;
              _queueProgress =
                  (float)(_fileProgress + self.requestedFilesCount -
                          self.downloadClient.operationQueue.operationCount) /
                  self.requestedFilesCount;
            }];

            [operation setCompletionBlockWithSuccess: ^(AFHTTPRequestOperation *operation, id responseObject) {
              success(operation, responseObject);
              [self.delegate downloadSucceededWithRequest:request
                                                 filename:filename];
            }

  failure:
    ^(AFHTTPRequestOperation * operation, NSError * error) {
      [self deleteFileInCache:filename];
      [self.delegate downloadFailedWithRequest:request
                                      filename:filename
                                         error:error];
    }];

    [self.downloadClient.operationQueue addOperation:operation];
  });
}

- (BOOL)hasFileInCache:(NSString *)filename {
  if (filename == nil) return NO;

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *filepath = [path stringByAppendingPathComponent:filename];

  NSError *error;
  return ([fileManager fileExistsAtPath:filepath] &&
          [fileManager attributesOfItemAtPath:filepath error:nil].fileSize >
              0 &&
          error == nil);
}

- (unsigned long long)sizeOfFileInCache:(NSString *)filename {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *filepath = [path stringByAppendingPathComponent:filename];

  if (![fileManager fileExistsAtPath:filepath]) return 0;

  return [[fileManager attributesOfItemAtPath:filepath error:nil] fileSize];
}

- (void)deleteFileInCache:(NSString *)filename {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *filepath = [path stringByAppendingPathComponent:filename];

  if ([fileManager fileExistsAtPath:filepath])
    [fileManager removeItemAtPath:filepath error:nil];
}

- (NSString *)pathForFilename:(NSString *)filename {
  return [path stringByAppendingPathComponent:filename];
}

- (void)setRequestedFilesCount:(NSUInteger)requestedFilesCount {
  _requestedFilesCount = requestedFilesCount;
}

@synthesize downloadClient = _downloadClient;
- (AFHTTPRequestOperationManager *)downloadClient {
  NSAssert(_baseURL, @"No base URL set.");

  if (!_downloadClient) {
    _downloadClient =
        [[AFHTTPRequestOperationManager alloc] initWithBaseURL:_baseURL];
    [_downloadClient.operationQueue setMaxConcurrentOperationCount:1];
  }

  return _downloadClient;
}

@synthesize requestedFilesCount = _requestedFilesCount;
- (NSUInteger)requestedFilesCount {
  return (self.downloadClient.operationQueue.operationCount > 0)
             ? _requestedFilesCount
             : 0;
}

- (NSString *)nameOfFileCurrentlyDownloading {
  return (!_downloadClient ||
          !(_downloadClient.operationQueue.operationCount > 0) ||
          currentDownloadFilename.length == 0)
             ? nil
             : currentDownloadFilename;
}

@end
