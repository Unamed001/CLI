//
//  InputTypes.swift
//
//  Created by MK_Dev on 26.12.20.
//  Last modified on 27.12.20
//

import Foundation


/// A object that defines the CLI input behaviour of an internal type.
public class InputType: CustomStringConvertible, CustomExportStringConvertible{
    
    // == Static Definitions ==
    //
    // To provide some predefined parsers static constants are used.
    // Naming does provide compatability with older versions (enum-based)
    // if enum type was explictly stated.
    //
    // To provide more dynamic defintions some static constructure for certain types are given.
    // Namping does provide compatability as well
    //
    
    /// Input type that accepts 32-bit floats in decimal notation.
    public static let float = InputType({ args -> Float in
        // Ensure that there are arguments to be parsed
        guard !args.isEmpty else { throw Errors.missingArguments }
        // Ensure parability by using internal implementation (atof)
        guard let value = Float(args.first!) else { throw Errors.parsingError }
        // Only remove argument once all tests/parses are done
        args.removeFirst()
        return value
    }, "float")
    
    /// Input type that accepts all strings.
    public static let string = InputType({ args -> String in
        // Ensure that there are arguments to be parsed
        guard !args.isEmpty else { throw Errors.missingArguments }
        // Only remove argument once all tests/parses are done
        return args.removeFirst()
    }, "string")
    
    /// Input type that accepts all path like components. Does not check for paths existence.
    public static let path = InputType({ args -> String in
        // Ensure that there are arguments to be parsed
        guard !args.isEmpty else { throw Errors.missingArguments }
        // Only remove argument once all tests/parses are done
        return args.removeFirst()
    }, "path")
    
    /// Input type that accepts all integers in the given radix notation (prefix-less).
    public static func int(_ radix: Int) -> InputType {
        // Create a new input type (not efficient if duplicates are created, but not to important)
        return InputType({ args -> Int in
            // Ensure that there are arguments to be parsed
            guard !args.isEmpty else { throw Errors.missingArguments }
            // Ensure parability by using internal implementation (atoi)
            guard let value = Int(args.first!, radix: radix) else { throw Errors.parsingError }
            // Only remove argument once all tests/parses are done
            args.removeFirst()
            return value
        }, "int")
    }
    
    /// Input type that accepts all strings conforming to the given Regex.
    public static func regex(_ regex: NSRegularExpression) -> InputType {
        // Create a new input type (not efficient if duplicates are created, but not to important)
        return InputType({ args -> String in
            // Ensure that there are arguments to be parsed
            guard !args.isEmpty else { throw Errors.missingArguments }
            // Test if first string conforms to given regex
            let rng = NSRange(location: 0, length: args.first!.utf16.count)
            guard regex.firstMatch(in: args.first!, options: .anchored, range: rng) != nil else {
                throw Errors.invalidStringFormat
            }
            // Only remove argument once all tests/parses are done
            return args.removeFirst()
        }, "string")
    }
    
    /// Input type that accepts only a certain number of input, defined in choices.
    public static func choice(_ choices: Array<String>) -> InputType {
        // Create a new input type (not efficient if duplicates are created, but not to important)
        return InputType({ args -> String in
            // Ensure that there are arguments to be parsed
            guard !args.isEmpty else { throw Errors.missingArguments }
            // Test if string is valid according to choices
            guard choices.contains(args.first!) else {
                throw Errors.unkownChoiceDescriptior
            }
            // Only remove argument once all tests/parses are done
            return args.removeFirst()
        }, "string")
    }
    
    /// Input type that falls back to a return value should no valid input be given.
    public static func optional(_ inputType: InputType, defaultValue: Any) -> InputType {
        return InputType({ args -> Any in
            do {
                return try inputType.parser(&args)
            } catch Errors.missingArguments {
                return defaultValue
            } catch {
                throw error
            }
        }, inputType.externalDescriptor + "?")
    }
    
    /// Input type that accepts mutiple inputs of the same type
    public static func sequence(_ inputType: InputType) -> InputType {
        return InputType({ args -> Any in
            var values = Array<Any>()
            while !args.isEmpty {
                do {
                    values.append(try inputType.parser(&args))
                } catch {
                    break
                }
            }
            return values
        }, inputType.externalDescriptor + "...")
    }
    
    //
    // == Internal error types ==
    //
    // Those errors should be handeled inside the CLI framework
    // and should never reach the user.
    //
    // If such an error should reach the user, it cannot be handeled
    // because those are internal (visibillity) errors.
    //
    
    /// Errors that can occur on InputType.parser calls
    internal enum Errors: Error {
        case missingArguments
        case parsingError
        case invalidStringFormat
        case unkownChoiceDescriptior
    }
    
    //
    // == Parser ==
    //
    // Userdefined (or static) function that parsers the requested value
    // from a stream of command line arguments
    //
    // Can use up mutiple arguments, can throw internal errors.
    // Should remove raw arguments once parsed succesfully.
    //
    
    /// Function that consumes the given input and transforms it into a value as defined by the InputType object.
    internal var parser: (inout Array<String>) throws -> Any
    
    //
    // == Descriptors ==
    //
    // Containers that hold the description of expected type to be parsed.
    // Holds a external name and an internal type signature (only as string to circumvent Generics).
    //
    // The internal type signature is only stored in debug mode, and serves no other
    // purpose than to inform the user(Developer) about the parsers behaviour.
    //
    
    /// Value that holds the external name of the expected type.
    internal var externalDescriptor: String
    
    #if DEBUG
    /// Value that holds the internal type signature of the expected type.
    internal var typeDescriptor: String
    #endif
    
    /// Creates a new input type using a custom parser (and external descriptor).
    init<T>(_ parser: @escaping (inout Array<String>) throws -> T, _ descriptor: String? = nil) {
        self.parser = parser
        self.externalDescriptor = descriptor ?? "\(T.self)"
        #if DEBUG
        self.typeDescriptor = "\(T.self)"
        #endif
    }
    
    //
    // == Exported Descriptions ==
    //
    // description - Internal complete description of the object.
    // exportDescription - Description for export to command line.
    //
    
    public var description: String {
        #if DEBUG
        return "InputType<\(self.externalDescriptor):\(self.typeDescriptor)>"
        #else
        return "InputType<\(self.externalDescriptor)>"
        #endif
        
    }
    
    public var exportDescription: String {
        return self.externalDescriptor
    }
}
