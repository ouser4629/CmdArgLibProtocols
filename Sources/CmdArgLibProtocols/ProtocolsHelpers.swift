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

func ensureNoDuplicateLabelsAmong(_ parameters: [Parameter], messages: inout [String])
{
    var labels: [String:[ParameterName]] = [:]
    func add(_ labelName: String?, _ parameterName: String) {
        if let labelName {
            var names = labels[labelName] ?? []
            names += [parameterName]
            labels[labelName] = names
        }
    }
    for parameter in parameters {
        add(parameter.shortLabelName, parameter.name)
        add(parameter.oldStyleLabelName, parameter.name)
        add(parameter.longLabelName, parameter.name)
    }
    for (label, parameterNames) in labels where parameterNames.count > 1 {
        let names = parameterNames.joinedWith("and", quoteChar: "\"")
        let message = "Parameters \(names) have the same label: \"\(label)\""
        messages.append(message)
    }
}

enum TypeWrapper { case none, optional, array }

func elementTypeAndWrapper(of childType: Any.Type) -> (Any.Type, String, TypeWrapper)
{
    var elementType = childType
    var elementTypeName = "\(childType)"
    var typeWrapper: TypeWrapper = .none

   if let optional = childType as? OptionalType.Type {
        elementType = optional.wrappedType
        elementTypeName = "\(elementType)"
        typeWrapper = .optional
    }
    else if let array = childType as? ArrayType.Type {
        elementType = array.elementType
        elementTypeName = "\(elementType)"
        typeWrapper = .array
    }
    return (elementType, elementTypeName, typeWrapper)
}

func ensureShadowGroups(_ parameters: [Parameter], shadwoGroups: [String], messages: inout [String]) {
    let parameterNames: Set<String> = parameters.reduce(into: [], {$0.insert($1.name)})
    var badShadowNames: [String] = []
    for group in shadwoGroups {
        let names = group.components(separatedBy: .whitespaces)
        for name in names {
            if !parameterNames.contains(name) {
                badShadowNames.append(name)
            }
        }
    }
    if !badShadowNames.isEmpty {
        let s = badShadowNames.count > 1 ? "s" : ""
        let message = "Unrecognized shadowGroup parameter name\(s): \(badShadowNames.joinedWith("and", quoteChar: "\""))"
        messages.append(message)
    }
}

