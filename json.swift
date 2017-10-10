import Foundation

typealias ParseResult = (output: Any, rest: String)?
typealias Parser = (String) -> ParseResult

func isDigit(value: String) -> Bool {
    if value >= "0" && value <= "9" {
        return true
    }
    return false
}

func digitParser (input: String) -> ParseResult {
    var c = input[input.startIndex]
    var index = input.startIndex
    if isDigit(value: String(c)) == false {
        return nil
    }
    while isDigit(value: String(c)) {
        index = input.index(after: index)
        c = input[index]
    }
    let output = input[..<index]
    let rest = String(input[index...])
    return (output,rest)
}

func exponentParser (input: String) -> ParseResult {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        var output = String(input[input.startIndex])
        var rest = String(input[input.index(after: input.startIndex)...])
        if rest.hasPrefix("+") == true || rest.hasPrefix("-") == true {
            output = output + String(rest[rest.startIndex])
            rest = String(rest[rest.index(after: rest.startIndex)...])
        }
        if let result = digitParser(input: rest) {
            output = output + String(describing: result.output)
            rest = result.rest
        }
        return (output, rest)
    }
    return nil
}


func fractionParser(input: String) -> ParseResult {
    
    if input[input.startIndex] == "." {
        var rest = String(input[input.index(after: input.startIndex)...])
        var output = "."
        if let result = digitParser(input: rest) {
            output = output + String(describing: result.output)
            rest = result.rest
        }
        return (output, rest)
    }
    return nil
}

func zeroParser(input: String) -> ParseResult {
    if input[input.startIndex] != "0" {
        return nil
    }
    var number = "0"
    var rest = String(input[input.index(after: input.startIndex)...])
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

func intFloatParser (input: String) -> ParseResult {
    if input[input.startIndex] == "0" || isDigit(value: String(input[input.startIndex])) == false {
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

func commaParser(input: String) -> ParseResult {
    if input[input.startIndex] != "," {
        return nil
    }
    let rest = String(input[input.index(after: input.startIndex)...])
    return (",", rest)
}


func colonParser (input: String) -> ParseResult {
    var m = input[input.startIndex]
    if m != ":" {
        return nil
    }
    var index = input.startIndex
    while m == ":" {
        m = input[index]
        index = input.index(after: index)
    }
    let rest = String(input[index...])
    return (":", rest)
}


func isSpace(space: String) -> Bool {
    switch space {
    case " ", "\t", "\n", "\r": return true
    default: return false
    }
}


func spaceParser (input: String) -> ParseResult {
    var m = input[input.startIndex]
    var has_space = isSpace(space: String(m))
    if has_space == false {
        return nil
    }
    var index = input.startIndex
    while has_space == true {
        index = input.index(after: index)
        m = input[index]
        has_space = isSpace(space: String(m))
    }
    let output = input[..<index]
    let rest = String(input[index...])
    return(output, rest)
}


func factoryParser (parsers: Parser...) -> Parser {
    func newParser(input: String) -> ParseResult {
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

func nullParser (input: String) -> ParseResult {
    if input.count < 4 {
        return nil
    }
    let output = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if output == "null" {
        let rest = String(input[input.index(input.startIndex, offsetBy: 4)...])
        return (Null(), rest)
    }
    return nil
}


func boolParser (input: String) -> ParseResult {
    if input.count < 5 {
        return nil
    }
    var value = String(input[...input.index(input.startIndex, offsetBy: 3)])
    if value == "true" {
        let output = Bool(value)!
        let rest = String(input[input.index(input.startIndex, offsetBy: 4)...])
        return(output,rest)
    }
    value = String(input[...input.index(input.startIndex, offsetBy: 4)])
    if value == "false" {
        let output = Bool(value)!
        let rest = String(input[input.index(input.startIndex, offsetBy: 5)...])
        return(output,rest)
    }
    return nil
}


func jsonNumberParser (input: String) -> ParseResult {
    var rest = input
    var minusFlag = 1
    if rest[rest.startIndex] == "-" {
        minusFlag = -1
        rest.remove(at: rest.startIndex)
    }
    if isDigit(value: String(rest[rest.startIndex])) == false {
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

func stringParser (input: String) -> ParseResult {
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
    let output = String(input[input.index(after: input.startIndex)..<index])
    index = input.index(after: index)
    let rest = String(input[index...])
    return (output, rest)
}


func arrayParser (input: String) -> ParseResult {
    if input[input.startIndex] != "[" {
        return nil
    }
    var output = [Any]()
    var rest = String(input[input.index(after: input.startIndex)...])
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
    rest.remove(at: rest.startIndex)
    return(output, rest)
}


func objectParser (input: String) -> ParseResult {
    if input[input.startIndex] != "{" {
        return nil
    }
    var key = ""
    var value: Any?
    var output = [String: Any]()
    var rest = String(input[input.index(after: input.startIndex)...])
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
    rest.remove(at: rest.startIndex)
    return (output, rest)
}

let valueParser = factoryParser(parsers: nullParser, boolParser, jsonNumberParser, stringParser, arrayParser, objectParser)
let jsonParser = factoryParser(parsers: arrayParser, objectParser)

let path = "/Users/mbp13/Documents/Swift/bigTwitter.txt"
let fileContents = try? String(contentsOfFile: path, encoding:String.Encoding.utf8)
var file = fileContents!
let start = CFAbsoluteTimeGetCurrent()
print(jsonParser(file)?.output as Any)
let end = CFAbsoluteTimeGetCurrent()

print(end - start)


