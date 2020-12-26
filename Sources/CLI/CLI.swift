//
// Command.swift
//
//
// Created by MK_Dev on 29.12.20
//

import Foundation

//
// Current Version: 3
//

open class Command: CustomStringConvertible, CustomExportStringConvertible {
    
    //
    // == External errors ==
    //
    // External errros are errors that may need a special handeling to
    // e.g. correct small spelling mistakes or to provied a dynamic help message.
    //
    
    /// CLI parsing erros that can be handeled by the user.
    enum Errors: Error {
        case unknownOption(String, [String])
        case missingRequiredOption(Option)
        case missingAnyArgument
    }
    
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
    
    /// An argument expected by the command (not dash-prefixed).
    private var argument: Argument?
    
    /// A callback function to handled execution of this particular command.
    private var callback: (([String:Any]) -> Void)?
    
    /// A collection of avaiable subcommands.
    private var subcommands: Array<Command> = []
    
    /// A map of all options and arguments read from the raw command line arguments.
    private var vars: Dictionary<String, Any> = [:]
    
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
        // Add argument to description if existens
        if let argument = self.argument {
            str.append(" > \(argument.description)")
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
        return "\(self.completeName) [-\(optionsShort)] \(subcommandsShort)\(self.argument?.exportDescription ?? "")"
        
    }
    
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
        assert((parent != nil) ==> (parent?.argument == nil))
        
        self.names = commands
        self.parent = parent
        self.options = [ .init("-h", "--help", helpText: "Shows this help text") ]
        self.parent?.subcommands.append(self)
    }
    
    /// Creates a new command with the given names, description (and parent).
    public init(_ commands: String..., description: String, parent: Command? = nil) {
        assert(!commands.isEmpty)
        assert((parent != nil) ==> (parent?.argument == nil))
        
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
    public func set(_ argument: Argument) {
        assert(self.subcommands.isEmpty)
        self.argument = argument
    }
    
    /// Defines a general purpose callback function for the command.
    public func exec(_ callback: @escaping ([String:Any]) -> Void) {
        self.callback = callback
    }
    
    /// Evaluates some given arguments and pipes the result and errors into a specific callback function(not general purpose).
    public func evaluate(_ args: [String],_ callback: @escaping ([String:Any], Error?) -> Void) {
        do {
            try self.evaluate(args, { (vars) -> Void in
                callback(vars, nil)
            })
        } catch {
            callback([:], error)
        }
    }
    
    /// Evaluates some given arguments and pipes the result into a specific callback function(not general purpose).
    public func evaluate(_ args: [String], _ callback: @escaping ([String:Any]) -> Void) throws {
        self.exec(callback)
        try self.evaluate(args)
    }
    
    /// Evaluates some given arguments and pipes the results into the general purpose callback function
    public func evaluate(_ args: [String]) throws {
        
        // Resets the parsed variables on a new parse cycle
        self.vars = [:]
        
        // Stores the raw arguments in a mutable buffer
        var ctx = args
        
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
            try option!.evaluate(&ctx, vars: &self.vars)
        }
        
        // If a help flag was found terminate parsing and return the help message
        if (vars["help"] as! Bool) {
            print(self.helpMessage)
            return
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
                subcommand.vars = self.vars
                try subcommand.evaluate(ctx)
                return
            }
        }
        
        // Parse the argument if one is specified
        if let argument = argument {
            try argument.evaluate(&ctx, &vars)
            
            // Parse options after argument (else there sould be none) (as in first round)
            while ctx.count != 0 && ctx.first!.hasPrefix("-") {
                let option = options.first { (op) -> Bool in
                    return op.matches(ctx)
                }
                guard option != nil else {
                    throw Errors.unknownOption(ctx[0], ctx)
                }
                
                ctx.removeFirst()
                try option?.evaluate(&ctx, vars: &self.vars)
            }
        }
        
        // Call callback if possible or print the help message
        if let callback = self.callback {
            callback(vars)
        } else {
            print(self.helpMessage)
        }
    }
}


