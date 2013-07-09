//
//  UpdatingImageView.h

//
//  Created by Om on 25/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadOperationDelegate.h"

@interface UpdatingImageView : UIImageView <DownloadOperationDelegate>
{
@private
    NSURL *_url;
    UIImage *_placeholder;
    NSString *_screenName;
}

@property(nonatomic, copy) NSURL *url;
@property(nonatomic, assign) BOOL useCacheIfExists;
@property(nonatomic, retain) UIImage *placeholderImage;
@property(nonatomic, retain) NSString *screenName;

@end
