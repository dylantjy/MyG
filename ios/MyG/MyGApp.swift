//
//  MyGApp.swift
//  MyG
//
//  Created by Dylan Teo on 27/5/25.
//

import GoogleSignIn
import SwiftUI
@main

struct MyGApp: App {
  @State private var isSignedIn = false
    
  var body: some Scene {
    WindowGroup {
      if isSignedIn {
        RootView(isSignedIn: $isSignedIn)
      } else {
          ContentView(isSignedIn: $isSignedIn)
              .onOpenURL { url in
                  GIDSignIn.sharedInstance.handle(url)
        }
      }
    }
  }
}



