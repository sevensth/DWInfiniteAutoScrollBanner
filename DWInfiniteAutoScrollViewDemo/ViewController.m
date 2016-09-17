//
//  ViewController.m
//  DWInfiniteAutoScrollViewDemo
//
//  Created by 宋岳 on 16/9/17.
//  Copyright © 2016年 dreamingwish. All rights reserved.
//

#import "ViewController.h"
#import "DWInfiniteAutoScrollBanner.h"
#import "DWDemoBannerHUD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet DWInfiniteAutoScrollBanner *infiniteAutoScrollBanner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //hud
    DWDemoBannerHUD *hud = [[[NSBundle mainBundle] loadNibNamed:@"DWDemoBannerHUD" owner:nil options:nil] lastObject];
    hud.userInteractionEnabled = NO;//HUD view will block user interaction in DWInfiniteAutoScrollBanner by default, if you want the HUD view to be interactive, you may need implement - (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event and/or some related apis.
    self.infiniteAutoScrollBanner.HUDView = hud;
    //banner data
    NSMutableArray<DWBannerData *> *dataList = [NSMutableArray array];
    //If you have SDWebImage linked, just use image URLs
//    [dataList addObject:[[DWBannerData alloc] initWithImageURL:[NSURL URLWithString:@"http://www.dreamingwish.com/resource/frontui/img/slide/wordpress.jpg"]]];
//    [dataList addObject:[[DWBannerData alloc] initWithImageURL:[NSURL URLWithString:@"http://www.dreamingwish.com/resource/frontui/img/slide/dwrm.jpg"]]];
    [dataList addObject:[[DWBannerData alloc] initWithImage:[UIImage imageNamed:@"bannerImage1"]]];
    [dataList addObject:[[DWBannerData alloc] initWithImage:[UIImage imageNamed:@"bannerImage2"]]];
    [dataList addObject:[[DWBannerData alloc] initWithImage:[UIImage imageNamed:@"bannerImage3"]]];
    [self.infiniteAutoScrollBanner updateWithBannerDataList:dataList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
