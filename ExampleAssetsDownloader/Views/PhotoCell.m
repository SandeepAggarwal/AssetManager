//
//  PhotoCell.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "PhotoCell.h"
#import "AssetManager.h"

@interface PhotoCell ()

@property (nonatomic, strong) UIImageView* photoImageView;

@end

@implementation PhotoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self)
    {
        return nil;
    }
    
    UIImageView* photoImageView = [UIImageView new];
    [photoImageView setContentMode:(UIViewContentModeScaleAspectFit)];
    [photoImageView.layer setBorderWidth:1.0f];
    [photoImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    [photoImageView.layer setCornerRadius:4.0f];
    [photoImageView.layer setMasksToBounds:YES];
    self.photoImageView = photoImageView;
    [self.contentView addSubview:photoImageView];
    
    return self;
}

- (void)layoutSubviews
{
    if (!self.photo)
    {
        return;
    }
    
    CGFloat aspectRatio = self.photo.width/self.photo.height;
    CGFloat width, height;
    
    if (aspectRatio < 1.0)
    {
        height = self.contentView.bounds.size.height;
        width = aspectRatio*height;
    }
    else
    {
        width = self.contentView.bounds.size.width;
        height = width/aspectRatio;
    }
    
    [self.photoImageView setBounds:CGRectMake(0, 0, width, height)];
    [self.photoImageView setCenter:CGPointMake(self.contentView.bounds.size.width*0.5, self.contentView.bounds.size.height*0.5)];
}


#pragma mark - <overridden setters>

- (void)setPhoto:(Photo *)photo
{
    _photo = photo;
    
    self.photoImageView.image = nil;
    
    __weak typeof(self) weakSelf = self;
    
    AssetManager* manager = [AssetManager sharedManager];
    [manager loadAssetType:(AssetImage) WithURL:photo.url options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
    {
        UIImage* image = asset;
        dispatch_async(dispatch_get_main_queue(), ^
           {
               [weakSelf.photoImageView setImage:image];
           });
    }];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
