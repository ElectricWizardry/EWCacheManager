//
//  EWCacheManager.m
//
//  Created by Eric Bailey on 12/6/13.
//  Copyright (c) 2013 Electric Wizardry, LLC. All rights reserved.
//

#import "EWCacheManager.h"
#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "NSFileManager+DirectoryLocations.h"


@implementation EWCacheManager
@synthesize fileProgress = _fileProgress;
@synthesize queueProgress = _queueProgress;

+ (id)sharedManager {
	static EWCacheManager *manager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    manager = [[self alloc] init];
	});
	return manager;
}

- (id)init {
	if (self = [super init]) {
		path = [[NSFileManager defaultManager] applicationSupportDirectory];
        
		_fileProgress = 0.0f;
		_requestedFilesCount = 0;
	}
	return self;
}

- (void)downloadFileWithRequest:(NSURLRequest *)request
                       filename:(NSString *)filename
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success {
	dispatch_async(dispatch_get_main_queue(), ^{
	    self.requestedFilesCount++;
	    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
	    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:[[EWCacheManager sharedManager] pathForFilename:filename] append:NO];
        
	    [operation setDownloadProgressBlock: ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            if (![filename isEqualToString:currentDownloadFilename]) {
                currentDownloadFilename = filename;
            }
            _fileProgress = (float)totalBytesRead / totalBytesExpectedToRead;
            _queueProgress = (float)(_fileProgress + self.requestedFilesCount - self.downloadClient.operationQueue.operationCount) / self.requestedFilesCount;
        }];
        
	    [operation setCompletionBlockWithSuccess: ^(AFHTTPRequestOperation *operation, id responseObject) {
            success(operation, responseObject);
            [self.delegate downloadSucceededWithRequest:request filename:filename];
        }
         
	                                     failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [self deleteFileInCache:filename];
                                             [self.delegate downloadFailedWithRequest:request
                                                                             filename:filename
                                                                                error:error];
                                         }];
        
	    [self.downloadClient enqueueHTTPRequestOperation:operation];
	});
}

- (BOOL)hasFileInCache:(NSString *)filename {
	if (filename == nil) return NO;
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filepath = [path stringByAppendingPathComponent:filename];
    
	NSError *error;
	return ([fileManager fileExistsAtPath:filepath] &&
	        [fileManager attributesOfItemAtPath:filepath error:nil].fileSize > 0 &&
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
    
	if ([fileManager fileExistsAtPath:filepath]) [fileManager removeItemAtPath:filepath error:nil];
}

- (NSString *)pathForFilename:(NSString *)filename {
	return [path stringByAppendingPathComponent:filename];
}

- (void)setRequestedFilesCount:(NSUInteger)requestedFilesCount {
	_requestedFilesCount = requestedFilesCount;
}

@synthesize baseURL = _baseURL;
- (void)setBaseURL:(NSURL *)baseURL {
	_baseURL = baseURL;
    
	_downloadClient = [[AFHTTPClient alloc] initWithBaseURL:_baseURL];
	[_downloadClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
	[_downloadClient.operationQueue setMaxConcurrentOperationCount:1];
}

@synthesize downloadClient = _downloadClient;
- (AFHTTPClient *)downloadClient {
	NSAssert(_baseURL, @"No base URL set.");
    
	return _downloadClient;
}

@synthesize requestedFilesCount = _requestedFilesCount;
- (NSUInteger)requestedFilesCount {
	if (self.downloadClient.operationQueue.operationCount > 0) {
		return _requestedFilesCount;
	}
    
	return 0;
}

- (NSString *)nameOfFileCurrentlyDownloading {
	if (!_downloadClient || !(_downloadClient.operationQueue.operationCount > 0) || currentDownloadFilename.length == 0) return nil;
    
	return currentDownloadFilename;
}

@end
