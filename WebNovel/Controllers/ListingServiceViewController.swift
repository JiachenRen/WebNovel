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
    
    var mgr: WNServiceManager {
        return WNServiceManager.shared
    }
    
    var listingServices: [WNListingService] {
        return mgr.serviceProvider
            .availableListingServices()
            .sorted {
                $0.serviceType.rawValue < $1.serviceType.rawValue
        }
    }
    
    var currentOptions: [String] {
        let selectedIdx = listingPickerView.selectedRow(inComponent: 0)
        return listingServices[selectedIdx]
            .availableParameters
            .sorted {$0 < $1}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentListingService = mgr.serviceProvider.listingService {
            let row = listingServices.enumerated().reduce(into: [:]) {
                $0[$1.1.serviceType] = $1.0
            }[currentListingService.serviceType]!
            listingPickerView.selectRow(row, inComponent: 0, animated: true)
        }
        
        if let parameter = mgr.serviceProvider.listingService?.parameterValue {
            let idx = currentOptions.enumerated().filter {$0.element == parameter}[0].offset
            optionsPickerView.selectRow(idx, inComponent: 0, animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        mgr.serviceProvider.listingService = listingServices[listingPickerView.selectedRow(inComponent: 0)]
        let options = currentOptions
        if options.count > 0 {
            mgr.serviceProvider.listingService?.parameterValue = options[optionsPickerView.selectedRow(inComponent: 0)]
        } else {
            mgr.serviceProvider.listingService?.parameterValue = nil
        }
        mgr.serviceProvider.listingService?.sortAscending = false
        mgr.serviceProvider.listingService?.sortingCriterion = nil
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
            return listingServices[row].serviceType.rawValue
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
