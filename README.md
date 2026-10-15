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

It exports two protocols, `MainFunctionDef` and `CommandNodeDef`, both of which define a `public static async main()` in
a conforming struct. The `main()` function reads and parses command line arguments, assigns the parsed values to stored
property values of an instance of the conforming struct, and calls the instances `run` method.

In addtion, `CommandNodeDef` defines a [`CommandNodes`](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#commandnode) 
also derived from the stored properties of a conforming struct. Command nodes can be used
to construct hierarchical command structures in which state is passed from parent nodes to child nodes.

---

## MainFunctionDef

### Typical Usage

1. Define a struct that conforms to `MainFunctionDef, and annotate it with `@main`.

2. Add one stored variable for each CLI argument.

3. Add an commandNodeAttributes property to provide additional information needed to define the CLI.

4. Add a `run() method that implements program logic.

5. Build and run in the terminal.

---

### Sample

TODO

---


### Requirements

A struct that defines a CLI by conforming to `MainFunctionDef` must define:
    
* `func run()`
* `init()`
* `var commandNodeAttributes: `MainFunctionAttributesConfig`
*  one "valid" stored property for each CLI argument

The struct's `run` method performs program logic.

The configuration property provides additional information needed to define the CLI. (It is not itself included in the CLI.)

A valid stored property is mutable and has a type allowed for a parameter of
 a [command function](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#command-function).
 
If a stored property's default value is `nil`, its corresponding argument in the CLI is required.

When the `run` is invoked, all of the stored properties, except for `commandNodeAttributes` will have been set from terminal input
or from associated default values. 

---

### ManinFunctionConfig

An instance of`CommandNodeAttributes<StateElement> ` has the following stored properties:

  * shadowGroups: [String] - names of parameters in shadow groups, the last one encountered in each group is determinative.
  * typeNames: [ParameterName:TypeName] - type names to use in help screens, etc.
  
---

## CommandNodeDef

### Typical Usage

1. Define a state element type that conforms to Sendable, say `StateElement` (or `Void`)

2. Define a struct that conforms to `CommandNodeDef<StateElement>`, and annotate it with `@main`.

3. Add one stored variable for each CLI argument.

4. Add a configuration property to provide additional information needed to define the CLI.

5. Add a `run(state: [StateElement]) -> [StateElement]` method that implements program logic.

6. Build and run in the terminal.

---

### Sample

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
    var _phrase: String? = nil

    var configuration: CommandNodeAttributes<Void>? = CommandNodeAttributes<Void>(
        commandName: "print-s1",
        shadowGroups: ["u l"],
    )

    func run(state: [Void]) throws -> [Void] {
        guard count >= 1 else { throw Exception.error("count must be >= 1") }
        let line = u ? _phrase!.uppercased() : l ? _phrase!.lowercased() : _phrase!
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

### Requirements

A struct that defines a CLI by conforming to `CommandNodeDef<StateElement>` must define:
    
* `func run(state: [StateElement]) async throws -> [StateElement]`
* `init()`
* `var configuration: CommandNodeAttributes<StateElement>? { get set }`
*  one "valid" stored property for each CLI argument

The struct's `run` method performs program logic and returns an updated state, where state is an instance of `[StateElement]`.

The `init()` requirement forces all of the stored properties to have default values.

The configuration property provides additional information needed to define the CLI. (It is not itself included in the CLI.)

A valid stored property is mutable and has a type allowed for a parameter of
 a [command function](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#command-function).
 
If a stored property's default value is `nil`, its corresponding argument in the CLI is required.

When the `run` is invoked, all of the stored properties, except for `configuration` will have been set from terminal input. 

---

### CommandNodeAttributes

An instance of`CommandNodeAttributes<StateElement> ` has the following stored properties:

  * shadowGroups: [String] - names of parameters in shadow groups, the last one encountered in each group is determinative.
  * typeNames: [ParameterName:TypeName] - type names to use in help screens, etc.
  * commandName: String - name of the program in error screens, help screens, etc.
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
