# Physical Cursor Measurements Implementation Plan

## Overview

Convert the cursor width from fixed device-independent points (108pt) to physical real-world measurements (inches) with user configuration support. Default width will be 1 inch, configurable between 0.5" - 2.0".

## Current Implementation

**File**: `TheElectricSlide/Cursor/CursorView.swift:270`
```swift
static let cursorWidth: CGFloat = 108
```

**Problem**: Hardcoded points don't correspond to real-world measurements. On an iPad Pro (264 PPI, 2x scale), 108 points = 216 pixels = 0.82 inches. We want exactly 1 inch.

## Solution Architecture

### 1. PhysicalDimensions Utility

**File**: `TheElectricSlide/Utilities/PhysicalDimensions.swift`

**Purpose**: Convert between inches and points using device-specific PPI values.

**Key Components**:
- Device PPI database (iPad Pro: 264, iPad Mini: 326, iPhone Pro: ~460)
- Device model detection via system identifier
- Conversion methods: `inchesToPoints()` and `pointsToInches()`
- Fallback to 264 PPI for unknown devices (iPad Pro standard)

**Formula**:
```
points = (inches × PPI) / scale
inches = (points × scale) / PPI
```

**Device PPI Reference**:
- iPad Pro (all sizes): 264 PPI
- iPad Air: 264 PPI  
- iPad Mini: 326 PPI
- Standard iPad: 264 PPI
- iPhone Pro models: ~458-460 PPI

### 2. CursorSettings Class

**File**: `TheElectricSlide/Settings/CursorSettings.swift`

**Purpose**: Store and manage cursor width preferences.

**Properties**:
- `widthInches: Double` - stored in UserDefaults via `@AppStorage`
- `minWidth: 0.5"`, `maxWidth: 2.0"`, `defaultWidth: 1.0"`
- `widthInPoints: CGFloat` - computed property using PhysicalDimensions
- `displayString: String` - formatted as "1.00\" (264 pts)"

**Methods**:
- `resetToDefault()` - restore 1 inch default
- `validateWidth()` - clamp to valid range

### 3. CursorSettingsView

**File**: `TheElectricSlide/Settings/CursorSettingsView.swift`

**Purpose**: UI for adjusting cursor width.

**Components**:
- Slider (0.5" to 2.0", step 0.1")
- Live preview showing "1.00\" (264 pts)"
- Reset button
- Device diagnostic info section (optional)
- Description text explaining physical measurements

### 4. Update CursorView

**Changes to**: `TheElectricSlide/Cursor/CursorView.swift`

**Modifications**:
- Remove `static let cursorWidth: CGFloat = 108`
- Add parameter: `var cursorWidth: CGFloat = PhysicalDimensions.inchesToPoints(1.0)`
- Replace all `Self.cursorWidth` references with `cursorWidth`

**Impact**: CursorView becomes configurable while maintaining default behavior.

### 5. Update CursorOverlay

**Changes to**: `TheElectricSlide/Cursor/CursorOverlay.swift`

**Modifications**:
- Add property: `let cursorSettings: CursorSettings`
- Pass `cursorWidth: cursorSettings.widthInPoints` to CursorView
- Update frame width to use `cursorSettings.widthInPoints`

### 6. Integrate into ContentView

**Changes to**: `TheElectricSlide/ContentView.swift`

**Modifications**:
- Add: `@StateObject private var cursorSettings = CursorSettings()`
- Pass cursorSettings to both front and back CursorOverlay instances
- Add settings button to StaticHeaderSection
- Present CursorSettingsView in sheet

**UI Location**: Add "Cursor Settings" button below the cursor display mode picker in the header.

## Implementation Phases

### Phase 1: Core Utilities ✅ Ready to Implement
1. Create `PhysicalDimensions.swift` with PPI database
2. Implement conversion methods
3. Add device detection logic
4. Test calculations on iPad Pro

### Phase 2: Settings Infrastructure ✅ Ready to Implement
1. Create `CursorSettings.swift` with @AppStorage
2. Implement validation methods
3. Create `CursorSettingsView.swift` with slider
4. Test persistence

### Phase 3: Integration ✅ Ready to Implement
1. Update CursorView to accept width parameter
2. Update CursorOverlay to pass settings
3. Add cursorSettings to ContentView
4. Add settings button to UI

### Phase 4: Testing
1. Verify 1 inch default on iPad Pro (should be ~264 pts at 2x scale)
2. Test on iPad Mini (should be ~326 pts at 2x scale)
3. Test slider range and step increments
4. Verify settings persistence
5. Test edge cases (min/max widths)

### Phase 5: Documentation
1. Add inline code documentation
2. Update README with physical measurements feature
3. Document PPI values and sources

## Technical Details

### PPI Calculation Example

iPad Pro 12.9" (2018-2024):
- Screen: 2732 × 2048 pixels
- Physical: 12.9" diagonal
- Scale: 2x
- PPI: 264
- 1 inch = 264 pixels = 132 points (at 2x scale)

### Device Detection Strategy

Use `utsname()` system call to get hardware identifier:
```
iPad8,5 = iPad Pro 12.9" (3rd gen)
iPad13,8 = iPad Pro 12.9" (5th gen)
```

Map identifiers to known PPI values. Unknown devices default to 264 PPI (safe iPad standard).

### Settings Persistence

Using `@AppStorage` with key "cursorWidthInches":
- Automatically persists to UserDefaults
- Observable changes trigger UI updates
- Type-safe Double storage
- Default value: 1.0

### Performance Considerations

- Conversion is simple arithmetic (negligible cost)
- PPI lookup is O(1) dictionary access
- Settings only written on user change
- No impact on rendering performance

## File Structure

```
TheElectricSlide/
├── Utilities/
│   └── PhysicalDimensions.swift       [NEW]
├── Settings/
│   ├── CursorSettings.swift           [NEW]
│   └── CursorSettingsView.swift       [NEW]
├── Cursor/
│   ├── CursorView.swift               [MODIFIED]
│   └── CursorOverlay.swift            [MODIFIED]
└── ContentView.swift                  [MODIFIED]
```

## Testing Checklist

### Unit Tests
- [ ] PhysicalDimensions.inchesToPoints() accuracy
- [ ] PhysicalDimensions.pointsToInches() inverse
- [ ] CursorSettings validation logic
- [ ] Settings persistence

### Integration Tests
- [ ] Default 1" cursor renders correctly
- [ ] Settings UI updates cursor width
- [ ] Persistence across app restarts
- [ ] Multiple device PPI values

### Manual Testing
- [ ] iPad Pro: 1" = 132 points (at 2x)
- [ ] iPad Mini: 1" = 163 points (at 2x)
- [ ] Slider smooth operation
- [ ] Visual feedback accurate
- [ ] Settings button accessible
- [ ] Reset button works

## Migration Strategy

**Backward Compatibility**: Yes
- Default 1.0" ≈ 132 points on iPad Pro (close to old 108pt)
- Existing users see minimal change
- No data migration needed

**User Communication**:
- Settings UI makes feature discoverable
- Help text explains physical measurements
- Device info shows current calculations

## Success Criteria

1. ✅ Cursor width expressed in real-world units (inches)
2. ✅ Default 1 inch works across all device types
3. ✅ User can configure width between 0.5" - 2.0"
4. ✅ Settings persist across app launches
5. ✅ Clear visual feedback of current width
6. ✅ No performance regression

## Next Steps

Ready to proceed with implementation in Code mode. The architecture is complete and all components are well-defined. Recommend implementing in phase order for clean integration.

## References

- [iOS Device Specifications](https://www.ios-resolution.com/)
- [UIScreen Documentation](https://developer.apple.com/documentation/uikit/uiscreen/)
- [AppStorage Documentation](https://developer.apple.com/documentation/swiftui/appstorage)