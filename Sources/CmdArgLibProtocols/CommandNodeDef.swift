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
public protocol CommandNodeDef: CommandDef, Sendable, Codable {
    associatedtype StateElement:Sendable
    var commandNodeAttributes: CommandNodeAttributes<StateElement>? { get set }
    func run(state: [StateElement]) async throws -> [StateElement]
}

extension CommandNodeDef {
    public static func run(with words: [String] = []) async throws {
        let commandNode = Self().commandNode
        try await commandNode.run(with: words)
    }
}

extension CommandNodeDef {

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
            let (encoded, trailingWords) = try await encodeNode(words: words, state: state, nodePath: nodePath, runContext: runContext)
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
