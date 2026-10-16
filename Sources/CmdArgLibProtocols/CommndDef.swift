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

public protocol CommandDef: Sendable {
    init()
    static var argumentAttributes: ArgumentAttributes {get}
    static func run(with words: [String]) async throws
}

extension CommandDef {

    public static var argumentAttributes: ArgumentAttributes { ArgumentAttributes() }

    public static func main() async {
        let words = Array(CommandLine.arguments.dropFirst())
        do {
            try await run(with: words)
        }
        catch {
            Exception.printAndExit(for: error)
        }
    }

    public static func run(parsing wordsString: String = "") async throws {
        let words = shellSplit(wordsString)
        try await run(with: words)
    }
}

extension CommandDef {

    @Sendable func runContextMaker() -> RunContext
    {
        let instance = Self.init()
        let typeName = String(describing: type(of:self))
        let commandName = SymbolFormatter.snake(typeName, "-")

        var runContext = RunContext(commandName)
        var metaTypePairs: [(ParameterName, MetaType)] = []
        var parameters: [Parameter] = []
        var storedPropertyNames: Set<String> = []
        var messages: [String] = []
        for child in Mirror(reflecting: instance).children {
            if let parameterName = child.label {
                storedPropertyNames.insert(parameterName)
                var defaultValueIsNil = false
                var childType = type(of: child.value)
                if let metaType = child.value as? MetaType{
                    metaTypePairs.append((parameterName, metaType))
                }
                if let optional = childType as? OptionalType.Type {
                    childType = optional.wrappedType
                    defaultValueIsNil = "\(child.value)" == "nil"
                }
                let actualTypeName = "\(childType)"
                if actualTypeName.hasPrefix("CommandNodeAttributes<") {
                    continue
                }
                let (actualElementType, _, _) = elementTypeAndWrapper(of: childType)
                if !(childType is Bool.Type || childType is Rest.Type) {
                    guard actualElementType is CmdArgBasicType.Type else {
                        messages.append("\(childType) is not a valid stored property type to use with MainFunctionDef")
                        continue
                    }
                }
                var typeName = Self.argumentAttributes.typeNameFor[parameterName] ?? actualTypeName
                if typeName == "Bool" {
                    typeName = "Flag"
                }
                if typeName.first == "[" && typeName.last == "]" {
                    typeName = "Array<\(typeName.dropFirst().dropLast())>"
                }
                if typeName.last == "?" {
                    var name = typeName.dropLast()
                    if name.last == "?" {
                        name = name.dropLast()
                        defaultValueIsNil = false
                    }
                    typeName = String(name)
                }
                if let value = child.value as? CustomStringConvertible {
                    let parameter = Parameter(parameterName, parameterName, typeName, __quotedOrNil(value), forceNotRequired: !defaultValueIsNil)
                    parameters.append(parameter)
                }
                else {
                    let parameter = Parameter(parameterName, parameterName, typeName, nil, forceNotRequired: !defaultValueIsNil)
                    parameters.append(parameter)
                }
            }
        }
        let showdowGroups = Self.argumentAttributes.shadowGroups
        ensureShadowGroups(parameters, shadwoGroups: showdowGroups, messages: &messages)
        ensureNoDuplicateLabelsAmong(parameters, messages: &messages)
        if !messages.isEmpty {
            fatalUseOfAPI(messages, file: #file, line: #line)
        }
        runContext.__addShadowGroups(showdowGroups)
        runContext.__setMetaTypes(metaTypePairs)
        runContext.setParameters(parameters)
        return runContext
    }
}
