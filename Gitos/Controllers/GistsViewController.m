//
//  GistsViewController.m
//  Gitos
//
//  Created by Tri Vuong on 12/16/12.
//  Copyright (c) 2012 Crafted By Tri. All rights reserved.
//

#import "GistsViewController.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "SSKeychain.h"
#import "GistCell.h"
#import "RelativeDateDescriptor.h"
#import "SVPullToRefresh.h"
#import "Gist.h"
#import "SSKeychain.h"
#import "AppConfig.h"
#import "GistViewController.h"

@interface GistsViewController ()

@end

@implementation GistsViewController

@synthesize currentPage, spinnerView, user, accessToken;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.gists = [[NSMutableArray alloc] initWithCapacity:0];
        self.currentPage = 1;
        self.relativeDateDescriptor = [[RelativeDateDescriptor alloc] initWithPriorDateDescriptionFormat:@"%@" postDateDescriptionFormat:@"in %@"];
        self.dateFormatter  = [[NSDateFormatter alloc] init];
        self.accessToken = [SSKeychain passwordForService:@"access_token" account:@"gitos"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Gists";

    UINib *nib = [UINib nibWithNibName:@"GistCell" bundle:nil];
    [gistsTable registerNib:nib forCellReuseIdentifier:@"GistCell"];
    [gistsTable setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [gistsTable setBackgroundView:nil];
    [gistsTable setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [gistsTable setSeparatorColor:[UIColor colorWithRed:206/255.0 green:206/255.0 blue:206/255.0 alpha:0.8]];
    [self.view setBackgroundColor:[UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0]];
    
    self.spinnerView = [SpinnerView loadSpinnerIntoView:self.view];
    
    [self setupPullToRefresh];
    [self getUserInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.gists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GistCell *cell = [gistsTable dequeueReusableCellWithIdentifier:@"GistCell"];
    
    if (!cell) {
        cell = [[GistCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GistCell"];
    }
    
    cell.gist = [self.gists objectAtIndex:indexPath.row];
    cell.dateFormatter = self.dateFormatter;
    cell.relativeDateDescriptor = self.relativeDateDescriptor;
    [cell render];
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GistViewController *gistController = [[GistViewController alloc] init];
    gistController.gist = [self.gists objectAtIndex:indexPath.row];
    gistController.user = self.user;
    [self.navigationController pushViewController:gistController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (([scrollView contentOffset].y + scrollView.frame.size.height) == scrollView.contentSize.height) {
        // Bottom of UITableView reached
        [self.spinnerView setHidden:NO];
        [self getUserGists:self.currentPage++];
    }
}

- (void)getUserInfo
{
    
    NSURL *userUrl = [NSURL URLWithString:@"https://api.github.com/user"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:userUrl];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.accessToken, @"access_token",
                                   @"bearer", @"token_type",
                                   nil];
    
    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:userUrl.absoluteString parameters:params];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];
    
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject){
         NSString *response = [operation responseString];
         
         NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
         
         self.user = [[User alloc] initWithOptions:json];
         [self getUserGists:self.currentPage++];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@", error);
     }];
    
    [operation start];
}

- (void)getUserGists:(NSInteger)page
{
    NSURL *gistsUrl = [NSURL URLWithString:self.user.gistsUrl];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:gistsUrl];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%i", page], @"page",
                                   nil];
    
    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:gistsUrl.absoluteString parameters:params];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];
    
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation, id responseObject){
         NSString *response = [operation responseString];
         
         NSArray *gistsArray = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

         Gist *g;

         for (int i=0; i < [gistsArray count]; i++) {
             g = [[Gist alloc] initWithData:[gistsArray objectAtIndex:i]];
             [self.gists addObject:g];
         }

         [gistsTable.pullToRefreshView stopAnimating];
         [gistsTable reloadData];
         [self.spinnerView setHidden:YES];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@", error);
         [self.spinnerView setHidden:YES];
     }];
    
    [operation start];
}

- (void)setupPullToRefresh
{
    self.currentPage = 1;
    [gistsTable addPullToRefreshWithActionHandler:^{
        [self getUserGists:self.currentPage];
    }];
}

@end
