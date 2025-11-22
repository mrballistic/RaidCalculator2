# RAIDGauge 📱💾

A beautiful, native iOS app that helps users understand RAID storage tradeoffs with instant calculations and modern glassmorphic design.

## ✨ Features

- **🎯 Instant Calculations** - See usable capacity, redundancy, and performance in real-time
- **📊 RAID Levels Supported** - RAID 0, 1, 5, 6, 10, and JBOD
- **🎨 Modern iOS Design** - Glassmorphic cards, blur effects, and SF Symbols
- **⚡ Performance Ratings** - Visual star ratings for speed and availability
- **🛡️ Smart Validation** - Helpful warnings for invalid configurations
- **📚 Educational Content** - Detailed info sheets for each RAID level
- **💾 Persistent Settings** - Remembers your last configuration
- **🌙 Dark Mode Support** - Looks great in light and dark modes
- **♿ Accessibility** - Supports Dynamic Type and VoiceOver

## 🚀 Quick Start

1. **Select RAID Level** - Choose from the segmented control
2. **Configure Drives** - Set number of drives (1-24) and size per drive
3. **View Results** - See capacity, redundancy, and performance ratings instantly
4. **Learn More** - Tap the info button for detailed RAID explanations

## 📱 Screenshots

The app features a clean, modern interface with:
- Gradient background with glassmorphic cards
- Intuitive segmented controls for RAID selection
- Real-time results with star ratings
- Comprehensive error handling with user-friendly messages

## 🏗️ Architecture

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM-lite
- **Minimum iOS**: iOS 17.0
- **Dependencies**: None (pure SwiftUI)

### Project Structure

```
RaidCalculator2/
├── Models.swift              # Data models (RaidLevel, Configuration, Result)
├── RaidCalculator.swift      # Business logic and calculations
├── RaidCalculatorViewModel.swift # State management and persistence
├── ContentView.swift         # Main calculator UI
├── RaidInfoSheet.swift       # RAID information detail view
└── RaidCalculator2App.swift  # App entry point
```

## 🧮 RAID Calculations

The app implements standard RAID formulas:

| RAID Level | Capacity Formula | Fault Tolerance | Speed | Availability |
|------------|------------------|-----------------|-------|--------------|
| RAID 0     | n × S            | 0 drives        | ⭐⭐⭐⭐⭐ | ⭐ |
| RAID 1     | S                | n-1 drives      | ⭐⭐   | ⭐⭐⭐⭐⭐ |
| RAID 5     | (n-1) × S        | 1 drive         | ⭐⭐⭐  | ⭐⭐⭐ |
| RAID 6     | (n-2) × S        | 2 drives        | ⭐⭐   | ⭐⭐⭐⭐ |
| RAID 10    | (n/2) × S        | Up to n/2*      | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| JBOD       | n × S            | 0 drives**      | ⭐⭐   | ⭐ |

*Depends on which drives fail  
**Data loss on any failed drive

## 🧪 Testing

The app includes comprehensive unit tests covering:
- ✅ All RAID level calculations
- ✅ Validation logic for invalid configurations
- ✅ Edge cases (decimal sizes, different units)
- ✅ Minimum drive requirements

Run tests with:
```bash
xcodebuild test -scheme RaidCalculator2 -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 📦 Installation

### Requirements
- Xcode 15.0+
- iOS 17.0+ target
- Swift 5.9+

### Build Steps
1. Clone the repository
2. Open `RaidCalculator2.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (⌘+R)

## 🎯 Use Cases

Perfect for:
- **🏠 Home Lab Tinkerers** - Planning NAS storage capacity
- **👨‍🎓 Students & Learners** - Understanding RAID concepts
- **💼 IT Professionals** - Quick capacity planning reference
- **🔧 System Administrators** - Offline RAID calculations

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines
- Follow Swift style conventions
- Maintain the glassmorphic design system
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** - For SwiftUI and the incredible iOS design system
- **SF Symbols** - For the beautiful, scalable icons
- **Swift Testing** - For the modern testing framework

---

Made with ❤️ for the iOS community

**RAIDGauge** - Making RAID storage decisions simple and beautiful 🚀
