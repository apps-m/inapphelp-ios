//  HAAttachmentsViewController.m
//
//Copyright (c) 2014 HelpStack (http://helpstack.io)
//
//Permission is hereby granted, free of charge, to any person obtaining a cop
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

#import "IAHAttachmentsViewController.h"
#import "IAHActivityIndicatorView.h"

@interface IAHAttachmentsViewController () <UIWebViewDelegate>

@property (nonatomic, strong) IAHActivityIndicatorView *loadingView;

@end

@implementation IAHAttachmentsViewController

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
    
    self.loadingView = [[IAHActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.loadingView];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    self.loadingView.hidden = YES;
    
    self.webView.delegate = self;
    
    if (_attachment.url) {
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_attachment.url]];
        [request addValue:[NSString stringWithFormat:@"http://%@.inapphelp.com/", [[IAHHelpDesk instance] getCompanyName]] forHTTPHeaderField:@"referer"];
        [self.webView loadRequest:request];
    }
    else {
        [self.webView loadData:_attachment.attachmentData MIMEType:_attachment.mimeType textEncodingName:nil baseURL:nil];
    }
    
    
    
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if(navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return false;
    }
    return true;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;
}

@end
