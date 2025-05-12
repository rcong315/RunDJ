//
//  RunningStatsManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/4/25.
//

import Foundation

// Helper struct to store data points for pace calculation
private struct PaceDataPoint: Equatable {
    let timestamp: Date
    let cumulativeDistance: Double // in meters

    static func == (lhs: PaceDataPoint, rhs: PaceDataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.cumulativeDistance == rhs.cumulativeDistance
    }
}

class RunningStatsManager {

    // MARK: - Public Properties (for display)

    /// Total elapsed time for the run, in seconds.
    private(set) var totalElapsedTime: TimeInterval = 0

    /// Total distance covered in the run, in meters.
    private(set) var totalDistance: Double = 0

    /// Overall average pace for the run, in seconds per kilometer.
    private(set) var currentPace: TimeInterval = 0

    /// Pace for the most recently completed full mile, in seconds. Nil if a full mile hasn't been completed yet or if data is insufficient.
    private(set) var rollingMilePace: TimeInterval?

    // MARK: - Private State

    private var startTime: Date?
    private var lastLocationTimestamp: Date? // Timestamp of the last recorded data point

    // Stores historical data points (timestamp, cumulativeDistance) for rolling pace calculation.
    private var paceDataPoints: [PaceDataPoint] = []

    // Constants for distance conversion
    private let mileInMeters: Double = 1609.344
    private let kilometerInMeters: Double = 1000.0
    
    // Maximum number of historical data points to keep. This helps manage memory
    // and ensures calculations are based on relevant recent data.
    // Adjust based on expected data frequency (e.g., per second, per 5 meters).
    // 500 points at 1s interval = ~8 minutes of history.
    // If running a 5-min mile (300s), this is sufficient.
    private let maxPaceDataPointsCount = 500


    // MARK: - Initialization
    init() {}

    // MARK: - Run Control

    /// Starts a new run. Resets all statistics and records the start time.
    func startRun() {
        resetStats()
        startTime = Date()
        lastLocationTimestamp = startTime
        // Add an initial data point at the start of the run.
        // This helps in pace calculation for the first mile if no other points exist near distance 0.
        if let runStartTime = startTime {
            paceDataPoints.append(PaceDataPoint(timestamp: runStartTime, cumulativeDistance: 0))
        }
        print("Run started at \(startTime!)")
    }

    /// Stops the current run. Finalizes the total elapsed time.
    func stopRun() {
        if let start = startTime, let lastTimestamp = lastLocationTimestamp {
            totalElapsedTime = lastTimestamp.timeIntervalSince(start)
        } else if let start = startTime { // Fallback if no data points were recorded
            totalElapsedTime = Date().timeIntervalSince(start)
        }
        // Perform any final calculations if needed (e.g., overall average pace is already up-to-date)
        print("Run stopped. Total time: \(formatTimeInterval(totalElapsedTime)), Total distance: \(formatDistance(totalDistance))")
    }

    /// Resets all running statistics to their initial states.
    func resetStats() {
        startTime = nil
        totalElapsedTime = 0
        totalDistance = 0
        currentPace = 0
        rollingMilePace = nil
        paceDataPoints.removeAll()
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
     */
    func recordDataPoint(newCumulativeDistance: Double, timestamp: Date) {
        guard let runStartTime = startTime else {
            print("Error: Run has not been started. Call startRun() first.")
            return
        }

        // Ensure distance is not decreasing (can happen with GPS inaccuracies)
        // And timestamp is not earlier than the last recorded one.
        if newCumulativeDistance < totalDistance || (lastLocationTimestamp != nil && timestamp < lastLocationTimestamp!) {
            print("Warning: New data point has invalid distance or timestamp. Ignoring. Current dist: \(totalDistance), new: \(newCumulativeDistance). Last time: \(String(describing: lastLocationTimestamp)), new: \(timestamp)")
            return
        }

        totalDistance = newCumulativeDistance
        totalElapsedTime = timestamp.timeIntervalSince(runStartTime)
        lastLocationTimestamp = timestamp

        // Add data point for rolling pace calculation, but only if distance has changed
        // to avoid redundant points if stationary.
        if paceDataPoints.last?.cumulativeDistance != totalDistance || paceDataPoints.isEmpty {
             paceDataPoints.append(PaceDataPoint(timestamp: timestamp, cumulativeDistance: totalDistance))
        }

        // Calculate overall average pace (seconds per km)
        if totalDistance > 0 && totalElapsedTime > 0 {
            currentPace = (totalElapsedTime / totalDistance) * kilometerInMeters
        } else {
            currentPace = 0
        }

        // Calculate rolling 1-mile pace
        calculateRollingMilePace()

        // Prune old data points to manage memory
        prunePaceDataPoints()
    }

    // MARK: - Pace Calculation

    /// Calculates the pace for the most recently completed mile.
    private func calculateRollingMilePace() {
        // Need at least two points to interpolate: one potentially being the (0, startTime) point.
        // The currentDataPoint is the latest in paceDataPoints.
        guard paceDataPoints.count >= 1, // At least the starting point (0,0) or a recorded one.
              let currentDataPoint = paceDataPoints.last,
              currentDataPoint.cumulativeDistance >= mileInMeters else {
            rollingMilePace = nil // Not enough distance covered or data points
            return
        }

        let currentTime = currentDataPoint.timestamp
        let currentDistance = currentDataPoint.cumulativeDistance
        let targetDistanceForMileStart = currentDistance - mileInMeters // This is D_target

        var pA: PaceDataPoint? // Point before or at targetDistanceForMileStart (Da, Ta)
        var pB: PaceDataPoint? // Point after targetDistanceForMileStart (Db, Tb)

        // Iterate through all recorded historical points to find points pA and pB
        // that bracket the targetDistanceForMileStart.
        // paceDataPoints are sorted by time and thus typically by distance.
        for point in paceDataPoints {
            if point.cumulativeDistance <= targetDistanceForMileStart {
                pA = point // pA is the latest point whose distance is <= targetDistanceForMileStart
            } else { // point.cumulativeDistance > targetDistanceForMileStart
                pB = point // pB is the earliest point whose distance is > targetDistanceForMileStart
                break      // Found our segment [pA, pB]
            }
        }
        
        let interpolatedTimeAtMileStartDate: Date

        if let pointA = pA, let pointB = pB {
            // Case 1: targetDistanceForMileStart is bracketed by two recorded points [pointA, pointB]
            let Da = pointA.cumulativeDistance
            let Ta = pointA.timestamp
            let Db = pointB.cumulativeDistance
            let Tb = pointB.timestamp

            if Db == Da { // Should ideally not happen if points are distinct and distance increases
                if targetDistanceForMileStart == Da {
                    interpolatedTimeAtMileStartDate = Ta
                } else {
                    rollingMilePace = nil; return // Cannot determine with this segment
                }
            } else {
                // Linear interpolation: T_target = Ta + (Tb - Ta) * (D_target - Da) / (Db - Da)
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else if pA == nil, let pointB = pB {
            // Case 2: targetDistanceForMileStart is between run start (0, startTime) and the first recorded point (pointB).
            // This means 0 <= targetDistanceForMileStart < pointB.distance
            guard let runStartTime = startTime else { rollingMilePace = nil; return }

            let Da = 0.0 // Distance at run start
            let Ta = runStartTime // Time at run start
            let Db = pointB.cumulativeDistance
            let Tb = pointB.timestamp

            if Db == Da { // First recorded point is at distance 0 (e.g. the initial point added in startRun)
                 if targetDistanceForMileStart == Da { // target is also 0
                     interpolatedTimeAtMileStartDate = Ta
                 } else { // target > 0, Db = 0. This implies an issue.
                    rollingMilePace = nil; return
                 }
            } else {
                 if targetDistanceForMileStart < 0 { rollingMilePace = nil; return } // Defensive check
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else if let pointA = pA, pB == nil {
            // Case 3: targetDistanceForMileStart is after the last suitable historical point (pointA),
            // and before or at currentDataPoint. The segment for interpolation is [pointA, currentDataPoint].
            // This implies all points in paceDataPoints up to pointA have distance <= targetDistanceForMileStart,
            // and no subsequent point pB was found before currentDataPoint.
            let Da = pointA.cumulativeDistance
            let Ta = pointA.timestamp
            let Db = currentDistance // currentDataPoint.cumulativeDistance
            let Tb = currentTime    // currentDataPoint.timestamp

            if Db == Da {
                if targetDistanceForMileStart == Da {
                    interpolatedTimeAtMileStartDate = Ta
                } else {
                    rollingMilePace = nil; return
                }
            } else {
                // Ensure targetDistanceForMileStart is within [Da, Db]
                // Da <= targetDistanceForMileStart <= Db (actually < Db since pB was not found for Db)
                // Given targetDistanceForMileStart = currentDistance - mileInMeters, it should be <= Db.
                let fraction = (targetDistanceForMileStart - Da) / (Db - Da)
                 if fraction < 0.0 || fraction > 1.0 { // Check if target is outside segment, indicating issue
                    // This might happen if Da is very close to Db, or if data is sparse leading to poor segment choice.
                    rollingMilePace = nil; return
                }
                let timeIntervalOffset = Tb.timeIntervalSince(Ta) * fraction
                interpolatedTimeAtMileStartDate = Ta.addingTimeInterval(timeIntervalOffset)
            }
        } else { // pA == nil and pB == nil
            // This case implies paceDataPoints might be empty or only contains currentDataPoint,
            // or some other unhandled configuration. Initial guards should catch most of this.
            rollingMilePace = nil
            return
        }
        
        // The rolling mile pace is the time elapsed from the interpolated start of the mile to the current time.
        let paceDuration = currentTime.timeIntervalSince(interpolatedTimeAtMileStartDate)

        if paceDuration > 0.1 { // Ensure pace is a sensible positive value (e.g. > 0.1s)
            rollingMilePace = paceDuration
        } else {
            // Negative or zero pace usually indicates an issue with data or interpolation
            // (e.g., timestamps not monotonic, or interpolated time is in the "future").
            rollingMilePace = nil
        }
    }

    /// Removes older data points from `paceDataPoints` to manage memory and keep calculations relevant.
    private func prunePaceDataPoints() {
        // Keep a fixed maximum number of data points.
        // This ensures the array doesn't grow indefinitely.
        if paceDataPoints.count > maxPaceDataPointsCount {
            paceDataPoints.removeFirst(paceDataPoints.count - maxPaceDataPointsCount)
        }
    }

    // MARK: - Formatting Helpers

    /// Formats a TimeInterval (seconds) into a string like HH:MM:SS or MM:SS.
    /// - Parameter interval: The time interval in seconds.
    /// - Returns: A formatted string representation of the time.
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? (interval >= 3600 ? "0:00:00" : "00:00")
    }

    /// Formats a distance (meters) into a string, optionally using metric or imperial units.
    /// - Parameters:
    ///   - distance: The distance in meters.
    ///   - useMetric: If true, formats as meters/kilometers. If false, formats as miles.
    /// - Returns: A formatted string representation of the distance.
    func formatDistance(_ distance: Double, useMetric: Bool = false) -> String { // distance in meters
        if useMetric {
            if distance < 1000 {
                return String(format: "%.0f m", distance)
            } else {
                return String(format: "%.2f km", distance / kilometerInMeters)
            }
        } else { // Imperial
            let miles = distance / mileInMeters
            return String(format: "%.2f mi", miles)
        }
    }

    /// Formats a pace (seconds per unit) into a string like M:SS /unit.
    /// - Parameters:
    ///   - pace: The pace in seconds per unit (e.g., seconds per mile or seconds per kilometer).
    ///   - perKm: If true, the unit is "/km". If false, the unit is "/mi".
    /// - Returns: A formatted string representation of the pace.
    func formatPace(_ pace: TimeInterval, perKm: Bool = false) -> String {
        let unit = perKm ? "km" : "mi"
        if pace <= 0 { return "0:00 /\(unit)" } // Or some other placeholder like "--:--"
        
        let totalSeconds = Int(round(pace))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /%@", minutes, seconds, unit)
    }
}
