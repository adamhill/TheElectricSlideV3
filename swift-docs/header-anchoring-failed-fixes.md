# Header Anchoring Failed Fixes

## 1. Problem Statement
- Header should stay fixed at the top of the screen during side switching
- Current behavior: Header tracks/moves with the top of the slide rule
- Affects macOS and iPad and iPhone, the iPhone doesn't matter much since it shows only one side. but there is minor movement for front and back sides with difffering number of scales, the header area still shifts.

## 2. Failed Fix Attempts (chronological order)

### Attempt 1: Centered Header with Spacers
- **What was tried:** Added leading/trailing `Spacer()` to center header
- **File:** `SlideRuleDetailView.swift`
- **Result:** Centered but still tracked with content

### Attempt 2: VStack to ZStack Restructure
- **What was tried:** Changed from VStack to `ZStack(alignment: .top)`. Moved header to be an overlay at top.
- **File:** `SlideRuleDetailView.swift`
- **Hypothesis:** ZStack layering would isolate header from content movement
- **Result:** Header still moved with top of content during side switch

### Attempt 3: Fixed Frame on Root ZStack
- **What was tried:** Added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to root ZStack
- **File:** `SlideRuleDetailView.swift`
- **Hypothesis:** Fixed frame would prevent ZStack top edge from moving
- **Result:** Failed - header still tracks with the top of the slide rule

### Attempt 4: GeometryReader with Clamped Frame
- **What was tried:** Wrapped content in `GeometryReader`. Clamped ZStack frame to viewport size: `.frame(width: geometry.size.width, height: geometry.size.height)`
- **File:** `SlideRuleDetailView.swift`
- **Hypothesis:** Prevent NavigationSplitView from adding ScrollView by reporting fixed size
- **Result:** Failed - header still moves with top of the slide rule

### Attempt 5: Added .clipped() Modifier
- **What was tried:** Added `.clipped()` to `DynamicSlideRuleContent`
- **File:** `SlideRuleDetailView.swift`
- **Hypothesis:** Prevent content from rendering outside bounds
- **Result:** Fixed clipping issue but header still not anchored. User indicated Clipping was not the problem though. I went off on a tangent.

## 3. Current State
- All attempts have failed to anchor the header
- Header continues to track with slide rule during swithcing showing sides of the slide rule
- Screenshot shows content zorder issues of the header (title of the slide rule) from recent attempts

## 4. Technical Analysis

**What We Know:**
- The issue appiies to iPhone/ macOS/iPad NavigationSplitView detail pane
- The header is in `SlideRuleDetailView.swift` as `combinedPickersSection`
- Zoom/pan transforms are applied somewhere in the view hierarchy

**What We Don't Know:**
- Where exactly the transforms / stacking are being applied that affect the header
- Why ZStack layering doesn't isolate the header


## 5. Recommended Next Steps
- Need deeper investigation of the exact view hierarchy in debug mode
- May need to examine how DynamicSlideRuleContent applies transforms

## 6. Files Involved
- `TheElectricSlide/Components/SlideRuleDetailView.swift` - Where header is defined
- `TheElectricSlide/Components/DynamicSlideRuleContent.swift` - Where content transforms may be applied
- `TheElectricSlide/ContentView.swift` - Main view structure
- `TheElectricSlide/Models/SlideRuleViewModel.swift` - State management for zoom/pan
