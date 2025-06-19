//
//  File.swift
//  
//
//  Created by David Gavilan Ruiz on 29/02/2024.
//

import Foundation

class DataIO {
    
    @available(macOS 13.0, iOS 15.0, *)
    static func loadJson(url: URL) async throws -> [String: Any]? {
        let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
        guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String : Any]??) else {
            throw SerializationError.invalid("json", data)
        }
        return json
    }
}
