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

import CmdArgLibCore
import Foundation

public struct MainFunctionAttributes: Sendable, Codable {

    public init(from decoder: any Decoder) throws
    {
        self.init()
    }

    public func encode(to encoder: any Encoder) throws
    {
        // Encode an empty object.
        _ = encoder.singleValueContainer()
    }

    public struct Embellishment: Sendable, Codable {
        public let name: ParameterName
        public let label: LabelSpec?
        public let typeName: TypeName?

        /// Add a custom label and or typename for use in error screens, helpscreens, manpages, etc
        public static func embellish(
            _ name: ParameterName,
            label: LabelSpec? = nil,
            typeName: TypeName? = nil) -> Embellishment
        {
            .init(name: name, label: label, typeName: typeName)
        }
    }

    public let shadowGroups: [String]
    public let embellishments: [Embellishment]

    public init(shadowGroups: [String] = [],
                embellishments: [Embellishment] = [])
    {
        self.shadowGroups = shadowGroups
        self.embellishments = embellishments
    }
}
