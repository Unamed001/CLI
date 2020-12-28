import XCTest
@testable import CLI

final class CLITests: XCTestCase {
    
    func test_command_core() {
        
        let command = Command("test", "test-command", description: "A test command")
        command.add(
            .init("-v", "--verbose", helpText: "help(verbose)"),
            .init("-u", "--unsafe", helpText: "help(unsafe)"),
            .init("cache", [ "-c", "--cache" ], InputType.path, isFlag: false, isRequired: false, defaultValue: "", helpText: "help(cache)")
        )
        
        command.set("files", InputType.sequence(InputType.path))
        
        XCTAssertEqual(command.completeName, "test")
        XCTAssertEqual(command.synopsis, "test [-hvuc] <files: path...>")
        XCTAssertEqual(command.names, [ "test", "test-command" ])
        
        command.eval([ "-c", "./.cache", "--verbose" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["verbose"] as? Bool, true)
            XCTAssertEqual(args["unsafe"] as? Bool, false)
            XCTAssertEqual(args["cache"] as? String, "./.cache")
        }
        
        command.eval([ ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["verbose"] as? Bool, false)
            XCTAssertEqual(args["unsafe"] as? Bool, false)
            XCTAssertEqual(args["cache"] as? String, "")
        }
    }
    
    func test_command_subcommands() {
        
        let parent = Command("parent")
        parent.add(
            .init("-p", "--parent", helpText: "help(parent)")
        )
        
        let child1 = Command("child1", parent: parent)
        child1.add(
            .init("-c1", "--child1", helpText: "help(child1)")
        )
        child1.set("files", InputType.sequence(InputType.path))
        
        let child2 = Command("child2", parent: parent)
        child2.add(
            .init("cache", [ "-c" ], InputType.path, isFlag: false, isRequired: false, defaultValue: "./.cache", helpText: "help(cache)")
        )
        
        XCTAssertEqual(parent.synopsis, "parent [-hp] [child1 child2]")
        XCTAssertEqual(child1.synopsis, "parent child1 [-hpc1] <files: path...>")
        XCTAssertEqual(child2.synopsis, "parent child2 [-hpc] ")
        
        parent.eval([ "--parent", "child1", "-c1" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["parent"] as? Bool, true)
            XCTAssertEqual(args["child1"] as? Bool, true)
        }
        
        parent.eval(["child1", "--child1" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["parent"] as? Bool, false)
            XCTAssertEqual(args["child1"] as? Bool, true)
        }
        
        parent.eval(["child2", "-c", "asd" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["parent"] as? Bool, false)
            XCTAssertEqual(args["cache"] as? String, "asd")
        }
        
        parent.eval([ "-p", "child2" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["parent"] as? Bool, true)
            XCTAssertEqual(args["cache"] as? String, "./.cache")
        }
        
        parent.eval(["child2", "-p" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["parent"] as? Bool, true)
            XCTAssertEqual(args["cache"] as? String, "./.cache")
        }
    }
    
    func test_options_flags() {
        
        let command = CLI.Command("test", description: "")
        
        command.add(
            .init("-ha", helpText: "<>"),
            .init("-geh", helpText: "<>"),
            .init("-g", helpText: "<>"),
            .init( "-c", "--current" , helpText: "<>")
        )
        
        command.eval([ "-ha", "-g" ]) { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["ha"] as? Bool, true)
            XCTAssertEqual(args["geh"] as? Bool, false)
            XCTAssertEqual(args["g"] as? Bool, true)
            XCTAssertEqual(args["current"] as? Bool, false)
        }
        
        command.eval([ "-g", "-geh" ], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["ha"] as? Bool, false)
            XCTAssertEqual(args["geh"] as? Bool, true)
            XCTAssertEqual(args["g"] as? Bool, true)
            XCTAssertEqual(args["current"] as? Bool, false)
        })
        
        command.eval(["-c", "-g"], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["ha"] as? Bool, false)
            XCTAssertEqual(args["geh"] as? Bool, false)
            XCTAssertEqual(args["g"] as? Bool, true)
            XCTAssertEqual(args["current"] as? Bool, true)
        })
        
        command.eval(["--current", "-geh"], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["ha"] as? Bool, false)
            XCTAssertEqual(args["geh"] as? Bool, true)
            XCTAssertEqual(args["g"] as? Bool, false)
            XCTAssertEqual(args["current"] as? Bool, true)
        })
        
        
        command.eval(["--currentt", "-geh"], { (args, error) in
            XCTAssertNotNil(error)
            
            XCTAssertEqual(args["ha"] as? Bool, nil)
            XCTAssertEqual(args["geh"] as? Bool, nil)
            XCTAssertEqual(args["g"] as? Bool, nil)
            XCTAssertEqual(args["current"] as? Bool, nil)
        })
    }
    
    func test_options_parameters() {
        
        let command = Command("test", description: "")
        command.add(
            .init("t1", [ "-t1", "--teh1" ], InputType.string, isFlag: false, isRequired: false, defaultValue: "t1:default", helpText: "<>"),
            .init("t2", [ "-t2", "--teh2" ], InputType.int(10), isFlag: false, isRequired: false, defaultValue: 0, helpText: "<>"),
            .init("t3", [ "-t3" ], InputType.choice([ "a", "b", "c" ]), isFlag: false, isRequired: false, defaultValue: "none", helpText: "<>")
        )
        
        
        command.eval([ "-t1", "t1:value", "-t3", "a" ], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["t1"] as? String, "t1:value")
            XCTAssertEqual(args["t2"] as? Int, 0)
            XCTAssertEqual(args["t3"] as? String, "a")
        })
        
        command.eval([ "--teh2", "123", "-t3", "c"  ], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["t1"] as? String, "t1:default")
            XCTAssertEqual(args["t2"] as? Int, 123)
            XCTAssertEqual(args["t3"] as? String, "c")
        })
        
        command.eval([], { (args, error) in
            XCTAssertNil(error)
            
            XCTAssertEqual(args["t1"] as? String, "t1:default")
            XCTAssertEqual(args["t2"] as? Int, 0)
            XCTAssertEqual(args["t3"] as? String, "none")
        })
        
        command.eval([ "-t1", "asd", "-t2", "asd" ]) { (args, error) in
            XCTAssertNotNil(error)
        }
        
        command.eval([ "-t3", "f", "-t2", "123" ]) { (args, error) in
            XCTAssertNotNil(error)
        }
        
        command.eval([ "-t11", "asd", "-t2", "123" ]) { (args, error) in
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
        
        args = [ "123" ]
        XCTAssertEqual(try? CLI.InputType.optional(InputType.int(10), defaultValue: 42).parser(&args) as? Int, 123)
        XCTAssertEqual(args.first, nil)
        
        XCTAssertEqual(try? CLI.InputType.optional(InputType.int(10), defaultValue: 42).parser(&args) as? Int, 42)
        XCTAssertEqual(args.first, nil)
        
        args = [ "1", "2", "3" ]
        XCTAssertEqual(try? CLI.InputType.sequence(InputType.int(10)).parser(&args) as? Array<Int>, [ 1, 2, 3 ])
        XCTAssertEqual(args.first, nil)
        
    }
    
    static var allTests = [
        ("input_types", test_input_types),
        ("options_flags", test_options_flags),
        ("options_parameters", test_options_parameters),
        ("commands_core", test_command_core),
        ("commands_subcommands", test_command_subcommands),
    ]
}
