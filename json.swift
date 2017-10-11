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
    var index = input.startIndex
    if !isDigit(value: input[input.startIndex]) {
        return nil
    }
    while isDigit(value: input[index]) {
        index = input.index(after: index)
    }
    return (input[..<index],input[index...])
}

func exponentParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        var output = ""
        output.append(String(input[input.startIndex]))
        var rest = input[input.index(after: input.startIndex)...]
        if rest.hasPrefix("+") || rest.hasPrefix("-") {
            output.append(rest[rest.startIndex])
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
    return (Double(number)!, rest)
}

func intFloatParser (input: Substring) -> ParseResult {
    if input.hasPrefix("0") || !isDigit(value: input[input.startIndex]) {
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
    return (Double(number)!, rest)
}


func commaParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "," {
        return nil
    }
    return (",", input[input.index(after: input.startIndex)...])
}


func colonParser (input: Substring) -> ParseResult {
    if input[input.startIndex] != ":" {
        return nil
    }
    var index = input.startIndex
    while input[index] == ":" {
        index = input.index(after: index)
    }
    return (":", input[index...])
}


func isSpace(space: Character) -> Bool {
    switch space {
    case " ", "\t", "\n", "\r": return true
    default: return false
    }
}


func spaceParser (input: Substring) -> ParseResult {
    if !isSpace(space: input[input.startIndex]) {
        return nil
    }
    var index = input.startIndex
    while isSpace(space: input[index]) {
        index = input.index(after: index)
    }
    return(input[..<index], input[index...])
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
    if input[...input.index(input.startIndex, offsetBy: 3)] == "null" {
        return (Null(), input[input.index(input.startIndex, offsetBy: 4)...])
    }
    return nil
}


func boolParser (input: Substring) -> ParseResult {
    if input.count < 5 {
        return nil
    }
    if input[...input.index(input.startIndex, offsetBy: 3)] == "true" {
        return(true, input[input.index(input.startIndex, offsetBy: 4)...])
    }
    if input[...input.index(input.startIndex, offsetBy: 4)] == "false" {
        return(false, input[input.index(input.startIndex, offsetBy: 5)...])
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
    var isEscape = false
    var index = input.index(after: input.startIndex)
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
    return (input[input.index(after: input.startIndex)..<index], input[input.index(after: index)...])
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
