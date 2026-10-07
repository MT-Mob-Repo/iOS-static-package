//
//  BaseNetworkResponse.swift
//  AlmatarStaticPackageSDK
//

import Foundation

struct BaseNetworkResponse<T: Codable>: Codable {
    let data: T?
    let status: Int
    let error: String?
    let errors: [String]?
}

struct BaseListResponse<T: Codable>: Codable {
    let data: [T]?
    let status: Int
    let errors: [String]?
}
