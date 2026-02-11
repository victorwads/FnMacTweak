#import "./views/popupViewController.h"
#import "./globals.h"

#import "../lib/fishhook.h"
#import <sys/sysctl.h>

#import <GameController/GameController.h>
#import <UIKit/UIKit.h>
#import <math.h>

// =====================================================================
// PERFECT PC SENSITIVITY MATCHING
// =====================================================================
// This implementation matches PC Fortnite sensitivity EXACTLY.
//
// PC Fortnite Formula:
// effective_sensitivity = (Base_XY / 100) × (Context_Sens / 100)
//
// Standard PC settings (800 DPI):
// - Base X/Y: 6.4%
// - Targeting (Look): 45% → effective = 6.4% × 45% = 2.88%
// - Scope (ADS): 45% → effective = 6.4% × 45% = 2.88%
//
// macOS Conversion:
// macOS mouse deltas are ~30x smaller than PC, so we multiply by scale.
// Optimal scale = 34.72 gives effective sensitivity = 1.0 for perfect input.
//
// Final formula:
// mouseDelta × (Base/100) × (Context/100) × SCALE
//
// Optimal: (6.4/100) × (45/100) × 34.72 = 1.0 effective sensitivity
// This ensures every pixel of mouse movement = 1 game unit (zero loss)

// --------- MOUSE FRACTIONAL ACCUMULATION ---------
// CRITICAL: The accumulator is necessary because UE's input system
// quantizes or ignores sub-integer movements. Without accumulation,
// small mouse movements (< 1.0 after scaling) are lost entirely.
static double mouseAccumX = 0.0;
static double mouseAccumY = 0.0;
static BOOL wasADS = NO;
static BOOL wasADSInitialized = NO;

/* Suggestions list:
    - remap keybinding - perfectly possible, but is it really necessary?
    - disable invalid key chime playing on Mac - not possible as far as I know
    - disable Esc key from unfullscreening the game - not possible as far as I know
*/

// --------- DEVICE SPOOFING ---------

// Code largely taken from PlayCover's Playtools library:

// Save original function pointers
static int (*orig_sysctl)(int *, u_int, void *, size_t *, void *, size_t) = NULL;
static int (*orig_sysctlbyname)(const char *, void *, size_t *, void *, size_t) = NULL;

// Update output of sysctl for key values hw.machine, hw.product and hw.target to match iOS output
// This spoofs the device type to apps allowing us to report as any iOS device
static int pt_sysctl(int *name, u_int namelen, void *buf, size_t *size, void *arg0, size_t arg1) {
    if (name[0] == CTL_HW && (name[1] == HW_MACHINE || name[1] == HW_PRODUCT)) {
        if (buf == NULL) {
            *size = strlen(DEVICE_MODEL) + 1;
        } else {
            if (*size > strlen(DEVICE_MODEL)) {
                strcpy((char *)buf, DEVICE_MODEL);
            } else {
                return ENOMEM;
            }
        }
        return 0;
    } else if (name[0] == CTL_HW && name[1] == HW_TARGET) {
        if (buf == NULL) {
            *size = strlen(OEM_ID) + 1;
        } else {
            if (*size > strlen(OEM_ID)) {
                strcpy((char *)buf, OEM_ID);
            } else {
                return ENOMEM;
            }
        }
        return 0;
    }
    return orig_sysctl(name, namelen, buf, size, arg0, arg1);
}

// Spoof sysctlbyname for hw.machine, hw.product, hw.model, hw.target
static int pt_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if ((strcmp(name, "hw.machine") == 0) || (strcmp(name, "hw.product") == 0) || (strcmp(name, "hw.model") == 0)) {
        if (oldp == NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            // We don't want to accidentally decrease it because the real sysctl call will ENOMEM
            // as model are much longer on Macs (eg. MacBookAir10,1)
            if (oldlenp && *oldlenp < strlen(DEVICE_MODEL) + 1) {
                *oldlenp = strlen(DEVICE_MODEL) + 1;
            }
            return ret;
        } else if (oldp != NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            const char *machine = DEVICE_MODEL;
            strncpy((char *)oldp, machine, strlen(machine));
            ((char *)oldp)[strlen(machine)] = '\0';
            if (oldlenp) *oldlenp = strlen(machine) + 1;
            return ret;
        }
    } else if (strcmp(name, "hw.target") == 0) {
        if (oldp == NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            if (oldlenp && *oldlenp < strlen(OEM_ID) + 1) {
                *oldlenp = strlen(OEM_ID) + 1;
            }
            return ret;
        } else if (oldp != NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            const char *machine = OEM_ID;
            strncpy((char *)oldp, machine, strlen(machine));
            ((char *)oldp)[strlen(machine)] = '\0';
            if (oldlenp) *oldlenp = strlen(machine) + 1;
            return ret;
        }
    }
    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

// --------- CONSTRUCTOR ---------

%ctor {
    // We use Fishhook instead of the built-in stuff because we are in a jailed environment
    struct rebinding rebindings[] = {
        {"sysctl", (void *)pt_sysctl, (void **)&orig_sysctl},
        {"sysctlbyname", (void *)pt_sysctlbyname, (void **)&orig_sysctlbyname}
    };
    rebind_symbols(rebindings, 2);

    // Restore folder access
    NSData *bookmark = [[NSUserDefaults standardUserDefaults] dataForKey:@"fnmactweak.datafolder"];
    if (bookmark) {
        BOOL stale = NO;
        NSError *error = nil;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                               options:NSURLBookmarkResolutionWithoutUI
                                         relativeToURL:nil
                                   bookmarkDataIsStale:&stale
                                                 error:&error];
        
        if (url) {
            if ([url startAccessingSecurityScopedResource]) {
                NSLog(@"[FnMacTweak] Successfully restored access to: %@", url);
            } else {
                NSLog(@"[FnMacTweak] Failed to start accessing resource: %@", url);
            }
        } else {
            NSLog(@"[FnMacTweak] Failed to resolve bookmark: %@", error);
        }
    }

    // Temporary (will remove maybe in case of keybinds support)
    TRIGGER_KEY = GCKeyCodeLeftAlt;
    POPUP_KEY = GCKeyCodeKeyP;
    
    // OPTIMIZATION: Pre-calculate sensitivities once at startup
    recalculateSensitivities();
}

// --------- HELPER FUNCTIONS ---------

// Helper to align coordinates to pixel boundaries (prevents blurry text)
static inline CGFloat PixelAlign(CGFloat value) {
    UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
    UIScreen *screen = scene.screen;
    CGFloat scale = screen.scale;
    return round(value * scale) / scale;
}

// Initialize the popup window
static void createPopup() {
    UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication] connectedScenes].anyObject;
    popupWindow = [[UIWindow alloc] initWithWindowScene:scene];
    
    // Use pixel-aligned coordinates for crisp rendering
    popupWindow.frame = CGRectMake(
        PixelAlign(100.0),
        PixelAlign(100.0),
        PixelAlign(330.0),
        PixelAlign(500.0)
    );
    
    popupWindow.windowLevel = UIWindowLevelAlert + 1;
    popupWindow.layer.cornerRadius = 15.0;
    popupWindow.clipsToBounds = true;
    
    popupViewController *popupVC = [popupViewController new];
    popupWindow.rootViewController = popupVC;
}

// Force a pointer lock update (future-proof, no deprecated APIs)
static void updateMouseLock(BOOL value) {
    // Get the active UIWindowScene
    UIWindowScene *scene = (UIWindowScene *)[[[UIApplication sharedApplication].connectedScenes allObjects] firstObject];
    if (!scene) return;

    // Get the main window for that scene
    UIWindow *keyWindow = scene.keyWindow ?: scene.windows.firstObject;
    if (!keyWindow) return;

    UIViewController *mainViewController = keyWindow.rootViewController;
    [mainViewController setNeedsUpdateOfPrefersPointerLocked];

    if (!value) {
        // Reset internal states when unlocking the mouse
        isAlreadyFocused = NO;
        mouseAccumX = 0.0;
        mouseAccumY = 0.0;
        wasADSInitialized = NO;  // CRITICAL: Reset ADS state
    }
}


// --------- THEOS HOOKS ---------

// Disable mouse movement when the mouse isn't locked
%hook GCMouseInput

- (void)setMouseMovedHandler:(GCMouseMoved)handler {
    if (!handler) {
        %orig;
        return;
    }
    
    GCMouseMoved customHandler = ^(GCMouseInput * _Nonnull eventMouse, float deltaX, float deltaY) {
        if (!isMouseLocked) return;

        // FIX: Read ADS state from eventMouse directly, not GCMouse.current,
        // to avoid stale/nil reads during focus transitions.
        BOOL isADS = (eventMouse.rightButton.value == 1.0);

        // Initialize wasADS on first mouse lock
        if (!wasADSInitialized) {
            wasADS = isADS;
            wasADSInitialized = YES;
        }

        // Reset accumulator on ADS transition to prevent snap-to-center
        // VERIFIED: This is necessary - removing it causes camera to snap left on ADS toggle
        if (isADS != wasADS) {
            mouseAccumX = 0.0;
            mouseAccumY = 0.0;
            wasADS = isADS;
        }

        // =====================================================================
        // PC FORTNITE EXACT SENSITIVITY FORMULA - OPTIMIZED
        // =====================================================================
        // Use pre-calculated sensitivities instead of computing them every frame
        // This eliminates 4-6 divisions/multiplications per mouse event
        
        // OPTIMIZATION: Direct multiplication with pre-calculated sensitivity
        // Compiler will optimize the branch prediction for the ternary operators
        mouseAccumX += deltaX * (isADS ? adsSensitivityX : hipSensitivityX);
        mouseAccumY += deltaY * (isADS ? adsSensitivityY : hipSensitivityY);

        // CORRECT: Truncate toward zero for both positive and negative values
        // This ensures fractional accumulation works correctly in all directions
        // (int)1.7 = 1, remainder 0.7 ✓
        // (int)-0.3 = 0, remainder -0.3 ✓
        // (int)-1.7 = -1, remainder -0.7 ✓
        int outX = (int)mouseAccumX;
        int outY = (int)mouseAccumY;

        // Keep fractional remainder for next frame
        mouseAccumX -= (double)outX;
        mouseAccumY -= (double)outY;

        // Only send input if there's actual movement (optimization)
        // MICRO-OPTIMIZATION: Use bitwise OR for single branch check
        if ((outX | outY) != 0) {
            handler(eventMouse, (float)outX, (float)outY);
        }
    };

    // Handle our custom method instead
    %orig(customHandler);
}

%end

// Disable GameController framework mouse touch input when we're using touch input
%hook GCControllerButtonInput

- (void)setPressedChangedHandler:(GCControllerButtonValueChangedHandler)handler {
    if (!handler) {
        %orig;
        return;
    }

    // BEST SOLUTION: Check at handler installation time if this is the left mouse button
    // This is reliable because setPressedChangedHandler is called for each button when
    // the mouse is connected/reconnected, so we always have the fresh reference
    GCMouse *currentMouse = GCMouse.current;
    BOOL isLeftButton = (currentMouse && currentMouse.mouseInput && 
                        currentMouse.mouseInput.leftButton == self);

    if (isLeftButton) {
        GCControllerButtonValueChangedHandler customHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
            // Only call the original handler if the mouse is locked
            if (isMouseLocked) {
                // Only register mouse presses once we've already clicked once, indicating
                // that our pointer is fully "locked"; to avoid presses when the mouse
                // isn't already hidden
                if (isAlreadyFocused) {
                    handler(button, value, pressed);
                } else {
                    isAlreadyFocused = true;
                }
            }
        };

        // Handle our custom method instead
        %orig(customHandler);
    } else {
        %orig;
    }
}

%end

// Press key to enable/disable mouse locking
%hook GCKeyboardInput

- (void)setKeyChangedHandler:(GCKeyboardValueChangedHandler)handler {
    if (!handler) {
        %orig;
        return;
    }
    
    // Only execute if we're assigning it to something to avoid an error
    GCKeyboardValueChangedHandler customHandler = ^(GCKeyboardInput * _Nonnull keyboard, GCControllerButtonInput * _Nonnull key, GCKeyCode keyCode, BOOL pressed) {
        // Check whether the triggering key was pressed and wasn't released
        if (!pressed) {
            handler(keyboard, key, keyCode, pressed);
            return;
        }

        if (keyCode == TRIGGER_KEY) {
            // Don't allow us to manually control the pointer visibility if we're in the popup settings UI
            if (isPopupVisible) return;
            
            // Toggle mouse-pointer functionality and request an update
            isMouseLocked = !isMouseLocked;

            updateMouseLock(isMouseLocked);
        } else if (keyCode == POPUP_KEY) {
            if (!popupWindow) {
                // Create window if it doesn't exist yet
                createPopup();
            }
            
            // Toggle visibility
            isPopupVisible = !isPopupVisible;
            popupWindow.hidden = !isPopupVisible;

            // Show mouse
            isMouseLocked = false;
            updateMouseLock(isMouseLocked);
        } else {
            // Idk, is this really necessary??
            // if (!isMouseLocked) return;

            // Call the original handler (equivalent to %orig)
            handler(keyboard, key, keyCode, pressed);
        }
    };

    // Handle our custom method instead
    %orig(customHandler);
}

%end

// Disable pointer "locking" mechanism, see UE source code for reference (IOSView.cpp)
%hook IOSViewController

- (BOOL)prefersPointerLocked {
    return isMouseLocked;
}

%end

// Enable 120 frames per second on any screen
%hook UIScreen

- (NSInteger)maximumFramesPerSecond {
    return 120;
}

%end

// See UE source code for reference (IOSView.cpp); normally mouse clicks get ignored, so trick the game into thinking they're touchscreen clicks
%hook UITouch

- (UITouchType)type {
    UITouchType _original = %orig;
    
    // UITouchTypeIndirectPointer = 3
    if (!isMouseLocked && _original == UITouchTypeIndirectPointer) {
        // UITouchTypeDirect = 0
        return UITouchTypeDirect;
    }
    else {
        return _original;
    }
}

%end
