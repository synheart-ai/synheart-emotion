# Synheart Emotion - iOS Example

This is a native iOS/macOS example demonstrating the Synheart Emotion SDK for Swift.

## Features

- **Command-line demo** showing SDK capabilities
- **Real-time emotion inference** from simulated biosignal data
- **Multiple emotional state scenarios** (Calm, Amused, Stressed)
- **Visual output** with emojis and progress bars
- **Buffer statistics** display
- **Error handling** demonstration

## Requirements

- Xcode 15.0+
- Swift 5.9+
- iOS 13.0+ / macOS 10.15+

## Setup and Running

### Option 1: Create an Xcode Project (Recommended)

The easiest way to run this example is to create a new Xcode project:

1. Create a new Xcode project (File → New → Project)
2. Choose "Command Line Tool" or "App" template
3. Add the Synheart Emotion SDK:
   - File → Add Packages
   - Click "Add Local..."
   - Navigate to `../../sdks/ios`
   - Add to your project
4. Copy the contents of `EmotionExampleApp.swift` into your project
5. Build and run (⌘R)

### Option 2: Using the SDK Directly

You can also build your own app and add the SDK as a dependency:

```bash
# In your Xcode project
# File → Add Packages → Add Local → select ../../sdks/ios
```

Or via Swift Package Manager in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/synheart-ai/synheart-emotion.git", from: "0.1.0")
]
```

## Project Structure

```
examples/ios/
├── EmotionExampleApp.swift  # Standalone example code
├── .gitignore               # Git ignore rules
└── README.md                # This file
```

## How It Works

The example demonstrates the Synheart Emotion SDK by:

1. **Initializing** the emotion engine with custom configuration
2. **Simulating** three emotional states with different biosignal patterns:
   - **Calm**: Low heart rate (~60 bpm), low variability
   - **Amused**: Medium heart rate (~75 bpm), medium variability
   - **Stressed**: High heart rate (~90 bpm), high variability
3. **Pushing** synthetic data to the engine
4. **Consuming** and displaying emotion inference results
5. **Showing** buffer statistics and clearing between scenarios

### Code Highlights

**Engine Initialization:**
```swift
let config = EmotionConfig(
    window: 60.0,        // 60 second window
    step: 5.0,           // 5 second step
    minRrCount: 30,      // Minimum 30 RR intervals
    hrBaseline: 70.0     // Baseline heart rate
)

let engine = try EmotionEngine.fromPretrained(
    config: config,
    onLog: { level, message, context in
        print("[\(level)] \(message)")
    }
)
```

**Pushing Data:**
```swift
engine.push(
    hr: 72.0,
    rrIntervalsMs: [850.0, 820.0, 830.0, ...],
    timestamp: Date()
)
```

**Consuming Results:**
```swift
let results = engine.consumeReady()
if !results.isEmpty {
    let result = results[0]
    print("Emotion: \(result.emotion)")
    print("Confidence: \(Int(result.confidence * 100))%")
    print("Probabilities: \(result.probabilities)")
}
```

**Error Handling:**
```swift
do {
    let engine = try EmotionEngine.fromPretrained(config: config)
    // Use engine...
} catch EmotionError.modelIncompatible(let expectedFeats, let actualFeats) {
    print("Model incompatible: expected \(expectedFeats), got \(actualFeats)")
} catch EmotionError.badInput(let reason) {
    print("Bad input: \(reason)")
} catch {
    print("Error: \(error)")
}
```

## Example Output

```
╔════════════════════════════════════════════════════════════╗
║          Synheart Emotion SDK - iOS/macOS Demo           ║
╚════════════════════════════════════════════════════════════╝

[1] Initializing emotion engine...
  ℹ️ [info] Loading pretrained model...
✓ Engine initialized successfully

────────────────────────────────────────────────────────────

[2] Starting biosignal simulation...

🎭 Simulating Calm state...
   HR: 60 bpm (±8)

   📊 Result 1:
      😌 Emotion: Calm
      🎯 Confidence: 87%
      📈 Probabilities:
         Calm: █████████████████ 87%
         Amused: ██ 10%
         Stressed: █ 3%

...
```

## Creating a SwiftUI App

To create a full SwiftUI iOS app (not just a command-line tool), create a new Xcode project and add the SDK as a dependency:

### 1. Create New Xcode Project

1. File → New → Project
2. Choose "App" template
3. Select SwiftUI interface

### 2. Add SDK Dependency

In Xcode:
1. File → Add Packages
2. Enter local path: `../../sdks/ios`
3. Add to your app target

Or via Package.swift:
```swift
dependencies: [
    .package(path: "../../sdks/ios")
]
```

### 3. Example SwiftUI View

```swift
import SwiftUI
import SynheartEmotion

struct ContentView: View {
    @StateObject private var viewModel = EmotionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentEmotion.emoji)
                .font(.system(size: 100))

            Text(viewModel.currentEmotion.name)
                .font(.title)

            Text("Confidence: \(viewModel.confidence)%")
                .font(.headline)

            // Probability bars for each emotion
            ForEach(viewModel.probabilities.sorted(by: { $0.value > $1.value }), id: \.key) { label, prob in
                HStack {
                    Text(label)
                        .frame(width: 100, alignment: .leading)
                    ProgressView(value: prob)
                    Text("\(Int(prob * 100))%")
                        .frame(width: 50)
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.startSimulation()
        }
    }
}

class EmotionViewModel: ObservableObject {
    @Published var currentEmotion: (name: String, emoji: String) = ("Unknown", "🤔")
    @Published var confidence: Int = 0
    @Published var probabilities: [String: Double] = [:]

    private var engine: EmotionEngine?

    init() {
        let config = EmotionConfig()
        engine = try? EmotionEngine.fromPretrained(config: config)
    }

    func startSimulation() {
        // Implement simulation logic similar to main.swift
    }
}
```

## Integration with Your App

To integrate the SDK into your own iOS/macOS app:

1. **Add the SDK** via Swift Package Manager or CocoaPods:
   ```swift
   // Swift Package Manager
   dependencies: [
       .package(url: "https://github.com/synheart-ai/synheart-emotion.git", from: "0.1.0")
   ]

   // CocoaPods
   pod 'SynheartEmotion', '~> 0.1.0'
   ```

2. **Import and initialize**:
   ```swift
   import SynheartEmotion

   let engine = try EmotionEngine.fromPretrained(config: EmotionConfig())
   ```

3. **Push real biosignal data** from HealthKit or your wearable:
   ```swift
   engine.push(hr: heartRate, rrIntervalsMs: rrIntervals, timestamp: Date())
   ```

4. **Consume and display results**:
   ```swift
   let results = engine.consumeReady()
   results.forEach { result in
       // Update UI with result.emotion, result.confidence, etc.
   }
   ```

## HealthKit Integration

For a complete HealthKit integration example, see the [iOS SDK Documentation](../../sdks/ios/README.md#healthkit-integration).

## Troubleshooting

### Build Errors

If you encounter build errors:

1. Make sure you're using Xcode 15.0+ with Swift 5.9+
2. Clean build folder: Product → Clean Build Folder (⇧⌘K)
3. Reset package cache: File → Packages → Reset Package Caches

### SDK Module Not Found

If Swift can't find the SDK module:

1. Verify the SDK path in `Package.swift`:
   ```swift
   .package(path: "../../sdks/ios")
   ```

2. Make sure the SDK exists at `../../sdks/ios/` relative to this directory

3. Run `swift package resolve` to resolve dependencies

## License

MIT License - See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/synheart-ai/synheart-emotion/issues
- Documentation: https://github.com/synheart-ai/synheart-emotion
