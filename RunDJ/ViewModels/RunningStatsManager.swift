//
//  RunningStatsManager.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation
import CoreLocation

/// Helper struct to store data points for pace calculation
private struct PaceDataPoint: Equatable {
    let timestamp: Date
    let cumulativeDistance: Double // in meters

    static func == (lhs: PaceDataPoint, rhs: PaceDataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.cumulativeDistance == rhs.cumulativeDistance
    }
}

/// Manages the collection and calculation of running statistics
class RunningStatsManager: ObservableObject {
    static let shared = RunningStatsManager()

    // MARK: - Published Properties
    
    /// Current running data
    @Published private(set) var runningData = RunningData()
    
    /// Total elapsed time for the run, in seconds (convenience accessor)
    var totalElapsedTime: TimeInterval {
        return runningData.elapsedTime
    }
    
    /// Total distance covered in the run, in meters (convenience accessor)
    var totalDistance: Double {
        return runningData.totalDistance
    }
    
    /// Overall average pace for the run, in seconds per kilometer (convenience accessor)
    var currentPace: TimeInterval {
        return runningData.currentPace
    }
    
    /// Pace for the most recently completed full mile
    @Published private(set) var rollingMilePace: TimeInterval?

    // MARK: - Private State
    private var startTime: Date?
    private var lastLocationTimestamp: Date? // Timestamp of the last recorded data point
    private var paceDataPoints: [PaceDataPoint] = []
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // Constants for distance conversion
    private let mileInMeters: Double = 1609.344
    private let kilometerInMeters: Double = 1000.0
    
    // Maximum number of historical data points to keep
    private let maxPaceDataPointsCount = 500

    // MARK: - Initialization
    init() {}

    // MARK: - Run Control

    /// Starts a new run. Resets all statistics and records the start time.
    func startRun() {
        resetStats()
        startTime = Date()
        lastLocationTimestamp = startTime
        
        // Add an initial data point at the start of the run
        if let runStartTime = startTime {
            paceDataPoints.append(PaceDataPoint(timestamp: runStartTime, cumulativeDistance: 0))
        }
        print("Run started at \(startTime!)")
    }

    /// Stops the current run. Finalizes the total elapsed time.
    func stopRun() {
        if let start = startTime, let lastTimestamp = lastLocationTimestamp {
            runningData.elapsedTime = lastTimestamp.timeIntervalSince(start)
        } else if let start = startTime {
            // Fallback if no data points were recorded
            runningData.elapsedTime = Date().timeIntervalSince(start)
        }
        
        print("Run stopped. Total time: \(formatTimeInterval(totalElapsedTime)), Total distance: \(formatDistance(totalDistance))")
    }

    /// Resets all running statistics to their initial states.
    func resetStats() {
        startTime = nil
        runningData = RunningData()
        rollingMilePace = nil
        paceDataPoints.removeAll()
        routeCoordinates.removeAll()
        lastLocationTimestamp = nil
        print("Stats reset.")
    }

    // MARK: - Stats Update

    /**
     Updates the running stats with a new data point.
     This method should be called whenever new location/distance data is available.

     - Parameters:
        - newCumulativeDistance: The new total distance covered so far (in meters).
        - timestamp: The time at which this new data point was recorded.
        - coordinate: Optional coordinate for route tracking
     */
    func recordDataPoint(newCumulativeDistance: Double, timestamp: Date, coordinate: CLLocationCoordinate2D? = nil) {
        guard let runStartTime = startTime else {
            print("Error: Run has not been started. Call startRun() first.")
            return
        }

        // Ensure distance is not decreasing and timestamp is valid
        if newCumulativeDistance < runningData.totalDistance || (lastLocationTimestamp != nil && timestamp < lastLocationTimestamp!) {
            print("Warning: New data point has invalid distance or timestamp. Ignoring.")
            return
        }

        // Update running data
        runningData.totalDistance = newCumulativeDistance
        runningData.elapsedTime = timestamp.timeIntervalSince(runStartTime)
        lastLocationTimestamp = timestamp
        
        // Add coordinate to route if provided
        if let coordinate = coordinate {
            routeCoordinates.append(coordinate)
            runningData.route = routeCoordinates
        }

        // Add data point for rolling pace calculation
        if paceDataPoints.last?.cumulativeDistance != runningData.totalDistance || paceDataPoints.isEmpty {
            paceDataPoints.append(PaceDataPoint(timestamp: timestamp, cumulativeDistance: runningData.totalDistance))
        }

        // Calculate overall average pace (seconds per km)
        if runningData.totalDistance > 0 && runningData.elapsedTime > 0 {
            runningData.currentPace = (runningData.elapsedTime / runningData.totalDistance) * kilometerInMeters
        } else {
            runningData.currentPace = 0
        }

        // Calculate rolling 1-mile pace
        calculateRollingMilePace()

        // Prune old data points to manage memory
        prunePaceDataPoints()
    }

    // MARK: - Pace Calculation

    /// Calculates the pace for the most recently completed mile.
    private func calculateRollingMilePace() {
        // Need at least two points to interpolate
        guard paceDataPoints.count >= 1,
              let currentDataPoint = paceDataPoints.last,
              currentDataPoint.cumulativeDistance >= mileInMeters else {
            rollingMilePace = nil
            return
        }

        let currentTime = currentDataPoint.timestamp
        let currentDistance = currentDataPoint.cumulativeDistance
        let targetDistanceForMileStart = currentDistance - mileInMeters
        
        var pA: PaceDataPoint? // Point before or at targetDistanceForMileStart
        var pB: PaceDataPoint? // Point after targetDistanceForMileStart

        // Find points that bracket the targetDistanceForMileStart
        for point in paceDataPoints {
            if point.cumulativeDistance <= targetDistanceForMileStart {
                pA = point
            } else {
                pB = point
                break
            }
        }
        
        let interpolatedTimeAtMileStartDate: Date

        if let pointA = pA, let pointB = pB {
            // Case 1: targetDistanceForMileStart is bracketed by two recorded points
            let Da = pointA.cumulativeDistance
            let Ta = pointA.timestamp
            let Db = pointB.cumulativeDistance
            let Tb = pointB.timestamp

            if Db == Da {
                if targetDistanceForMileStart == Da {
                    interpolatedTimeAtMileStartDate = Ta
                } else {
                    rollingMilePace = nil; return
                }
            } else {
                // Linear interpolation
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else if pA == nil, let pointB = pB {
            // Case 2: targetDistanceForMileStart is between run start and first recorded point
            guard let runStartTime = startTime else { rollingMilePace = nil; return }

            let Da = 0.0
            let Ta = runStartTime
            let Db = pointB.cumulativeDistance
            let Tb = pointB.timestamp

            if Db == Da {
                 if targetDistanceForMileStart == Da {
                     interpolatedTimeAtMileStartDate = Ta
                 } else {
                    rollingMilePace = nil; return
                 }
            } else {
                 if targetDistanceForMileStart < 0 { rollingMilePace = nil; return }
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else if let pointA = pA, pB == nil {
            // Case 3: targetDistanceForMileStart is after the last historical point
            let Da = pointA.cumulativeDistance
            let Ta = pointA.timestamp
            let Db = currentDistance
            let Tb = currentTime

            if Db == Da {
                if targetDistanceForMileStart == Da {
                    interpolatedTimeAtMileStartDate = Ta
                } else {
                    rollingMilePace = nil; return
                }
            } else {
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                 if fraction < 0.0 || fraction > 1.0 {
                    rollingMilePace = nil; return
                }
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else {
            rollingMilePace = nil
            return
        }
        
        // Calculate rolling mile pace
        let paceDuration = currentTime.timeIntervalSince(interpolatedTimeAtMileStartDate)

        if paceDuration > 0.1 {
            rollingMilePace = paceDuration
        } else {
            rollingMilePace = nil
        }
    }

    /// Removes older data points to manage memory
    private func prunePaceDataPoints() {
        if paceDataPoints.count > maxPaceDataPointsCount {
            paceDataPoints.removeFirst(paceDataPoints.count - maxPaceDataPointsCount)
        }
    }

    // MARK: - Formatting Helpers

    /// Formats a TimeInterval (seconds) into a string like HH:MM:SS or MM:SS.
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? (interval >= 3600 ? "0:00:00" : "00:00")
    }

    /// Formats a distance (meters) into a string with appropriate units
    func formatDistance(_ distance: Double, useMetric: Bool = false) -> String {
        if useMetric {
            if distance < 1000 {
                return String(format: "%.0f m", distance)
            } else {
                return String(format: "%.2f km", distance / kilometerInMeters)
            }
        } else {
            let miles = distance / mileInMeters
            return String(format: "%.2f mi", miles)
        }
    }

    /// Formats a pace into a readable string like M:SS /unit
    func formatPace(_ pace: TimeInterval, perKm: Bool = false) -> String {
        let unit = perKm ? "km" : "mi"
        if pace <= 0 { return "--:-- /\(unit)" }
        
        let totalSeconds = Int(round(pace))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /%@", minutes, seconds, unit)
    }
}
