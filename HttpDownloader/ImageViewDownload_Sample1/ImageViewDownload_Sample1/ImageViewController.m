//
//  ImageViewController.m
//  ImageViewDownload_Sample1
//
//  Created by omkar_ramtekkar on 19/06/13.
//  Copyright (c) 2013 omkar_ramtekkar. All rights reserved.
//

#import "ImageViewController.h"
@interface ImageViewController ()

@end

@implementation ImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**
     * UpdatingImageView is a subclass of UIImageView, which handles all internal operations/delegates of DownloadManager
     * Developer just need to create an object of UpdatingImageView and set the url property.
     * screenName property is an enhanced feature for pause and resume facility
     */
    
    UpdatingImageView* dynamicImageView = [[UpdatingImageView alloc] initWithFrame:self.view.frame];
    dynamicImageView.screenName = @"testscreen";
    dynamicImageView.url = [NSURL URLWithString:@"http://www.noaanews.noaa.gov/stories/images/goes-12-firstimage-large081701.jpg"];
    
    [self.view addSubview: dynamicImageView];
    [dynamicImageView release];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [super dealloc];
}
@end
