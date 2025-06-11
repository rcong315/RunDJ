//
//  RunningView+LiveActivity.swift
//  RunDJ
//
//  Created on 6/8/25.
//
//  This file contains extensions for other classes to support Live Activities.
//  The RunningView Live Activity functions are already integrated into RunningView.swift
//

import SwiftUI
import ActivityKit

// MARK: - RunManager Extension

extension RunManager {
    func requestPermissionsAndStartWithLiveActivity(targetBPM: Int) {
        self.requestPermissionsAndStart()
        
        Task {
            do {
                try await LiveActivityManager.shared.startActivity(targetBPM: targetBPM)
            }
        }
    }
    
    func stopWithLiveActivity() {
        // Original stop logic
        self.stop()
        
        // End Live Activity
        Task {
            await LiveActivityManager.shared.endActivity()
        }
    }
}
