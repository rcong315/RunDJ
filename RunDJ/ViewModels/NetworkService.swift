//
//  NetworkService.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation
import Sentry

/// Protocol defining the network operations required by the app
protocol NetworkService {
    func register(accessToken: String, completion: @escaping (Bool) -> Void)
    func getSongsByBPM(accessToken: String, bpm: Double, sources: [String], completion: @escaping ([String: Double]) -> Void)
    func getPresetPlaylist(accessToken: String, stepsPerMinute: Double, completion: @escaping (String?) -> Void)
    func createPlaylist(accessToken: String, bpm: Double, sources: [String], completion: @escaping (String?) -> Void)
    func sendFeedback(accessToken: String, songId: String, feedback: String, completion: @escaping (Bool) -> Void)
}

/// Default implementation of the NetworkService protocol
class DefaultNetworkService: NetworkService {
    
    private let baseURL: String
    private let apiKey: String
    
    struct BpmSongResponse: Decodable {
        let tracks: [String: Double]
        let count: Int
        let min, max: Double
        let user: String
    }
    
    struct PlaylistResponse: Decodable {
        let id: String
    }
    
    init(baseURL: String? = nil) {
        self.baseURL = baseURL ?? Configuration.serverBaseURL
        self.apiKey = Configuration.serverAPIKey
    }
    
    private func captureNetworkError(_ error: Error, method: String, parameters: [String: Any] = [:]) {
        SentrySDK.capture(error: error) { scope in
            var context = parameters
            context["method"] = method
            context["base_url"] = self.baseURL
            scope.setContext(value: context, key: "network_request")
            scope.setLevel(.error)
        }
    }
    
    private func captureJSONError(_ error: Error, method: String, responseData: Data?, parameters: [String: Any] = [:]) {
        SentrySDK.capture(error: error) { scope in
            var context = parameters
            context["method"] = method
            scope.setContext(value: context, key: "json_decode")
            
            if let data = responseData, let jsonString = String(data: data, encoding: .utf8) {
                // Limit JSON string to prevent too large payloads
                let truncatedJSON = String(jsonString.prefix(1000))
                scope.setContext(value: ["raw_json": truncatedJSON], key: "response_data")
            }
            scope.setLevel(.error)
        }
    }
    
    func register(accessToken: String, completion: @escaping (Bool) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/user/register")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            SentrySDK.capture(message: "Invalid URL for register endpoint") { scope in
                scope.setContext(value: ["access_token": accessToken], key: "request_params")
                scope.setLevel(.error)
            }
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.captureNetworkError(error, method: "register", parameters: ["access_token": accessToken])
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode >= 400 {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .error
                    breadcrumb.category = "network"
                    breadcrumb.message = "Register failed with status \(httpResponse.statusCode)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                }
                completion(httpResponse.statusCode < 400)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    func getPresetPlaylist(accessToken: String, stepsPerMinute: Double, completion: @escaping (String?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/songs/preset")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "bpm", value: String(stepsPerMinute))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            SentrySDK.capture(message: "Invalid URL for getPresetPlaylist endpoint") { scope in
                scope.setContext(value: ["bpm": stepsPerMinute], key: "request_params")
                scope.setLevel(.error)
            }
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.captureNetworkError(error, method: "getPresetPlaylist", parameters: ["bpm": stepsPerMinute])
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                SentrySDK.capture(message: "No data received from getPresetPlaylist") { scope in
                    scope.setContext(value: ["bpm": stepsPerMinute], key: "request_params")
                    scope.setLevel(.warning)
                }
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode >= 400 {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .error
                    breadcrumb.category = "network"
                    breadcrumb.message = "getPresetPlaylist failed with status \(httpResponse.statusCode)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                }
            }
            
            let uri = String(data: data, encoding: .utf8) ?? ""
            print("Received URI: \(uri)")
            completion(uri)
        }
        task.resume()
    }
    
    func getSongsByBPM(accessToken: String, bpm: Double, sources: [String], completion: @escaping ([String: Double]) -> Void) {
        print("Getting songs by BPM \(bpm)")
        var components = URLComponents(string: "\(baseURL)/api/songs/bpm/" + String(bpm))
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "sources", value: sources.joined(separator: ","))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            SentrySDK.capture(message: "Invalid URL for getSongsByBPM endpoint") { scope in
                scope.setContext(value: ["bpm": bpm, "sources": sources], key: "request_params")
                scope.setLevel(.error)
            }
            completion([:])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.captureNetworkError(error, method: "getSongsByBPM", parameters: ["bpm": bpm, "sources": sources])
                completion([:])
                return
            }
            
            guard let data = data else {
                print("No data received")
                SentrySDK.capture(message: "No data received from getSongsByBPM") { scope in
                    scope.setContext(value: ["bpm": bpm, "sources": sources], key: "request_params")
                    scope.setLevel(.warning)
                }
                completion([:])
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response received:\n\(jsonString)")
            } else {
                print("Could not convert received data to UTF8 string. Data size: \(data.count) bytes.")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode >= 400 {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .error
                    breadcrumb.category = "network"
                    breadcrumb.message = "getSongsByBPM failed with status \(httpResponse.statusCode)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                }
            }
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(BpmSongResponse.self, from: data)
                let songs = responseData.tracks
                print("Successfully decoded \(responseData.count) songs.")
                let breadcrumb = Breadcrumb()
                breadcrumb.level = .info
                breadcrumb.category = "network"
                breadcrumb.message = "Successfully fetched \(responseData.count) songs for BPM \(bpm)"
                SentrySDK.addBreadcrumb(breadcrumb)
                completion(songs)
            } catch {
                print("Error decoding JSON: \(error)")
                self.captureJSONError(error, method: "getSongsByBPM", responseData: data, parameters: ["bpm": bpm])
                completion([:])
            }
        }
        task.resume()
    }
    
    func createPlaylist(accessToken: String, bpm: Double, sources: [String], completion: @escaping (String?) -> Void) {
        print("Creating playlist for BPM \(bpm)")
        var components = URLComponents(string: "\(baseURL)/api/playlist/bpm/" + String(bpm))
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "sources", value: sources.joined(separator: ","))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            SentrySDK.capture(message: "Invalid URL for createPlaylist endpoint") { scope in
                scope.setContext(value: ["bpm": bpm, "sources": sources], key: "request_params")
                scope.setLevel(.error)
            }
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.captureNetworkError(error, method: "createPlaylist", parameters: ["bpm": bpm, "sources": sources])
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                SentrySDK.capture(message: "No data received from createPlaylist") { scope in
                    scope.setContext(value: ["bpm": bpm, "sources": sources], key: "request_params")
                    scope.setLevel(.warning)
                }
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode >= 400 {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .error
                    breadcrumb.category = "network"
                    breadcrumb.message = "createPlaylist failed with status \(httpResponse.statusCode)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                }
            }
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(PlaylistResponse.self, from: data)
                print("Successfully decoded playlist \(responseData.id)")
                let breadcrumb = Breadcrumb()
                breadcrumb.level = .info
                breadcrumb.category = "network"
                breadcrumb.message = "Successfully created playlist \(responseData.id) for BPM \(bpm)"
                SentrySDK.addBreadcrumb(breadcrumb)
                completion(responseData.id)
            } catch {
                print("Error decoding JSON: \(error)")
                self.captureJSONError(error, method: "createPlaylist", responseData: data, parameters: ["bpm": bpm])
                completion(nil)
            }
        }
        task.resume()
    }
    
    func sendFeedback(accessToken: String, songId: String, feedback: String, completion: @escaping (Bool) -> Void) {
        print("Sending feedback for song \(songId)")
        var components = URLComponents(string: "\(baseURL)/api/song/\(songId)/feedback")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "feedback", value: feedback)
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            SentrySDK.capture(message: "Invalid URL for sendFeedback endpoint") { scope in
                scope.setContext(value: ["songId": songId, "feedback": feedback], key: "request_params")
                scope.setLevel(.error)
            }
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.captureNetworkError(error, method: "sendFeedback", parameters: ["songId": songId, "feedback": feedback])
                completion(false)
                return
            }
            
            guard data != nil else {
                print("No data received")
                SentrySDK.capture(message: "No data received from sendFeedback") { scope in
                    scope.setContext(value: ["songId": songId, "feedback": feedback], key: "request_params")
                    scope.setLevel(.warning)
                }
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                // Check if status code indicates success (200-299)
                let isSuccess = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                if !isSuccess {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .error
                    breadcrumb.category = "network"
                    breadcrumb.message = "sendFeedback failed with status \(httpResponse.statusCode)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                } else {
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .info
                    breadcrumb.category = "network"
                    breadcrumb.message = "Successfully sent feedback for song \(songId)"
                    SentrySDK.addBreadcrumb(breadcrumb)
                }
                completion(isSuccess)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
}
