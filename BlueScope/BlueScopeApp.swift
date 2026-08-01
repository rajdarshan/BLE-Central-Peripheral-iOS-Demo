//
//  BlueScopeApp.swift
//  BlueScope
//
//  Created by Darshan Raju on 07/07/26.
//

import SwiftUI

@main
struct BlueScopeApp: App {
    @StateObject private var roleManager = RoleManager()

    var body: some Scene {
        WindowGroup {
            RoleSelectionView(roleManager: roleManager)
        }
    }
}
