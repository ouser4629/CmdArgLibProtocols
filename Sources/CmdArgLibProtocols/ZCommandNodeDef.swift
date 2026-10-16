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

/// Conforming structs have a static property, commandNode, that is an instance of CommandNode
public protocol ZCommandNodeDef: CommandDef, Sendable, Codable {
    associatedtype StateElement:Sendable
    var commandNodeAttributes: CommandNodeAttributes<StateElement>? { get set }
    func run(state: [StateElement]) async throws -> [StateElement]
}

extension ZCommandNodeDef {
    public static func run(with words: [String] = []) async throws {
        let commandNode = Self().commandNode
        try await commandNode.run(with: words)
    }
}

extension ZCommandNodeDef {

    public var commandNode: CommandNode<StateElement> {

        let instance = Self.init()
        let typeName = String(describing: type(of:self))
        let defaultCommandName = SymbolFormatter.snake(typeName, "-")
        let tentativeAttributes = instance.commandNodeAttributes ?? CommandNodeAttributes(commandName: defaultCommandName)
        let commandNodeAttributes = if tentativeAttributes.commandName == "" {
            CommandNodeAttributes(
                commandName: defaultCommandName,
                commandSynopsis: tentativeAttributes.commandSynopsis,
                children: tentativeAttributes.children
            )
        }
        else {
            tentativeAttributes
        }

        @Sendable func action(
            words: [String], state: [StateElement] = [],
            nodePath: [CommandNode<StateElement>],
            runContext: RunContext) async throws -> ([StateElement], [String])
        {
            let callNames = nodePath.map { $0.name }
            let parseResult = try ParseResult(
                callNames: nodePath.map { $0.name },
                words: words,
                parentCommandMode: !nodePath.last!.__children__.isEmpty,
                context: runContext)
            let trailingWords = parseResult.trailingWords
            var messages = parseResult.parsedErrors.map { $0.description }
            var codedStrings: [String] = []
            for child in Mirror(reflecting: self).children {
                guard let name = child.label else {
                    continue
                }
                var childType = type(of: child.value)
                if let optional = childType as? OptionalType.Type {
                    childType = optional.wrappedType
                }

                let (elementType, actualElementTypeName, typeWrapper) = elementTypeAndWrapper(of: childType)
                if actualElementTypeName.hasPrefix("CommandNodeAttributes<") {
                    continue
                }
                if let parsedValue = parseResult.parsedValues[name], parsedValue.wasEncountered, parsedValue.wasValid {
                    let parameter = parsedValue.parameter
                    if parameter.isFlagOrMetaFlag {
                        codedStrings.append("\"\(name)\":true")
                        continue
                    }
                    let values = parsedValue.encounteredValues.map{ $0.trimmingCharacters(in: .whitespaces) }
                    if values.isEmpty {
                        continue
                    }
                    var encodedElement = ""
                    if actualElementTypeName == "RawArg" {
                        encodedElement = parsedValue.encodedRawArg.joined(separator: ",")
                    }
                    else if child.value is MetaType {
                        encodedElement = "{}"
                    }
                    else if elementType is String.Type {
                        encodedElement = values.map { "\"\($0)\"" }.joined(separator: ",")
                    }
                    else if let type = elementType as? CmdArgBasicType.Type {
                        let elementTypeName = ParameterFormatter.elementTypeName(of: parameter)
                        var encodedElements: [String] = []
                        let elementStrings = values.map{ $0.trimmingCharacters(in: .whitespaces) }
                        for (i, elementString) in elementStrings.enumerated() {
                            if let value = type.initFromString(elementString) {
                                let data = try JSONEncoder().encode(value)
                                encodedElements.append(String(decoding: data, as: UTF8.self))
                            }
                            else {
                                var label = parsedValue.encounteredLabels.first
                                if i < parsedValue.encounteredLabels.count {
                                    label = parsedValue.encounteredLabels[i]
                                }
                                messages.append(invalidValueStringMsg(elementTypeName, elementString, after: label))
                            }
                        }
                        encodedElement = encodedElements.joined(separator: ",")
                    }
                    else if elementType == Rest.self  {
                        encodedElement = "{\"elements\":[\(values.map{ "\"\($0)\""}.joined(separator: ", "))]}"
                    }
                    switch typeWrapper {
                    case .array:
                        encodedElement = "[\(encodedElement)]"
                    case .optional, .none:
                        break
                    }
                    codedStrings.append("\"\(name)\":\(encodedElement)")
                }
                else {
                    if child.value is MetaType {
                        codedStrings.append("\"\(name)\":{}")
                    }
                    else {
                        switch typeWrapper {
                        case .optional:
                            codedStrings.append("\"\(name)\":null")
                        default:
                            if let value = child.value as? Codable {
                                let data = try JSONEncoder().encode(value)
                                let encodedString = String(decoding: data, as: UTF8.self)
                                codedStrings.append("\"\(name)\":\(encodedString)")
                            }
                        }
                    }
                }
            }
            if !messages.isEmpty {
                let errorScreen = ErrorScreen(callNames: callNames, messages: messages, context: runContext)
                throw Exception.stderr(errorScreen.description)
            }
            let encoded = "{\(codedStrings.joined(separator: ", "))}"
            let decoder = JSONDecoder()
            let data = encoded.data(using: .utf8)!
            var newInstance = try decoder.decode(Self.self, from: data)
            newInstance.commandNodeAttributes = self.commandNodeAttributes
            let newState: [Self.StateElement] = try await newInstance.run(state: state)
            return (newState, trailingWords)
        }

        let commandNode = CommandNode(
            name: commandNodeAttributes.commandName,
            synopsis: commandNodeAttributes.commandSynopsis,
            action: action,
            runContextMaker: runContextMaker,
            children: commandNodeAttributes.children
        )
        return commandNode
    }
}
