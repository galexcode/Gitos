//
//  NewsfeedViewController.m
//  Gitos
//
//  Created by Tri Vuong on 12/16/12.
//  Copyright (c) 2012 Crafted By Tri. All rights reserved.
//

#import "NewsfeedViewController.h"
#import "NewsfeedDetailsViewController.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "SSKeychain.h"
#import "User.h"
#import "NewsFeedCell.h"
#import "SpinnerView.h"
#import "RelativeDateDescriptor.h"
#import "SVPullToRefresh.h"
#import "TimelineEvent.h"

@interface NewsfeedViewController ()

@end

@interface UILabel (BPExtensions)

- (void)sizeToFitFixedWith:(CGFloat)fixedWith;

@end

@implementation UILabel (BPExtensions)

- (void)sizeToFitFixedWith:(CGFloat)fixedWith
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, fixedWith, 0);
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.numberOfLines = 0;
    [self sizeToFit];
}

@end

@implementation NewsfeedViewController

@synthesize newsFeed, user, spinnerView, currentPage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.newsFeed       = [[NSMutableArray alloc] initWithCapacity:0];
        self.currentPage    = 1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"News Feed";
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"header_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    UINib *nib = [UINib nibWithNibName:@"NewsFeed" bundle:nil];
    
    [newsFeedTable registerNib:nib forCellReuseIdentifier:@"NewsFeed"];
    [newsFeedTable setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [newsFeedTable setBackgroundView:nil];
    [self.view setBackgroundColor:[UIColor whiteColor]];

    self.spinnerView = [SpinnerView loadSpinnerIntoView:self.view];
    [self setupPullToRefresh];
    [self getUserInfoAndNewsFeed];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getUserInfoAndNewsFeed
{
    NSString *accessToken = [SSKeychain passwordForService:@"access_token" account:@"gitos"];

    NSURL *userUrl = [NSURL URLWithString:@"https://api.github.com/user"];

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:userUrl];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   accessToken, @"access_token",
                                   @"bearer", @"token_type",
                                   nil];

    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:userUrl.absoluteString parameters:params];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];

    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject){
         NSString *response = [operation responseString];

         NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

         self.user = [[User alloc] initWithOptions:json];
         [self getUserNewsFeed:self.currentPage++];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     }];

    [operation start];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.newsFeed.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NewsFeedCell *cell = [newsFeedTable dequeueReusableCellWithIdentifier:@"NewsFeed"];
//    if (!cell) {
//        cell = [[NewsFeedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NewsFeed"];
//    }
//    //[cell.actionDescription sizeToFitFixedWith:301];
//    
//    return cell.actionDescription.frame.size.height + cell.actionDate.frame.size.height + 10;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsFeedCell *cell = [newsFeedTable dequeueReusableCellWithIdentifier:@"NewsFeed"];
    
    if (!cell) {
        cell = [[NewsFeedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NewsFeed"];
    }
    cell.event = [self.newsFeed objectAtIndex:indexPath.row];
    [cell displayEvent];

    return  cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsfeedDetailsViewController *newsfeedDetailsController = [[NewsfeedDetailsViewController alloc] init];
    newsfeedDetailsController.event = [self.newsFeed objectAtIndex:indexPath.row];
    newsfeedDetailsController.currentPage = (indexPath.row / 30) + 1;
    newsfeedDetailsController.username = self.user.login;
    
    UIImage *backButtonImage = [[UIImage imageNamed:@"barButtonBack.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 5)];

    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    [backButton setTintColor:[UIColor colorWithRed:209/255.0 green:0 blue:0 alpha:1]];
    [self.navigationItem setBackBarButtonItem:backButton];
    
    [self.navigationController pushViewController:newsfeedDetailsController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (([scrollView contentOffset].y + scrollView.frame.size.height) == scrollView.contentSize.height) {
        // Bottom of UITableView reached
        [self.spinnerView setHidden:NO];
        [self getUserNewsFeed:self.currentPage++];
    }
}

- (void)getUserNewsFeed:(NSInteger)page
{
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:self.user.receivedEventsUrl]];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%i", page], @"page",
                                   nil];

    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:self.user.receivedEventsUrl parameters:params];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];

    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject){
         NSString *response = [operation responseString];

         NSArray *newsfeed = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

         for (int i=0; i < newsfeed.count; i++) {
             [self.newsFeed addObject:[[TimelineEvent alloc] initWithOptions:[newsfeed objectAtIndex:i]]];
         }
         
         [self.spinnerView setHidden:YES];

         [newsFeedTable.pullToRefreshView stopAnimating];
         [newsFeedTable reloadData];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [self.spinnerView setHidden:YES];
         [newsFeedTable.pullToRefreshView stopAnimating];
     }
     ];

    [operation start];

}

- (void)setupPullToRefresh
{
    self.currentPage = 1;
    [newsFeedTable addPullToRefreshWithActionHandler:^{
        [self getUserNewsFeed:self.currentPage++];
    }];
}

@end
