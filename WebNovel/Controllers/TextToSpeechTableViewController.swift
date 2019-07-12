//
//  TextToSpeechTableViewController.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/12/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import UIKit

class TextToSpeechTableViewController: UITableViewController {

    @IBOutlet weak var pauseResumeLabel: UILabel!
    
    @IBOutlet weak var pauseResumeButton: UIButton!
    
    @IBOutlet weak var pitchMultiplierSlider: UISlider!
    
    @IBOutlet weak var speedSlider: UISlider!
    
    @IBOutlet weak var autoNextSwitch: UISwitch!
    
    @IBOutlet weak var pauseResumeCell: UITableViewCell!
    
    @IBOutlet weak var startSpeakingLabel: UILabel!
    
    @IBOutlet weak var startSpeakingButton: UIButton!
    
    @IBOutlet weak var startSpeakingCell: UIView!
    
    @IBOutlet weak var resetCell: UITableViewCell!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var resetLabel: UILabel!
    
    @IBOutlet weak var webNovelTitleLabel: UILabel!
    
    @IBOutlet weak var chapterTitleLabel: UILabel!
    
    var chapterToRead: WNChapter!
    var reader: WNReader {
        return WNReader.shared
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .lightGrayBackground
        updateControls()
        updateCurrentlyReading()
        
        observe(.startedReadingChapter, #selector(readerStatusUpdated))
        observe(.finishedReadingChapter, #selector(readerStatusUpdated))
    }
    
    @objc private func readerStatusUpdated() {
        updateCurrentlyReading()
        updateControls()
    }
    
    private func updateCurrentlyReading() {
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        if let chapter = reader.chapter {
            webNovelTitleLabel.text = chapter.retrieveWebNovel().title
            chapterTitleLabel.text = chapter.properTitle() ?? "#\(chapter.id) - identifier \(chapter.name)"
        }
    }
    
    private func updateControls() {
        
        // Start speaking
        startSpeakingCell.isUserInteractionEnabled = !reader.isReading
        startSpeakingButton.isEnabled = !reader.isReading
        startSpeakingLabel.isEnabled = !reader.isReading
        
        // Reset
        resetCell.isUserInteractionEnabled = reader.isReading
        resetButton.isEnabled = reader.isReading
        resetLabel.isEnabled = reader.isReading
        
        // Pause/resume
        pauseResumeLabel.isEnabled = reader.isReading
        pauseResumeButton.isEnabled = reader.isReading
        pauseResumeCell.isUserInteractionEnabled = reader.isReading
        pauseResumeLabel.text = reader.isPaused ? "Resume" : "Pause"
        let image: UIImage = reader.isPaused ? .circledFilledResume : .circledFilledPause
        pauseResumeButton.setImage(image, for: .normal)
        
        // Others
        pitchMultiplierSlider.value = reader.pitchMultiplier
        speedSlider.value = reader.rate
        autoNextSwitch.isOn = reader.autoNext
    }
    
    @IBAction func pitchMultiplierSliderValueChanged(_ sender: Any) {
        reader.pitchMultiplier = pitchMultiplierSlider.value
    }
    
    @IBAction func speedSliderValueChanged(_ sender: Any) {
        reader.rate = speedSlider.value
    }
    
    @IBAction func autoNextSwitchValueChanged(_ sender: Any) {
        reader.autoNext = autoNextSwitch.isOn
    }
    
}

// MARK: - Table view delegate

extension TextToSpeechTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0 where reader.chapter != nil:
            postNotification(.requestShowChapter, object: reader.chapter!)
        case 1:
            switch indexPath.row {
            case 0:
                reader.read(chapterToRead)
            case 1:
                if reader.isPaused {
                    reader.resume()
                } else {
                    reader.pause()
                }
            case 2:
                reader.reset()
                updateCurrentlyReading()
            default: break
            }
            updateControls()
        default:
            break
        }
    }
    
}

// MARK: - Table view data source

extension TextToSpeechTableViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && !reader.isReading {
            return 0.1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && !reader.isReading {
            return 0.1
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !reader.isReading {
            return reader.isReading ? 1 : 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

}
