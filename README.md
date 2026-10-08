<!-- 
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
-->

## CmdArgLibProtocols

CmdArgLibProtocols is part of the [Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git).

It provides the `CommandNodeDef` protocol, which
defines a [`CommandNode`](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#commandnode) 
from the stored properties and configuration of a conforming struct.

---

## Typical Usage

1. Define a state element type that conforms to Sendable, say `StateElement`.

2. Define a struct that conforms to `CommandNodeDef<StateElement>`, and annotate it with `@main`.

3. Add one stored variable for each CLI argument.

4. Add a configuration property to provide additional information needed to define the CLI.

5. Add a `@MainActor run(state: [StateElement]) -> [StateElement]` method that implements program logic.

6. Build and run in the terminal.

---

## Sample

This sample program prints a phrase.

<details>
<summary>Code</summary>

```swift
import CmdArgLibCore
import CmdArgLibProtocols

@main
struct Main: CommandNodeDef {
    var l: Flag = false
    var u: Flag = false
    var count: Int = 1
    var phrase: String? = nil

    var configuration: CommandNodeConfig<Void>? = CommandNodeConfig<Void>(
        commandName: "print-s1",
        shadowGroups: ["u l"],
        embellishments: [.embellish("phrase", label: "_"),]
    )

    func run(state: [Void]) throws -> [Void] {
        guard count >= 1 else { throw Exception.error("count must be >= 1") }
        let line = u ? phrase!.uppercased() : l ? phrase!.lowercased() : phrase!
        for _ in 1...count { print(line) }
        return []
    }
}
```

</details>

<details>
<summary>Command Calls</summary>

```
> print-s1 --count=2 "Hello world!" 
Hello world!
Hello world!

> print-s1 -lu "Hello world!"
HELLO WORLD!

> print-s1 -ul "Hello world!"
hello world!

> print-s1 -xuxxylzz --count 2.15
Errors:
  unrecognized options: "-x", "-y" and "-z", in "-xuxxylzz"
  missing value: "<phrase>"
  "2.15" is not a valid <int> after --count
See "print-s1 --help" for more information.
```

</details>

---

## Requirements

A struct that defines a CLI by conforming to `CommandNodeDef<StateElement>` must define:
    
* `func run(state: [StateElement]) async throws -> [StateElement]`
* `init()`
* `var configuration: CommandNodeConfig<StateElement>? { get set }`
*  one "valid" stored property for each CLI argument

The struct's `run` method performs program logic and returns an updated state, where state is an instance of `[StateElement]`.

The `init()` requirement forces all of the stored properties to have default values.

The configuration property provides additional information needed to define the CLI. (It is not itself included in the CLI.)

A valid stored property is mutable and has a type allowed for a parameter of
 a [command function](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#command-function).
 
If a stored property's default value is `nil`, its corresponding argument in the CLI is required.

When the `run` is invoked, all of the stored properties, except for `configuration` will have been set from terminal input. 

---

## CommandNodeConfig

An instance of`CommandNodeConfig<StateElement> ` has the following stored properties:

  * commandName: String - name of the program in error screens, help screens, etc.
  * shadowGroups: [String] - names of parameters in shadow groups, the last one encountered in each group is determinative.
  * embellishments: [Embellishment] - alternative label-specs and type names
  * commandSynopsis: String — synopsis of the command
  * children: [CommandNode<StateElement>] - children of the struct's command node
  
---

## Examples

[Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git) has extensive examples
that show how to use `CmdArgLibProtocols`.

---

### Project Status

This software is licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

It is currently in beta (version 0.5.2).
