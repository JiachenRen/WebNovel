//
//  ListingServiceViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/18/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class ListingServiceViewController: UIViewController {

    @IBOutlet weak var listingPickerView: UIPickerView!
    
    @IBOutlet weak var optionsPickerView: UIPickerView!
    
    var manager: WNServiceManager {
        return WNServiceManager.shared
    }
    
    var serviceProvider: WNServiceProvider {
        return manager.serviceProvider
    }
    
    var listingServices: [WNListingService] {
        return serviceProvider.availableListingServices()
            .sorted {$0.rawValue < $1.rawValue}
    }
    
    var currentOptions: [WNListingService.Option] {
        let selectedIdx = listingPickerView.selectedRow(inComponent: 0)
        return serviceProvider.listingServiceOptions(for: listingServices[selectedIdx])?
            .sorted {$0 < $1} ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let row = listingServices.enumerated().reduce(into: [:]) {
            $0[$1.1] = $1.0
        }[manager.listingService]!
        listingPickerView.selectRow(row, inComponent: 0, animated: true)
        if let option = manager.listingServiceOption {
            let idx = currentOptions.enumerated().filter {$0.element == option}[0].offset
            optionsPickerView.selectRow(idx, inComponent: 0, animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        manager.listingService = listingServices[listingPickerView.selectedRow(inComponent: 0)]
        let options = currentOptions
        if options.count > 0 {
            manager.listingServiceOption = options[optionsPickerView.selectedRow(inComponent: 0)]
        } else {
            manager.listingServiceOption = nil
        }
        self.dismiss(animated: true)
        postNotification(.listingServiceUpdated)
    }
    
}

extension ListingServiceViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView === listingPickerView ? listingServices.count : currentOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === listingPickerView {
            return listingServices[row].rawValue
        } else {
            return currentOptions[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === listingPickerView {
            optionsPickerView.reloadAllComponents()
        }
    }
}
