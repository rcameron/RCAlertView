//
// RCAlertView.m
//
// Copyright (c) 2013 Rich Cameron (github.com/rcameron)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "RCAlertView.h"
#import "RCAlertDialogView.h"

static CGFloat const kAlertViewMinimumHeight  = 130.f;
static CGFloat const kAlertViewButtonHeight = 44.f;
static CGFloat const kAlertViewPadding = 22.f;

@interface RCAlertView ()
<UIGestureRecognizerDelegate>

@end

@implementation RCAlertView
{
  RCAlertDialogView    *_dialogView;
  MPMoviePlayerController *_moviePlayerController;
  UIActivityIndicatorView *_movieActivityIndicator;
  
  void (^_confirmBlock)(void);
  void (^_cancelBlock)(void);
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Init
////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
              image:(UIImage *)image
         contentURL:(NSURL *)contentURL
 confirmButtonTitle:(NSString *)confirmButtonTitle
            confirm:(void (^)(void))confirmBlock
  cancelButtonTitle:(NSString *)cancelButtonTitle
             cancel:(void (^)(void))cancelBlock
    showImmediately:(BOOL)showImmediately
{
  // Make sure we have something to show
  if (!title && !message && !contentURL) return nil;
  
  self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
  
  if (!self) return nil;
  
  BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
  
  // Figure out our width
  CGFloat alertViewFrameWidth = isPad ? 400.f : 300.f;
  
  // If we have a good image, re-size our alert view to fit it
  // Doing this here so that everything is centered properly based on the actual width
  if (image && ( image.size.width + (kAlertViewPadding * 2) <= isPad ? 768.f : 320.f)) {
    alertViewFrameWidth = MAX(alertViewFrameWidth, image.size.width + (kAlertViewPadding * 2));
  }
  
  // Style view
  [self setOpaque:NO];
  [self setAlpha:0.0f];
  [self setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.7f]];
  
  // Make the background tappable
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(dismiss)];
  
  [tapRecognizer setDelegate:self];
  [self addGestureRecognizer:tapRecognizer];
  
  
  // Create dialog view
  _dialogView = [[RCAlertDialogView alloc] initWithFrame:CGRectZero];
  
  CGFloat currentY = kAlertViewPadding;
  
  /*******************
   * Add video
   * If we have a video, we're not adding anything else. So, shut it down!
   * TODO: Add video support for iPhone
   *******************/
  if (contentURL && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // frame sizes for video content
    alertViewFrameWidth = 644.f;
    CGFloat alertViewFrameHeight = 381.5; // based on 16:9 ratio + padding
    
    
    // Configure the view now because we won't be adding anything else
    [_dialogView setFrame:CGRectMake(0.f, 0.f,
                                     alertViewFrameWidth,
                                     alertViewFrameHeight)];
    
    [_dialogView setCenter:CGPointMake(CGRectGetWidth(self.frame) * 0.5f,
                                       CGRectGetHeight(self.frame) * 1.5f)];
    
    
    [self addSubview:_dialogView];
    
    
    _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
    [_moviePlayerController setControlStyle:MPMovieControlStyleNone];
    
    [_moviePlayerController.view setFrame:CGRectMake(0.f, 0.f,
                                                     alertViewFrameWidth - (2*kAlertViewPadding),
                                                     alertViewFrameHeight - (2*kAlertViewPadding))];
    [_moviePlayerController.view setCenter:CGPointMake(alertViewFrameWidth*0.5f, _dialogView.frame.size.height*0.5f)];
    [_dialogView addSubview:_moviePlayerController.view];
    
    _movieActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_movieActivityIndicator setHidesWhenStopped:YES];
    [_movieActivityIndicator startAnimating];
    [_movieActivityIndicator setCenter:CGPointMake(alertViewFrameWidth*0.5f, _dialogView.frame.size.height*0.5f)];
    [_dialogView addSubview:_movieActivityIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismiss)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMoviePlayerPlaybackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    [_moviePlayerController prepareToPlay];
    
    
    if (showImmediately)
      [self show];
    
    return self; // skip everything else
  }
  
  /*******************
   // Add title
   *******************/
  if (title) {
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setText:title];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:24.f]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel sizeToFit];
    [titleLabel setFrame:CGRectMake(kAlertViewPadding,
                                    currentY,
                                    alertViewFrameWidth - (2*kAlertViewPadding),
                                    CGRectGetHeight(titleLabel.frame))];
    [_dialogView addSubview:titleLabel];
    
    currentY += kAlertViewPadding + CGRectGetHeight(titleLabel.frame);
  }
  
  /*******************
   // Add Image
   *******************/
  // Add image if it isnt too big
  if (image &&
     (image.size.width + (kAlertViewPadding * 2) <= isPad ? 768.f : 320.f)) {
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    [imageView setCenter:CGPointMake(alertViewFrameWidth * 0.5f, currentY + (image.size.height * 0.5f))];
    
    [_dialogView addSubview:imageView];
    
    currentY += image.size.height + kAlertViewPadding;
  }
  
  /*******************
   // Add Message
   *******************/
  if (message) {
    CGSize labelSize = [message sizeWithFont:[UIFont systemFontOfSize:17]
                           constrainedToSize:CGSizeMake(alertViewFrameWidth - (2*kAlertViewPadding), CGFLOAT_MAX)
                               lineBreakMode:NSLineBreakByWordWrapping];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewPadding,
                                                                      currentY,
                                                                      alertViewFrameWidth - (2*kAlertViewPadding),
                                                                      labelSize.height)];
    [messageLabel setNumberOfLines:0];
    [messageLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [messageLabel setText:message];
    [messageLabel setBackgroundColor:[UIColor clearColor]];
    [messageLabel setTextColor:[UIColor whiteColor]];
    [messageLabel setTextAlignment:NSTextAlignmentCenter];
    
    [_dialogView addSubview:messageLabel];
    
    currentY += kAlertViewPadding + labelSize.height;
  }
  
  
  /*******************
   // Dialog view size and style
   *******************/
  CGFloat calculatedHeight = currentY + kAlertViewButtonHeight + kAlertViewPadding;
  
  calculatedHeight = MAX(calculatedHeight, kAlertViewMinimumHeight);
  
  [self updateOrientation:nil];
  
  [_dialogView setFrame:CGRectMake(0.f, 0.f,
                                   alertViewFrameWidth,
                                   calculatedHeight)];
  
  [_dialogView setCenter:CGPointMake(CGRectGetWidth(self.bounds) * 0.5f,
                                     CGRectGetHeight(self.bounds) * 1.5f)];
  
  
  [self addSubview:_dialogView];
  
  /*******************
   // Add buttons
   *******************/
  // If no button titles are set, set one
  if (!confirmButtonTitle && !cancelButtonTitle)
    cancelButtonTitle = @"OK";
  
  currentY = CGRectGetHeight(_dialogView.bounds) - 36.f - kAlertViewPadding;
  
  CGFloat buttonWidth = alertViewFrameWidth * 0.66f;
  CGFloat currentX = (CGRectGetWidth(_dialogView.frame) * 0.5f) - (buttonWidth * 0.5f);
  
  // If we have two buttons, re-calculate!
  if (confirmButtonTitle && cancelButtonTitle) {
    buttonWidth = (alertViewFrameWidth * 0.5f) - (3 * kAlertViewPadding) + 8;
    currentX = 2 * kAlertViewPadding - 8;
  }
  
  
  // Cancel button
  if (cancelButtonTitle) {
    _cancelBlock = [cancelBlock copy];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton.layer setCornerRadius:4.f];
    [cancelButton.layer setMasksToBounds:YES];
    [cancelButton.layer setBorderWidth:1.f];
    [cancelButton.layer setBorderColor:[UIColor colorWithRed:44.f/255.f green:45.f/255.f blue:50.f/255.f alpha:1.0f].CGColor];
    
    UIImage *image = [UIImage imageNamed:@"button"];
    UIImage *imagePressed = [UIImage imageNamed:@"button_pressed"];
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 5, 0, 5);
    
    [cancelButton setBackgroundImage:[image resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[imagePressed resizableImageWithCapInsets:insets] forState:UIControlStateHighlighted];
    [cancelButton setAdjustsImageWhenHighlighted:YES];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [cancelButton setFrame:CGRectMake(currentX, currentY, buttonWidth, 43.f)];
    
    [cancelButton addTarget:self
                     action:@selector(tappedCancel)
           forControlEvents:UIControlEventTouchUpInside];
    
    [_dialogView addSubview:cancelButton];
    
    currentX += buttonWidth + (2 * kAlertViewPadding);
  }
  
  // Confirm button
  if (confirmButtonTitle) {
    _confirmBlock = [confirmBlock copy];
    
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmButton.layer setCornerRadius:4.f];
    [confirmButton.layer setMasksToBounds:YES];
    [confirmButton.layer setBorderWidth:1.f];
    [confirmButton.layer setBorderColor:[UIColor colorWithRed:44.f/255.f green:45.f/255.f blue:50.f/255.f alpha:1.0f].CGColor];
    
    UIImage *image = [UIImage imageNamed:@"button"];
    UIImage *imagePressed = [UIImage imageNamed:@"button_pressed"];
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 5, 0, 5);
    
    [confirmButton setBackgroundImage:[image resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    [confirmButton setBackgroundImage:[imagePressed resizableImageWithCapInsets:insets] forState:UIControlStateHighlighted];
    [confirmButton setAdjustsImageWhenHighlighted:YES];
    [confirmButton setTitle:confirmButtonTitle forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [confirmButton setFrame:CGRectMake(currentX, currentY, buttonWidth, 43.f)];
    
    [confirmButton addTarget:self
                      action:@selector(tappedConfirm)
            forControlEvents:UIControlEventTouchUpInside];
    
    [_dialogView addSubview:confirmButton];
  }
  
  if (showImmediately)
    [self show];
  
  return self;
}

////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
              image:(UIImage *)image
 confirmButtonTitle:(NSString *)confirmButtonTitle
            confirm:(void (^)(void))confirmBlock
  cancelButtonTitle:(NSString *)cancelButtonTitle
             cancel:(void (^)(void))cancelBlock
    showImmediately:(BOOL)showImmediately
{
  return [self initWithTitle:title
                     message:message
                       image:image
                  contentURL:nil
          confirmButtonTitle:confirmButtonTitle
                     confirm:confirmBlock
           cancelButtonTitle:cancelButtonTitle
                      cancel:cancelBlock
             showImmediately:showImmediately];
}

////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
 confirmButtonTitle:(NSString *)confirmButtonTitle
            confirm:(void (^)(void))confirmBlock
  cancelButtonTitle:(NSString *)cancelButtonTitle
             cancel:(void (^)(void))cancelBlock
    showImmediately:(BOOL)showImmediately
{
  return [self initWithTitle:title
                     message:message
                       image:nil
          confirmButtonTitle:confirmButtonTitle
                     confirm:confirmBlock
           cancelButtonTitle:cancelButtonTitle
                      cancel:cancelBlock
             showImmediately:showImmediately];
}

////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
 confirmButtonTitle:(NSString *)confirmButtonTitle
            confirm:(void (^)(void))confirmBlock
  cancelButtonTitle:(NSString *)cancelButtonTitle
             cancel:(void (^)(void))cancelBlock
{
  return [self initWithTitle:title
                     message:message
                       image:nil
          confirmButtonTitle:confirmButtonTitle
                     confirm:confirmBlock
           cancelButtonTitle:cancelButtonTitle
                      cancel:cancelBlock
             showImmediately:NO];
}

////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
{
  return [self initWithTitle:title
                     message:message
                       image:nil
          confirmButtonTitle:nil
                     confirm:nil
           cancelButtonTitle:nil
                      cancel:nil
             showImmediately:NO];
}

////////////////////////////////////////////////////////
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
              image:(UIImage *)image
{
  return [self initWithTitle:title
                     message:message
                       image:image
          confirmButtonTitle:nil
                     confirm:nil
           cancelButtonTitle:nil
                      cancel:nil
             showImmediately:NO];
}

////////////////////////////////////////////////////////
- (id)initWithContentURL:(NSURL *)contentURL showImmediately:(BOOL)showImmediately
{
  return [self initWithTitle:nil
                     message:nil
                       image:nil
                  contentURL:contentURL
          confirmButtonTitle:nil
                     confirm:nil
           cancelButtonTitle:nil
                      cancel:nil
             showImmediately:showImmediately];
}

////////////////////////////////////////////////////////
- (id)initWithContentURL:(NSURL *)contentURL
{
  return [self initWithContentURL:contentURL showImmediately:NO];
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Show
////////////////////////////////////////////////////////
+ (RCAlertView*)showWithTitle:(NSString *)title
                       message:(NSString *)message
            confirmButtonTitle:(NSString *)confirmButtonTitle
                       confirm:(void (^)(void))confirmBlock
             cancelButtonTitle:(NSString *)cancelButtonTitle
                        cancel:(void (^)(void))cancelBlock
{
  return [[[self class] alloc] initWithTitle:title
                                     message:message
                          confirmButtonTitle:confirmButtonTitle
                                     confirm:confirmBlock
                           cancelButtonTitle:cancelButtonTitle
                                      cancel:cancelBlock
                             showImmediately:YES];
}

////////////////////////////////////////////////////////
+ (RCAlertView*)showWithTitle:(NSString *)title
                       message:(NSString *)message
                         image:(UIImage *)image
            confirmButtonTitle:(NSString *)confirmButtonTitle
                       confirm:(void (^)(void))confirmBlock
             cancelButtonTitle:(NSString *)cancelButtonTitle
                        cancel:(void (^)(void))cancelBlock
{
  return [[[self class] alloc] initWithTitle:title
                                     message:message
                                       image:image
                          confirmButtonTitle:confirmButtonTitle
                                     confirm:confirmBlock
                           cancelButtonTitle:cancelButtonTitle
                                      cancel:cancelBlock
                             showImmediately:YES];
}

////////////////////////////////////////////////////////
+ (RCAlertView *)showWithContentURL:(NSURL *)contentURL
{
  return [[[self class] alloc] initWithContentURL:contentURL showImmediately:YES];
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - UI
////////////////////////////////////////////////////////
- (void)show
{
  // Add view to main window
  [[[UIApplication sharedApplication] keyWindow] addSubview:self];
  
  [self updateOrientation:nil];
  
  // Make sure we rotate when the device rotates
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
  
  [UIView animateWithDuration:0.2f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     [self setAlpha:1.0f];
                   }
                   completion:^(BOOL finished) {
                     // Animate in the dialog view
                     [UIView animateWithDuration:0.3f
                                           delay:0.1f
                                         options:UIViewAnimationOptionCurveEaseOut
                                      animations:^{
                                        [_dialogView setCenter:CGPointMake(CGRectGetWidth(self.bounds) * 0.5f,
                                                                           CGRectGetHeight(self.bounds) * 0.5f)];
                                      }
                                      completion:^(BOOL finished) {
                                        // If we have a video in the alert view, play it
                                        if (_moviePlayerController)
                                          [_moviePlayerController play];
                                      }];
                   }];
}

- (void)dismiss
{
  [self dismissWithBlock:nil];
}

////////////////////////////////////////////////////////
- (void)dismissWithBlock:(void(^)(void))block
{
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseIn
                   animations:^{
                     [_dialogView setCenter:CGPointMake(CGRectGetWidth(self.bounds) * 0.5f,
                                                        CGRectGetHeight(self.bounds) * 1.5f)];
                   }
                   completion:^(BOOL finished) {
                     [UIView animateWithDuration:0.2f
                                      animations:^{
                                        [self setAlpha:0.0f];
                                      }
                                      completion:^(BOOL finished) {
                                        // Shut down movie player
                                        [_moviePlayerController stop];
                                        _moviePlayerController = nil;
                                        [_movieActivityIndicator stopAnimating];
                                        
                                        // Stop listening for notifications
                                        [[NSNotificationCenter defaultCenter] removeObserver:self];
                                        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
                                        
                                        [self removeFromSuperview]; // remove ourselves
                                        
                                        if( block ) block(); // run
                                      }];
                   }];
}

////////////////////////////////////////////////////////
- (void)tappedConfirm
{
  [self dismissWithBlock:_confirmBlock];
}

////////////////////////////////////////////////////////
- (void)tappedCancel
{
  
  [self dismissWithBlock:_cancelBlock];
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Video state handling
////////////////////////////////////////////////////////
- (void)handleMoviePlayerPlaybackStateDidChangeNotification:(NSNotification *)notification
{
  MPMoviePlaybackState state = [_moviePlayerController playbackState];
  
  if (state & MPMoviePlaybackStatePlaying)
    [_movieActivityIndicator stopAnimating];
  else
    [_movieActivityIndicator startAnimating];
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizer Delegate
////////////////////////////////////////////////////////
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if ([touch.view isDescendantOfView:_dialogView])
    return NO;
  else
    return YES;
}

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
#pragma mark - Rotation
////////////////////////////////////////////////////////
- (void)updateOrientation:(NSNotification *)notification
{
  UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
  
  [UIView animateWithDuration:0.3f
                   animations:^{
                    
                     if (currentOrientation == UIDeviceOrientationPortraitUpsideDown)
                       [_dialogView setTransform:CGAffineTransformMakeRotation(M_PI)];
                     
                     else if (currentOrientation == UIDeviceOrientationPortrait)
                       [_dialogView setTransform:CGAffineTransformIdentity];
                    
                     else if (currentOrientation == UIDeviceOrientationLandscapeLeft)
                       [_dialogView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
                    
                     else if (currentOrientation == UIDeviceOrientationLandscapeRight)
                       [_dialogView setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
                    
                     
                   }];
}

////////////////////////////////////////////////////////
@end