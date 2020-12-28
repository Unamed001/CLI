//
//  Options.swift
//
//  Created by MK_Dev on 26.12.20.
//  Last modified on 27.12.20
//

import Foundation

/// Object that defines a (dash-prefixed) option for a CLI argument parser.
open class Option: CustomStringConvertible, CustomExportStringConvertible {
    
    // MARK: - Properties
    
    //
    // == Identification ==
    //
    // An option has a unique call name, that defines the internal name
    // and the representation in debug/help messages.
    //
    // On the other hand it can posses mutiple external names which correspond
    // with it (e.g. -v and --verbose), and thus define the parsing behaviour.
    //
    
    /// Unique identifier that names the options.
    public var id: String
    
    /// External callnames which can trigger a parsing if this option.
    public var identifiers: [String]
    
    /// Indicates if a identifiers is currenly applicable to the next not-parsed raw in the ctx.
    internal func matches(_ ctx: [String]) -> Bool {
        let v = self.identifiers.contains(ctx.first ?? "")
        self.wasSet = self.wasSet || v
        return v
    }
    
    //
    // == Definition Structure ==
    //
    // A options is defined by a few flags and (if needed) some additional parameters.
    //
    // All options need a 'helpMessage' and most a default value (sometimes implicit).
    //
    // The flags 'isFlag' and 'isRequired' define the runtime behaviour of the given option.
    // Note that flags cannot be required (they can only be set, so if you require this operation => same result).
    //
    // Is a option expects parameters that additional parameter 'type' will store the specification.
    //
    
    /// Paramerter that defines the input behaviour of the expected argument.
    public private(set) var type: InputType?
    
    /// Indicator if the option is a flag.
    public private(set) var isFlag: Bool
    
    /// Indicator if the option is required.
    public private(set) var isRequired: Bool
    
    /// Options description that is used to create global help messages.
    public private(set) var helpText: String
    
    // Values that is given should the option not be given in the programm call (nil if invalid).
    internal var defaultValue: Any
    
    // Indicator if the options was set before, to prevent information loss due to muplicalls.
    internal var wasSet: Bool = false
    
    //
    // == Exported Descriptions ==
    //
    // The value 'description' gives a description of the Option for debug purposes.
    // The value 'exportDescription' provides a templated description for usage in a command help message.
    // This means that the entire description is indented one tab.
    //
    
    public var description: String {
        // Collect optional information for debug
        var str = Array<String>()
        // If an argument is expected add it to the debug descripton
        if let type = self.type {
            str.append("\(self.id): \(type.description)")
        }
        // If the defining indicators are set add them to the description
        if self.isFlag  { str.append("flag") }
        if self.isRequired { str.append("required") }
        
        return "Option<\(self.identifiers.joined(separator: ", "))>(\(str.joined(separator: " ")))"
    }
    
    public var exportDescription: String {
        // Create a inented description for usage in commands help messages
        var str = ""
        if let type = self.type {
            str += "\(self.id):\(type.exportDescription)".formated(.underline, .noColor)
        }
        return "\t\(self.identifiers.joined(separator: ", ")) \(str)\n\t\t\(self.helpText)"
    }
    
    // MARK: - Initalizers
    
    //
    // == Initialisation ==
    //
    // There are different constructors to better construct options.
    // E.g. the flag constructor dose not need 'isFlag', 'isRequired' or 'defaultValue'
    // because those are static in the flag constructor.
    //
    
    /// Creates an option object according to the given parameters.
    public init(_ id: String, _ identifiers: Array<String>, _ argument: InputType?, isFlag: Bool, isRequired: Bool, defaultValue: Any, helpText: String) {
        
        assert(isRequired ==> !isFlag)
        assert(isFlag ==> ((defaultValue as? Bool) == false))
        assert(isFlag ==> (argument == nil))
        
        self.id = id
        self.identifiers = identifiers
        self.isFlag = isFlag
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.helpText = helpText
        self.type = argument
    }
    
    /// Creates a flag option using the the long id (prefix-less) as unique id.
    /// Expects dash-prefixed short and double-dash-prefixed long identifier.
    public init(_ shortIdentifier: String, _ longIdentifier: String, helpText: String) {
        assert(shortIdentifier.hasPrefix("-"))
        assert(longIdentifier.hasPrefix("--"))
        
        var id = longIdentifier
        while id.first == "-" { id.removeFirst() }
        
        self.id = id
        self.identifiers = [ shortIdentifier, longIdentifier ]
        self.isFlag = true
        self.isRequired = false
        self.defaultValue = false
        self.helpText = helpText
    }
    
    /// Creates a flag option using the the given id (prefix-less) as unique id.
    /// Expects dash-prefixed short identifier.
    public init(_ shortIdentifier: String, helpText: String) {
        assert(shortIdentifier.hasPrefix("-"))
        
        var id = shortIdentifier
        while id.first == "-" { id.removeFirst() }
        
        self.id = id
        self.identifiers = [ shortIdentifier ]
        self.isFlag = true
        self.defaultValue = false
        self.isRequired = false
        self.helpText = helpText
    }
    
    //
    // == Evaluation ==
    //
    // If the 'evaluate' function is called the options was called through on of
    // its external identifiers.
    //
    // If the option is a flag it is it's state is simply set to true.
    // Should the option no be a flag then it should have a argument ('type')
    // and thus will try to parse the expected value.
    //
    
    // MARK: - Evaluation
    
    /// Applies the defined options behaviour to the current context.
    internal func evaluate(_ ctx: inout [String], vars: inout [String:Any]) throws {
        if isFlag {
            vars[self.id] = true
            return
        }
        guard let type = self.type else { fatalError() }
        vars[self.id] = try type.parser(&ctx)
    }
}
