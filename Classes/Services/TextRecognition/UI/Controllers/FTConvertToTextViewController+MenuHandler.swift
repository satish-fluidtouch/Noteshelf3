//
//  FTConvertToTextViewController+MenuHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 16/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTConvertToTextViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.recognitionInfo?.recognisedString = textView.text
    }
    func textViewDidChange(_ textView: UITextView) {
        self.recognitionInfo?.recognisedString = textView.text
    }

    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var additionalActions: [UIMenuElement] = []
        if let completeText = textView.text, !completeText.isEmpty, range.length > 0, let reqRange = Range(range, in: completeText)  {
            let reqWord = String(completeText[reqRange.lowerBound..<reqRange.upperBound])
            let existingWords = FTSpellCheckManager.shared.fetchSpellLearnWords()
            if !existingWords.contains(reqWord) {
                let learnSpellAction = UIAction(title: "Learn Spelling", image: nil) { _ in
                    UITextChecker.learnWord(reqWord)
                    FTSpellCheckManager.shared.save(spellWord: reqWord)
                }
                additionalActions.append(learnSpellAction)
            }
        }
        return UIMenu(children: suggestedActions + additionalActions)
    }

    internal func getFormattedRecognizedString(_ textToConvert: String) -> String {
        var replacedSentence = textToConvert
        if !textToConvert.isEmpty {
            let fullRange = NSRange(0..<textToConvert.utf16.count)
            if let textRange = Range(fullRange, in: textToConvert) {
                textToConvert.enumerateSubstrings(in: textRange, options: .byWords) { (substring, _, _, _) in
                    if let word = substring {
                        let language = FTUtils.currentLanguage()
                        let misspelledRange =
                        self.textChecker.rangeOfMisspelledWord(in: word,
                                                               range: NSRange(0..<word.utf16.count),
                                                               startingAt: 0,
                                                               wrap: false,
                                                               language: language)
                        if misspelledRange.location != NSNotFound,
                           var guesses = self.textChecker.guesses(forWordRange: misspelledRange,
                                                                  in: word,
                                                                  language: language), !guesses.isEmpty {
                            let spellWords = FTSpellCheckManager.shared.fetchSpellLearnWords()
                            if let matchedGuess = spellWords.first(where: { guesses.contains($0) }) {
                                replacedSentence = textToConvert.replacingOccurrences(of: word, with: matchedGuess)
                            }
                        }
                    }
                }
            }
        }
        return replacedSentence
    }
}

extension UITextView {
    func addDoneButton(title: String, target: Any, selector: Selector) {

        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))//1
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        let barButton = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)//3
        toolBar.setItems([flexible, barButton], animated: false)//4
        self.inputAccessoryView = toolBar//5
    }
}
