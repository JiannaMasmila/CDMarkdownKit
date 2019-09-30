//
//  CDMarkdownParser.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright (c) 2016-2017 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

open class CDMarkdownParser {

    // MARK: - Element Arrays
    fileprivate var escapingElements: [CDMarkdownElement]
    fileprivate var defaultElements: [CDMarkdownElement]
    fileprivate var unescapingElements: [CDMarkdownElement]

    open var customElements: [CDMarkdownElement]

    // MARK: - Basic Elements
    public let header: CDMarkdownHeader
    public let list: CDMarkdownList
    public let quote: CDMarkdownQuote
    public let link: CDMarkdownLink
    public let automaticLink: CDMarkdownAutomaticLink
    public let bold: CDMarkdownBold
    public let italic: CDMarkdownItalic
    public let code: CDMarkdownCode
    public let syntax: CDMarkdownSyntax
    public let image: CDMarkdownImage
    public var paragraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 3
        paragraphStyle.paragraphSpacingBefore = 0
        paragraphStyle.lineSpacing = 1.38
        return paragraphStyle
    }()

    // MARK: - Escaping Elements
    fileprivate var codeEscaping = CDMarkdownCodeEscaping()
    fileprivate var escaping = CDMarkdownEscaping()
    fileprivate var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration
    // Enables or disables detection of URLs even without Markdown format
    open var automaticLinkDetectionEnabled: Bool = true
    public let font: UIFont
    public let fontColor: UIColor
    public let backgroundColor: UIColor

    // MARK: - Initializer
    public init(font: UIFont? = nil,
                boldFont: UIFont? = nil,
                italicFont: UIFont? = nil,
                fontColor: UIColor = UIColor.black,
                backgroundColor: UIColor = UIColor.clear,
                automaticLinkDetectionEnabled: Bool = true,
                customElements: [CDMarkdownElement] = []) {
        if let defaultFont = font {
            self.font = defaultFont
        } else {
            #if os(iOS)
                self.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
            #else
                self.font = UIFont.systemFont(ofSize: 20)
            #endif
        }
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor

        header = CDMarkdownHeader(font: font)
        list = CDMarkdownList(font: font)
        quote = CDMarkdownQuote(font: font)
        link = CDMarkdownLink(font: font)
        automaticLink = CDMarkdownAutomaticLink(font: font)
        bold = CDMarkdownBold(font: font, customBoldFont: boldFont)
        italic = CDMarkdownItalic(font: font, customItalicFont: italicFont)
        code = CDMarkdownCode(font: font)
        syntax = CDMarkdownSyntax(font: font)
        image = CDMarkdownImage(font: font)

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.escapingElements = [codeEscaping, escaping]
        self.defaultElements = [header, list, quote, image, link, automaticLink, bold, italic]
        self.unescapingElements = [code, syntax, unescaping]
        self.customElements = customElements
    }

    // MARK: - Element Extensibility
    open func addCustomElement(_ element: CDMarkdownElement) {
        customElements.append(element)
    }

    open func removeCustomElement(_ element: CDMarkdownElement) {
        guard let index = customElements.firstIndex(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }

    // MARK: - Parsing
    open func parse(_ markdown: String) -> NSAttributedString {
        return parse(NSAttributedString(string: markdown))
    }

    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        let mutableString = attributedString.mutableString
        mutableString.replaceOccurrences(of: "\n\n\n+", with: "\n\n",
                                         options: .regularExpression,
                                         range: NSRange(location: 0, length: mutableString.length))
        mutableString.replaceOccurrences(of: "&nbsp;", with: " ",
                                         range: NSRange(location: 0, length: mutableString.length))

        let regExp = try? NSRegularExpression(pattern: "^\\s+", options: .anchorsMatchLines)
        if let regExp = regExp {
            regExp.replaceMatches(in: mutableString, options: [],
                                  range: NSRange(location: 0, length: mutableString.length),
                                  withTemplate: "\n")
        }

        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: range)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: fontColor, range: range)
        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: backgroundColor, range: range)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        var elements: [CDMarkdownElement] = escapingElements
        elements.append(contentsOf: defaultElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)
        elements.forEach { element in
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }
        return attributedString
    }
}
