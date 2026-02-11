#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

// For spoofing device specifications
#define DEVICE_MODEL "iPad17,4"
#define OEM_ID "A3361"

// Setting keys
#define kSettingsKey @"fnmactweak.settings"
#define kBaseXYKey @"baseXYSensitivity"
#define kLookXKey @"lookSensitivityX"
#define kLookYKey @"lookSensitivityY"
#define kScopeXKey @"scopeSensitivityX"
#define kScopeYKey @"scopeSensitivityY"
#define kScaleKey @"macOSToPCScale"

// Key for hiding/revealing mouse pointer
extern GCKeyCode TRIGGER_KEY;
extern GCKeyCode POPUP_KEY;

// Fortnite PC sensitivity settings
// Match your exact PC Fortnite settings here
// Optimal: 6.4% base × 45% look/scope × 34.72 scale = 1.0 effective
extern float BASE_XY_SENSITIVITY;         // X/Y-Axis Sensitivity (standard: 6.4%)
extern float LOOK_SENSITIVITY_X;          // Look Sensitivity X - Hip-fire (standard: 45%)
extern float LOOK_SENSITIVITY_Y;          // Look Sensitivity Y - Hip-fire (standard: 45%)
extern float SCOPE_SENSITIVITY_X;         // Scope Sensitivity X - ADS (standard: 45%)
extern float SCOPE_SENSITIVITY_Y;         // Scope Sensitivity Y - ADS (standard: 45%)

// macOS to PC conversion scale
extern float MACOS_TO_PC_SCALE;           // Conversion factor (optimal: 34.72 for 1.0 effective)

// Pre-calculated sensitivities for performance optimization
extern double hipSensitivityX;
extern double hipSensitivityY;
extern double adsSensitivityX;
extern double adsSensitivityY;

// Keyboard handler
extern GCKeyboardValueChangedHandler keyboardChangedHandler;
extern BOOL isMouseLocked;
extern BOOL isAlreadyFocused;

// UI and popup stuff
extern UIWindow *popupWindow;
extern BOOL isPopupVisible;

// Function to recalculate pre-computed sensitivities (call after settings change)
#ifdef __cplusplus
extern "C" {
#endif
void recalculateSensitivities(void);
#ifdef __cplusplus
}
#endif
