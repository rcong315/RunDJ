//
//  SPTAppRemotePlayerAPI+Async.swift
//  RunDJ
//
//  Created on 6/1/25.
//
//  This extension provides async/await wrappers for the Spotify SDK's callback-based API

import SpotifyiOS

extension SPTAppRemotePlayerAPI {

    /// Play a track asynchronously
    /// - Parameter uri: The Spotify URI of the track to play
    /// - Throws: Any error that occurs during playback
    func playAsync(_ uri: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.play(uri) { _, error in // result is typically Any?, ignore if function returns Void
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Resume playback asynchronously
    /// - Throws: Any error that occurs during resume
    func resumeAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.resume { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Pause playback asynchronously
    /// - Throws: Any error that occurs during pause
    func pauseAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.pause { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Skip to the next track asynchronously
    /// - Throws: Any error that occurs during skip
    func skipToNextAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.skip(toNext: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }

    /// Skip to the previous track asynchronously
    /// - Throws: Any error that occurs during skip
    func skipToPreviousAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.skip(toPrevious: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }

    /// Seek to a specific position asynchronously
    /// - Parameter position: The position to seek to in milliseconds
    /// - Throws: Any error that occurs during seek
    func seekAsync(toPosition position: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.seek(toPosition: position) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Enqueue a track URI asynchronously
    /// - Parameter uri: The Spotify URI of the track to enqueue
    /// - Throws: Any error that occurs during enqueue
    func enqueueTrackUriAsync(_ uri: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.enqueueTrackUri(uri) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Set repeat mode asynchronously
    /// - Parameter mode: The repeat mode to set
    /// - Throws: Any error that occurs during the operation
    func setRepeatModeAsync(_ mode: SPTAppRemotePlaybackOptionsRepeatMode) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.setRepeatMode(mode) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Subscribe to player state asynchronously
    /// This function confirms that the subscription was initiated.
    /// Actual player state updates will be delivered via the callback provided to the original SDK method.
    /// - Throws: Any error that occurs during the subscription attempt.
    func subscribeToPlayerStateAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // The `result` parameter in this specific callback is the SPTAppRemotePlayerState.
            // However, this async function's purpose (returning Void) is to confirm
            // the subscription call itself succeeded, not to return the first player state.
            // The player state updates will be handled by the callback itself, persistently.
            self.subscribe(toPlayerState: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Successfully initiated the subscription.
                    continuation.resume(returning: ())
                }
            })
        }
    }
}
