//: Playground - noun: a place where people can play

import Cocoa


let path = "/Users/mbp13/Documents/Swift/document.txt"
let fileContents = try? String(contentsOfFile: path, encoding:String.Encoding.utf8)
var file = fileContents!


func Bool_Parse (input: String) -> (output: Bool, remaining: String)? {
    var value = input[Range(uncheckedBounds: (lower: (input.startIndex), upper: (input.index((input.startIndex),offsetBy: 4))))]
    if value == "true" {
        let output = Bool(value)!
        let remaining = input[Range(uncheckedBounds: (lower: (input.index((file.startIndex),offsetBy: 4)), upper: (input.endIndex)))]
        return(output,remaining) as (output: Bool, remaining: String)
    }
    
    value = input[Range(uncheckedBounds: (lower: (input.startIndex), upper: (input.index((input.startIndex),offsetBy: 5))))]
    if value == "false" {
        value = input[Range(uncheckedBounds: (lower: (input.startIndex), upper: (input.index((input.startIndex),offsetBy: 5))))]
        let output = Bool(value)!
        let remaining = input[Range(uncheckedBounds: (lower: (input.index((input.startIndex),offsetBy: 5)), upper: (input.endIndex)))]
        return(output,remaining) as (output: Bool, remaining: String)
    }
    return nil
}


//Integer Parser. Takes the remaining variable from the boolean parser

func Int_Parse (input: String) -> (output: Int, remaining: String)? {
    var c = input[input.startIndex]
    if c < "0" || c > "9" {
        return nil
    }
    
    var remaining = input
    var number = ""
    while c >= "0" && c <= "9" {
        number = number + String(c)
        remaining.remove(at: remaining.startIndex)
        c = remaining[remaining.startIndex]
    }
    
    let output = Int(number)!
    return (output, remaining)
}


//String Parser. Takes the remaining variable from int parser

func String_Parse (input:String) -> (output: String, remaining: String)? {
    var remaining = input
    if input[input.startIndex] != "\"" {
        return nil
    }
    
    remaining.remove(at: remaining.startIndex)
    var output = ""
    while remaining[remaining.startIndex] != "\"" {
        let m = remaining[remaining.startIndex]
        output = output + String(m)
        remaining.remove(at: remaining.startIndex)
    }
    
    remaining.remove(at: remaining.startIndex)
    return(output, remaining)
}


//Comma parser
func Comma_Parse(input: String) -> (output: String, remaining: String)? {
    var remaining = input
    if input[input.startIndex] != "," {
        return nil
    }
    
    remaining.remove(at: input.startIndex)
    return (",", remaining)
}


//Value Parser

func Value_Parse (input: String) -> (output: Any, remaining: String)? {
    //let output: Any?
    let remaining = input
    
    if let result = Bool_Parse (input: remaining) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = Int_Parse (input: remaining) {
        //output = result.output
        //remaining = result.remaining
        return (result.output as Any, result.remaining)
    }
    
    if let result = String_Parse (input: remaining) {
        //output = result.output
        //remaining = result.remaining
        return (result.output as Any, result.remaining)
    }
    
    return nil
}


//Space Parser

func space_parse (input: String) -> (output: String, remaining: String)? {
    var remaining = input
    var m = remaining[remaining.startIndex]
    var output = ""
    
    if m != "\t" || m != "\n" || m != " " {
        return nil
    }
    
    while m == "\t" || m == "\n" || m == " " {
        remaining.remove(at: remaining.startIndex)
        output.append(m)
        m = remaining[remaining.startIndex]
    }
    
    return(output,remaining)
}



space_parse(input: file)


//Colon Parser

func colon_parse (input: String) -> (output: String, remaining: String)? {
    var remaining = input
    var m = remaining[remaining.startIndex]
    
    
    while m == ":" {
        remaining.remove(at: remaining.startIndex)
        m = remaining[remaining.startIndex]
    }
    
    return(":",remaining)
}
colon_parse(input: file)



//Array Parser

func Array_Parse (input: String) -> (output: [Any], remaining: String)? {
    if input[input.startIndex] != "[" {
        return nil
    }
    
    var remaining = input
    var output = [Any]()
    
    remaining.remove(at: remaining.startIndex)
    
    while remaining[remaining.startIndex] != "]" {
        
        if let result = Value_Parse (input: remaining) {
            output.append(result.output)
            remaining = result.remaining
        }
        
        if let result = Comma_Parse (input: remaining) {
            //output.append(result.output)
            remaining = result.remaining
            
        }
        
        if let result = Array_Parse (input: remaining) {
            output.append(result.output)
            remaining = result.remaining
        }
        print(output)
        print(remaining)
    }
    remaining.remove(at: remaining.startIndex)
    return(output, remaining)
}

Array_Parse(input: file)


//Object Parser

func Object_Parse (input: String) -> (output: [String : Any], remaining: String)? {
    
    if input[input.startIndex] != "{" {
        return nil
    }
    
    var key = ""
    var value: Any?
    var output = [String: Any]()
    var remaining = input
    
    remaining.remove(at: remaining.startIndex)
    
    while remaining[remaining.startIndex] != "}" {
        
        //getting key
        if let result = String_Parse(input: remaining) {
            key = result.output
            remaining = result.remaining
        }
        
        //Parsing colon and getting value
        
        if let result = Colon_Parse (input: remaining) {
            remaining = result.remaining
        }
        
        if let result = Value_Parse(input: remaining) {
            value = result.output
            remaining = result.remaining
        }
        
        if let result = Array_Parse(input: remaining) {
            value = result.output
            remaining = result.remaining
        }
        
        output[key] = value
        
        if let result = Comma_Parse(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = Object_Parse(input: remaining) {
            value = result.output
        }
        
        
    }
    
    remaining.remove(at: remaining.startIndex)
    
    return (output, remaining)
    
}


Object_Parse(input: file)


//Stringifying and pretty printing the array output to check if array parser is parsing 2D array correctly

func JSONStringify(value: Any,prettyPrinted:Bool = false) -> String{
    
    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
    
    
    if JSONSerialization.isValidJSONObject(value) {
        
        do{
            let data = try JSONSerialization.data(withJSONObject: value, options: options)
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                return string as String
            }
        }catch {
            
            print("error")
            //Access error here
        }
        
    }
    return ""
    
}


//print(JSONStringify(value: Array_Parse(input: file)?.output as Any))

