# SessionManager Implementation Guide

## Overview
Guide that explains how to integrate a custom SessionManager class into your iOS app to track session metrics like duration.

## 1. Add SessionManager Class

1. Create a new Swift file named `SessionManager.swift` in your project
2. Copy the entire SessionManager class implementation into this file
3. Ensure you have the required imports:
```swift
import Foundation
import UIKit
```

## 2. Configure AppDelegate

Add the SessionManager initialization to your `AppDelegate.swift`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize SessionManager with 120-second timeout
    let manager = SessionManager.shared
    manager.updateSessionTimeout(120)
    
    // Your existing initialization code...
    
    return true
}
```

## 3. Track Sessions with Singular

Add session tracking to relevant view controllers or events. Here's an example:

```swift
func trackSessionMetrics() {
    let manager = SessionManager.shared
    
    // Collect session metrics
    let metrics: [AnyHashable: Any] = [
        "currentDuration": manager.getCurrentSessionDuration(),
        "previousDuration": manager.getPreviousSessionDuration(),
        "totalSessions": manager.getTotalSessionCount()
    ]
    
    // Send to Singular
    Singular.event(EVENT_SNG_LEVEL_ACHIEVED, withArgs: metrics)
}
```

## Common Implementation Points

**Track Session at App Launch:**
```swift
class MainViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackSessionMetrics()
    }
}
```

**Track Session at Key Events:**
```swift
func userCompletedAction() {
    // Your existing code...
    trackSessionMetrics()
}
```

## Best Practices

1. **Session Timeout:**
   - Default is 120 seconds
   - Adjust based on your app's usage patterns:
   ```swift
   SessionManager.shared.updateSessionTimeout(300) // 5 minutes
   ```

2. **Event Tracking:**
   - Track sessions at meaningful points
   - Consider tracking at:
     - App launch
     - Level completion
     - User registration
     - Purchase events

3. **Metric Usage:**
   ```swift
   let manager = SessionManager.shared
   
   // Current session length
   print("Current session: \(manager.getCurrentSessionDuration()) seconds")
   
   // Previous session length
   print("Last session: \(manager.getPreviousSessionDuration()) seconds")
   
   // Total session count
   print("Total sessions: \(manager.getTotalSessionCount())")
   ```

## Verification

1. Test background timeout:
   - Launch app
   - Background app
   - Wait 121 seconds
   - Return to app
   - Verify new session started

2. Monitor Singular events:
   - Check Singular dashboard
   - Verify metrics are received
   - Validate data accuracy

## Troubleshooting

- **Session Not Ending:** Verify timeout duration is set correctly
- **Missing Metrics:** Ensure Singular integration is complete
- **Background Issues:** Check background task configuration

## Example Integration

Complete example of tracking a user level achievement:

```swift
func userCompletedLevel(_ level: Int) {
    let manager = SessionManager.shared
    
    var eventData: [AnyHashable: Any] = [
        "level": level,
        "currentDuration": manager.getCurrentSessionDuration(),
        "previousDuration": manager.getPreviousSessionDuration(),
        "totalSessions": manager.getTotalSessionCount()
    ]
    
    // Add additional game metrics
    eventData["score"] = getCurrentScore()
    eventData["difficulty"] = getCurrentDifficulty()
    
    // Send to Singular
    Singular.event(EVENT_SNG_LEVEL_ACHIEVED, withArgs: eventData)
}
```

This implementation guide provides a foundation for session tracking in your iOS app. Adjust the integration points and metrics based on your specific needs.
