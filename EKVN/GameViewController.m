//
//  GameViewController.m
//  AdvTest
//
//  Created by James on 9/21/15.
//  Copyright (c) 2015 James. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"

#import "EKUtils.h"
#import "VNTestScene.h"
@import iAd;

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file {
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
    
    return scene;
}

@end

#pragma mark - Copy this to new projects

@interface GameViewController () <ADBannerViewDelegate>
@property (nonatomic, strong) ADBannerView *banner;
@end

@implementation GameViewController

#pragma mark - AD BANNER STUFF

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    //CGFloat bannerHeight = self.banner.frame.size.height;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    self.banner.alpha = 1;
    [UIView commitAnimations];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    self.banner.alpha = 0;
    [UIView commitAnimations];
}

- (void)showBannerAd
{
    NSLog(@"View Controller should show banner ad");
    
    self.banner.frame = self.view.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    self.banner.hidden = NO;
    self.banner.alpha = 1;
    [UIView commitAnimations];
}

- (void)hideBannerAd
{
    NSLog(@"View Controller should hide banner ad");
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    self.banner.hidden = YES;
    self.banner.alpha = 0;
    [UIView commitAnimations];
}

- (void)addBannerToViewWhenViewAppears
{
    if( self.banner == nil) {
        self.banner = [[ADBannerView alloc] initWithFrame:CGRectZero];
    }
    
    //self.banner.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierLandscape];
    //self.banner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    
    self.banner.frame = self.view.frame;
    
    self.banner.hidden = YES;
    self.banner.alpha = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBannerAd) name:EKUtilsHideAdsNotificationID object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBannerAd) name:EKUtilsShowAdsNotificationID object:nil];
    
    self.banner.delegate = self;
    //[self.banner setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.banner setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.banner];
}

- (void)removeBannerFromView
{
    self.banner.delegate = nil;
    [self.banner removeFromSuperview];
}

- (void)addBannerToViewWhenViewLoads
{
    if( self.banner == nil) {
        self.banner = [[ADBannerView alloc] init];
    }
    
    //self.canDisplayBannerAds = YES;
}

#pragma mark - View stuff

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addBannerToViewWhenViewAppears];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeBannerFromView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addBannerToViewWhenViewLoads];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = YES;
    
    // Create and configure the scene.
    //GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];
    
    VNTestScene* scene = [[VNTestScene alloc] initWithSize:skView.frame.size];
    
    //scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        
        //return uiinterfaceorientation
        
        return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
