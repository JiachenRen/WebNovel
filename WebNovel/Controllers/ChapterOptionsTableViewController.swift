//
//  ChapterOptionsTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/25/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import SafariServices

class ChapterOptionsTableViewController: UITableViewController {

    @IBOutlet var sanitizationCells: [UITableViewCell]!
    
    @IBOutlet weak var hostSpecificCell: UITableViewCell!
    @IBOutlet weak var readabilityCell: UITableViewCell!
    @IBOutlet weak var sanitizedHtmlCell: UITableViewCell!
    @IBOutlet weak var webCell: UITableViewCell!
    
    @IBOutlet weak var fontSizeStepper: UIStepper!
    
    @IBOutlet weak var fontWeightSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var fontFamilyLabel: UILabel!
    
    @IBOutlet weak var paragraphSpacingStepper: UIStepper!
    
    @IBOutlet weak var lineSpacingStepper: UIStepper!
    
    var sanitization: ChapterViewController.Sanitization!
    var attributes: ChapterViewController.Attributes!
    var chapter: WNChapter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSanitizationCells()
        updateAttributesUI()
        
        observe(.fontFamilyUpdated, #selector(updateFontFamily(_:)))
    }
    
    @objc func updateFontFamily(_ notif: Notification) {
        guard let family = notif.object as? String else {
            return
        }
        fontFamilyLabel.text = family
        attributes.fontFamily = family
        postNotification(.attributesUpdated, object: attributes)
    }
    
    func updateAttributesUI() {
        fontSizeStepper.value = Double(attributes.fontSize)
        fontWeightSegmentedControl.selectedSegmentIndex = attributes.fontWeight == .light ? 0 : 1
        fontFamilyLabel.text = attributes.fontFamily
        paragraphSpacingStepper.value = Double(attributes.paragraphSpacing)
        lineSpacingStepper.value = Double(attributes.lineHeightMultiple)
    }
    
    func updateSanitizationCells() {
        sanitizationCells.forEach { cell in
            cell.accessoryType = .none
        }
        
        switch sanitization! {
        case .readability:
            readabilityCell.accessoryType = .checkmark
        case .hostSpecific:
            hostSpecificCell.accessoryType = .checkmark
        case .sanitizedHtml:
            sanitizedHtmlCell.accessoryType = .checkmark
        case .rawHtml:
            webCell.accessoryType = .checkmark
        }
    }
    
    private func updateSanitization(_ indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell === sanitizedHtmlCell {
                sanitization = .sanitizedHtml
            } else if cell === readabilityCell {
                sanitization = .readability
            } else if cell === hostSpecificCell {
                sanitization = .hostSpecific
            } else if cell == webCell {
                sanitization = .rawHtml
            }
            postNotification(.sanitizationUpdated, object: sanitization)
            updateSanitizationCells()
        }
    }
    
    @IBAction func fontSizeStepperValueChanged(_ sender: Any) {
        attributes.fontSize = CGFloat(fontSizeStepper.value)
        postNotification(.attributesUpdated, object: attributes)
    }
    
    @IBAction func fontWeightSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        attributes.fontWeight = sender.selectedSegmentIndex == 0 ? .light : .regular
        postNotification(.attributesUpdated, object: attributes)
    }
    
    @IBAction func paragraphSpacingStepperValueChanged(_ sender: UIStepper) {
        attributes.paragraphSpacing = CGFloat(sender.value)
        postNotification(.attributesUpdated, object: attributes)
    }
    
    @IBAction func lineSpacingStepperValueChanged(_ sender: UIStepper) {
        attributes.lineHeightMultiple = CGFloat(sender.value)
        postNotification(.attributesUpdated, object: attributes)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0: updateSanitization(indexPath)
        case 1:
            switch indexPath.row {
            case 0:
                postNotification(.reloadChapter)
                self.dismiss(animated: true)
            case 1: visitChapterWebPage()
            default: break
            }
        default: break
        }
        
    }
    
    private func visitChapterWebPage() {
        guard let urlStr = chapter.url, let url = URL(string: urlStr) else {
            self.presentError(WNError.urlNotFound)
            return
        }
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let webController = SFSafariViewController(url: url, configuration: config)
        webController.modalPresentationStyle = .fullScreen
        self.present(webController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fontFamilyController = segue.destination as? FontFamilyTableViewController {
            fontFamilyController.currentFontFamily = attributes.fontFamily
        }
    }

}
