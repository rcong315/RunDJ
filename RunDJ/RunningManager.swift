//
//  RunningManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/4/25.
//

import CoreMotion

class RunningManager: ObservableObject {
    
    static let shared = RunningManager()
    
    @Published var distance: Double = 0
    @Published var duration: Double = 0
    @Published var pace: Double = 0
    
    
}
