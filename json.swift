//: Playground - noun: a place where people can play

import Cocoa


let path = "/Users/mbp13/Documents/Swift/document.txt"
let fileContents = try? String(contentsOfFile: path, encoding:String.Encoding.utf8)
var file = fileContents!

var test = 00

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
    remaining = input[Range(uncheckedBounds: (lower: (input.index((input.startIndex),offsetBy: 1)), upper: (input.endIndex)))]
    return (",", remaining)
}

//
//
////Space Parser
//func Space_Parse(input: String) -> String? {
//    if input[input.startIndex] != " " {
//        return nil
//    }
//    return " "
//}


//Array Parser

func Array_Parse (input: String) -> (output: [Any], remaining: String)? {
    if input[input.startIndex] != "[" {
        return nil
    }
    
    var remaining = input
    var output = [Any]()
    
    remaining.remove(at: remaining.startIndex)
    
    while remaining[remaining.startIndex] != "]" {
        
        //        if let result = Value_Parse (input: remaining) {
        //            output.append(result.output)
        //            remaining = result.remaining
        //        }
        
        if let result = Int_Parse (input: remaining) {
            output.append(result.output)
            remaining = result.remaining
        }
        
        if let result = String_Parse (input: remaining) {
            output.append(result.output)
            remaining = result.remaining
        }
        
        if let result = Comma_Parse (input: remaining) {
            //output.append(result.output)
            remaining = result.remaining
        }
        
    }
    remaining.remove(at: remaining.startIndex)
    return(output, remaining)
}

Array_Parse(input: file)

//Value Parser

func Value_Parse (input: String) -> (output: Any, remaining: String) {
    var output: Any?
    var remaining = input
    
    if let result = Bool_Parse (input: remaining) {
        output = result.output as Any
        remaining = result.remaining
    }
    
    if let result = Int_Parse (input: remaining) {
        output = result.output
        remaining = result.remaining
    }
    
    if let result = String_Parse (input: remaining) {
        output = result.output
        remaining = result.remaining
    }
    
    if let result = Comma_Parse (input: remaining) {
        output = result.output
        remaining = result.remaining
    }
    
    if let result = Array_Parse (input: remaining) {
        output = result.output
        remaining = result.remaining
    }
    
    return (output as Any, remaining)
}


Value_Parse(input: file)

//Space Parser

func Space_Parse (input: String) -> (output: String, remaining: String)? {
    var m = input[input.startIndex]
    var space = true
    
    switch m {
    case " ", "\t", "\n": space = true
    default: space = false
    }
    
    if  space == false {
        return nil
    }
    
    let remaining = input[Range(uncheckedBounds: (lower: (input.index((input.startIndex),offsetBy: 1)), upper: (input.endIndex)))]
    return(" ", remaining)
}

