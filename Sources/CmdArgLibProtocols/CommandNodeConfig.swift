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

public typealias ParameterName = String
public typealias TypeName = String
public typealias Alias = String

public struct CommandNodeConfig<StateElement:Sendable>: Sendable, Codable {

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

    public let commandName: String
    public let shadowGroups: [String]
    public let embellishments: [Embellishment]
    public let commandSynopsis: String
    public let children: [CommandNode<StateElement>]
    
    public init(commandName: String = "",
                shadowGroups: [String] = [],
                embellishments: [Embellishment] = [],
                commandSynopsis: String? = nil,
                children: [CmdArgLibCore.CommandNode<StateElement>] = [])
    {
        self.commandName = commandName
        self.shadowGroups = shadowGroups
        self.embellishments = embellishments
        self.commandSynopsis = commandSynopsis ?? commandName
        self.children = children
    }
}

protocol ArrayType {
    static var elementType: Any.Type { get }
}

extension Array: ArrayType {
    static var elementType: Any.Type { Element.self }
}

protocol OptionalType {
    static var wrappedType: Any.Type { get }
}

extension Optional: OptionalType {
    static var wrappedType: Any.Type { Wrapped.self }
}

extension ParsedValue {
    var encodedRawArg: [String] {
        let values = encounteredValues
        let positions = encounteredPositions
        let parsedLabels = encounteredLabels
        if values.isEmpty { return [] }
        let name = parameter.name
        var encodeds: [String] = []
        let labelslMax = parsedLabels.count - 1  // zero if variant, values.count - 1 if array
        let positionsMax = positions.count - 1 //
        let multiValue = positionsMax == 0 && values.count > 1
        for i in 0..<values.count {
            var position = Double(positions[min(i, positionsMax)])
            if multiValue {
                position += Double(i) / 100
            }
            let label = labelslMax < 0 ? "nil" : parsedLabels[min(i, labelslMax)]
            let value = values[i]
            let encoded = """
            {"position":\(position),"parameterName":"\(name)","value":"\(value)","label":"\(label)"}
            """
            encodeds.append(encoded)
        }
        return encodeds
    }
}
