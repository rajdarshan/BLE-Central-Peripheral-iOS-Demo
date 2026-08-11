//
//  BlueScopeApp.swift
//  BlueScope
//
//  Created by Darshan Raju on 07/07/26.
//

import SwiftUI

@main
struct BlueScopeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var roleManager = RoleManager()

    var body: some Scene {
        WindowGroup {
            RoleSelectionView(roleManager: roleManager)
        }
    }
}
