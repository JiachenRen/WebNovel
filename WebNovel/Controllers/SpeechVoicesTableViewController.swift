//
//  SpeechVoicesTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/12/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit
import AVFoundation

class SpeechVoicesTableViewController: UITableViewController {
    
    let voices: [AVSpeechSynthesisVoice] = {
        return AVSpeechSynthesisVoice.speechVoices()
            .filter {$0.language.contains("en")}
            .sorted(by: {$0.name < $1.name})
    }()
    
    var reader: WNReader {
        return WNReader.shared
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "speechVoices.voice", for: indexPath)
        let voice = voices[indexPath.row]
        cell.textLabel?.text = voice.name
        cell.detailTextLabel?.text = voice.language
        if reader.voice.identifier == voice.identifier {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        reader.voice = voices[indexPath.row]
        tableView.reloadData()
    }
    
}
