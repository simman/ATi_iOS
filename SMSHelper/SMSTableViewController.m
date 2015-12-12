//
//  SMSTableViewController.m
//  SMSHelper
//
//  Created by SimMan on 15/12/12.
//  Copyright © 2015年 Toutoo. All rights reserved.
//

#import "SMSTableViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import "MJRefresh.h"
#import "SMSTableViewCell.h"
#import "MJRefreshConst.h"

const NSInteger pageSize = 20;

@interface SMSTableViewController () {
    NSMutableArray *dataArray;
}

@property (nonatomic, assign) NSInteger pageNum;

- (IBAction)reloadData:(UIBarButtonItem *)sender;

@end

inline static NSString * stringWithDate(NSDate *date) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

@implementation SMSTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    [self loadDataWith:0];
    
    
    __unsafe_unretained UITableView *tableView = self.tableView;
    __unsafe_unretained SMSTableViewController *controller = self;
        
    // 下拉刷新
    tableView.header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        _pageNum = 0;
        [controller loadDataWith:_pageNum];
    }];
    
    // 设置自动切换透明度(在导航栏下面自动隐藏)
    tableView.header.autoChangeAlpha = YES;
    
    // 上拉刷新
    tableView.footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        _pageNum ++;
        [controller loadDataWith:_pageNum];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"SMStableViewCell";
    SMSTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
 
    if (!cell) {
        cell = [[SMSTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier];
    }
    
    AVObject *object = dataArray[indexPath.row];
    
    [cell.cellTitlteLabel setText:[NSString stringWithFormat:@"%@", [object objectForKey:@"sender"]]];
    [cell.cellDetailLabel setText:[NSString stringWithFormat:@"%@", [object objectForKey:@"content"]]];
    [cell.cellDateTimeLabel setText:[NSString stringWithFormat:@"%@", stringWithDate([object objectForKey:@"sendTime"])]];
    
    BOOL isRead = [[object objectForKey:@"isRead"] boolValue];
    
    if (isRead) {
        cell.backgroundColor = [UIColor whiteColor];
    } else {
        cell.backgroundColor = MJRefreshColor(196, 244, 255);
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AVObject *post = dataArray[indexPath.row];
    [post setObject:@(YES) forKey:@"isRead"];
    [post saveInBackground];
    [tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AVObject *post = dataArray[indexPath.row];
        [post deleteInBackground];
        [dataArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) loadDataWith:(NSInteger)pageNum
{
    AVQuery *query = [AVQuery queryWithClassName:@"SMSMessage"];
    query.limit = pageSize;
    query.skip = pageSize * _pageNum;
    [query orderByDescending:@"createdAt"];
    query.cachePolicy = kAVCachePolicyNetworkElseCache;
    //设置缓存有效期
    query.maxCacheAge = 24 * 3600 * 30 * 12;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (!dataArray) {
                dataArray = [NSMutableArray new];
            }
            
            if (![objects count]) {
                [self endRefresh];
                return ;
            }
            
            if (!_pageNum) {
                [dataArray removeAllObjects];
            }
            [dataArray addObjectsFromArray:objects];
            
            [self.tableView reloadData];
        } else {
            
            if (_pageNum) {
                _pageNum --;
            }
            // 输出错误信息
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [self endRefresh];
    }];
}

- (void) endRefresh
{
    [self.tableView.header endRefreshing];
    [self.tableView.footer endRefreshing];
}

- (IBAction)reloadData:(UIBarButtonItem *)sender {
    _pageNum = 0;
    [self loadDataWith:_pageNum];
}
@end
