//
//  DWInfiniteAutoScrollBanner.m
//  DWInfiniteAutoScrollBanner
//
//  Created by dreamingwish.com on 16/9/17.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import "DWInfiniteAutoScrollBanner.h"
#import "DWBannerData.h"

#if DEBUG
//#define DEBUG_MGAutoScrollBanner 1
#endif

static const NSInteger FakeInfintePageCount = 400;
static const NSInteger PrepareImageCount = 2;
static const NSInteger ReuseImageCount = 1 + 2*PrepareImageCount;
static const CGFloat AutoScrollInterval = 3.0;
static const CGFloat MinAutoScrollInterval = 1.0;

@interface DWInfiniteAutoScrollBanner () <UIScrollViewDelegate>
@property (strong, nonatomic) UIScrollView *scrollview;
@property (strong, nonatomic) NSMutableArray<__kindof UIImageView *> *imagesViews;
@property (strong, nonatomic) NSArray<DWBannerData *> *bannerDataList;
@property (nonatomic) NSInteger actualImagesCount;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) NSInteger lastPageIndex;
@property (nonatomic) NSInteger firstImagePageIndex;
@property (strong, nonatomic) CADisplayLink *autoScrollTimer;
@property (nonatomic) CFTimeInterval lastScrollMediaTime;
@property (nonatomic) BOOL needsReorderAndReloadImageViews;
@end

@implementation DWInfiniteAutoScrollBanner

#pragma mark -
#pragma mark Life cycle

- (void)commonInit
{
    //basic
    self.autoScrollInterval = AutoScrollInterval;
    self.currentPageIndex = -1;
    self.lastPageIndex = -1;
    //scroll view
    self.scrollview = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollview.delegate = self;
    self.scrollview.scrollEnabled = YES;
    self.scrollview.pagingEnabled = YES;
    self.scrollview.showsVerticalScrollIndicator = NO;
    self.scrollview.showsHorizontalScrollIndicator = NO;
    self.scrollview.bounces = NO;
    self.scrollview.alwaysBounceVertical = NO;
    self.scrollview.alwaysBounceHorizontal = NO;
    self.scrollview.maximumZoomScale = 1.0;
    self.scrollview.minimumZoomScale = 1.0;
    self.scrollview.bouncesZoom = NO;
    self.scrollview.scrollsToTop = NO;
    [self addSubview:self.scrollview];
    //reuse image views
    self.imagesViews = [[NSMutableArray alloc] initWithCapacity:ReuseImageCount];
    for (NSInteger i = 0; i < ReuseImageCount; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self.scrollview addSubview:imageView];
        [self.imagesViews addObject:imageView];
    }
    
#if DEBUG_MGAutoScrollBanner
    self.scrollview.showsVerticalScrollIndicator = YES;
    self.scrollview.showsHorizontalScrollIndicator = YES;
    self.imagesViews[0].backgroundColor = [UIColor redColor];
    self.imagesViews[1].backgroundColor = [UIColor orangeColor];
    self.imagesViews[2].backgroundColor = [UIColor yellowColor];
    self.imagesViews[3].backgroundColor = [UIColor greenColor];
    self.imagesViews[4].backgroundColor = [UIColor blueColor];
#endif
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark -
#pragma mark getter/setter

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval
{
    if (autoScrollInterval == 0.0) {
        [self destoryTimer];
    } else {
        if (autoScrollInterval < MinAutoScrollInterval) {
            autoScrollInterval = MinAutoScrollInterval;
        }
        [self setupTimerIfNeeded];
    }
    _autoScrollInterval = autoScrollInterval;
}

- (void)setPaused:(BOOL)paused
{
    if (_paused && !paused) {
        self.lastScrollMediaTime = CACurrentMediaTime();
        //fix scrollview content offset: view disappear while scrolling, it stucks
        [self scrollToPageIndex:self.currentPageIndex animated:YES];
    }
    self.autoScrollTimer.paused = _paused = paused;
}

- (void)setHUDView:(UIView<DWInfiniteAutoScrollBannerHUD> *)HUDView
{
    if (HUDView != _HUDView) {
        [_HUDView removeFromSuperview];
        _HUDView = HUDView;
        [self addSubview:_HUDView];
        //update
        //        _HUDView.userInteractionEnabled = NO;
        CGRect HUDViewFrame = self.frame;
        HUDViewFrame.origin = CGPointZero;
        _HUDView.frame = HUDViewFrame;
        if ([_HUDView respondsToSelector:@selector(infiniteAutoScrollBanner:didChangeImagesCountTo:)]) {
            [_HUDView infiniteAutoScrollBanner:self didChangeImagesCountTo:self.actualImagesCount];
        }
        if ([_HUDView respondsToSelector:@selector(infiniteAutoScrollBanner:didScrollToImageIndex:)]) {
            [_HUDView infiniteAutoScrollBanner:self didScrollToImageIndex:[self imageIndexFromPageIndex:self.currentPageIndex]];
        }
    }
}

#pragma mark public
- (void)updateWithBannerDataList:(NSArray<DWBannerData *> *)bannerDataList
{
    self.bannerDataList = bannerDataList;
    self.actualImagesCount = bannerDataList.count;
    self.scrollview.scrollEnabled = (self.actualImagesCount > 1);
    if ([self.HUDView respondsToSelector:@selector(infiniteAutoScrollBanner:didChangeImagesCountTo:)]) {
        [self.HUDView infiniteAutoScrollBanner:self didChangeImagesCountTo:self.actualImagesCount];
    }
    [self setNeedsLayout];
    [self setupTimerIfNeeded];
}

- (void)scrollToImageIndex:(NSInteger)imageIndex isForward:(BOOL)isForward animated:(BOOL)animated
{
    NSInteger pageIndex = [self pageIndexFromImageIndex:imageIndex isForward:isForward];
    [self scrollToPageIndex:pageIndex animated:animated];
}

#pragma mark protected
- (void)layoutSubviews
{
    if (self.actualImagesCount <= 0) {
        return;
    }
    
    CGRect pageFrame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    //hud
    self.HUDView.frame = pageFrame;
    //images
    CGRect imageFrame = pageFrame;
    for (int i = 0; i < ReuseImageCount; i++) {
        //reserve origin in case -[layoutSubviews] be called after -[reorderAndReloadImageViews]
        //@TODO: restore image position by their tag(pageIndex), and restore srollview's contentOffset
        imageFrame.origin = self.imagesViews[i].frame.origin;
        self.imagesViews[i].frame = imageFrame;
        self.imagesViews[i].tag = -1;
    }
    //scrollview
    self.scrollview.frame = pageFrame;
    self.scrollview.contentSize = CGSizeMake(self.frame.size.width * FakeInfintePageCount, self.scrollview.frame.size.height);
    CGFloat expectedContentOffsetX = self.scrollview.contentSize.width / 2.0;
    self.firstImagePageIndex = expectedContentOffsetX / pageFrame.size.width;
    //[self reorderAndReloadImageViews] will be called by scrollViewDidScroll when setContentOffset is first time called
    //set needsReorderAndReloadImageViews before setContentOffset to avoid calling reorderAndReloadImageViews twice
    self.needsReorderAndReloadImageViews = YES;
    self.scrollview.contentOffset = CGPointMake(expectedContentOffsetX, 0.0);
    [self reorderAndReloadImageViews];
}

- (void)didMoveToWindow
{
    [self destoryTimer];
    [self setupTimerIfNeeded];
}

#pragma mark private
- (void)setupTimerIfNeeded
{
    if (self.window && self.actualImagesCount > 1 && self.autoScrollInterval >= MinAutoScrollInterval) {
        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScrollTimerFired:)];
        self.autoScrollTimer.frameInterval = 10;
        self.autoScrollTimer.paused = self.paused;
        [self.autoScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)destoryTimer
{
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
}

- (void)reorderAndReloadImageViews
{
    if (!self.needsReorderAndReloadImageViews) {
        return;
    }
    self.needsReorderAndReloadImageViews = NO;
    
    NSInteger expectedLeftImagePageIndex = self.currentPageIndex - PrepareImageCount;
    NSInteger pageMoveDistance = expectedLeftImagePageIndex - self.imagesViews.firstObject.tag;
    NSInteger absPageMoveDistance = ABS(pageMoveDistance);
    
    //scroll very fast, beyound left image's left or right image's right
    if (absPageMoveDistance >= ReuseImageCount) {
        for (NSInteger i = 0; i < self.imagesViews.count; i++) {
            [self updateImageView:self.imagesViews[i] toPageIndex:expectedLeftImagePageIndex + i];
        }
    } else { //reuse
        if (pageMoveDistance > 0) {
            // L2 L1 M  R1 R2 -> M  R1 R2 [L2] [L1]
            // 10 11 12 13 14 -> 12 13 14  15   16
            for (NSInteger i = 0; i < absPageMoveDistance; i++) {
                [self updateImageView:self.imagesViews[i] toPageIndex:expectedLeftImagePageIndex + ReuseImageCount - absPageMoveDistance + i];
            }
            [self rollLeftArray:self.imagesViews byDistance:absPageMoveDistance];
        } else if (pageMoveDistance < 0) {
            // L2 L1 M R1 R2 -> [R1] [R2] L2 L1 M
            for (NSInteger i = 0; i < absPageMoveDistance; i++) {
                [self updateImageView:self.imagesViews[i + ReuseImageCount - absPageMoveDistance] toPageIndex:expectedLeftImagePageIndex + i];
            }
            [self rollRightArray:self.imagesViews byDistance:absPageMoveDistance];
        }
    }
}

- (void)updateImageView:(UIImageView *)imageView toPageIndex:(NSInteger)pageIndex
{
    //update frame and tag
    CGFloat pageWidth = self.scrollview.frame.size.width;
    CGRect imageFrame = imageView.frame;
    imageFrame.origin.x = pageWidth * pageIndex;
    imageView.frame = imageFrame;
    imageView.tag = pageIndex;
    //load image
    NSInteger imageURLIndex = [self imageIndexFromPageIndex:pageIndex];
#if DEBUG_MGAutoScrollBanner
    NSLog(@"firstImagePageIndex is: %i, load index: %i, reuse image: %i, load image %i, URL: %@", self.firstImagePageIndex, pageIndex, ReuseImageCount, imageURLIndex, self.imageURLs[imageURLIndex]);
#endif
    DWBannerData *bannerData = self.bannerDataList[imageURLIndex];
    if (bannerData.image) {
        imageView.image = bannerData.image;
    } else {
        static SEL sdSetImageSelector = nil;
        if (!sdSetImageSelector) {
            sdSetImageSelector = NSSelectorFromString(@"sd_setImageWithURL:");
        }
        if ([imageView respondsToSelector:sdSetImageSelector]) {
            NSURL *imageURL = bannerData.imageURL;
            ((void (*)(id, SEL, id))[imageView methodForSelector:sdSetImageSelector])(imageView, sdSetImageSelector, imageURL);
        } else {
#if DEBUG_MGAutoScrollBanner
            NSLog(@"none of image or image URL set for MGBannerData:%@", bannerData);
#endif
        }
    }
}

- (NSInteger)imageIndexFromPageIndex:(NSInteger)pageIndex
{
    if (pageIndex < 0) {
        return -1;
    }
    return (self.actualImagesCount - (self.firstImagePageIndex % self.actualImagesCount) + pageIndex) % self.actualImagesCount;
}

- (NSInteger)pageIndexFromImageIndex:(NSInteger)imageIndex isForward:(BOOL)isForward
{
    if (imageIndex < 0 || imageIndex >= self.actualImagesCount) {
        return -1;
    }
    NSInteger currentImageIndex = [self imageIndexFromPageIndex:self.currentPageIndex];
    if (currentImageIndex == imageIndex) {
        return self.currentPageIndex;
    }
    if (isForward) {
        if (imageIndex < currentImageIndex) {
            imageIndex += self.actualImagesCount;
        }
        return self.currentPageIndex + (imageIndex - currentImageIndex);
    } else {
        if (imageIndex > currentImageIndex) {
            imageIndex -= self.actualImagesCount;
        }
        return self.currentPageIndex - (currentImageIndex - imageIndex);
    }
}

- (void)autoScrollTimerFired:(CADisplayLink *)timer
{
    CFTimeInterval currentMediaTime = CACurrentMediaTime();
    if (currentMediaTime - self.lastScrollMediaTime >= self.autoScrollInterval) {
        self.lastScrollMediaTime = currentMediaTime;
        if (!self.scrollview.isTracking) {
            [self scrollToPageIndex:self.currentPageIndex + 1 animated:YES];
        }
#if DEBUG_MGAutoScrollBanner
        NSLog(@"Auto scroll to page index: %i", self.currentPageIndex + 1);
#endif
    }
}

- (void)scrollToPageIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
    CGPoint contentOffset = self.scrollview.contentOffset;
    contentOffset.x = self.scrollview.frame.size.width * pageIndex;
    [self.scrollview setContentOffset:contentOffset animated:animated];
}

- (void)rollLeftArray:(NSMutableArray *)mutableArray byDistance:(NSUInteger)distance
{
    for (NSInteger i = (NSInteger)distance; i > 0; i--) {
        NSObject* obj = [mutableArray firstObject];
        [mutableArray addObject:obj];
        [mutableArray removeObjectAtIndex:0];
    }
}

- (void)rollRightArray:(NSMutableArray *)mutableArray byDistance:(NSUInteger)distance
{
    for (NSInteger i = (NSInteger)distance; i > 0; i--) {
        NSObject* obj = [mutableArray lastObject];
        [mutableArray insertObject:obj atIndex:0];
        [mutableArray removeLastObject];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.lastScrollMediaTime = CACurrentMediaTime();
    self.currentPageIndex = scrollView.contentOffset.x / self.scrollview.frame.size.width;
    BOOL pageIndexChanged = self.lastPageIndex != self.currentPageIndex;
    self.needsReorderAndReloadImageViews = (self.needsReorderAndReloadImageViews || pageIndexChanged);
    [self reorderAndReloadImageViews];
    self.lastPageIndex = self.currentPageIndex;
    //callback
    if (pageIndexChanged && [_HUDView respondsToSelector:@selector(infiniteAutoScrollBanner:didScrollToImageIndex:)]) {
        [_HUDView infiniteAutoScrollBanner:self didScrollToImageIndex:[self imageIndexFromPageIndex:self.currentPageIndex]];
    }
}

@end
