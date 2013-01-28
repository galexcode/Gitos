//
//  GistViewController.m
//  Gitos
//
//  Created by Tri Vuong on 1/27/13.
//  Copyright (c) 2013 Crafted By Tri. All rights reserved.
//

#import "GistViewController.h"
#import "GistDetailsCell.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "SSKeychain.h"
#import "AppConfig.h"
#import "GistFile.h"

@interface GistViewController ()

@end

@implementation GistViewController

@synthesize gist, user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.accessToken = [SSKeychain passwordForService:@"access_token" account:@"gitos"];
        self.accessTokenParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  self.accessToken, @"access_token",
                                  @"bearer", @"token_type",
                                  nil];
        self.files = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.navigationItem setTitle:[self.gist getName]];
    [self performHouseKeepingTasks];
    [self getGistStats];
}

- (void)performHouseKeepingTasks
{
    UINib *nib = [UINib nibWithNibName:@"GistDetailsCell" bundle:nil];

    NSArray *tables = [[NSArray alloc] initWithObjects:detailsTable, filesTable, nil];

    UITableView *table;

    for (int i=0; i < tables.count; i++) {
        table = [tables objectAtIndex:i];
        [table registerNib:nib forCellReuseIdentifier:@"GistDetailsCell"];
        [table setBackgroundView:nil];
        [table setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [table setSeparatorColor:[UIColor colorWithRed:206/255.0 green:206/255.0 blue:206/255.0 alpha:0.8]];
        [table setScrollEnabled:NO];
    }

    [self.view setBackgroundColor:[UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0]];
}

- (void)getGistStats
{
    NSString *githubApiHost = [AppConfig getConfigValue:@"GithubApiHost"];

    NSURL *gistDetailsUrl = [NSURL URLWithString:[githubApiHost stringByAppendingFormat:@"/gists/%@", [self.gist getId]]];

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:gistDetailsUrl];

    NSMutableURLRequest *getRequest = [httpClient requestWithMethod:@"GET" path:gistDetailsUrl.absoluteString parameters:self.accessTokenParams];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:getRequest];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"getting gist details");
        NSString *response = [operation responseString];

        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

        [self setGistStats:json];
        [detailsTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)setGistStats:(NSDictionary *)stats
{
    self.gist.details = [[NSDictionary alloc] initWithDictionary:stats];

    NSDictionary *gistFiles = [self.gist getFiles];

    for (NSString *key in [gistFiles allKeys]) {
        NSLog(@"%@", key);
        [self.files addObject:[[GistFile alloc] initWithData:[gistFiles valueForKey:key]]];
    }
    [filesTable reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == detailsTable) {
        return 3;
    } else {
        return [self.files count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == detailsTable) {
        static NSString *cellIdentifier = @"GistDetailsCell";
        GistDetailsCell *cell = [detailsTable dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[GistDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell setGist:self.gist];
        [cell renderForIndexPath:indexPath];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else {
        UITableViewCell *cell = [filesTable dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        GistFile *file = [self.files objectAtIndex:indexPath.row];
        cell.textLabel.text = [file getName];
        cell.textLabel.font = [UIFont fontWithName:@"Arial" size:12.0];

        return cell;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
