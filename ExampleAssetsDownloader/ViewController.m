//
//  ViewController.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "ViewController.h"

#import "PhotoCell.h"
#import "Photo.h"

#import "PhotoObjectsFetcher.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray<Photo *>* photos;

@end

@implementation ViewController

static NSString* PhotoIdentifier = @"PhotoIdentifier";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.photos = [NSMutableArray new];
    PhotoObjectsFetcher* fetcher = [PhotoObjectsFetcher new];
    
    __weak typeof(self) weakSelf = self;
    [fetcher fetchPhotosWithOffset:0 count:10 completionBlock:^(NSArray<Photo *> *photos, NSError *error)
    {
        [weakSelf.photos addObjectsFromArray:photos];
        
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [weakSelf. tableView reloadData];
        });
    }];
    [self addTableViewController];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat width,height,x,y;
    
    width = [self maxPhotoWidth];
    height = self.view.bounds.size.height - 100;
    y = 100;
    x = (self.view.bounds.size.width - width)*0.5;
    [self.tableView setFrame:CGRectMake(x , y, width, height)];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.photos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Photo* photo = [self photoObjectForIndexPath:indexPath];
    PhotoCell* cell = [tableView dequeueReusableCellWithIdentifier:PhotoIdentifier forIndexPath:indexPath];
    [cell setPhoto:photo];
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRowAtIndexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 30.0f;
}


#pragma mark - Private Methods

- (void)addTableViewController
{
    UITableViewController* tableViewController = [UITableViewController new];
    [self addChildViewController:tableViewController];
    [self.view addSubview:tableViewController.view];
    UITableView* tableView = tableViewController.tableView;
    self.tableView = tableView;
    [tableView registerClass:[PhotoCell class] forCellReuseIdentifier:PhotoIdentifier];
    
    [tableView setSeparatorStyle:(UITableViewCellSeparatorStyleNone)];
    [tableView setShowsVerticalScrollIndicator:NO];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setAllowsSelection:NO];
    [tableViewController didMoveToParentViewController:self];
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0f;
    
    Photo* photo = [self photoObjectForIndexPath:indexPath];
    
    CGFloat aspectRatio = photo.width/photo.height;
    if (aspectRatio < 1.0)
    {
        height = [self maxPhotoHeight];
    }
    else
    {
        height = [self maxPhotoWidth]/aspectRatio;
    }
    
    return height;
}

- (CGFloat)maxPhotoWidth
{
    return self.view.bounds.size.width * 0.8;
}

- (CGFloat)maxPhotoHeight
{
    return self.view.bounds.size.height * 0.4;
}

- (Photo*)photoObjectForIndexPath:(NSIndexPath *)indexPath
{
    return [self.photos objectAtIndex:indexPath.section];
}

@end
