//
//  CLI.swift
//
//  Created by MK_Dev on 26.12.20.
//  Last modified on 27.12.20
//

import Foundation

open class Command: CustomStringConvertible, CustomExportStringConvertible {
    
    // MARK: - External Error Handling
    
    //
    // == External errors ==
    //
    // External errros are errors that may need a special handeling to
    // e.g. correct small spelling mistakes or to provied a dynamic help message.
    //
    
    /// CLI parsing erros that can be handeled by the user.
    public enum Errors: Error {
        case unknownOption(String, [String])
        case missingRequiredOption(Option)
        case optionParsingError(Option, Error)
        case argumentParsingError(Error)
    }
    
    //
    // == Error Handlers ==
    //
    // The command class supplies a function to  handle errors thrown in
    // the prasing process.
    //
    
    /// Handles errors emitted from command line parsing
    public func handleError(_ error: Error) {
        // Define common prefix
        let prefix = self.completeName + ": " + "Error".formated(.bold, .red)
        
        if let error = error as? Command.Errors {
            switch error {
                
            // Catch error if a required option is missing
            case .missingRequiredOption(let option):
                print(prefix + " Missing required option \((option.id + ":" + (option.type?.exportDescription ?? "flag")).formated(.underline, .noColor))")
                break
                
            // Catch errors on unkown options detecttion
            case .unknownOption(let opt, let rem):
                print(prefix + " Unkown option token '\(opt)' in (\(rem.joined(separator: " ")))")
                break
                
            // Catch errors thrown in the option parsing phase
            case .optionParsingError(let option, let error):
                if let error = error as? InputType.Errors {
                    switch error {
                    case .unkownChoiceDescriptior(let ch, let choices):
                        print(prefix + " Unkown choice '\(ch)' at option '\(option.id)'. Use '\(choices.joined(separator: " | "))'")
                        break
                    case .missingArguments:
                        print(prefix + " Missing argument at option '\(option.id)'")
                        break
                    case .invalidStringFormat:
                        print(prefix + " Invalid string format at option '\(option.id)'")
                        break
                    case .parsingError:
                        print(prefix + " Parsing error at option '\(option.id)'")
                        break
                    }
                } else {
                    print(prefix + "\n" + error.localizedDescription)
                }
                break
                
            // Catch errors thrown in the argument parsing phase
            case .argumentParsingError(let error):
                if let error = error as? InputType.Errors {
                    switch error {
                    case .unkownChoiceDescriptior(let ch, let choices):
                        print(prefix + " Unkown choice '\(ch)' at argument '\(self.argumentName!)'. Use '\(choices.joined(separator: " | "))'")
                        break
                    case .missingArguments:
                        print(prefix + " Missing argument at argument '\(self.argumentName!)'")
                        break
                    case .invalidStringFormat:
                        print(prefix + " Invalid string format at argument '\(self.argumentName!)'")
                        break
                    case .parsingError:
                        print(prefix + " Parsing error at argument '\(self.argumentName!)'")
                        break
                    }
                } else {
                    print(prefix + "\n" + error.localizedDescription)
                }
                break
            }
        } else {
            print(prefix + "\n" + error.localizedDescription)
        }
    }
    
    // MARK: - Properties
    
    //
    // == Identification ==
    //
    // A command can either be a top-level command that accepts all parameters given to the executable
    // or a subcommand of another command in a tree-like structure.
    //
    // A command is identified by his first name, but can posses some aliases.
    // The defined names only have an effect is the command is a subcommand because the top-level
    // command just uses the executables name as callname.
    //
    // Note: The name is still used in creating the help message
    //
    
    /// A link to the parent command (if existent).
    private var parent: Command?
    
    /// A list of callnames for the given command.
    public private(set) var names: Array<String>
    
    /// A short description of the commands effects.
    public private(set) var commandDescription: String?
    
    //
    // == Structure ==
    //
    // A command consists of options, and argument (optional),
    // subcommands and a callback function.
    //
    // There are n classes of commands:
    // - Endpoints accept an argument, but thus cannot accept subcommands
    // - Intermediates can accept subcommands, but thus not an argument
    // - Calls have neither subcommands, nor arguments
    //
    
    /// A collection of all possible (dash-prefixed) command line options.
    private var options: Array<Option>
    
    /// The name of the argument expected by the command.
    private var argumentName: String?
    
    /// The type of the argument expected by the command.
    private var argumentType: InputType?
    
    /// A callback function to handled execution of this particular command.
    private var callback: (([String:Any]) -> Void)?
    
    /// A collection of avaiable subcommands.
    private var subcommands: Array<Command> = []
    
    /// A callname for the command (including parents names).
    internal var completeName: String {
        return "\((self.parent == nil) ? "" : "\(self.parent!.completeName) ")\(self.names[0])"
    }
    
    /// A help message constructed from the commands requirements
    public var helpMessage: String {
        return self.exportDescription
    }
    
    //
    // == Exported Desciptions ==
    //
    // 'desciption' - provides a full debug description of the internal type
    // 'exportDescription' - provides a command line ready description (aka. help message) of the command
    //
    
    public var description: String {
        var str = Array<String>()
        // Collect all subcommands for description
        self.subcommands.forEach { (command) in
            str.append(" + Command<\(command.names.joined(separator: " | "))>")
        }
        // Collect all options for descriptiom
        self.options.forEach { (option) in
            str.append(" - \(option.description)")
        }
        
        if let argumentName = self.argumentName, let argumentType = self.argumentType {
            str.append(" > Argument<\(argumentName): \(argumentType)>")
        }
        
        return "Command<\(self.completeName)> {\n\(str.joined(separator: "\n"))\n}"
    }
    
    public var exportDescription: String {
        var str = ""
        str += "SYNOPSIS:\n"
        str += "\t\(self.synopsis)\n"
        if let commandDescription = self.commandDescription {
            str += "\t=> \(commandDescription)\n"
        }
        str += "\n"
        if !self.subcommands.isEmpty {
            str += "SUBCOMMANDS:\n"
            str += self.subcommands.map({ "\t+ \($0.synopsis)"}).joined(separator: "\n") + "\n"
            str += "\n"
        }
        str += "OPTIONS:\n"
        str += self.options.map({ $0.exportDescription }).joined(separator: "\n")
        str += "\n"
        return str
    }
    
    /// A short description of the commands syntax
    private var synopsis: String {
        let optionsShort = self.options.map { $0.identifiers.first!.suffix($0.identifiers.first!.count - 1) }.joined()
        let subcommandsShort = self.subcommands.isEmpty ? "" : "[\(self.subcommands.map { $0.names.first! }.joined(separator: " "))]"
        
        var argumentStr = ""
        if let argumentName = self.argumentName, let argumentType = self.argumentType {
            argumentStr = "<\(argumentName): \(argumentType.exportDescription)>"
        }
        
        return "\(self.completeName) [-\(optionsShort)] \(subcommandsShort)\(argumentStr)"
        
    }
    
    // MARK: - Command construction
    
    //
    // == Command Construction ==
    //
    // A command can allways be altered (e.g. new options added)
    // but a few steps must be done first.
    //
    // When initalizing a command you must define its name and its parent (if existing).
    // This will trigger the command no notify its parent, to be incuded in its parents
    // parsing behaviour.
    //
    // Then options, argument and callbacks can be added.
    //
    
    /// Creates a new command with the given names (and parent).
    public init(_ commands: String..., parent: Command? = nil) {
        assert(!commands.isEmpty)
        assert((parent != nil) ==> (parent?.argumentType == nil && parent?.argumentName == nil))
        
        self.names = commands
        self.parent = parent
        self.options = [ .init("-h", "--help", helpText: "Shows this help text") ]
        self.parent?.subcommands.append(self)
    }
    
    /// Creates a new command with the given names, description (and parent).
    public init(_ commands: String..., description: String, parent: Command? = nil) {
        assert(!commands.isEmpty)
        assert((parent != nil) ==> (parent?.argumentType == nil && parent?.argumentName == nil))
        
        self.names = commands
        self.commandDescription = description
        self.parent = parent
        self.options = [ .init("-h", "--help", helpText: "Shows this help text") ]
        self.parent?.subcommands.append(self)
    }
    
    /// Adds options to the commands parsing behaviour.
    public func add(_ options: Option...) {
        options.forEach { (option) in
            self.options.append(option)
        }
    }
    
    /// Sets the argument (can only be one) of the command.
    @available(*, deprecated, message: "Use set(_,_) instead.")
    public func set(_ argument: Argument) {
        assert(self.subcommands.isEmpty)
        self.argumentName = argument.id
        self.argumentType = argument.type
    }
    
    /// Set the argument (can only be one) of the command.
    public func set(_ argumentName: String, _ argumentType: InputType) {
        assert(self.subcommands.isEmpty)
        self.argumentName = argumentName
        self.argumentType = argumentType
    }
    
    /// Defines a general purpose callback function for the command.
    @available(*, deprecated, renamed: "register")
    public func exec(_ callback: @escaping ([String:Any]) -> Void) {
        self.register(callback: callback)
    }
    
    // Defines a general purpose callback function for the command.
    public func register(callback: @escaping (Dictionary<String,Any>) -> Void) {
        self.callback = callback
    }
    
    // MARK: - Argument evaluation
    
    /// Deprecated
    @available(*, deprecated, message: "Use evaluate(_) instead.")
    public func evaluate(_ args: [String],_ callback: @escaping ([String:Any]) -> Void) throws {
        let vars = try self.eval(args)
        callback(vars)
    }
    
    /// Deprecated
    @available(*, deprecated, renamed: "eval")
    public func evaluate(_ args: Array<String>,_ callback: @escaping (Dictionary<String, Any>, Error?) -> Void) {
        self.eval(args, callback)
    }
    
    /// Evaulates sime given argument and pipes the result into a specfic callback function.
    public func eval(_ args: Array<String>,_ callback: @escaping (Dictionary<String, Any>, Error?) -> Void) {
        do {
            let vars = try self.eval(args)
            callback(vars, nil)
        } catch {
            callback([:], error)
        }
    }
    
    /// Runs the parser for the current command using the 'CommandLine.arguments'.
    @available(OSX 10.10, *)
    public func run() throws {
        var args = CommandLine.arguments
        args.removeFirst()
        try self.run(args)
    }
    
    /// Evaluates some given arguments and pipes the result into the general purpose callback function.
    public func run(_ args: Array<String>) throws {
        var vars = Dictionary<String,Any>()
        guard let result = try self.evaluate(arguments: args, using: &vars) else {
            return
        }
        if let callback = result.callback {
            callback(vars)
        } else {
            print(result.helpMessage)
        }
    }
    
    /// Deprecated
    @available(*, deprecated, renamed: "run")
    public func evaluate(_ args: Array<String>) throws {
        try self.run(args)
    }
    
    /// Evaluates some given arguments and pipes the result into a specific callback function(not general purpose).
    public func eval(_ args: Array<String>) throws -> Dictionary<String, Any>{
        var vars = Dictionary<String,Any>()
        try self.evaluate(arguments: args, using: &vars)
        return vars
    }
    
    /// Evaluates some given arguments and returns the generated parameters or fails.
    @discardableResult
    private func evaluate(arguments: Array<String>, using vars: inout Dictionary<String,Any>) throws -> Command? {
        
        // Stores the raw arguments in a mutable buffer
        var ctx = arguments
        
        // Sets the default values of operations if not allready set (sould not be)
        for option in options {
            if vars[option.id] == nil {
                vars[option.id] = option.defaultValue
            }
        }
        
        // Iterate through raw arguments to parse (dash-prefixed) options as long as possible
        while ctx.count != 0 && ctx.first!.hasPrefix("-") {
            // Find option with matching identifier (else invalid option)
            let option = options.first { (op) -> Bool in
                return op.matches(ctx)
            }
            guard option != nil else {
                throw Errors.unknownOption(ctx[0], ctx)
            }
            
            // Remove call argument and begin handeling option-event
            ctx.removeFirst()
            do {
                try option!.evaluate(&ctx, vars: &vars)
            } catch {
                throw Errors.optionParsingError(option!, error)
            }
        }
        
        // If a help flag was found terminate parsing and return the help message
        if (vars["help"] as! Bool) {
            print(self.helpMessage)
            return nil
        }
        
        // Check if all required options were set
        // Must be done in first options round in case a subcommand is found
        for option in options {
            if option.isRequired && !option.wasSet {
                throw Errors.missingRequiredOption(option)
            }
        }
        
        // Test for subcommand names with current remaing context
        for subcommand in subcommands {
            if subcommand.names.contains(ctx.first ?? "") {
                ctx.removeFirst()
                return try subcommand.evaluate(arguments: ctx, using: &vars)
            }
        }
        
        // Parse the argument if one is specified
        if let argumentName = self.argumentName, let argumentType = self.argumentType {
            vars[argumentName] = try argumentType.parser(&ctx)
        }
        
        // Parse options after argument (else there sould be none) (as in first round)
        while ctx.count != 0 && ctx.first!.hasPrefix("-") {
            let option = options.first { (op) -> Bool in
                return op.matches(ctx)
            }
            guard option != nil else {
                throw Errors.unknownOption(ctx[0], ctx)
            }
            
            // Remove call argument and begin handeling option-event
            ctx.removeFirst()
            do {
                try option!.evaluate(&ctx, vars: &vars)
            } catch {
                throw Errors.optionParsingError(option!, error)
            }
        }
        
        return self
    }
}


