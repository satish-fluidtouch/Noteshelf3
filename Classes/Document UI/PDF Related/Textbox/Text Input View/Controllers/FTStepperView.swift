//
//  FTMacStepperView.swift
//  Noteshelf3
//
//  Created by Rakesh on 16/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

enum StepperValueCapturedIn{
    case fontsize
    case lineHeight
}

protocol FTStepperViewDelegate: AnyObject {
    func valueChanged(_ value: Int, valueCaptureAt: StepperValueCapturedIn)
}

class FTStepperView: UIView {
    weak var delegate: FTStepperViewDelegate?
    private let valueCaptureAt: StepperValueCapturedIn

#if targetEnvironment(macCatalyst)
    private var value: Int = 0

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let incrementButton: UIButton = {
        let button = createButton(withTitle: "+")
        return button
    }()

    private let separatorView: UILabel = {
        let label = UILabel()
        label.text = "|"
        label.textAlignment = .center
        label.textColor = UIColor.appColor(.gray60)
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 1),
            label.heightAnchor.constraint(equalToConstant: 2),
        ])
        return label
    }()

    private let decrementButton: UIButton = {
        let button = createButton(withTitle: "-")
        return button
    }()
#else
    private var iOSStepper: UIStepper?
#endif

    init(frame: CGRect,valueCaptureAt: StepperValueCapturedIn) {
        self.valueCaptureAt = valueCaptureAt
        super.init(frame: frame)
        setupStepperUI()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateInitialValue(_ value: Int) {
#if !targetEnvironment(macCatalyst)
        self.iOSStepper?.value = Double(value)
#else
        self.value = value
#endif
    }

#if targetEnvironment(macCatalyst)
    func setupStepperUI() {
        stackView.addArrangedSubview(decrementButton)
        stackView.addArrangedSubview(separatorView)
        stackView.addArrangedSubview(incrementButton)
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor,constant: 0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        decrementButton.addTarget(self, action: #selector(stepperDecrementBtnTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(stepperIncrementBtnTapped), for: .touchUpInside)
    }

    private static func createButton(withTitle title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.appColor(.black1), for: .normal)
        return button
    }

    @objc func stepperIncrementBtnTapped() {
        value += 1
        updateValue(value: value)
    }

    @objc func stepperDecrementBtnTapped() {
        if value > 0 {
            value -= 1
            updateValue(value: value)
        }
    }

    #else
    func setupStepperUI() {
        let stepper =  UIStepper()
        addSubview(stepper)
        self.iOSStepper = stepper
        self.iOSStepper?.addTarget(self, action: #selector(tappedonStepper(_:)), for: .valueChanged)
    }
    @objc func tappedonStepper(_ sender: UIStepper) {
        updateValue(value: Int(sender.value))
    }
#endif

    private func updateValue(value: Int) {
        DispatchQueue.main.async {
            self.delegate?.valueChanged(value, valueCaptureAt: self.valueCaptureAt)
        }
    }
}
