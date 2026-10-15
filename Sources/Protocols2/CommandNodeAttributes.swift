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

public struct CommandNodeAttributes<StateElement:Sendable>: Sendable, Codable {

    public let commandName: String
    public let commandSynopsis: String
    public let children: [CommandNode<StateElement>]

    public init(commandName: String = "",
                commandSynopsis: String = "",
                children: [CmdArgLibCore.CommandNode<StateElement>] = [])
    {
        self.commandName = commandName
        self.commandSynopsis = commandSynopsis
        self.children = children
    }

    public init(from decoder: any Decoder) throws
    {
        self.init()
    }

    public func encode(to encoder: any Encoder) throws
    {
        // Encode an empty object.
        _ = encoder.singleValueContainer()
    }
}

