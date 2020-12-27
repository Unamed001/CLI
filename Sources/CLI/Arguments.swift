//
//  Arguments.swift
//  
//
//  Created by MK_Dev on 26.12.20.
//

import Foundation

//
// == Legacy Support 0.9.1 ==
//
// The Argument protocol and it's implementations will be removed in v.1
// concerning v0.9.1 the argument types will be internally deconstructed to autoparse
// them into the new CLI parsing mechanisms
//


@available(*, deprecated, message: "Use new InputType API instead.")
public protocol Argument{
    var id: String { get set }
    var type: InputType { get set }
}

@available(*, deprecated, message: "Use new InputType API instead.")
public class TypedArgument: Argument {
    
    public var id: String
    public var type: InputType
   
    @available(*, deprecated, message: "Use new InputType API instead.")
    public convenience init(_ id: String, type: InputType) {
        self.init(id, type)
    }
    
    @available(*, deprecated, message: "Use new InputType API instead.")
    public init(_ id: String, _ type: InputType) {
        self.id = id
        self.type = type
    }
}

@available(*, deprecated, message: "Use new InputType API instead.")
public class OptionalArgument: Argument {
    
    public var id: String
    public var type: InputType
    
    @available(*, deprecated, message: "Use new InputType API instead.")
    public init(_ argument: Argument, _ defaultValue: Any) {
        self.id = argument.id
        self.type = InputType.optional(argument.type, defaultValue: defaultValue)
    }
}

@available(*, deprecated, message: "Use new InputType API instead.")
public class SequenceArgument: Argument {
    public var id: String
    public var type: InputType
    
    @available(*, deprecated, message: "Use new InputType API instead.")
    public init(_ id: String, _ type: InputType) {
        self.id = id
        self.type = InputType.sequence(type)
    }
}

@available(*, deprecated, message: "Use new InputType API instead.")
public class TupelArgument: Argument {
    
    public var id: String = ""
    public var type: InputType
    
    @available(*, deprecated, message: "Use new InputType API instead.")
    public init(_ lhs: TypedArgument, _ rhs: TypedArgument) {
        assert(lhs.id == rhs.id)
        self.id = lhs.id
        self.type = InputType({ args -> (Any, Any) in
            let val1 = try lhs.type.parser(&args)
            let val2 = try rhs.type.parser(&args)
            return (val1, val2)
        })
    }
}
