import Foundation

typealias ParseResult = (output: Any, rest: Substring)?
typealias Parser = (Substring) -> ParseResult

func isDigit(value: Character) -> Bool {
    if value >= "0" && value <= "9" {
        return true
    }
    return false
}

func digitParser (input: Substring) -> ParseResult {
    var c = input[input.startIndex]
    var index = input.startIndex
    if isDigit(value: c) == false {
        return nil
    }
    while isDigit(value: c) {
        index = input.index(after: index)
        c = input[index]
    }
    let output = input[..<index]
    let rest = input[index...]
    return (output,rest)
}


func exponentParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        var output = String(input[input.startIndex])
        var rest = input[input.index(after: input.startIndex)...]
        if rest.hasPrefix("+") == true || rest.hasPrefix("-") == true {
            output = output + String(rest[rest.startIndex])
            rest = rest[rest.index(after: rest.startIndex)...]
        }
        if let result = digitParser(input: rest) {
            output = output + String(describing: result.output)
            rest = result.rest
        }
        return (output, rest)
    }
    return nil
}


func fractionParser(input: Substring) -> ParseResult {
    
    if input[input.startIndex] == "." {
        var rest = input[input.index(after: input.startIndex)...]
        var output = "."
        if let result = digitParser(input: rest) {
            output = output + String(describing: result.output)
            rest = result.rest
        }
        return (output, rest)
    }
    return nil
}


func zeroParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "0" {
        return nil
    }
    var number = "0"
    var rest = input[input.index(after: input.startIndex)...]
    if let result = fractionParser(input: rest) {
        number = number + String(describing: result.output)
        rest = result.rest
    }
    if let result = exponentParser(input: rest) {
        number = number + String(describing: result.output)
        rest = result.rest
    }
    let output = Double(number)!
    return (output, rest)
}

func intFloatParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "0" || isDigit(value: input[input.startIndex]) == false {
        return nil
    }
    var rest = input
    var number = ""
    if let result = digitParser(input: rest) {
        rest = result.rest
        number = number + String(describing: result.output)
        
        if let fraction = fractionParser(input: rest) {
            rest = fraction.rest
            number = number + String(describing: fraction.output)
        }
        if let result = exponentParser(input: rest) {
            number = number + String(describing: result.output)
            rest = result.rest
        }
    }
    let output = Double(number)!
    return (output, rest)
}


func commaParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "," {
        return nil
    }
    let rest = input[input.index(after: input.startIndex)...]
    return (",", rest)
}


func colonParser (input: Substring) -> ParseResult {
    var m = input[input.startIndex]
    if m != ":" {
        return nil
    }
    var index = input.startIndex
    while m == ":" {
        m = input[index]
        index = input.index(after: index)
    }
    let rest = input[index...]
    return (":", rest)
}


func isSpace(space: Character) -> Bool {
    switch space {
    case " ", "\t", "\n", "\r": return true
    default: return false
    }
}


func spaceParser (input: Substring) -> ParseResult {
    var m = input[input.startIndex]
    var has_space = isSpace(space: m)
    if has_space == false {
        return nil
    }
    var index = input.startIndex
    while has_space == true {
        index = input.index(after: index)
        m = input[index]
        has_space = isSpace(space: m)
    }
    let output = input[..<index]
    let rest = input[index...]
    return(output, rest)
}


func factoryParser (parsers: Parser...) -> Parser {
    func newParser(input: Substring) -> ParseResult {
        for parser in parsers {
            if let result = parser(input) {
                return result
            }
        }
        return nil
    }
    return newParser
}


struct Null {}

func nullParser (input: Substring) -> ParseResult {
    if input.count < 4 {
        return nil
    }
    let output = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if output == "null" {
        let rest = input[input.index(input.startIndex, offsetBy: 4)...]
        return (Null(), rest)
    }
    return nil
}


func boolParser (input: Substring) -> ParseResult {
    if input.count < 5 {
        return nil
    }
    var value = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if value == "true" {
        let output = Bool(value)!
        let rest = input[input.index(input.startIndex, offsetBy: 4)...]
        return(output,rest)
    }
    value = String(input[...input.index(input.startIndex, offsetBy: 4)])
    if value == "false" {
        let output = Bool(value)!
        let rest = input[input.index(input.startIndex, offsetBy: 5)...]
        return(output,rest)
    }
    return nil
}


func jsonNumberParser (input: Substring) -> ParseResult {
    var rest = input
    var minusFlag = 1
    if rest[rest.startIndex] == "-" {
        minusFlag = -1
        rest = rest[rest.index(after: rest.startIndex)...]
    }
    if isDigit(value: rest[rest.startIndex]) == false {
        return nil
    }
    var output = Double()
    if let result = zeroParser(input: rest) {
        output = result.output as! Double
        rest = result.rest
    }
    if let result = intFloatParser(input: rest) {
        output = result.output as! Double
        rest = result.rest
    }
    output = output * Double(minusFlag)
    return(output, rest)
}


func stringParser (input: Substring) -> ParseResult {
    if input[input.startIndex] != "\"" {
        return nil
    }
    var index = input.startIndex
    var isEscape = false
    index = input.index(after: index)
    while index != input.endIndex {
        let m = input[index]
        if m == "\"" && isEscape == false {
            break
        }
        if m == "\\" {
            isEscape = true
        } else {
            isEscape = false
        }
        index = input.index(after: index)
    }
    let output = input[input.index(after: input.startIndex)..<index]
    index = input.index(after: index)
    let rest = input[index...]
    return (output, rest)
}


func arrayParser (input: Substring) -> ParseResult {
    if input[input.startIndex] != "[" {
        return nil
    }
    var output = [Any]()
    var rest = input[input.index(after: input.startIndex)...]
    while rest[rest.startIndex] !=   "]" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = valueParser (rest) {
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
    }
    rest = rest[input.index(after: rest.startIndex)...]
    return(output, rest)
}


func objectParser (input: Substring) -> ParseResult {
    if input[input.startIndex] != "{" {
        return nil
    }
    var key = ""
    var value: Any?
    var output = [String: Any]()
    var rest = input[input.index(after: input.startIndex)...]
    while rest[rest.startIndex] != "}" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = stringParser(input: rest) {
            key = String(describing: result.output)
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
        if let result = valueParser(rest) {
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
    }
    rest = rest[input.index(after: rest.startIndex)...]
    return (output, rest)
}

let valueParser = factoryParser(parsers: nullParser, boolParser, jsonNumberParser, stringParser, arrayParser, objectParser)
let jsonParser = factoryParser(parsers: arrayParser, objectParser)

let path = "/Users/mbp13/Documents/Swift/twitter.txt"
let fileContents = (try? String(contentsOfFile: path, encoding:String.Encoding.utf8))!
var file = fileContents[fileContents.startIndex...]
let start = CFAbsoluteTimeGetCurrent()
print(jsonParser(file)?.output as Any)
let end = CFAbsoluteTimeGetCurrent()

print(end - start)
