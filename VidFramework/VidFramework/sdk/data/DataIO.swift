//
//  DataIO.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/05/05.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Foundation

class DataIO {
    static func loadAsync(forResource res: String, withExtension ext: String, bundle: Bundle, completion: @escaping ([String : Any]?, Error?) -> Void) {
        // about @escaping http://stackoverflow.com/a/38990967/1765629
        guard let url = bundle.url(forResource: res, withExtension: ext) else {
            completion(nil, FileError.missing(res))
            return
        }
        // http://stackoverflow.com/a/39423764/1765629
        URLSession.shared.dataTask(with:url) { (data, response, error) in
            if let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String : Any]??) {
                completion(json, error)
            } else {
                completion(nil, error)
            }
        }.resume()
    }
}
