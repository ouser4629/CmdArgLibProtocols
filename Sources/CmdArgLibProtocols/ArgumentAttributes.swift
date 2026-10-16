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

public struct ArgumentAttributes: Sendable, Codable {

    public let shadowGroups: [String]
    public let typeNameFor: [ParameterName:TypeName]

    public init(shadowGroups: [ParameterName] = [], showElements: [ShowElement] = [])
    {
        var typeNameFor:[ParameterName:TypeName] = [:]
        for element in showElements {
            if case .parameterElement(let parameteElement) = element.member {
                if let typeName = parameteElement.typeName {
                    typeNameFor[parameteElement.name] = typeName
                }
            }
        }
        self.typeNameFor = typeNameFor
        self.shadowGroups = shadowGroups
    }
}
