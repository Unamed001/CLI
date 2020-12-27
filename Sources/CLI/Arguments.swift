//
//  Arguments.swift
//  
//
//  Created by MK_Dev on 26.12.20.
//

import Foundation

//
// !! To be removed !!
//

@available(*, deprecated, message: "Use InputType instead (API not compatabile).")
public protocol Argument: CustomStringConvertible, CustomExportStringConvertible {
    var id: String { get set }
    func evaluate(_ ctx: inout Array<String>, _ vars: inout Dictionary<String, Any>) throws
}

@available(*, deprecated, message: "Use InputType instead (API not compatabile).")
public class TypedArgument: Argument {
    public var id: String
    public var type: InputType
   
    @available(*, deprecated, message: "Use init(_,_) instead.")
    public convenience init(_ id: String, type: InputType) {
        self.init(id, type)
    }
    
    public init(_ id: String, _ type: InputType) {
        self.id = id
        self.type = type
    }
    
    public func evaluate(_ ctx: inout Array<String>, _ vars: inout Dictionary<String, Any>) throws {
        vars[self.id] = try self.type.parser(&ctx)
    }
    
    public var description: String {
        return "TypedArgument<\(self.id): \(self.type)>"
    }
    
    public var exportDescription: String {
        return "<\(id)>"
    }
}

@available(*, deprecated, message: "Use InputType instead (API not compatabile).")
public class OptionalArgument: Argument {
    
    public var id: String
    public var argument: Argument
    public var defaultValue: Any
    
    public init(_ argument: Argument, _ defaultValue: Any) {
        self.argument = argument
        self.defaultValue = defaultValue
        self.id = self.argument.id
    }
    
    public func evaluate(_ ctx: inout Array<String>, _ vars: inout Dictionary<String, Any>) throws {
        do {
            try self.argument.evaluate(&ctx, &vars)
        } catch InputType.Errors.missingArguments {
            vars[self.id] = self.defaultValue
        } catch {
            throw error
        }
    }
    
    public var description: String {
        return "OptionalArgument<\(self.argument.description)>"
    }
    
    public var exportDescription: String {
        return self.argument.exportDescription + "?"
    }
}

@available(*, deprecated, message: "Use InputType instead (API not compatabile).")
public class SequenceArgument: Argument {
    public var id: String
    public var type: InputType
    
    public init(_ id: String, _ type: InputType) {
        self.id = id
        self.type = type
    }
    
    public func evaluate(_ ctx: inout Array<String>, _ vars: inout Dictionary<String, Any>) throws {
        var array = Array<Any>()
        while !ctx.isEmpty {
            array.append(try self.type.parser(&ctx))
        }
        vars[self.id] = array
    }
    
    public var description: String {
        return "SequenceArgument<\(self.id): \(self.type)>"
    }
    
    public var exportDescription: String {
        return "<\(self.id)...>"
    }
}

@available(*, deprecated, message: "Use InputType instead (API not compatabile).")
public class TupelArgument: Argument {
    
    public var id: String = ""
    public var lhs: TypedArgument
    public var rhs: TypedArgument
    
    public init(_ lhs: TypedArgument, _ rhs: TypedArgument) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    public func evaluate(_ ctx: inout [String], _ vars: inout [String : Any]) throws {
        try self.lhs.evaluate(&ctx, &vars)
        try self.rhs.evaluate(&ctx, &vars)
    }
    
    public var description: String {
        return "TupelArgument<\(self.rhs.description) | \(self.lhs.description)>"
    }
    
    public var exportDescription: String {
        return lhs.description + " " + rhs.description
    }
}
