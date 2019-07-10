//
//  ChapterViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import WebKit

class ChapterViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var moreButton: UIBarButtonItem!
    
    @IBOutlet weak var webView: WKWebView!
    
    enum Sanitization {
        
        /// WNParser (which is host-specific)
        case hostSpecific
        
        /// Readability.js parser (uses contentText)
        case readability
        
        /// Readability.js with content html
        case sanitizedHtml
        
        /// WebView loaded with raw html.
        case rawHtml
    }
    
    struct Attributes {
        var fontFamily = "Gill Sans"
        var fontSize: CGFloat = 21
        var paragraphSpacing: CGFloat = 20
        var fontWeight: FontWeight = .light
        var lineHeightMultiple: CGFloat = 1.5
        
        var font: UIFont {
            // Some font does not support all weights... it's better to be safe than sorry
            let regularFont = UIFont(name: fontFamily, size: fontSize)!
            guard var regularFontName = UIFont.fontNames(forFamilyName: fontFamily)
                .sorted(by: {$0.count < $1.count}).first else {
                return regularFont
            }
            switch fontWeight {
            case .regular:
                break
            default:
                regularFontName += "-\(fontWeight.rawValue)"
            }
            return UIFont(name: regularFontName, size: fontSize) ?? regularFont
        }
        
        /// Generated attributes compatible with NSAttributedString
        var attrs: [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = lineHeightMultiple
            paragraphStyle.paragraphSpacing = paragraphSpacing
            return [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: font.withSize(fontSize)
            ]
        }
        
        enum FontWeight: String {
            case light = "Light"
            case bold = "Bold"
            case semiBold = "SemiBold"
            case regular
        }
        
        /// Apply the attributes to the given string
        func apply(to str: String) -> NSMutableAttributedString {
            let attributedStr = NSMutableAttributedString(string: str)
            let range = NSRange(location: 0, length: attributedStr.length)
            attributedStr.addAttributes(attrs, range: range)
            return attributedStr
        }
    }
    
    var chapter: WNChapter!
    var sanitization: Sanitization = .readability
    var attributes: Attributes = Attributes()
    var titleAttributes: Attributes {
        var titleAttrs = attributes
        titleAttrs.fontSize *= 1.2
        titleAttrs.fontWeight = .semiBold
        return titleAttrs
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.textContainerInset = .init(top: 0, left: 20, bottom: 0, right: 20)
        navigationItem.title = chapter.chapter
        navigationController?.setNavigationBarHidden(true, animated: true)
        loadChapter()
        
        // Setup tap gesture recognizers
        textView.addGestureRecognizer(makeTapGestureRecognizer())
        
        // Observe notifications
        observe(.sanitizationUpdated, #selector(sanitizationUpdated(_:)))
        observe(.reloadChapter, #selector(reloadChapter))
        observe(.attributesUpdated, #selector(attributesUpdated(_:)))
    }
    
    /// Instantiates a tap gesture recognizer that recognizes a single touch by one finger
    private func makeTapGestureRecognizer() -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recognizer.numberOfTapsRequired = 1
        recognizer.numberOfTouchesRequired = 1
        return recognizer
    }
    
    @objc private func handleTap(_ sender: UIGestureRecognizer? = nil) {
        guard let nav = navigationController else {
            return
        }
        nav.setNavigationBarHidden(!nav.isNavigationBarHidden, animated: true)
        textView.selectedTextRange = nil
    }
    
    @objc private func attributesUpdated(_ notif: Notification) {
        guard let attrs = notif.object as? Attributes else {
            return
        }
        self.attributes = attrs
        presentChapter()
    }
    
    @objc private func reloadChapter() {
        loadChapter(cachePolicy: .overwritesCache)
    }
    
    @objc private func sanitizationUpdated(_ notif: Notification) {
        sanitization = notif.object as! Sanitization
        presentChapter()
    }
    
    private func loadChapter(cachePolicy policy: WNCache.Policy = .usesCache) {
        textView.isHidden = true
        webView.isHidden = true
        WNServiceManager.shared.serviceProvider.loadChapter(chapter, cachePolicy: policy)
            .done { chapter in
                self.chapter = chapter
                self.presentChapter()
                // Prevent the top from being clipped by the annoying face ID camera
                self.textView.setContentOffset(.init(x: 0, y: -40), animated: true)
            }.catch(self.presentError)
    }
    
    private func presentChapter() {
        switch sanitization {
        case .readability, .hostSpecific:
            let supplier: SanitizedContentSupplier? = sanitization == .readability ? chapter.article : chapter
            let attrStr = NSMutableAttributedString()
            if let title = supplier?.title {
                attrStr.append(titleAttributes.apply(to: "\(title)"))
            }
            if let textContent = supplier?.textContent {
                attrStr.append(attributes.apply(to: textContent))
            }
            textView.attributedText = attrStr
        case .sanitizedHtml:
            let attrStr = NSMutableAttributedString()
            if let title = chapter.article?.title {
                attrStr.append(NSAttributedString(string: "\(title)\n"))
            }
            if let html = chapter.article?.content {
                let htmlData = NSString(string: html).data(using: String.Encoding.unicode.rawValue)
                let options = [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html
                ]
                if let attrContent = try? NSMutableAttributedString(
                    data: htmlData ?? Data(),
                    options: options,
                    documentAttributes: nil
                    ) {
                    attrStr.append(attrContent)
                }
            }
            textView.attributedText = attrStr
        case .rawHtml:
            if let html = chapter.rawHtml, let url = URL(string: chapter.url) {
                webView.loadHTMLString(html, baseURL: url)
            }
        }
        webView.isHidden = sanitization != .rawHtml
        textView.isHidden = sanitization == .rawHtml
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "ChapterReader", bundle: .main)
        let vc = storyBoard.instantiateViewController(withIdentifier: "chapter.options.nav") as! UINavigationController
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.barButtonItem = moreButton
        let optionsController = vc.topViewController as! ChapterOptionsTableViewController
        optionsController.sanitization = sanitization
        optionsController.attributes = attributes
        optionsController.chapter = chapter
        self.present(vc, animated: true)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}

extension ChapterViewController: UIPopoverPresentationControllerDelegate {
    /// Ensure that the presentation controller is NOT fullscreen
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

fileprivate protocol SanitizedContentSupplier {
    var title: String? {get}
    var textContent: String? {get}
}

extension WNChapter: SanitizedContentSupplier {}
extension Article: SanitizedContentSupplier {}
