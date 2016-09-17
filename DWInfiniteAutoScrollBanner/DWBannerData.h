//
//  DWBannerData.h
//  dreamingwish.com
//
//  Created by dreamingwish.com on 16/8/26.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DWBannerData : NSObject
@property (nonatomic, strong, readonly) NSURL *imageURL;
@property (nonatomic, strong, readonly) UIImage *image;
+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithURLStringArray:(NSArray<NSString *> *)URLStringArray;
+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithURLArray:(NSArray<NSURL *> *)URLArray;
+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithImageArray:(NSArray<UIImage *> *)imageArray;
+ (NSMutableArray<__kindof NSURL *> *)imageURLsFromBannerList:(NSArray<__kindof DWBannerData *> *)bannerList;
- (instancetype)initWithImageURL:(NSURL *)imageURL;
- (instancetype)initWithImage:(UIImage *)image;
@end
