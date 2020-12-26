import XCTest
@testable import CLI

final class CLITests: XCTestCase {
    
    func test_options_flags() {
        
        let command = CLI.Command("test", description: "")
        
        command.add(
            .init("-h", helpText: "<>"),
            .init("-geh", helpText: "<>"),
            .init("-g", helpText: "<>"),
            .init( "-c", "--current" , helpText: "<>")
        )
        
        do {
            
            try command.evaluate([ "-h", "-g" ]) { (args) in
                XCTAssertEqual(args["h"] as? Bool, true)
                XCTAssertEqual(args["geh"] as? Bool, false)
                XCTAssertEqual(args["g"] as? Bool, true)
                XCTAssertEqual(args["current"] as? Bool, false)
            }
            
            try command.evaluate([ "-g", "-geh" ], { (args) in
                XCTAssertEqual(args["h"] as? Bool, false)
                XCTAssertEqual(args["geh"] as? Bool, true)
                XCTAssertEqual(args["g"] as? Bool, true)
                XCTAssertEqual(args["current"] as? Bool, false)
            })
            
            try command.evaluate(["-c", "-g"], { (args) in
                XCTAssertEqual(args["h"] as? Bool, false)
                XCTAssertEqual(args["geh"] as? Bool, false)
                XCTAssertEqual(args["g"] as? Bool, true)
                XCTAssertEqual(args["current"] as? Bool, true)
            })
            
            try command.evaluate(["--current", "-geh"], { (args) in
                XCTAssertEqual(args["h"] as? Bool, false)
                XCTAssertEqual(args["geh"] as? Bool, true)
                XCTAssertEqual(args["g"] as? Bool, false)
                XCTAssertEqual(args["current"] as? Bool, true)
            })
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        command.evaluate(["--currentt", "-geh"], { (args, error) in
            XCTAssertEqual(args["h"] as? Bool, nil)
            XCTAssertEqual(args["geh"] as? Bool, nil)
            XCTAssertEqual(args["g"] as? Bool, nil)
            XCTAssertEqual(args["current"] as? Bool, nil)
            XCTAssertNotNil(error)
        })
    }
    
    func test_options_parameters() {
        
        let command = Command("test", description: "")
        command.add(
            .init("t1", [ "-t1", "--teh1" ], InputType.string, isFlag: false, isRequired: false, defaultValue: "t1:default", helpText: "<>"),
            .init("t2", [ "-t2", "--teh2" ], InputType.int(10), isFlag: false, isRequired: false, defaultValue: 0, helpText: "<>"),
            .init("t3", [ "-t3" ], InputType.choice([ "a", "b", "c" ]), isFlag: false, isRequired: false, defaultValue: "none", helpText: "<>")
        )
        
        do {
            
            try command.evaluate([ "-t1", "t1:value", "-t3", "a" ], { (args) in
                XCTAssertEqual(args["t1"] as? String, "t1:value")
                XCTAssertEqual(args["t2"] as? Int, 0)
                XCTAssertEqual(args["t3"] as? String, "a")
            })
            
            try command.evaluate([ "--teh2", "123", "-t3", "c"  ], { (args) in
                XCTAssertEqual(args["t1"] as? String, "t1:default")
                XCTAssertEqual(args["t2"] as? Int, 123)
                XCTAssertEqual(args["t3"] as? String, "c")
            })
            
            try command.evaluate([], { (args) in
                XCTAssertEqual(args["t1"] as? String, "t1:default")
                XCTAssertEqual(args["t2"] as? Int, 0)
                XCTAssertEqual(args["t3"] as? String, "none")
            })
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        command.evaluate([ "-t1", "asd", "-t2", "asd" ]) { (args, error) in
            XCTAssertNotNil(error)
        }
        
        command.evaluate([ "-t3", "f", "-t2", "123" ]) { (args, error) in
            XCTAssertNotNil(error)
        }
        
        command.evaluate([ "-t11", "asd", "-t2", "123" ]) { (args, error) in
            XCTAssertNotNil(error)
        }
        
    }
    
    func test_input_types() {
        
        // Tests statics
        var args: Array<String> = [ "test1", "test2", "test3", "12", "101", "3.14", "ls" ]
        
        XCTAssertEqual(try? CLI.InputType.string.parser(&args) as? String, "test1")
        XCTAssertEqual(args.first, "test2")
        
        XCTAssertEqual(try? CLI.InputType.string.parser(&args) as? String, "test2")
        XCTAssertEqual(args.first, "test3")
        
        XCTAssertEqual(try? CLI.InputType.regex(NSRegularExpression(pattern: "test[0-9]")).parser(&args) as? String, "test3")
        XCTAssertEqual(args.first, "12")
        
        XCTAssertEqual(try? CLI.InputType.int(10).parser(&args) as? Int, 12)
        XCTAssertEqual(args.first, "101")
        
        XCTAssertEqual(try? CLI.InputType.int(2).parser(&args) as? Int, 0b101)
        XCTAssertEqual(args.first, "3.14")
        
        XCTAssertEqual(try? CLI.InputType.float.parser(&args) as? Float, 3.14)
        XCTAssertEqual(args.first, "ls")
        
        XCTAssertNil(try? CLI.InputType.choice(["pwd", "sudo", "cd"]).parser(&args) as? String)
        XCTAssertEqual(args.first, "ls")
        
        XCTAssertEqual(try? CLI.InputType.choice(["pwd", "ls", "cd"]).parser(&args) as? String, "ls")
        XCTAssertEqual(args.first, nil)
        
    }
    
    static var allTests = [
        ("options_flags", test_options_flags),
        ("options_parameters", test_options_parameters),
        ("input_types", test_input_types),
    ]
}
