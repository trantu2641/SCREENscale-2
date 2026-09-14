#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - Configuration

/*
 * 96% scale
 */
static CGFloat const SC16_SCALE = 0.96;

/*
 * Crop:
 * Portrait  = 34pt top + 34pt bottom
 * Landscape = 34pt left + 34pt right
 */
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

/*
 * Keyboard / text input windows must never be scaled.
 */
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


/*
 * These are windows which are dangerous to transform.
 *
 * NOTE:
 * StatusBar is deliberately NOT excluded.
 *
 * We need StatusBar to participate in the scale.
 */
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

    /*
     * System gesture windows should not be transformed.
     */
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


static BOOL SC16IsStatusBarWindow(UIWindow *window)
{
    if (!window)
        return NO;

    NSString *name = NSStringFromClass(window.class);

    return [name containsString:@"StatusBar"] ||
           [name containsString:@"_UIStatusBar"];
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
    CGFloat longSide  = MAX(screenWidth, screenHeight);

    CGFloat minShort = shortSide * 0.88;
    CGFloat minLong  = longSide * 0.88;

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

    UIViewController *root = window.rootViewController;

    if (!root)
        return nil;

    UIView *view = root.view;

    if (!view)
        return nil;

    return view;
}


#pragma mark - Scale

/*
 * Scale ONLY.
 *
 * Không thay:
 * - frame
 * - bounds
 * - center
 *
 * Không dùng UIWindow.layer.transform.
 */
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

    if (!CGAffineTransformEqualToTransform(view.transform, target))
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

    UIView *overlay = SC16FindCropOverlay(window);

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

    /*
     * Make sure crop stays above the scaled root view.
     */
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
                CGRectGetMinX(bounds),
                CGRectGetMinY(bounds),
                width,
                SC16_CROP
            );

        secondFrame =
            CGRectMake(
                CGRectGetMinX(bounds),
                CGRectGetMaxY(bounds) - SC16_CROP,
                width,
                SC16_CROP
            );
    }
    else
    {
        firstFrame =
            CGRectMake(
                CGRectGetMinX(bounds),
                CGRectGetMinY(bounds),
                SC16_CROP,
                height
            );

        secondFrame =
            CGRectMake(
                CGRectGetMaxX(bounds) - SC16_CROP,
                CGRectGetMinY(bounds),
                SC16_CROP,
                height
            );
    }

    first.frame = firstFrame;
    second.frame = secondFrame;

    [overlay bringSubviewToFront:first];
    [overlay bringSubviewToFront:second];
}


#pragma mark - Apply One Window

/*
 * Normal window:
 * scale root view
 * crop window
 */
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

    /*
     * Crop is applied only to windows which are
     * actually large enough to represent a display.
     *
     * Small system panels are scaled but not cropped.
     */
    if (SC16IsRootSceneWindow(window) ||
        SC16IsFullDisplayWindow(window))
    {
        SC16ApplyCrop(window);
    }
}


/*
 * Scale-only version.
 *
 * Used for:
 * - Status Bar
 * - Lock Screen auxiliary windows
 * - Notification Center auxiliary windows
 * - App Library auxiliary windows
 * - other SpringBoard UI windows
 */
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


#pragma mark - Find Application Window

static UIWindow *SC16FindApplicationWindow(UIWindowScene *scene)
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

        /*
         * Prefer the key window.
         */
        if (window.isKeyWindow)
            return window;

        /*
         * Otherwise remember first usable window.
         */
        if (!fallback)
            fallback = window;
    }

    return fallback;
}


#pragma mark - SpringBoard Window Priority

/*
 * We use the window ordering only to decide
 * which windows are likely to represent the
 * actual display.
 *
 * We do NOT change windowLevel.
 * We do NOT change layer.transform.
 */
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
     * ============================================================
     * SPRINGBOARD
     * ============================================================
     */
    if (SC16IsSpringBoard())
    {
        /*
         * First pass:
         *
         * Find the actual display window.
         *
         * We prefer UIRootSceneWindow.
         * If unavailable, use the largest visible window.
         */
        UIWindow *displayWindow = nil;

        for (UIScene *scene in application.connectedScenes)
        {
            if (![scene isKindOfClass:[UIWindowScene class]])
                continue;

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            if (windowScene.activationState ==
                UISceneActivationStateUnattached)
            {
                continue;
            }

            for (UIWindow *window in windowScene.windows)
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
         * If there is no UIRootSceneWindow,
         * select largest display-like window.
         */
        if (!displayWindow)
        {
            for (UIScene *scene in application.connectedScenes)
            {
                if (![scene isKindOfClass:[UIWindowScene class]])
                    continue;

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
                    CGRectGetWidth(displayWindow.bounds) *
                    CGRectGetHeight(displayWindow.bounds);

                CGFloat newArea =
                    CGRectGetWidth(candidate.bounds) *
                    CGRectGetHeight(candidate.bounds);

                if (newArea > oldArea)
                    displayWindow = candidate;
            }
        }


        /*
         * ========================================================
         * SECOND PASS
         *
         * This is the important change.
         *
         * We no longer only process:
         *
         *     UIRootSceneWindow
         *     StatusBar
         *     FullDisplay
         *
         * We process EVERY visible SpringBoard window
         * that has a rootViewController and isn't a
         * keyboard/system gesture window.
         *
         * This is what allows:
         *
         *     Home Screen
         *     App Library
         *     Lock Screen
         *     Notification Center
         *     Status Bar
         *
         * to participate.
         * ========================================================
         */
        for (UIScene *scene in application.connectedScenes)
        {
            if (![scene isKindOfClass:[UIWindowScene class]])
                continue;

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            /*
             * Never touch unattached scenes.
             */
            if (windowScene.activationState ==
                UISceneActivationStateUnattached)
            {
                continue;
            }

            for (UIWindow *window in windowScene.windows)
            {
                if (!window)
                    continue;

                if (window.hidden)
                    continue;

                if (window.alpha <= 0.0)
                    continue;

                /*
                 * Keyboard is explicitly excluded.
                 */
                if (SC16IsKeyboardWindow(window))
                    continue;

                /*
                 * Other unsafe internal gesture windows
                 * are also excluded.
                 */
                if (SC16IsUnsafeWindow(window))
                    continue;

                /*
                 * No root VC = nothing safe to transform.
                 */
                if (!window.rootViewController)
                    continue;


                /*
                 * Main display window:
                 *
                 * scale + crop.
                 */
                if (window == displayWindow)
                {
                    SC16ApplyWindow(window);
                    continue;
                }


                /*
                 * Every other SpringBoard UI window:
                 *
                 * scale only.
                 *
                 * This includes StatusBar windows.
                 */
                SC16ApplyScaleOnlyWindow(window);
            }
        }

        return;
    }


    /*
     * ============================================================
     * NORMAL APPLICATION
     * ============================================================
     */
    for (UIScene *scene in application.connectedScenes)
    {
        if (![scene isKindOfClass:[UIWindowScene class]])
            continue;

        UIWindowScene *windowScene =
            (UIWindowScene *)scene;

        if (windowScene.activationState ==
            UISceneActivationStateUnattached)
        {
            continue;
        }

        UIWindow *window =
            SC16FindApplicationWindow(windowScene);

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


/*
 * Existing window becomes visible.
 */
- (void)makeKeyAndVisible
{
    %orig;

    SC16ScheduleApply();

    SC16ScheduleApplyAfter(0.10);

    SC16ScheduleApplyAfter(0.25);
}


/*
 * Root VC changes.
 *
 * Important for:
 *
 * - Lock Screen
 * - Notification Center
 * - App Library
 * - SpringBoard transitions
 */
- (void)setRootViewController:
    (UIViewController *)rootViewController
{
    %orig(rootViewController);

    SC16ScheduleApply();

    SC16ScheduleApplyAfter(0.10);

    SC16ScheduleApplyAfter(0.25);
}


/*
 * Window becomes visible/hidden.
 */
- (void)setHidden:(BOOL)hidden
{
    %orig(hidden);

    if (!hidden)
    {
        SC16ScheduleApply();

        SC16ScheduleApplyAfter(0.10);
    }
}


/*
 * IMPORTANT:
 *
 * A lot of SpringBoard system windows are attached
 * dynamically.
 *
 * This hook catches that moment.
 */
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


/*
 * View becomes visible.
 */
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


/*
 * Layout can reset UIView transform.
 *
 * Reapply only to the root view of a window.
 */
- (void)viewDidLayoutSubviews
{
    %orig;

    if (!SC16Enabled())
        return;

    UIWindow *window = self.view.window;

    if (!window)
        return;

    if (window.rootViewController != self)
        return;

    if (SC16IsUnsafeWindow(window))
        return;

    /*
     * Do NOT touch keyboard.
     */
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

    /*
     * Only full-display/root scene windows get crop.
     */
    if (SC16IsRootSceneWindow(window) ||
        SC16IsFullDisplayWindow(window))
    {
        SC16ApplyCrop(window);
    }
}


/*
 * Rotation / orientation.
 */
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
         * Initial SpringBoard pass.
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
         *
         * Gives SpringBoard time to create
         * Lock Screen / Notification Center /
         * App Library windows.
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
