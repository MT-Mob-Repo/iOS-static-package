//
//  AppDelegate.swift
//  MyApp
//
//  Created by mahmoud ismail on 07/10/2026.
//

import UIKit
import AlmatarStaticPackageSDK

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureStaticPackageSDK()
        AlmatarFonts.register()
        return true
    }

    private func configureStaticPackageSDK() {
        let sdk = AlmatarStaticPackageSDK.shared

        sdk.configure(StaticPackageConfiguration(
            baseURL: AppConstants.baseURL,
            language: .english,
            brand: AppConstants.brand,
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            useMockData: false   // set to false once the API is ready
        ))

        sdk.setTokenProvider {
            // Return the logged-in user's token, or nil for guests
            UserDefaults.standard.string(forKey: AppConstants.tokenKey)
        }
    }
}

enum AppConstants {
    static let baseURL = "https://alpha.alm6ar.com"
    static let brand = "Almatar"
    static let tokenKey = "access_token"
}
