//
//  APIConfig.swift
//  MyG
//

import Foundation

enum APIConfig {
    #if DEBUG
    // Debug builds talk to the backend running on this Mac (cd backend && npm start).
    // The simulator shares the Mac's network; on a physical iPhone use the Mac's LAN IP instead.
    static let baseURL = "http://localhost:3000"
    #else
    static let baseURL = "https://myg-de3i.onrender.com"
    #endif
}
