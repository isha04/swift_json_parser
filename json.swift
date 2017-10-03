import Cocoa

let path = "/Users/mbp13/Documents/Swift/document1.txt"
let fileContents = try? String(contentsOfFile: path, encoding:String.Encoding.utf8)
var file = fileContents!

//Null Parse
func nullParser (input:String) -> (output: AnyObject?, remaining: String)? {
    var output: AnyObject?
    
    if input.characters.count < 4 {
        return nil
    }
    let value = input[Range(uncheckedBounds: (lower: (input.startIndex), upper: (input.index((input.startIndex),offsetBy: 4))))]
    if value != "null" {
        return nil
    }
    
    output = nil
    let remaining = input[Range(uncheckedBounds: (lower: (input.index((file.startIndex),offsetBy: 4)), upper: (input.endIndex)))]
    
    return(output, remaining)
}

//nullParse(input:file)

func boolParser (input: String) -> (output: Bool, remaining: String)? {
    
    if input.characters.count < 5 {
        return nil
    }
    
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

//isNumber(input: file)

func isNumber(value: Character) -> Bool {
    if value >= "0" && value <= "9" {
        return true
    }
    return false
}

//isNumber(value: file[file.startIndex])

//Digit Parser

func digitParser (input: String) -> (output: String, remaining: String)? {
    
    var c = input[input.startIndex]
    
    if isNumber(value: c) == false {
        return nil
    }
    
    var remaining = input
    var number = ""
    
    while isNumber(value: c) {
        number = number + String(c)
        remaining.remove(at: remaining.startIndex)
        c = remaining[remaining.startIndex]
    }
    
    return (number, remaining)
}

//expoential Parser

func exponentParser (input: String) -> (output: String, remaining: String)? {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        
        var remaining = input
        var output = String(remaining[remaining.startIndex])
        remaining.remove(at: remaining.startIndex)
        
        if remaining.hasPrefix("+") == true || remaining.hasPrefix("-") == true {
            output = output + String(remaining[remaining.startIndex])
            remaining.remove(at: remaining.startIndex)
        }
        
        if let result = digitParser(input: remaining) {
            output = output + result.output
            remaining = result.remaining
        }
        
        return (output, remaining)
        
    }
    return nil
}

//Fraction Parser - will handle input such as 0.89

func fractionParser(input: String) -> (output: String, remaining: String)? {
    
    if input[input.startIndex] == "." {
        
        var remaining = input
        remaining.remove(at: remaining.startIndex)
        var output = "."
        
        if let result = digitParser(input: remaining) {
            output = output + result.output
            remaining = result.remaining
        }
        
        return (output, remaining)
    }
    
    return nil
    
}

////zeroParser

func zeroParser(input: String) -> (output: Double, remaining: String)? {
    
    var remaining = input
    if remaining[remaining.startIndex] != "0" {
        return nil
    }
    
    var number = "0"
    remaining = input[Range(uncheckedBounds: (lower: (input.index((input.startIndex),offsetBy: 1)), upper: (input.endIndex)))]
    
    if let result = fractionParser(input: remaining) {
        number = number + result.output
        remaining = result.remaining
    }
    
    if let result = exponentParser(input: remaining) {
        number = number + result.output
        remaining = result.remaining
    }
    
    let output = Double(number)!
    return (output, remaining)
    
}

//zeroParser(input: file)

//Integer + Float Parser

func intFloatParser (input: String) -> (output: Double, remaining: String)? {
    if input[input.startIndex] == "0" || isNumber(value: input[input.startIndex]) == false {
        return nil
    }
    
    var remaining = input
    var number = ""
    
    if let result = digitParser(input: remaining) {
        remaining = result.remaining
        number = number + result.output
        
        if let fraction = fractionParser(input: remaining) {
            remaining = fraction.remaining
            number = number + fraction.output
        }
        
        if let result = exponentParser(input: remaining) {
            number = number + result.output
            remaining = result.remaining
        }
        
    }
    
    let output = Double(number)!
    return (output, remaining)
}

//print(intFloatParser(input: file)?.output as Any)

func jsonNumberParser (input: String) -> (output: Double, remaining: String)? {
    
    var remaining = input
    
    var minusFlag = 1
    if remaining[remaining.startIndex] == "-" {
        minusFlag = -1
        remaining.remove(at: remaining.startIndex)
    }
    
    if isNumber(value: remaining[remaining.startIndex]) == false {
        return nil
    }
    
    var output = Double()
    
    if let result = zeroParser(input: remaining) {
        output = result.output
        remaining = result.remaining
    }
    
    if let result = intFloatParser(input: remaining) {
        output = result.output
        remaining = result.remaining
        
    }
    output = output * Double(minusFlag)
    
    return(output, remaining)
    
}

jsonNumberParser(input: file)


//String Parser. Takes the remaining variable from int parser

func stringParser (input:String) -> (output: String, remaining: String)? {
    var remaining = input
    if input[input.startIndex] != "\"" {
        return nil
    }
    
    var isEscape = false
    remaining.remove(at: remaining.startIndex)
    var output = ""
    while remaining[remaining.startIndex] != "\"" && isEscape == false {
        var m = remaining[remaining.startIndex]
        if String(m) == "\\" && remaining[remaining.index (remaining.startIndex, offsetBy: 1)] == "\"" {
            isEscape = true
        } else {
            remaining.remove(at: remaining.startIndex)
            output = output + String(m)
        }
        
        if isEscape == true {
            output = output + "\\" + "\""
            remaining.remove(at: remaining.startIndex)
            remaining.remove(at: remaining.startIndex)
            m = remaining[remaining.startIndex]
            isEscape = false
        }
    }
    
    remaining.remove(at: remaining.startIndex)
    return(output, remaining)
}


//Comma parser
func commaParser(input: String) -> (output: String, remaining: String)? {
    var remaining = input
    if remaining[remaining.startIndex] != "," {
        return nil
    }
    
    remaining.remove(at: input.startIndex)
    return (",", remaining)
}


//Value Parser

func valueParser (input: String) -> (output: Any, remaining: String)? {
    
    if let result = boolParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = jsonNumberParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = stringParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = nullParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = arrayParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    
    if let result = objectParser (input: input) {
        return (result.output as Any, result.remaining)
    }
    return nil
}


//valueParser(input: file)


//Colon Parser

func colonParser (input: String) -> (output: String, remaining: String)? {
    var remaining = input
    var m = remaining[remaining.startIndex]
    
    if m != ":" {
        return nil
    }
    
    while m == ":" {
        remaining.remove(at: remaining.startIndex)
        m = remaining[remaining.startIndex]
    }
    
    return (":", remaining)
}
//Colon_Parse(input: file)


//Space Parser

func isSpace(space: Character) -> Bool {
    switch space {
    case " ", "\t", "\n": return true
    default: return false
    }
}

//isSpace(space: file[file.startIndex])

func spaceParser (input: String) -> (output: String, remaining: String)? {
    var remaining = input
    var m = remaining[remaining.startIndex]
    var output = ""
    
    var has_space = isSpace(space: m)
    
    if has_space == false {
        return nil
    }
    
    while has_space == true {
        output = output + String(m)
        remaining.remove(at: remaining.startIndex)
        m = remaining[remaining.startIndex]
        has_space = isSpace(space: m)
    }
    return(output, remaining)
}

//Space_Parser(input: file)


//Parser

func arrayParser (input: String) -> (output: [Any], remaining: String)? {
    if input[input.startIndex] != "[" {
        return nil
    }
    
    var remaining = input
    var output = [Any]()
    
    remaining.remove(at: remaining.startIndex)
    
    while remaining[remaining.startIndex] != "]" {
        
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = valueParser (input: remaining) {
            output.append(result.output)
            remaining = result.remaining
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = commaParser (input: remaining) {
            remaining = result.remaining
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
    }
    
    remaining.remove(at: remaining.startIndex)
    return(output, remaining)
}



//Object Parser

func objectParser (input: String) -> (output: [String : Any], remaining: String)? {
    
    if input[input.startIndex] != "{" {
        return nil
    }
    
    var key = ""
    var value: Any?
    var output = [String: Any]()
    var remaining = input
    
    remaining.remove(at: remaining.startIndex)
    
    while remaining[remaining.startIndex] != "}" {
        //print(key,value as Any)
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = stringParser(input: remaining) {
            key = result.output
            remaining = result.remaining
            if key.isEmpty {
                key = "empty_key"
            }
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = colonParser (input: remaining) {
            remaining = result.remaining
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = valueParser(input: remaining) {
            value = result.output
            remaining = result.remaining
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = commaParser(input: remaining) {
            remaining = result.remaining
        }
        
        if let result = spaceParser(input: remaining) {
            remaining = result.remaining
        }
        
        output[key] = value
    }
    
    remaining.remove(at: remaining.startIndex)
    
    return (output, remaining)
    
}

func jsonParser (input: String) -> (output: Any, remaining: String)? {
    
    if let result = arrayParser(input: input) {
        return (result.output, result.remaining)
    }
    
    if let result = objectParser(input: input) {
        return (result.output, result.remaining)
    }
    
    return nil
}

print(jsonParser(input: file)?.output as Any)


//func JSONStringify(value: Any,prettyPrinted:Bool = false) -> String{
//
//    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
//
//
//    if JSONSerialization.isValidJSONObject(value) {
//
//        do{
//            let data = try JSONSerialization.data(withJSONObject: value, options: options)
//            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
//                return string as String
//            }
//        }catch {
//
//            print("error")
//            //Access error here
//        }
//
//    }
//    return ""
//
//}
//
//let jsonStringPretty = JSONStringify(value: (objectParser(input: file)?.output) as Any, prettyPrinted: false)
//
//print(jsonStringPretty)
