//
//  AirTrollerApp.swift
//  AirTroller
//
//  Created by exerhythm on 02.11.2022.
//

import SwiftUI

@main
struct AirTrollerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    checkNewVersions()
                    
                    // Clean up tmp dir
                    for url in (try? FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.removeItem(at: url)
                    }
                    
                    // Check if user has root access
                    do {
                        try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/mobile"), includingPropertiesForKeys: nil)
                    } catch {
                        UIApplication.shared.alert(body: "The app needs to be installed either using TrollStore or on Jailbroken devices error: \(error)", withButton: false)
                    }
                }
        }
    }
    
    func checkNewVersions() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://api.github.com/repos/sourcelocation/AirTroller/releases/latest") {
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if (json["tag_name"] as? String)?.compare(version, options: .numeric) == .orderedDescending {
                        UIApplication.shared.confirmAlert(title: "Update available", body: "A new AirTroller update is available, do you want to visit releases page?", onOK: {
                            UIApplication.shared.open(URL(string: "https://github.com/sourcelocation/AirTroller/releases/latest")!)
                        }, noCancel: false)
                    }
                }
            }
            task.resume()
        }
    }
}

func remLog(_ objs: Any...) {
    for obj in objs {
        let args: [CVarArg] = [ String(describing: obj) ]
        withVaList(args) { RLogv("%@", $0) }
    }
}
