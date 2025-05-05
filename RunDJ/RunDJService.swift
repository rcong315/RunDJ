//
//  PlaylistService.swift
//  RunDJ
//
//  Created by Richard Cong on 2/23/25.
//

import Foundation

class RunDJService: ObservableObject {
    static let shared = RunDJService()
    
    private let baseURL = "https://rundjserver.onrender.com"
    private var accessToken: String?
    
    struct BpmSongResponse: Decodable {
        let tracks: [String]
        let count: Int
        let min, max: Double
        let user: String
    }
    
    struct PlaylistResponse: Decodable {
        let id: String
    }
    
    //TODO: Check error code for both endpoints
    func getPresetPlaylist(accessToken: String, stepsPerMinute: Double, completion: @escaping (String?) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/songs/preset")
        components?.queryItems = [
            URLQueryItem(name: "bpm", value: String(stepsPerMinute))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("access_token", forHTTPHeaderField: accessToken)
        
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
    
    // TODO: SwiftData for offline mode
    func getSongsByBPM(accessToken: String, bpm: Double, sources: [String], completion: @escaping ([String]) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/songs/bpm/" + String(bpm))
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "sources", value: sources.joined(separator: ","))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion([])
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
                completion([])
            }
        }
        task.resume()
    }
    
    func createPlaylist(accessToken: String, stepsPerMinute: Double, sources: [String], completion: @escaping (String) -> Void) {
        var components = URLComponents(string: "\(baseURL)/api/playlist/bpm/" + String(stepsPerMinute))
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "sources", value: sources.joined(separator: ","))
        ]
        
        guard let url = components?.url else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            let uri = String(data: data, encoding: .utf8) ?? ""
            print("Received URI: \(uri)")
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(PlaylistResponse.self, from: data)
                print("Successfully decoded playlist \(responseData.id)")
                completion(responseData.id)
            } catch {
                print("Error decoding JSON: \(error)")
                completion("")
            }
        }
        task.resume()
    }
}
