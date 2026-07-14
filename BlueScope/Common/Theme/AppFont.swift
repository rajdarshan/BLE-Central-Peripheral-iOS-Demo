//
//  AppFont.swift
//  BlueScope
//
//  Created by Darshan Raju on 07/07/26.
//

import SwiftUI

extension Font {
    /// Font with size: 22 , weight: medium
    static let screenTitle = Font.system(size: 22, weight: .medium)
    /// Font with size: 13 , weight: medium
    static let sectionHeader = Font.system(size: 13, weight: .medium)
    /// Font with size: 15 , weight: regular
    static let bodyText = Font.system(size: 15, weight: .regular)
    /// Font with size: 12 , weight: regular
    static let captionText = Font.system(size: 12, weight: .regular)
    /// Font with size:14 , weight: regular
    static let monospaceValue = Font.system(size: 14, weight: .regular, design: .monospaced) // for hex/UUID display
}
