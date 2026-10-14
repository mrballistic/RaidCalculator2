//
//  AppStorePage.swift
//  RaidCalculator2
//

import StoreKit
import SwiftUI

/// RAID Calculator's App Store page, shown inside the app over whatever is on
/// screen (the retirement sheet included). When the page can't load, such
/// as offline or in the Simulator, it closes and the App Store URL opens instead.
enum AppStorePage {
    private static let delegate = Delegate()

    static func open(fallback openURL: OpenURLAction) {
        guard let presenter = topViewController() else {
            openURL(Retirement.storeURL)
            return
        }
        let store = SKStoreProductViewController()
        store.delegate = delegate
        presenter.present(store, animated: true)
        Task {
            do {
                try await store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: Retirement.appStoreID)])
            } catch {
                store.dismiss(animated: true)
                openURL(Retirement.storeURL)
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    private final class Delegate: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true)
        }
    }
}
