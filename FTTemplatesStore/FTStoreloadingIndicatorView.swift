//
//  FTStoreloadingIndicatorView.swift
//  FTTemplatesStore
//
//  Created by Siva on 22/06/23.
//

import UIKit
extension UIViewController {
    static let loadingIndicatorTag: Int = 9876

    func showingLoadingindicator(message: String = "") {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.tag = UIViewController.loadingIndicatorTag
        view.addSubview(overlayView)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.appColor(.hModeToolbarBgColor)
        loadingView.layer.cornerRadius = 10
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 100),
            loadingView.heightAnchor.constraint(equalToConstant: 100)
        ])

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])

        activityIndicator.startAnimating()

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = UIColor.black
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8)
        ])

        // Disable user interactions on the superview
        view.isUserInteractionEnabled = false
    }

    func hideLoadingindicator() {
        if let overlayView = view.viewWithTag(UIViewController.loadingIndicatorTag) {
            overlayView.removeFromSuperview()
        }
        // Enable user interactions on the superview
        view.isUserInteractionEnabled = true
    }
}
