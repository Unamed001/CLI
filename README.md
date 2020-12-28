# CLI - Swift command line argument parser

This swift package contains a CL argument parser with a modern [Swift](https://swift.org) syntax and some other helper functions usefull in developing a Command line programm.

## Installation

### Using Git
```bash
git clone https://github.com/Unamed001/CLI && cd CLI
swift build
```

```swift
// Package.swift
...
dependencies: [
  ...
  .package(path: "path/to/local/copy")
]
...
```

### Using Swift Packages

```swift
// Package.swift
...
dependencies: [
  ...
  .package(url: "https://github.com/Unamed001/CLI", from: Version(0,9,0))
]
...
```

## Usage

### Define CL Options / Arguments on a command object.
```swift
import CLI

let command = Command("myCommand", description: "This is my command, and only mine")
command.add(
  Option.init("-v", "--verbose", helpText: "Gives debug output as well"),
  Option.init("-u", "--unsafe", helpText: "Does something unsafe"),
  Option.init("config", [ "-c", "--cnf" ], InputType.path, isFlag: false, isRequired: false, defaultValue: "~/.myCommand-config", helpText: "Sets the config file")
)
command.set("myParameters", InputType.sequence(InputType.path))
command.register(callback: { args in
  print("Parsed the following arguments:")
  for (key, value) in args {
    print("\(key): \(value)")
  }
})

try! command.run()
```

### Define subcommands to better structure you command line tool

```swift
import CLI

let command = Command("someCmd")
...

let subcommand = Command("test", parent: command)
subcommand.register { args in ... }
...

try! command.run()
```
- Note that options of parent commands are inherited (including the help command defined in the main root)
- Note that CLI provides a function to handle error thrown in the 'eval' or 'run' calls.

### Use specific callback functions
```swift
import CLI

let command = Command("veryGoodCommand", description: "Is very good")
...

var args = CommandLine.arguments
args.removeFirst()
command.evaluate(args) { args, error in
  if let error = error {
    print(error)
  } else {
    print(args)
  }
}
```
- Note that this method does not override the general-purpose callback

## License

CLI is available under the MIT license.

Copyright 2020 Petrichor(https://github.com/Unamed001)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
