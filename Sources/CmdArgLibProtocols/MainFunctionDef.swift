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
public protocol MainFunctionDef: Sendable, Codable {
    init()
    var attributes: MainFunctionAttributes? { get set }
    func run() async throws
}

extension MainFunctionDef {

    public static func main() async {
        let words = Array(CommandLine.arguments.dropFirst())
        do {
            try await run(with: words)
        }
        catch {
            Exception.printAndExit(for: error)
        }
    }

    public static func run(with words: [String] = []) async throws {
        let commandNode = Self().commandNode
        try await commandNode.run(with: words)
    }

    public static func run(parsing wordsString: String = "") async throws {
        let commandNode = Self().commandNode
        try await commandNode.run(parsing: wordsString)
    }

}

extension MainFunctionDef {

    var commandNode: CommandNode<Void> {

        let instance = Self.init()
        let typeName = String(describing: type(of:self))
        let commandName = SymbolFormatter.snake(typeName, "-")
        let config = instance.attributes ?? MainFunctionAttributes()

        @Sendable func action(
            words: [String], state: [Void] = [],
            nodePath: [CommandNode<Void>],
            runContext: RunContext) async throws -> ([Void], [String])
        {
            let callNames = nodePath.map { $0.name }
            let parseResult = try ParseResult(
                callNames: nodePath.map { $0.name },
                words: words,
                parentCommandMode: false,
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
                if actualElementTypeName.hasPrefix("MainFunctionAttributes") {
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
                    case .array, .variadic:
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
            newInstance.attributes = self.attributes
            try await newInstance.run()
            return ([], trailingWords)
        }

        @Sendable func runContextMaker() -> RunContext
        {
            var runContext = RunContext(commandName)
            var metaTypePairs: [(ParameterName, MetaType)] = []
            var parameterCustomSpecs: [ParameterName: (LabelSpec?, TypeName?)] = [:]
            var parameters: [Parameter] = []
            for e in config.embellishments {
                parameterCustomSpecs[e.name] = (e.label, e.typeName)
            }
            // Add parameters for stored properties
            var storedPropertyNames: Set<String> = []
            var messages: [String] = []
            for child in Mirror(reflecting: instance).children {
                if let parameterName = child.label {
                    storedPropertyNames.insert(parameterName)
                    var defaultValueIsNil = false
                    var childType = type(of: child.value)
                    let deadwood =  "\(childType)"
                    if let metaType = child.value as? MetaType{
                        metaTypePairs.append((parameterName, metaType))
                    }
                    if let optional = childType as? OptionalType.Type {
                        defaultValueIsNil = "\(child.value)" == "nil"
                    }
                    let actualTypeName = "\(childType)"
                    if actualTypeName.hasPrefix("MainFunctionAttributes") {
                        continue
                    }
                    let (actualElementType, actualElementTypeName, actualTypewrapper) = elementTypeAndWrapper(of: childType)
                    if !(actualElementType is Bool.Type || actualElementType is Rest.Type) {
                        guard actualElementType is CmdArgBasicType.Type else {
                            messages.append("\(childType) is not a valid stored property type to use with MainFunctionDef")
                            continue
                        }
                    }

                    var labelSpec = parameterName
                    var elementTypeName = actualElementTypeName
                    var typeWrapper = actualTypewrapper
                    var typeIsMaybe = false
                    if let (maybeLabelSpec, maybeTypeName) = parameterCustomSpecs[parameterName] {
                        let customLabelSpec = maybeLabelSpec ?? labelSpec
                        var customTypeName = maybeTypeName ?? actualTypeName
                        typeIsMaybe = customTypeName.hasPrefix("Maybe<") && customTypeName.hasSuffix(">")
//                        if customTypeName.hasSuffix("??") {
//                            customTypeName = "Optional<\(customTypeName.dropLast(2))>"
//                        }
//                        else if customTypeName.hasSuffix("?") {
//                            customTypeName = "\(customTypeName.dropLast(1))"
//                        }
                        let (customElementTypeName, customTypeWrapper) = elementTypeNameAndWrapper(of: customTypeName)
                        var intendedTypeWrapper = customTypeWrapper
                        if customTypeWrapper == .variadic {
                            intendedTypeWrapper = .array
                        }
                        if intendedTypeWrapper != typeWrapper {
                            messages.append("Embellished typeName for \(parameterName), \(customTypeName), is incompatible with its actual type.")
                        }
                        labelSpec = customLabelSpec
                        elementTypeName = customElementTypeName
                        typeWrapper = customTypeWrapper
                    }
                    if elementTypeName == "Bool" {
                        elementTypeName = "Flag"
                    }
                    var typeName = ""
                    switch typeWrapper {
                    case .optional:
                        typeName = "\(elementTypeName)?"
                    case .array:
                        typeName = "Array<\(elementTypeName)>"
                    case .variadic:
                        typeName = "Variadic<\(elementTypeName)>"
                    case .none:
                        typeName = elementTypeName
                    }
                    if let value = child.value as? CustomStringConvertible, !defaultValueIsNil {
                        let parameter = Parameter(labelSpec, parameterName, typeName, __quotedOrNil(value))
                        parameters.append(parameter)
                    }
                    else {
                        let notRequired = typeWrapper == .optional && typeIsMaybe
                        let parameter = Parameter(labelSpec, parameterName, typeName, nil, forceNotRequired: notRequired)
                        parameters.append(parameter)
                    }
                }
            }
            for parameterName in parameterCustomSpecs.keys {
                if !storedPropertyNames.contains(parameterName) {
                    messages.append("invalid parameterName in parameterCustomSpecs: \(parameterName)")
                }
            }
            ensureNoDuplicateLabelsAmong(parameters, messages: &messages)
            if !messages.isEmpty {
                fatalUseOfAPI(messages, file: #file, line: #line)
            }
            runContext.__addShadowGroups(config.shadowGroups)
            runContext.__setMetaTypes(metaTypePairs)
            runContext.setParameters(parameters)
            return runContext
        }

        let commandNode = CommandNode(
            name: commandName,
            synopsis: "",
            action: action,
            runContextMaker: runContextMaker,
            children: []
        )
        return commandNode
    }
}

