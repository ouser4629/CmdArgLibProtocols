// Copyright (c) 2025-2026 Peter Summerland LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CmdArgLibProtocols",
    platforms: [.macOS(.v12)],

    products: [
        .library(name: "CmdArgLibProtocols", targets: ["CmdArgLibProtocols"])
    ],

    dependencies: [
        .package(url: "https://github.com/ouser4629/CmdArgLibCore.git", branch: "main")
    ],

    targets: [
        .target(
            name: "CmdArgLibProtocols",
            dependencies: ["CmdArgLibCore"],
            swiftSettings: [.defaultIsolation(nil)]
        )
    ]
)
