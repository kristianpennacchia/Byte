//
//  YoutubePerson.swift
//  Byte
//
//  Created by Kristian Pennacchia on 1/10/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

struct YoutubePerson: Decodable {
    struct Name: Decodable {
        struct Metadata: Decodable {
            struct Source: Decodable {
                let type: String
                let id: String
            }

            let primary: Bool
            let source: Source
            let sourcePrimary: Bool
        }

        let metadata: Metadata
        let displayName: String
        let givenName: String
        let displayNameLastFirst: String
        let unstructuredName: String
    }

    let names: [Name]

    var primaryName: Name { names.first { $0.metadata.primary }! }
}
