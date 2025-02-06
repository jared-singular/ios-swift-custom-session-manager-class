//
//  SessionManager.swift
//  SwiftCocoaPods
//
//  Created by Jared Ornstead on 2/6/25.
//  Singular Solution Engineering
//
import Foundation
import UIKit

/// SessionManager: Tracks and manages app usage sessions
/// - Monitors app state transitions (foreground/background)
/// - Tracks session duration and counts
/// - Persists session data between app launches
/// - Implements configurable timeout for background sessions
final class SessionManager {
    // MARK: - Singleton
    /// Shared instance for app-wide session management
    static let shared = SessionManager()
    
    // MARK: - Public Properties
    /// Duration (in seconds) before a background session is considered ended
    private(set) var sessionTimeout: TimeInterval
    
    // MARK: - Private Properties
    /// Timestamp when app entered background state
    private var backgroundDate: Date?
    /// Timer to track background duration
    private var backgroundTimer: Timer?
    /// Unique identifier for current session
    private var sessionID: UUID?
    /// Timestamp when current session started
    private var sessionStartTime: Date?
    /// Duration of the previous session in seconds
    private var lastSessionDuration: TimeInterval {
        didSet {
            persistenceManager.save(lastSessionDuration, forKey: .lastSessionDuration)
        }
    }
    /// Total number of sessions since app installation
    private var totalSessionCount: Int {
        didSet {
            persistenceManager.save(totalSessionCount, forKey: .totalSessionCount)
        }
    }
    /// Manager for persisting session data
    private let persistenceManager: PersistenceManaging
    /// Identifier for background task
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    /// Private initializer to enforce singleton pattern
    /// - Parameters:
    ///   - timeout: Duration in seconds before background session ends (default: 60)
    ///   - persistenceManager: Storage manager for session data
    private init(
        timeout: TimeInterval = 60,
        persistenceManager: PersistenceManaging = UserDefaultsPersistenceManager()
    ) {
        self.sessionTimeout = timeout
        self.persistenceManager = persistenceManager
        self.lastSessionDuration = persistenceManager.retrieve(.lastSessionDuration) ?? 0
        self.totalSessionCount = persistenceManager.retrieve(.totalSessionCount) ?? 0
        
        setupSessionTracking()
    }
    
    // MARK: - Public Methods
    
    /// Updates the duration required in background before ending session
    /// - Parameter seconds: New timeout duration in seconds (minimum 0)
    func updateSessionTimeout(_ seconds: TimeInterval) {
        sessionTimeout = max(0, seconds)
    }
    
    /// Calculates current session duration
    /// - Returns: Duration in seconds since session start, 0 if no active session
    func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Retrieves the duration of the last completed session
    /// - Returns: Duration in seconds of previous session
    func getPreviousSessionDuration() -> TimeInterval {
        lastSessionDuration
    }
    
    /// Retrieves total number of app sessions
    /// - Returns: Count of all sessions since app installation
    func getTotalSessionCount() -> Int {
        totalSessionCount
    }
}

// MARK: - Private Methods
private extension SessionManager {
    /// Initializes session tracking system
    func setupSessionTracking() {
        registerLifecycleObservers()
        startNewSession()
    }
    
    /// Begins a new session with unique identifier
    func startNewSession() {
        sessionID = UUID()
        sessionStartTime = Date()
        totalSessionCount += 1
        
        debugPrint("📱 New session started: \(sessionID?.uuidString ?? "unknown")")
    }
    
    /// Ends current session and records its duration
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        lastSessionDuration = Date().timeIntervalSince(startTime)
        sessionStartTime = nil
        
        debugPrint("📱 Session ended: \(lastSessionDuration) seconds")
    }
    
    /// Registers for app lifecycle notifications
    func registerLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTransition),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundTransition),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// Handles app entering background state
    @objc func handleBackgroundTransition() {
        backgroundDate = Date()
        startBackgroundTask()
    }
    
    /// Handles app returning to foreground state
    @objc func handleForegroundTransition() {
        endBackgroundTask()
        if let backgroundDate = backgroundDate {
            let backgroundDuration = Date().timeIntervalSince(backgroundDate)
            if backgroundDuration >= sessionTimeout {
                endSession()
                startNewSession()
            }
        }
        backgroundDate = nil
        backgroundTimer?.invalidate()
    }
    
    /// Handles app termination
    @objc func handleAppTermination() {
        endSession()
    }
    
    /// Initiates background task and timeout timer
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if UIApplication.shared.applicationState == .background {
                self.endSession()
                self.endBackgroundTask()
            }
        }
    }
    
    /// Cleans up background task and timer
    func endBackgroundTask() {
        backgroundTimer?.invalidate()
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Persistence Protocol
/// Protocol defining persistence operations for session data
protocol PersistenceManaging {
    func save<T>(_ value: T, forKey key: PersistenceKey)
    func retrieve<T>(_ key: PersistenceKey) -> T?
}

/// Keys for persistent storage
enum PersistenceKey: String {
    case lastSessionDuration
    case totalSessionCount
}

/// UserDefaults implementation of PersistenceManaging
struct UserDefaultsPersistenceManager: PersistenceManaging {
    private let defaults = UserDefaults.standard
    
    func save<T>(_ value: T, forKey key: PersistenceKey) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    func retrieve<T>(_ key: PersistenceKey) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }
}
