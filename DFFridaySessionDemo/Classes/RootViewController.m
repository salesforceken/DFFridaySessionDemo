/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "RootViewController.h"

#import "SFRestAPI.h"
#import "SFRestRequest.h"
#import "SFOAuthCoordinator.h"

@implementation RootViewController

@synthesize dataRows;

#pragma mark Misc

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    self.dataRows = nil;
    [super dealloc];
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Mobile SDK Sample App";
    //Here we use a query that should work on either Force.com or Database.com
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForResources];
    request.path = [NSString stringWithFormat:@"%@%@", request.path, @"/chatter/feeds/news/me/feed-items"];
    [[SFRestAPI sharedInstance] send:request delegate:self];
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"items"];
    NSLog(@"request:didLoadResponse: #records: %d", records.count);
    self.dataRows = records;
    [self.tableView reloadData];
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    //add your failed error handling here
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    //add your failed error handling here
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    //add your failed error handling here
}

- (void)postOnSocialMedia:(NSString *)tweetText
{
    //self.slVC = [[SLComposeViewController alloc] init];
    if ([tweetText rangeOfString:@"#socialshare-twitter"].location != NSNotFound) {
        self.slVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    }
    else
        self.slVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [self.slVC setInitialText:[NSString stringWithFormat: tweetText, self.slVC.serviceType]];
    [self.slVC addURL:[NSURL URLWithString:@"http://cloudevent.force.com/"]];
    [self presentViewController:self.slVC animated:YES completion:nil];
    
    [self.slVC setCompletionHandler:^(SLComposeViewControllerResult result) {
        
        NSString *output;
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                output = @"ActionCancelled";
                break;
            case SLComposeViewControllerResultDone:
                output = @"Post Successfull";
                break;
            default:
                break;
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share Status" message:output delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *rowDict = [self.dataRows objectAtIndex:indexPath.row];
    NSDictionary *body = [rowDict objectForKey:@"body"];
    NSString *tweetText = [body objectForKey:@"text"];
    
    // check if the text has #socialshare
    if ([tweetText rangeOfString:@"#socialshare"].location == NSNotFound) {
        UIAlertView *alertD = [[UIAlertView alloc] initWithTitle:@"Feed Item not shareable" message:@"Feed Item can't be shared on Twitter" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertD show];
        return;
    }
    
    // see if tweet text is less than 140 chars
    if (tweetText.length > 140) {
        UIAlertView *alertDialog = [[UIAlertView alloc] initWithTitle:@"Character Count Violation" message:@"Number of characters should be less than 140" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertDialog show];
        return;
    }
    
    //[self postOnFacebook:tweetText];
    [self postOnSocialMedia:tweetText];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataRows count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   static NSString *CellIdentifier = @"CellIdentifier";

    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        
    }
	//if you want to add an image to your cell, here's how
	// Configure the cell to show the data.
	NSDictionary *obj = [self.dataRows objectAtIndex:indexPath.row];
    //actor
    NSDictionary *actor = [obj objectForKey:@"actor"];
    //get profile pic
    NSDictionary *photo = [actor objectForKey:@"photo"];
    
    //we need the token to get the profile photos
    NSString *token = [SFRestAPI sharedInstance].coordinator.credentials.accessToken;
    
    NSString *profilePicUrl = [NSString stringWithFormat:@"%@%@%@", [photo objectForKey:@"smallPhotoUrl"], @"?oauth_token=", token];
    NSURL * imageURL = [NSURL URLWithString:profilePicUrl];
    NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
    UIImage *image = [UIImage imageWithData:imageData];
    NSDictionary *body = [obj objectForKey:@"body"];
    
    
    cell.textLabel.text = [actor objectForKey:@"name"];
    cell.detailTextLabel.text = [body objectForKey:@"text"];
    cell.imageView.image = image;
    
    if ([[body objectForKey:@"text"] rangeOfString:@"#socialshare"].location != NSNotFound) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0, 0.0, 44.0, 25.0);
        if([[body objectForKey:@"text"] rangeOfString:@"#socialshare-facebook"].location != NSNotFound)
            [button setImage:[UIImage imageNamed:@"facebook_logo_small"] forState:UIControlStateNormal];
        else if ([[body objectForKey:@"text"] rangeOfString:@"#socialshare-twitter"].location != NSNotFound)
            [button setImage:[UIImage imageNamed:@"twitter_small_logo"] forState:UIControlStateNormal];
        
        cell.accessoryView = button;
    }
    
    return cell;


}
@end
