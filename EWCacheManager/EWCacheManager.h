//
//  EWCacheManager.h
//
//  Created by Eric Bailey on 2013-12-06.
//  Copyright (c) 2013 Electric Wizardry, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPClient;
@class AFHTTPRequestOperation;

@class EWCacheManager;
@protocol EWCacheManagerDelegate
- (void)downloadFailedWithRequest:(NSURLRequest *)request
                         filename:(NSString *)filename
                            error:(NSError *)error;

@optional
- (void)downloadSucceededWithRequest:(NSURLRequest *)request
                            filename:(NSString *)filename;
@end

/**
 *  The `EWCacheManager` class provides a singleton cache manager with
 *  convenience methods for downloading (via `AFNetworking`) and interacting
 *  with files stored in the app's application support directory.
 */
@interface EWCacheManager : NSObject {
  NSString *path;
  NSString *currentDownloadFilename;
}

@property(nonatomic, weak) id<EWCacheManagerDelegate> delegate;

@property(nonatomic, strong) AFHTTPClient *downloadClient;
@property(nonatomic, strong) NSURL *baseURL;

@property(readonly) float fileProgress;
@property(readonly) float queueProgress;
@property(assign) NSUInteger requestedFilesCount;

///---------------------------------------------
/// @name Getting the Shared Cache Manager
///---------------------------------------------

/**
 *  Returns the singleton cache manager.
 */
+ (id)sharedManager;

///---------------------------------------------
/// @name Getting Information About Cached Files
///---------------------------------------------

/**
 *  Returns the full path for the cached file with the specified filename.
 *
 *  @param filename The name of a cached file.
 */
- (NSString *)pathForFilename:(NSString *)filename;

/**
 *  Returns a `BOOL` representing a file's presence in the cache.
 *
 *  @param filename The name of a possibly cached file.
 *
 *  @return `YES` if the file is present, otherwise `NO`.
 */
- (BOOL)hasFileInCache:(NSString *)filename;

/**
 *  Returns the size in bytes of the cached file, or 0 if the file is not found.
 *
 *  @param filename The name of a cached file.
 */
- (unsigned long long)sizeOfFileInCache:(NSString *)filename;

/**
 *  Checks to see if a file exists in the cache, and if so, deletes it.
 *
 *  @param filename The name of a cached file.
 */
- (void)deleteFileInCache:(NSString *)filename;

/**
 *  Description
 *
 *  @param request  request description
 *  @param filename filename description
 *  @param success  success description
 */
- (void)downloadFileWithRequest:(NSURLRequest *)request
                       filename:(NSString *)filename
                        success:(void (^)(AFHTTPRequestOperation *operation,
                                          id responseObject))success;

/**
 *  Description
 *
 *  @return return value description
 */
- (NSString *)nameOfFileCurrentlyDownloading;

@end
