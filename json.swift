import Cocoa

let path = "/Users/mbp13/Documents/Swift/document.txt"
let fileContents = try? String(contentsOfFile: path, encoding:String.Encoding.utf8)
var file = fileContents!

//Null Parse
func nullParser (input:String) -> (output: Any?, rest: String)? {
    
    if input.count < 4 {
        return nil
    }
    let value = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if value != "null" {
        return nil
    }
    
    let rest = String(input[input.index(input.startIndex, offsetBy: 4)...])
    
    return(nil, rest)
}

func boolParser (input: String) -> (output: Bool, rest: String)? {
    if input.count < 5 {
        return nil
    }
    
    var value = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if value == "true" {
        let output = Bool(value)!
        let rest = String(input[input.index(input.startIndex, offsetBy: 4)...])
        return(output,rest) as (output: Bool, rest: String)
    }
    
    value = String(input[...input.index(input.startIndex, offsetBy: 4)])
    if value == "false" {
        let output = Bool(value)!
        let rest = String(input[input.index(input.startIndex, offsetBy: 5)...])
        return(output,rest) as (output: Bool, rest: String)
    }
    return nil
}

func isNumber(value: Character) -> Bool {
    if value >= "0" && value <= "9" {
        return true
    }
    return false
}

func digitParser (input: String) -> (output: String, rest: String)? {
    
    var c = input[input.startIndex]
    
    if isNumber(value: c) == false {
        return nil
    }
    
    var rest = input
    var number = ""
    
    while isNumber(value: c) {
        number = number + String(c)
        rest.remove(at: rest.startIndex)
        c = rest[rest.startIndex]
    }
    
    return (number, rest)
}

func exponentParser (input: String) -> (output: String, rest: String)? {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        
        var rest = input
        var output = String(rest[rest.startIndex])
        rest.remove(at: rest.startIndex)
        
        if rest.hasPrefix("+") == true || rest.hasPrefix("-") == true {
            output = output + String(rest[rest.startIndex])
            rest.remove(at: rest.startIndex)
        }
        
        if let result = digitParser(input: rest) {
            output = output + result.output
            rest = result.rest
        }
        
        return (output, rest)
        
    }
    return nil
}

func fractionParser(input: String) -> (output: String, rest: String)? {
    
    if input[input.startIndex] == "." {
        var rest = input
        rest.remove(at: rest.startIndex)
        var output = "."
        
        if let result = digitParser(input: rest) {
            output = output + result.output
            rest = result.rest
        }
        return (output, rest)
    }
    
    return nil
}

func zeroParser(input: String) -> (output: Double, rest: String)? {
    
    var rest = input
    if rest[rest.startIndex] != "0" {
        return nil
    }
    
    var number = "0"
    rest = String(input[input.index(input.startIndex, offsetBy: 1)...])
    
    if let result = fractionParser(input: rest) {
        number = number + result.output
        rest = result.rest
    }
    
    if let result = exponentParser(input: rest) {
        number = number + result.output
        rest = result.rest
    }
    
    let output = Double(number)!
    return (output, rest)
}

func intFloatParser (input: String) -> (output: Double, rest: String)? {
    if input[input.startIndex] == "0" || isNumber(value: input[input.startIndex]) == false {
        return nil
    }
    
    var rest = input
    var number = ""
    
    if let result = digitParser(input: rest) {
        rest = result.rest
        number = number + result.output
        
        if let fraction = fractionParser(input: rest) {
            rest = fraction.rest
            number = number + fraction.output
        }
        
        if let result = exponentParser(input: rest) {
            number = number + result.output
            rest = result.rest
        }
        
    }
    
    let output = Double(number)!
    return (output, rest)
}


func jsonNumberParser (input: String) -> (output: Double, rest: String)? {
    
    var rest = input
    
    var minusFlag = 1
    if rest[rest.startIndex] == "-" {
        minusFlag = -1
        rest.remove(at: rest.startIndex)
    }
    
    if isNumber(value: rest[rest.startIndex]) == false {
        return nil
    }
    
    var output = Double()
    
    if let result = zeroParser(input: rest) {
        output = result.output
        rest = result.rest
    }
    
    if let result = intFloatParser(input: rest) {
        output = result.output
        rest = result.rest
        
    }
    output = output * Double(minusFlag)
    
    return(output, rest)
    
}

func stringParser (input:String) -> (output: String, rest: String)? {
    var rest = input
    if input[input.startIndex] != "\"" {
        return nil
    }
    
    var isEscape = false
    rest.remove(at: rest.startIndex)
    var output = ""
    while rest[rest.startIndex] != "\"" && isEscape == false {
        var m = rest[rest.startIndex]
        if String(m) == "\\" && rest[rest.index (rest.startIndex, offsetBy: 1)] == "\"" {
            isEscape = true
        } else {
            rest.remove(at: rest.startIndex)
            output = output + String(m)
        }
        
        if isEscape == true {
            output = output + "\\" + "\""
            rest.remove(at: rest.startIndex)
            rest.remove(at: rest.startIndex)
            m = rest[rest.startIndex]
            isEscape = false
        }
    }
    
    rest.remove(at: rest.startIndex)
    return(output, rest)
}

func commaParser(input: String) -> (output: String, rest: String)? {
    var rest = input
    if rest[rest.startIndex] != "," {
        return nil
    }
    
    rest.remove(at: input.startIndex)
    return (",", rest)
}

func colonParser (input: String) -> (output: String, rest: String)? {
    var rest = input
    var m = rest[rest.startIndex]
    
    if m != ":" {
        return nil
    }
    
    while m == ":" {
        rest.remove(at: rest.startIndex)
        m = rest[rest.startIndex]
    }
    
    return (":", rest)
}

func isSpace(space: Character) -> Bool {
    switch space {
    case " ", "\t", "\n", "\r": return true
    default: return false
    }
}


func spaceParser (input: String) -> (output: String, rest: String)? {
    var rest = input
    var m = rest[rest.startIndex]
    var output = ""
    
    var has_space = isSpace(space: m)
    
    if has_space == false {
        return nil
    }
    
    while has_space == true {
        output = output + String(m)
        rest.remove(at: rest.startIndex)
        m = rest[rest.startIndex]
        has_space = isSpace(space: m)
    }
    return(output, rest)
}

func arrayParser (input: String) -> (output: [Any], rest: String)? {
    if input[input.startIndex] != "[" {
        return nil
    }
    
    var rest = input
    var output = [Any]()
    
    rest.remove(at: rest.startIndex)
    
    while rest[rest.startIndex] != "]" {
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = valueParser (input: rest) {
            output.append(result.output)
            rest = result.rest
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = commaParser (input: rest) {
            rest = result.rest
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        //print(rest)
    }
    
    rest.remove(at: rest.startIndex)
    return(output, rest)
}


func objectParser (input: String) -> (output: [String : Any], rest: String)? {
    
    if input[input.startIndex] != "{" {
        return nil
    }
    
    var key = ""
    var value: Any?
    var output = [String: Any]()
    var rest = input
    
    rest.remove(at: rest.startIndex)
    
    while rest[rest.startIndex] != "}" {
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = stringParser(input: rest) {
            key = result.output
            rest = result.rest
            if key.isEmpty {
                key = "empty_key"
            }
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = colonParser (input: rest) {
            rest = result.rest
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = valueParser(input: rest) {
            value = result.output
            rest = result.rest
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        if let result = commaParser(input: rest) {
            rest = result.rest
        }
        
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        
        output[key] = value
        //print(key,value as Any)
    }
    
    rest.remove(at: rest.startIndex)
    
    return (output, rest)
    
}

func valueParser (input: String) -> (output: Any, rest: String)? {
    
    if let result = boolParser (input: input) {
        return (result.output as Any, result.rest)
    }
    
    if let result = jsonNumberParser (input: input) {
        return (result.output as Any, result.rest)
    }
    
    if let result = stringParser (input: input) {
        return (result.output as Any, result.rest)
    }
    
    if let result = nullParser (input: input) {
        return (result.output as Any, result.rest)
    }
    
    if let result = arrayParser (input: input) {
        return (result.output as Any, result.rest)
    }
    
    if let result = objectParser (input: input) {
        return (result.output as Any, result.rest)
    }
    return nil
}

func jsonParser (input: String) -> (output: Any, rest: String)? {
    
    if let result = arrayParser(input: input) {
        return (result.output, result.rest)
    }
    
    if let result = objectParser(input: input) {
        return (result.output, result.rest)
    }
    
    return nil
}

print(jsonParser(input: file)?.output as Any)
