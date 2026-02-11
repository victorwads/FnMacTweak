#import "./globals.h"

#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

// Key for hiding/revealing mouse pointer
GCKeyCode TRIGGER_KEY;
GCKeyCode POPUP_KEY;

// Fortnite PC sensitivity settings
// OPTIMAL CONFIGURATION FOR PERFECT PC MATCH + ZERO INPUT LOSS
// Default: 6.4% base × 50% look/scope × 20.0 scale = balanced sensitivity
// These values provide a good starting point for most users
float BASE_XY_SENSITIVITY = 6.4f;          // X/Y-Axis (base) sensitivity (recommended: 6.4)
float LOOK_SENSITIVITY_X = 50.0f;          // Look Sensitivity X (hip-fire) (recommended: 50%)
float LOOK_SENSITIVITY_Y = 50.0f;          // Look Sensitivity Y (hip-fire) (recommended: 50%)
float SCOPE_SENSITIVITY_X = 50.0f;         // Scope Sensitivity X (ADS) (recommended: 50%)
float SCOPE_SENSITIVITY_Y = 50.0f;         // Scope Sensitivity Y (ADS) (recommended: 50%)

// macOS to PC conversion scale
// This factor converts macOS mouse deltas to match PC input scale
// Based on testing with various mice and DPI settings
// Recommended: 20.0 for balanced feel that matches PC Fortnite
float MACOS_TO_PC_SCALE = 20.0f;          // Conversion factor (recommended: 20.0)

// Pre-calculated sensitivities for performance optimization
double hipSensitivityX = 0.0;
double hipSensitivityY = 0.0;
double adsSensitivityX = 0.0;
double adsSensitivityY = 0.0;

// Function to recalculate sensitivities (call when settings change)
void recalculateSensitivities() {
    hipSensitivityX = (BASE_XY_SENSITIVITY / 100.0) * (LOOK_SENSITIVITY_X / 100.0) * MACOS_TO_PC_SCALE;
    hipSensitivityY = (BASE_XY_SENSITIVITY / 100.0) * (LOOK_SENSITIVITY_Y / 100.0) * MACOS_TO_PC_SCALE;
    adsSensitivityX = (BASE_XY_SENSITIVITY / 100.0) * (SCOPE_SENSITIVITY_X / 100.0) * MACOS_TO_PC_SCALE;
    adsSensitivityY = (BASE_XY_SENSITIVITY / 100.0) * (SCOPE_SENSITIVITY_Y / 100.0) * MACOS_TO_PC_SCALE;
}

// Keyboard handler
GCKeyboardValueChangedHandler keyboardChangedHandler = nil;
BOOL isMouseLocked = false;
BOOL isAlreadyFocused = false;

// UI and popup stuff
UIWindow *popupWindow = nil;
BOOL isPopupVisible = false;
