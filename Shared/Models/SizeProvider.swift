//
//  SizeProvider.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/8/19.
//  Copyright © 2019 Kristian Pennacchia. All rights reserved.
//

import CoreGraphics

protocol SizeProvider {
    static var small: CGSize { get }
    static var medium: CGSize { get }
    static var large: CGSize { get }
}
