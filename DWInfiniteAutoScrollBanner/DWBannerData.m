//
//  DWBannerData.m
//  dreamingwish.com
//
//  Created by dreamingwish.com on 16/8/26.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import "DWBannerData.h"

@interface DWBannerData ()
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, strong, readwrite) NSURL *imageURL;
@end

@implementation DWBannerData

+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithURLStringArray:(NSArray<NSString *> *)URLStringArray
{
    if (![URLStringArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray<__kindof DWBannerData *> *bannerList = [[NSMutableArray alloc] initWithCapacity:[URLStringArray count]];
    for (NSString *URLString in URLStringArray) {
        NSURL *URL = [NSURL URLWithString:URLString];
        DWBannerData* bannerData = nil;
        if (URL) {
            bannerData = [[DWBannerData alloc] initWithImageURL:URL];
        }
        if (bannerData) {
            [bannerList addObject:bannerData];
        }
    }
    return bannerList;
}

+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithURLArray:(NSArray<NSURL *> *)URLArray
{
    if (![URLArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray<__kindof DWBannerData *> *bannerList = [[NSMutableArray alloc] initWithCapacity:[URLArray count]];
    for (NSURL *URL in URLArray) {
        DWBannerData* bannerData = nil;
        if (URL) {
            bannerData = [[DWBannerData alloc] initWithImageURL:URL];
        }
        if (bannerData) {
            [bannerList addObject:bannerData];
        }
    }
    return bannerList;
}

+ (NSMutableArray<__kindof DWBannerData *> *)bannerListWithImageArray:(NSArray<UIImage *> *)imageArray
{
    if (![imageArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray<__kindof DWBannerData *> *bannerList = [[NSMutableArray alloc] initWithCapacity:[imageArray count]];
    for (UIImage *image in imageArray) {
        DWBannerData* bannerData = bannerData = [[DWBannerData alloc] initWithImage:image];
        if (bannerData) {
            [bannerList addObject:bannerData];
        }
    }
    return bannerList;
}

+ (NSMutableArray<__kindof NSURL *> *)imageURLsFromBannerList:(NSArray<__kindof DWBannerData *> *)bannerList
{
    NSMutableArray<__kindof NSURL *> *imageURLs = [NSMutableArray array];
    for (DWBannerData *bannerData in bannerList) {
        if (bannerData.imageURL) {
            [imageURLs addObject:bannerData.imageURL];
        }
    }
    return imageURLs;
}

- (instancetype)initWithImageURL:(NSURL *)imageURL
{
    self = [super init];
    if (self) {
        self.imageURL = imageURL;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

@end
