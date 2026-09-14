#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - Configuration

static CGFloat const SC16_SCALE = 0.96;
static CGFloat const SC16_CROP = 34.0;
static NSInteger const SC16_TAG = 0x5316;


#pragma mark - Process

static BOOL SC16Enabled(void)
{
    NSString *version = UIDevice.currentDevice.systemVersion;

    if (!version)
        return NO;

    return [version hasPrefix:@"16."];
}

static BOOL SC16IsSpringBoard(void)
{
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;

    return [bundleID isEqualToString:@"com.apple.springboard"];
}


#pragma mark - Window Detection

static BOOL SC16IsKeyboardWindow(UIWindow *window)
{
    if (!window)
        return YES;

    NSString *name = NSStringFromClass(window.class);

    if ([name containsString:@"Keyboard"])
        return YES;

    if ([name containsString:@"UITextEffects"])
        return YES;

    if ([name containsString:@"UIRemoteKeyboard"])
        return YES;

    if ([name containsString:@"UIInput"])
        return YES;

    return NO;
}


static BOOL SC16IsUnsafeWindow(UIWindow *window)
{
    if (!window)
        return YES;

    NSString *name = NSStringFromClass(window.class);

    if ([name containsString:@"Keyboard"])
        return YES;

    if ([name containsString:@"UITextEffects"])
        return YES;

    if ([name containsString:@"UIRemoteKeyboard"])
        return YES;

    if ([name containsString:@"UIInput"])
        return YES;

    if ([name containsString:@"SystemGesture"])
        return YES;

    if ([name containsString:@"GestureWindow"])
        return YES;

    return NO;
}


static BOOL SC16IsRootSceneWindow(UIWindow *window)
{
    if (!window)
        return NO;

    NSString *name = NSStringFromClass(window.class);

    return [name isEqualToString:@"UIRootSceneWindow"];
}


static BOOL SC16IsFullDisplayWindow(UIWindow *window)
{
    if (!window)
        return NO;

    CGRect bounds = window.bounds;

    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    if (width <= 0.0 || height <= 0.0)
        return NO;

    CGRect screenBounds = UIScreen.mainScreen.bounds;

    CGFloat screenWidth = CGRectGetWidth(screenBounds);
    CGFloat screenHeight = CGRectGetHeight(screenBounds);

    CGFloat shortSide = MIN(screenWidth, screenHeight);
    CGFloat longSide = MAX(screenWidth, screenHeight);

    CGFloat minShort = shortSide * 0.88;
    CGFloat minLong = longSide * 0.88;

    if (width >= minShort && height >= minLong)
        return YES;

    if (height >= minShort && width >= minLong)
        return YES;

    return NO;
}


#pragma mark - Root View

static UIView *SC16RootViewForWindow(UIWindow *window)
{
    if (!window)
        return nil;

    UIViewController *root =
        window.rootViewController;

    if (!root)
        return nil;

    UIView *view = root.view;

    if (!view)
        return nil;

    return view;
}


#pragma mark - Scale

static void SC16ApplyScale(UIView *view)
{
    if (!view)
        return;

    CGRect bounds = view.bounds;

    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    if (width <= 0.0 || height <= 0.0)
        return;

    CGAffineTransform target =
        CGAffineTransformMakeScale(
            SC16_SCALE,
            SC16_SCALE
        );

    if (!CGAffineTransformEqualToTransform(
            view.transform,
            target))
    {
        view.transform = target;
    }
}


#pragma mark - Crop

static UIView *SC16FindCropOverlay(UIWindow *window)
{
    if (!window)
        return nil;

    for (UIView *subview in window.subviews)
    {
        if (subview.tag == SC16_TAG)
            return subview;
    }

    return nil;
}


static void SC16ApplyCrop(UIWindow *window)
{
    if (!window)
        return;

    if (SC16IsKeyboardWindow(window))
        return;

    CGRect bounds = window.bounds;

    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    if (width <= 0.0 || height <= 0.0)
        return;

    UIView *overlay =
        SC16FindCropOverlay(window);

    if (!overlay)
    {
        overlay =
            [[UIView alloc] initWithFrame:CGRectZero];

        overlay.tag = SC16_TAG;

        overlay.userInteractionEnabled = NO;

        overlay.backgroundColor =
            UIColor.clearColor;

        overlay.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;

        [window addSubview:overlay];
    }

    [window bringSubviewToFront:overlay];

    overlay.frame = bounds;

    BOOL portrait = height >= width;

    UIView *first = nil;
    UIView *second = nil;

    for (UIView *subview in overlay.subviews)
    {
        if (subview.tag == SC16_TAG + 1)
            first = subview;

        else if (subview.tag == SC16_TAG + 2)
            second = subview;
    }

    if (!first)
    {
        first =
            [[UIView alloc] initWithFrame:CGRectZero];

        first.tag = SC16_TAG + 1;

        first.backgroundColor =
            UIColor.blackColor;

        first.userInteractionEnabled = NO;

        [overlay addSubview:first];
    }

    if (!second)
    {
        second =
            [[UIView alloc] initWithFrame:CGRectZero];

        second.tag = SC16_TAG + 2;

        second.backgroundColor =
            UIColor.blackColor;

        second.userInteractionEnabled = NO;

        [overlay addSubview:second];
    }

    CGRect firstFrame;
    CGRect secondFrame;

    if (portrait)
    {
        firstFrame =
            CGRectMake(
                0.0,
                0.0,
                width,
                SC16_CROP
            );

        secondFrame =
            CGRectMake(
                0.0,
                height - SC16_CROP,
                width,
                SC16_CROP
            );
    }
    else
    {
        firstFrame =
            CGRectMake(
                0.0,
                0.0,
                SC16_CROP,
                height
            );

        secondFrame =
            CGRectMake(
                width - SC16_CROP,
                0.0,
                SC16_CROP,
                height
            );
    }

    first.frame = firstFrame;
    second.frame = secondFrame;

    [overlay bringSubviewToFront:first];
    [overlay bringSubviewToFront:second];
}


#pragma mark - Window Apply

static void SC16ApplyWindow(UIWindow *window)
{
    if (!window)
        return;

    if (window.hidden)
        return;

    if (window.alpha <= 0.0)
        return;

    if (SC16IsUnsafeWindow(window))
        return;

    UIView *rootView =
        SC16RootViewForWindow(window);

    if (!rootView)
        return;

    SC16ApplyScale(rootView);

    if (SC16IsRootSceneWindow(window) ||
        SC16IsFullDisplayWindow(window))
    {
        SC16ApplyCrop(window);
    }
}


static void SC16ApplyScaleOnlyWindow(UIWindow *window)
{
    if (!window)
        return;

    if (window.hidden)
        return;

    if (window.alpha <= 0.0)
        return;

    if (SC16IsUnsafeWindow(window))
        return;

    UIView *rootView =
        SC16RootViewForWindow(window);

    if (!rootView)
        return;

    SC16ApplyScale(rootView);
}


#pragma mark - Application Window

static UIWindow *SC16FindApplicationWindow(
    UIWindowScene *scene
)
{
    if (!scene)
        return nil;

    UIWindow *fallback = nil;

    for (UIWindow *window in scene.windows)
    {
        if (!window)
            continue;

        if (window.hidden)
            continue;

        if (window.alpha <= 0.0)
            continue;

        if (SC16IsUnsafeWindow(window))
            continue;

        if (!window.rootViewController)
            continue;

        if (window.isKeyWindow)
            return window;

        if (!fallback)
            fallback = window;
    }

    return fallback;
}


#pragma mark - Largest SpringBoard Window

static UIWindow *SC16FindLargestDisplayWindow(
    NSArray<UIWindow *> *windows
)
{
    UIWindow *best = nil;

    CGFloat bestArea = 0.0;

    for (UIWindow *window in windows)
    {
        if (!window)
            continue;

        if (window.hidden)
            continue;

        if (window.alpha <= 0.0)
            continue;

        if (SC16IsUnsafeWindow(window))
            continue;

        CGRect bounds = window.bounds;

        CGFloat width =
            CGRectGetWidth(bounds);

        CGFloat height =
            CGRectGetHeight(bounds);

        if (width <= 0.0 || height <= 0.0)
            continue;

        CGFloat area = width * height;

        if (!best || area > bestArea)
        {
            best = window;
            bestArea = area;
        }
    }

    return best;
}


#pragma mark - Apply All

static void SC16ApplyAll(void)
{
    if (!SC16Enabled())
        return;

    UIApplication *application =
        UIApplication.sharedApplication;

    if (!application)
        return;


    /*
     * ==========================================================
     * SPRINGBOARD
     * ==========================================================
     */
    if (SC16IsSpringBoard())
    {
        UIWindow *displayWindow = nil;


        /*
         * First:
         * Find UIRootSceneWindow.
         */
        for (UIScene *scene
             in application.connectedScenes)
        {
            if (![scene
                  isKindOfClass:[UIWindowScene class]])
            {
                continue;
            }

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            if (windowScene.activationState ==
                UISceneActivationStateUnattached)
            {
                continue;
            }

            for (UIWindow *window
                 in windowScene.windows)
            {
                if (!window)
                    continue;

                if (window.hidden)
                    continue;

                if (window.alpha <= 0.0)
                    continue;

                if (SC16IsUnsafeWindow(window))
                    continue;

                if (SC16IsRootSceneWindow(window))
                {
                    displayWindow = window;
                    break;
                }
            }

            if (displayWindow)
                break;
        }


        /*
         * Fallback:
         * choose largest visible window.
         */
        if (!displayWindow)
        {
            for (UIScene *scene
                 in application.connectedScenes)
            {
                if (![scene
                      isKindOfClass:[UIWindowScene class]])
                {
                    continue;
                }

                UIWindowScene *windowScene =
                    (UIWindowScene *)scene;

                if (windowScene.activationState ==
                    UISceneActivationStateUnattached)
                {
                    continue;
                }

                UIWindow *candidate =
                    SC16FindLargestDisplayWindow(
                        windowScene.windows
                    );

                if (!candidate)
                    continue;

                if (!displayWindow)
                {
                    displayWindow = candidate;
                    continue;
                }

                CGFloat oldArea =
                    CGRectGetWidth(
                        displayWindow.bounds
                    ) *
                    CGRectGetHeight(
                        displayWindow.bounds
                    );

                CGFloat newArea =
                    CGRectGetWidth(
                        candidate.bounds
                    ) *
                    CGRectGetHeight(
                        candidate.bounds
                    );

                if (newArea > oldArea)
                    displayWindow = candidate;
            }
        }


        /*
         * ======================================================
         * Apply to SpringBoard windows.
         *
         * Main display:
         *     96% + crop
         *
         * Other visible SB windows:
         *     96%
         *
         * This includes Status Bar windows.
         * ======================================================
         */
        for (UIScene *scene
             in application.connectedScenes)
        {
            if (![scene
                  isKindOfClass:[UIWindowScene class]])
            {
                continue;
            }

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            /*
             * IMPORTANT:
             *
             * Never touch unattached scenes.
             */
            if (windowScene.activationState ==
                UISceneActivationStateUnattached)
            {
                continue;
            }

            for (UIWindow *window
                 in windowScene.windows)
            {
                if (!window)
                    continue;

                if (window.hidden)
                    continue;

                if (window.alpha <= 0.0)
                    continue;

                /*
                 * Keyboard is never touched.
                 */
                if (SC16IsKeyboardWindow(window))
                    continue;

                /*
                 * Other unsafe windows are ignored.
                 */
                if (SC16IsUnsafeWindow(window))
                    continue;

                /*
                 * We need a root VC.
                 */
                if (!window.rootViewController)
                    continue;


                /*
                 * Main SpringBoard display.
                 */
                if (window == displayWindow)
                {
                    SC16ApplyWindow(window);
                    continue;
                }


                /*
                 * Other SpringBoard windows.
                 *
                 * This is intentionally scale-only.
                 *
                 * No crop is placed over Status Bar,
                 * Lock Screen auxiliary windows, etc.
                 */
                SC16ApplyScaleOnlyWindow(window);
            }
        }

        return;
    }


    /*
     * ==========================================================
     * NORMAL APPLICATIONS
     * ==========================================================
     */
    for (UIScene *scene
         in application.connectedScenes)
    {
        if (![scene
              isKindOfClass:[UIWindowScene class]])
        {
            continue;
        }

        UIWindowScene *windowScene =
            (UIWindowScene *)scene;

        if (windowScene.activationState ==
            UISceneActivationStateUnattached)
        {
            continue;
        }

        UIWindow *window =
            SC16FindApplicationWindow(
                windowScene
            );

        if (window)
        {
            SC16ApplyWindow(window);
        }
    }
}


#pragma mark - Scheduling

static void SC16ScheduleApply(void)
{
    if (!SC16Enabled())
        return;

    static BOOL scheduled = NO;

    if (scheduled)
        return;

    scheduled = YES;

    dispatch_async(
        dispatch_get_main_queue(),
        ^{
            scheduled = NO;

            SC16ApplyAll();
        }
    );
}


static void SC16ScheduleApplyAfter(
    NSTimeInterval delay
)
{
    if (!SC16Enabled())
        return;

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(
                delay * NSEC_PER_SEC
            )
        ),
        dispatch_get_main_queue(),
        ^{
            SC16ApplyAll();
        }
    );
}


#pragma mark - UIWindow Hooks

%hook UIWindow


- (void)makeKeyAndVisible
{
    %orig;

    SC16ScheduleApply();

    SC16ScheduleApplyAfter(0.10);

    SC16ScheduleApplyAfter(0.25);
}


- (void)setRootViewController:
    (UIViewController *)rootViewController
{
    %orig(rootViewController);

    SC16ScheduleApply();

    SC16ScheduleApplyAfter(0.10);

    SC16ScheduleApplyAfter(0.25);
}


- (void)setHidden:(BOOL)hidden
{
    %orig(hidden);

    if (!hidden)
    {
        SC16ScheduleApply();

        SC16ScheduleApplyAfter(0.10);
    }
}


- (void)didMoveToWindow
{
    %orig;

    if (SC16Enabled())
    {
        SC16ScheduleApply();

        SC16ScheduleApplyAfter(0.05);
    }
}


%end


#pragma mark - UIViewController Hooks

%hook UIViewController


- (void)viewDidAppear:(BOOL)animated
{
    %orig(animated);

    if (SC16Enabled())
    {
        SC16ScheduleApply();

        SC16ScheduleApplyAfter(0.05);

        SC16ScheduleApplyAfter(0.15);
    }
}


- (void)viewDidLayoutSubviews
{
    %orig;

    if (!SC16Enabled())
        return;

    UIWindow *window =
        self.view.window;

    if (!window)
        return;

    /*
     * Only root controller.
     */
    if (window.rootViewController != self)
        return;

    if (SC16IsUnsafeWindow(window))
        return;

    if (SC16IsKeyboardWindow(window))
        return;

    UIView *view = self.view;

    if (!view)
        return;

    CGAffineTransform target =
        CGAffineTransformMakeScale(
            SC16_SCALE,
            SC16_SCALE
        );

    if (!CGAffineTransformEqualToTransform(
            view.transform,
            target))
    {
        SC16ApplyScale(view);
    }

    if (SC16IsRootSceneWindow(window) ||
        SC16IsFullDisplayWindow(window))
    {
        SC16ApplyCrop(window);
    }
}


- (void)viewWillTransitionToSize:
    (CGSize)size
    withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator
{
    %orig(
        size,
        coordinator
    );

    if (!SC16Enabled())
        return;

    SC16ScheduleApply();

    [coordinator
        animateAlongsideTransition:nil
        completion:
        ^(id<UIViewControllerTransitionCoordinatorContext> context)
        {
            SC16ScheduleApply();

            SC16ScheduleApplyAfter(0.10);
        }
    ];
}


%end


#pragma mark - Constructor

%ctor
{
    @autoreleasepool
    {
        if (!SC16Enabled())
            return;


        /*
         * Initial pass.
         */
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(
                    0.50 * NSEC_PER_SEC
                )
            ),
            dispatch_get_main_queue(),
            ^{
                SC16ApplyAll();
            }
        );


        /*
         * Second pass.
         */
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(
                    1.50 * NSEC_PER_SEC
                )
            ),
            dispatch_get_main_queue(),
            ^{
                SC16ApplyAll();
            }
        );


        /*
         * Third pass.
         */
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(
                    3.00 * NSEC_PER_SEC
                )
            ),
            dispatch_get_main_queue(),
            ^{
                SC16ApplyAll();
            }
        );
    }
}
