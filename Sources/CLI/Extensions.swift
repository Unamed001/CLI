//
//  Extensions.swift
//  
//
//  Created by MK_Dev on 26.12.20.
//

import Foundation

/// This extension provieds colored string for the command line interface.
extension String {
    
    /// This type defines the apperance of the formated string on the command line.
    public enum FormatType: String {
        case regular = "0;"
        case bold = "1;"
        case underline = "4;"
        case background = ""
        case reset = "0"
    }
    
    // This type defines the color of the formated strinf on the command line.
    public enum FormatColors: String {
        // Supports standart ANSI bash-colors
        case black = "30"
        case red = "31"
        case green = "32"
        case yellow = "33"
        case blue = "34"
        case purple = "35"
        case cyan = "36"
        case white = "37"
        case noColor = "39"
        
        // Supports the intense bash-colors as well
        case intenseBlack = "90"
        case intenseRed = "91"
        case intenseGreen = "92"
        case intenseYellow = "93"
        case intenseBlue = "94"
        case intensePurple = "95"
        case intenseCyan = "96"
        case intenseWhite = "97"
        
        // Does support colore resets
        case reset = ""
        
        // Does not suuport intense bash-background-colors (100-107)
    }
    
    /// Formates this string according to the given transforms.
    /// Formatting is suppressed in DEBUG-XCode-Console mode.
    public func formated(_ type: FormatType = .reset, _ color: FormatColors = .reset) -> String {
        #if DEBUG
        if isTerminal() {
            return "\u{001B}[\(type.rawValue)\(color.rawValue))m\(self)\u{001B}[0;39m"
        } else {
            return self
        }
        #else
        return "\u{001B}[\(type.rawValue))\(color.rawValue))m\(self)\u{001B}[0;39m"
        #endif
    }
}

/// A function that indicates if the current execution enviroment is a terminal enviroment or XCode's console.
public func isTerminal() -> Bool {
    var w = winsize()
    _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
    let isT = !(w.ws_col==0&&w.ws_row==0&&w.ws_xpixel==0&&w.ws_ypixel==0)
    return isT
}

/// A handler to inject shell commands into a bash process.
@discardableResult
public func shell(_ command: String...) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c"] + command
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    
    return output
}

/// A type with a command line compatabile textual representation.
@available(*, introduced: 3.0)
public protocol CustomExportStringConvertible{
    /// Defines a string for export to the command line.
    @available(*, introduced: 3)
    var exportDescription: String { get }
}

/// A functions that returns a securely read passphrase from stdin.
@available(*, introduced: 3)
public func readPassphrase(_ prefix: String) -> String? {
    let buffer = Array<Int8>(repeating: 0, count: 1024)
    guard let phrase = readpassphrase(prefix, (UnsafeMutablePointer<Int8>)(mutating: buffer), buffer.count, 0) else {
        return nil
    }
    return String.init(validatingUTF8: phrase)
}


/// Boolean implies operator.
@available(*, introduced: 3)
infix operator ==>: AdditionPrecedence
public func ==>(_ lhs: Bool, _ rhs: Bool) -> Bool {
    return !lhs || (lhs && rhs)
}

/// Boolean implies operator.
@available(*, introduced: 3)
infix operator <==: AdditionPrecedence
public func <==(_ lhs: Bool, _ rhs: Bool) -> Bool {
    return rhs ==> lhs
}
