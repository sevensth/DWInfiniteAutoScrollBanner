//
//  DWDemoBannerHUD.m
//
//  Created by dreamingwish.com on 16/8/21.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import "DWDemoBannerHUD.h"

@interface DWDemoBannerHUD ()
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@end

@implementation DWDemoBannerHUD

- (void)infiniteAutoScrollBanner:(DWInfiniteAutoScrollBanner *)banner didChangeImagesCountTo:(NSInteger)imagesCount
{
    self.pageControl.numberOfPages = imagesCount;
}

- (void)infiniteAutoScrollBanner:(DWInfiniteAutoScrollBanner *)banner didScrollToImageIndex:(NSInteger)imageIndex
{
    imageIndex = (imageIndex < 0 || self.pageControl.numberOfPages <= 0) ? 0 : (imageIndex % self.pageControl.numberOfPages);
    self.pageControl.currentPage = imageIndex;
}

@end
