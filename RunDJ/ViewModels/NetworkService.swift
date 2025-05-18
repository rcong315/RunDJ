//
//  NetworkService.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation

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
    
    struct BpmSongResponse: Decodable {
        let tracks: [String: Double]
        let count: Int
        let min, max: Double
        let user: String
    }
    
    struct PlaylistResponse: Decodable {
        let id: String
    }
    
    init(baseURL: String = "https://rundjserver.onrender.com") {
        self.baseURL = baseURL
    }
    
    func register(accessToken: String, completion: @escaping (Bool) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/user/register")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
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
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
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
            completion([:])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion([:])
                return
            }
            
            guard let data = data else {
                print("No data received")
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
            }
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(BpmSongResponse.self, from: data)
                let songs = responseData.tracks
                print("Successfully decoded \(responseData.count) songs.")
                completion(songs)
            } catch {
                print("Error decoding JSON: \(error)")
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
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(PlaylistResponse.self, from: data)
                print("Successfully decoded playlist \(responseData.id)")
                completion(responseData.id)
            } catch {
                print("Error decoding JSON: \(error)")
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
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard data != nil else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                // Check if status code indicates success (200-299)
                let isSuccess = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                DispatchQueue.main.async {
                    completion(isSuccess)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
        task.resume()
    }
}
