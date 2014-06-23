/*

    File: EWCacheManager.h
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

#import <Foundation/Foundation.h>

@class AFHTTPRequestOperation;
@class AFHTTPRequestOperationManager;

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

@property(nonatomic, strong) AFHTTPRequestOperationManager *downloadClient;
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
 *  Initiates a download request with the specified request and filename,
 *  executing success() and failure() as appropriate, if defined.
 *
 *  @param request  The URL request to make.
 *  @param filename The filename where the data should be downloaded.
 *  @param success  The block to execute upon sucessfully downloading the
 *                  requested file.
 *  @param failure  The block to execute upon failure (lost connection, data
 *                  corruption, IO error, etc).
 */
- (void)downloadFileWithRequest:(NSURLRequest *)request
                       filename:(NSString *)filename
                        success:(void (^)(AFHTTPRequestOperation *operation,
                                          id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation,
                                          NSError *error))failure;

/**
 *  Returns the name of the file currently being downloaded.
 *
 *  @return The filename.
 */
- (NSString *)nameOfFileCurrentlyDownloading;

@end
