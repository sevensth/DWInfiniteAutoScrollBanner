//
//  DWInfiniteAutoScrollBanner.h
//  DWInfiniteAutoScrollBanner
//
//  Created by dreamingwish.com on 16/9/17.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWBannerData.h"

@class DWInfiniteAutoScrollBanner;
@protocol DWInfiniteAutoScrollBannerHUD <NSObject>
@optional
- (void)infiniteAutoScrollBanner:(DWInfiniteAutoScrollBanner *)banner didChangeImagesCountTo:(NSInteger)imagesCount;
- (void)infiniteAutoScrollBanner:(DWInfiniteAutoScrollBanner *)banner didScrollToImageIndex:(NSInteger)imageIndex;
@end

@interface DWInfiniteAutoScrollBanner : UIView
@property(getter=isPaused, nonatomic) BOOL paused;
@property (nonatomic) CGFloat autoScrollInterval; ///< In second
//@property (nonatomic) BOOL preloadAllImages;
@property (strong, nonatomic) UIView<DWInfiniteAutoScrollBannerHUD> *HUDView;
//@property (weak, nonatomic) id<DWInfiniteAutoScrollBannerHUD> delegate;

- (void)updateWithBannerDataList:(NSArray<DWBannerData *> *)bannerDataList;
- (void)scrollToImageIndex:(NSInteger)imageIndex isForward:(BOOL)isForward animated:(BOOL)animated;

@end
