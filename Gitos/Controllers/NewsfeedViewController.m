//
//  NewsfeedViewController.m
//  Gitos
//
//  Created by Tri Vuong on 12/16/12.
//  Copyright (c) 2012 Crafted By Tri. All rights reserved.
//

#import "NewsfeedViewController.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "SSKeychain.h"
#import "User.h"
#import "NewsFeedCell.h"
#import "SpinnerView.h"

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

@synthesize newsFeed, user, spinnerView;

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
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"News Feed";
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"header_bg.png"] forBarMetrics:UIBarMetricsDefault];
    
    UINib *nib = [UINib nibWithNibName:@"NewsFeed" bundle:nil];
    
    [newsFeedTable registerNib:nib forCellReuseIdentifier:@"NewsFeed"];
    [newsFeedTable setAutoresizingMask:YES];

    self.spinnerView = [SpinnerView loadSpinnerIntoView:self.view];
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
         [self getUserNewsFeed];
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
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSDictionary *item = [self.newsFeed objectAtIndex:indexPath.row];

    NSString *eventType = [item valueForKey:@"type"];
    NSString *actor     = [[item valueForKey:@"actor"] valueForKey:@"login"];
    NSString *repoName  = [[item valueForKey:@"repo"] valueForKey:@"name"];

    if ([eventType isEqualToString:@"ForkEvent"]) {

        cell.actionDescription.text = [NSString stringWithFormat:@"%@ forked %@", actor, repoName];

    } else if ([eventType isEqualToString:@"WatchEvent"]) {

        cell.actionDescription.text = [NSString stringWithFormat:@"%@ watched %@", actor, repoName];

    } else if ([eventType isEqualToString:@"CreateEvent"]) {

        cell.actionDescription.text = [NSString stringWithFormat:@"%@ created %@", actor, repoName];

    } else if ([eventType isEqualToString:@"FollowEvent"]) {
        
        NSString *target = [[[item valueForKey:@"payload"] valueForKey:@"target"] valueForKey:@"login"];
        cell.actionDescription.text = [NSString stringWithFormat:@"%@ started following %@", actor, target];
        
    } else if ([eventType isEqualToString:@"GistEvent"]) {

        NSString *action = [[item valueForKey:@"payload"] valueForKey:@"action"];
        NSString *gist = [[[item valueForKey:@"payload"] valueForKey:@"gist"] valueForKey:@"id"];
        cell.actionDescription.text = [NSString stringWithFormat:@"%@ %@ gist:%@", actor, action, gist];

    } else if ([eventType isEqualToString:@"IssuesEvent"]) {

        NSString *issue = [[[item valueForKey:@"payload"] valueForKey:@"issue"] valueForKey:@"id"];
        NSString *action = [[item valueForKey:@"payload"] valueForKey:@"action"];
        cell.actionDescription.text = [NSString stringWithFormat:@"%@ %@ issue:%@", actor, action, issue];

    }
    
    cell.actionDate.text = [item valueForKey:@"created_at"];

    return  cell;
}

- (void)getUserNewsFeed
{
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:self.user.receivedEventsUrl]];

    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:self.user.receivedEventsUrl parameters:nil];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];

    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject){
         NSString *response = [operation responseString];

         self.newsFeed = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
         
         [self.spinnerView removeFromSuperview];

         [newsFeedTable reloadData];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"an exception happened");
     }
     ];

    [operation start];

}

@end
