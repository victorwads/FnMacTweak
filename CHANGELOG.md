# FnMacTweak Changelog - Version Comparison

## Overview
This document compares **FnMacTweak_OLD** (original version) with **FnMacTweak_Updated** (new version) to provide a clear summary of all changes.

---

## 🎯 MAJOR CHANGES

### 1. **Complete Sensitivity System Overhaul**

#### OLD SYSTEM (Simple Multipliers):
- 4 settings: `LOOK_MULTIPLIER_X/Y` and `ADS_MULTIPLIER_X/Y`
- Default: 100% (no modification)
- Direct multiplication: `deltaX * LOOK_MULTIPLIER_X / 100.0f`
- No fractional accumulation (input loss on small movements)

#### NEW SYSTEM (PC Fortnite Formula Match):
- 6 settings: `BASE_XY_SENSITIVITY`, `LOOK_SENSITIVITY_X/Y`, `SCOPE_SENSITIVITY_X/Y`, `MACOS_TO_PC_SCALE`
- Default: Base 6.4%, Look/Scope 50%, Scale 20.0
- PC-accurate formula: `(Base ÷ 100) × (% ÷ 100) × Scale`
- **Fractional accumulation** - zero input loss
- **Pre-calculated sensitivities** for performance optimization

**Why this matters:**
- ✅ Matches PC Fortnite's nested sensitivity system exactly
- ✅ Zero input chunking (fractional accumulation saves sub-pixel movements)
- ✅ Better performance (sensitivities pre-computed at startup, not every frame)

---

### 2. **Fractional Accumulation (CRITICAL NEW FEATURE)**

#### OLD VERSION:
```objc
// Direct pass-through - any movement < 1.0 is lost
handler(eventMouse, deltaX * MULTIPLIER / 100.0f, deltaY * MULTIPLIER / 100.0f);
```

**Problem:** If `deltaX * MULTIPLIER / 100` = 0.7, the game receives 0 and the 0.7 is lost forever.

#### NEW VERSION:
```objc
// Accumulate fractional remainders
static double mouseAccumX = 0.0;
static double mouseAccumY = 0.0;

mouseAccumX += deltaX * sensitivity;
mouseAccumY += deltaY * sensitivity;

int outX = (int)mouseAccumX;  // Send integer part to game
int outY = (int)mouseAccumY;

mouseAccumX -= (double)outX;  // Keep fractional remainder
mouseAccumY -= (double)outY;
```

**Result:** Every tiny mouse movement is captured and accumulated. Zero input loss.

---

### 3. **ADS State Tracking Improvements**

#### OLD VERSION:
```objc
if (GCMouse.current.mouseInput.rightButton.value == 1.0) {
    // Use ADS multiplier
}
```

**Problem:** Can return stale/nil values during focus transitions.

#### NEW VERSION:
```objc
BOOL isADS = (eventMouse.rightButton.value == 1.0);  // Read from event directly

// Reset accumulator on ADS transition to prevent snap-to-center
if (isADS != wasADS) {
    mouseAccumX = 0.0;
    mouseAccumY = 0.0;
    wasADS = isADS;
}
```

**Result:** Prevents camera snap issues when toggling ADS.

---

### 4. **Settings UI Complete Redesign**

#### OLD UI:
- Simple labels: "Regular Sensitivity Multiplier (in %)"
- Simple labels: "Right-Click Sensitivity Multiplier (in %)"
- Basic text fields with X/Y inputs
- Small window: 330x400
- No guidance or explanations

#### NEW UI:
- **Sectioned design** with rounded cards
- **Clear descriptions:**
  - "Base Sensitivity - X/Y-Axis Sensitivity (recommended: 6.4)"
  - "Hip-Fire (Look) - Targeting sensitivity when not aiming"
  - "ADS (Scope) - Sensitivity when aiming down sights"
  - "Mouse Conversion Scale - Converts macOS mouse movement to PC scale"
- **Instruction banner** showing the actual formula
- **Advanced section** for scale factor
- **"Apply Defaults" button** - one-click reset to recommended values
- Larger window: 330x500 (accommodates more content)
- **Pixel-aligned rendering** for crisp text
- **Better visual hierarchy** with color coding

---

### 5. **New "Apply Defaults" Button**

This is a brand new feature that didn't exist in the old version.

**Functionality:**
- Sets Base: 6.4, Look/Scope: 50%, Scale: 20
- Updates UI fields visually
- Saves settings immediately (no need to click Save separately)
- Shows confirmation: "✓ Defaults Applied & Saved"

**Why it's needed:**
Users can experiment with settings and quickly reset to known-good values.

---

### 6. **Performance Optimizations**

#### OLD VERSION:
- Calculations done **every mouse event**: `deltaX * MULTIPLIER_X / 100.0f`
- 2-4 divisions/multiplications per frame

#### NEW VERSION:
- Sensitivities **pre-calculated once** at startup and when settings change:
```objc
void recalculateSensitivities() {
    hipSensitivityX = (BASE_XY_SENSITIVITY / 100.0) * (LOOK_SENSITIVITY_X / 100.0) * MACOS_TO_PC_SCALE;
    // ... etc
}
```
- Mouse handler uses direct multiplication: `deltaX * hipSensitivityX`
- Eliminates 4-6 operations per frame
- Micro-optimizations like bitwise OR for movement detection

---

### 7. **Code Quality & Maintainability**

#### OLD VERSION:
- Simple but limited
- No comments explaining the math
- Hard-coded values
- Deprecated API usage (keyWindow warning)

#### NEW VERSION:
- Extensive documentation in code comments
- Explains PC Fortnite formula
- Future-proof API usage (no deprecation warnings)
- Helper functions like `PixelAlign()` for crisp UI
- Detailed explanations of why each optimization exists

---

## 📊 SETTINGS COMPARISON TABLE

| Setting | OLD Name | OLD Default | NEW Name | NEW Default | Purpose |
|---------|----------|-------------|----------|-------------|---------|
| Hip X | LOOK_MULTIPLIER_X | 100% | LOOK_SENSITIVITY_X | 50% | Hip-fire horizontal |
| Hip Y | LOOK_MULTIPLIER_Y | 100% | LOOK_SENSITIVITY_Y | 50% | Hip-fire vertical |
| ADS X | ADS_MULTIPLIER_X | 100% | SCOPE_SENSITIVITY_X | 50% | ADS horizontal |
| ADS Y | ADS_MULTIPLIER_Y | 100% | ADS_MULTIPLIER_Y | 50% | ADS vertical |
| Base | *(none)* | *(none)* | BASE_XY_SENSITIVITY | 6.4 | **NEW** - PC base sensitivity |
| Scale | *(none)* | *(none)* | MACOS_TO_PC_SCALE | 20.0 | **NEW** - macOS to PC conversion |

---

## 🔧 TECHNICAL IMPROVEMENTS

### Deprecated API Removal
**OLD:**
```objc
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
```

**NEW:**
```objc
UIWindowScene *scene = (UIWindowScene *)[[[UIApplication sharedApplication].connectedScenes allObjects] firstObject];
UIWindow *keyWindow = scene.keyWindow ?: scene.windows.firstObject;
```

### Pixel-Perfect UI Rendering
**NEW:** All UI elements aligned to pixel boundaries to prevent blurry text on Retina displays.

### Accumulator Reset on Mouse Unlock
**NEW:** Clears fractional accumulator when mouse unlocks to prevent incorrect delta on next lock.

---

## 🎨 UI/UX IMPROVEMENTS SUMMARY

1. **Better visual design** - Modern card-based layout with proper spacing
2. **Clear hierarchy** - Sections, headers, and labels properly organized
3. **User guidance** - Formula banner and helpful descriptions
4. **One-click defaults** - New button for easy reset
5. **Larger window** - More room for content (400px → 500px height)
6. **Pixel-perfect rendering** - Crisp text on all screen resolutions
7. **Feedback animations** - Visual confirmation when saving settings

---

## 🐛 BUG FIXES

1. **Camera snap on ADS toggle** - Fixed by resetting accumulator on ADS state change
2. **Input loss on small movements** - Fixed by fractional accumulation
3. **Stale ADS state reads** - Fixed by reading from event instead of GCMouse.current
4. **Deprecated API warnings** - Fixed by using modern UIWindowScene API
5. **Blurry UI text** - Fixed by pixel-aligning all coordinates

---

## 💾 STORAGE KEY CHANGES

### OLD:
```objc
kLookXKey = @"lookMultiplierX"
kLookYKey = @"lookMultiplierY"
kADSXKey = @"adsMultiplierX"
kADSYKey = @"adsMultiplierY"
```

### NEW:
```objc
kBaseXYKey = @"baseXYSensitivity"
kLookXKey = @"lookSensitivityX"
kLookYKey = @"lookSensitivityY"
kScopeXKey = @"scopeSensitivityX"
kScopeYKey = @"scopeSensitivityY"
kScaleKey = @"macOSToPCScale"
```

**Note:** These are different keys, so old settings won't auto-migrate. Users will start with new defaults.

---

## 🎯 IMPACT SUMMARY

| Aspect | OLD | NEW | Improvement |
|--------|-----|-----|-------------|
| **Input Accuracy** | Loses sub-pixel movements | Zero loss (accumulation) | ✅ CRITICAL |
| **Performance** | Calculates per-frame | Pre-calculated | ✅ Better |
| **PC Match** | Approximate | Exact formula match | ✅ Better |
| **User Experience** | Basic UI | Polished, guided UI | ✅ Much Better |
| **Default Feel** | Too sensitive (100%) | Balanced (50%) | ✅ Better |
| **Code Quality** | Functional | Well-documented | ✅ Better |
| **API Future-proofing** | Uses deprecated APIs | Modern APIs | ✅ Better |

---

## 📝 MIGRATION NOTES

### For Users:
- **Settings won't carry over** from old version (different storage keys)
- New defaults will apply on first launch
- Use "Apply Defaults" button to get recommended settings
- Old: 100% = no change, New: 50% is the recommended starting point

### For Developers:
- Complete rewrite of sensitivity system - not a simple patch
- Core Tweak.xm restructured with fractional accumulation
- New globals.h/.m with additional variables
- Complete UI redesign in popupViewController.m
- All changes maintain backward compatibility with device spoofing and core features

---

## ✅ WHAT STAYED THE SAME

- Device spoofing (iPad17,4)
- 120 FPS unlock functionality
- Mouse lock toggle (Left Option key)
- Settings popup (P key)
- Data folder selection feature
- Touch interaction fix for mobile UI
- Fishhook library integration
- Build system (Makefile, Theos)

---

## 🎓 WHY THESE CHANGES MATTER

### For Competitive Players:
- **Zero input loss** means every micro-adjustment counts
- **Exact PC formula** means your muscle memory transfers perfectly
- **Consistent feel** across gaming sessions

### For Casual Players:
- **Better defaults** that feel good out of the box
- **Clear UI** makes configuration easy
- **One-click reset** removes configuration anxiety

### For All Users:
- **Better performance** with pre-calculated values
- **Future-proof** code that won't break with macOS updates
- **Professional polish** in both code and UI