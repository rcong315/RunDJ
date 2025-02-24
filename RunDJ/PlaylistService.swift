//
//  PlaylistService.swift
//  RunDJ
//
//  Created by Richard Cong on 2/23/25.
//

import Foundation

class PlaylistService: ObservableObject {
    private let baseURL = "https://rundjserver.onrender.com"
    private var accessToken: String?
    
    func getPresetPlaylist(stepsPerMinute: Double, completion: @escaping (String?) -> Void) {
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
        //        request.addValue("access_token", forHTTPHeaderField: accessToken!)
        
        var uri = ""
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
}
