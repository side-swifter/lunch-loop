// swift-tools-version: 5.9

// Swift Playgrounds version of Lunch Loop. The code is the same as the Xcode project.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Lunch Loop",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "Lunch Loop",
            targets: ["AppModule"],
            bundleIdentifier: "com.akshaysanjai.lunchloop",
            teamIdentifier: "DZM75243KS",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
