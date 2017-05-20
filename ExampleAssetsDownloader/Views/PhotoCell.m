//
//  PhotoCell.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "PhotoCell.h"

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
    self.photoImageView = photoImageView;
    [self.contentView addSubview:photoImageView];
    
    return self;
}

- (void)layoutSubviews
{
    [self.photoImageView setFrame:self.bounds];
}


#pragma mark - <overridden setters>

- (void)setPhoto:(Photo *)photo
{
    _photo = photo;
    [self.photoImageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:photo.url]]];
}

@end
