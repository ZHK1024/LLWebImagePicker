//
//  LLWebImageError.swift
//  LLWebImagePicker
//
//  Created by Ruris on 2024/5/11.
//

import Foundation

public struct LLWebImageError: Error {
    
    /// 错误信息
    let message: String
    
    var localizedDescription: String { message }
    
    init(_ message: String?) {
        self.message = message ?? "未知错误"
    }
}

extension LLWebImageError: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.message = value
    }
}

extension LLWebImageError: LocalizedError {
    
    public var errorDescription: String? {
        return message
    }
}
