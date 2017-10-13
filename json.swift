#!/usr/bin/swift
import Foundation

typealias ParseResult = (output: Any, rest: Substring)?
typealias Parser = (Substring) -> ParseResult

func isNotDigit(value: Character) -> Bool {
    if value >= "0" && value <= "9" {
        return false
    }
    return true
}

func digitParser(input: Substring) -> ParseResult {
    if let index = input.index (where: isNotDigit) {
        return (input[input.startIndex..<index], input[index...])
    }
    return nil
}

func exponentParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        var index = input.startIndex
        if input[input.index(after: index)] == "+" || input[input.index(after: index)] == "-" {
            index = input.index(after: index)
        }
        if let result = digitParser(input: input[input.index(after: index)...]) {
            let length = (result.output as! Substring).count
            index = input.index(index, offsetBy: length)
        }
        
        return (input[...index], input[input.index(after: index)...])
    }
    return nil
}

func fractionParser(input: Substring) -> ParseResult {
    
    if input[input.startIndex] == "." {
        var index = input.startIndex
        if let result = digitParser(input: input[input.index(after: index)...]) {
            let length = (result.output as! Substring).count
            index = input.index(index, offsetBy: length)
        }
        return (input[...index], input[input.index(after: index)...])
    }
    return nil
}

func zeroParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "0" {
        return nil
    }
    var index = input.startIndex
    if let result = fractionParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = exponentParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    return (input[...index], input[input.index(after: index)...])
}

func intFloatParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "0" || isNotDigit(value: input[input.startIndex]) {
        return nil
    }
    var index = input.startIndex
    if let result = digitParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = fractionParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = exponentParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    return (input[...index], input[input.index(after: index)...])
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

func jsonNumberParser(input: Substring) -> ParseResult {
    var index = input.startIndex
    if input[index] == "-" {
        index = input.index(after: index)
    }
    if isNotDigit(value: input[index])  {
        return nil
    }
    if let result = zeroParser(input: input[index...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = intFloatParser(input: input[index...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    let output = Double(input[..<index])!
    return (output, input[index...] )
}

func stringParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "\"" {
        return nil
    }
    var isEscape = true
    func inspectChar(char: Character) -> Bool {
        if char == "\"" && !isEscape {
            return true
        }
        if char == "\\" {
            isEscape = true
        } else {
            isEscape = false
        }
        return false
    }
    if let index = input.index(where: inspectChar) {
        let emptyIndex = input.index(after: input.startIndex)
        if input[emptyIndex] == "\"" {
            return("", input[input.index(after: emptyIndex)...])
        } else {
            return (input[input.index(after: input.startIndex)...input.index(before: index)],
                    input[input.index(after: index)...])
        }
    }
    return nil
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
