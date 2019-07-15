//
//  WNReader.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/12/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class WNReader : NSObject, AVSpeechSynthesizerDelegate {
    static var shared: WNReader = {
        return WNReader()
    }()
    
    /// Speech synthesizer is used to read the chapter
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let announcer = AVSpeechSynthesizer()
    private let readQueue = DispatchQueue(
        label: "com.jiachenren.WebNovel.read",
        qos: .background,
        attributes: .concurrent,
        autoreleaseFrequency: .workItem,
        target: nil
    )
    
    /// The WNChapter that's currently being read
    private(set) var chapter: WNChapter? {
        didSet {
            updateNowPlayingInfo()
        }
    }
    
    /// Sentences pending to be spoken
    var sentences: [String] = []
    
    /// All sentences for the chapter, used to track playback progress
    var allSentences: [String] = []
    
    /// Rate at which utterances are spoken, default is 0.5 while max is 1
    var rate: Float = 0.5 {
        didSet {
            playbackDurationsPerWord = []
        }
    }
    
    /// Voice for the speech synthesizer
    var voice: AVSpeechSynthesisVoice = AVSpeechSynthesisVoice(language: "en-US")!
    
    /// Pitch for the syntehsized speech.
    /// Default is 1, possible values are from 0.5 to 2
    var pitchMultiplier: Float = 1
    
    /// Whether to automatically start reading the next chapter
    var autoNext: Bool = false
    
    /// Amount of time to wait in seconds after speaking each utterance.
    var postUtteranceDelay: TimeInterval = 0
    
    /// A record of playback durations for word
    var playbackDurationsPerWord: [TimeInterval] = []
    
    var anchor: TimeInterval?
    
    var isPaused: Bool = false
    
    var isReading: Bool = false
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    private func makeUtterance(_ sentence: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.postUtteranceDelay = postUtteranceDelay
        utterance.voice = voice
        return utterance
    }
    
    /// Reads the chapter, verbatim.
    func read(_ chapter: WNChapter) {
        isReading = true
        self.chapter = chapter
        // Merge chapter title and chapter content
        let text = (chapter.article?.title ?? "") + (chapter.article?.textContent ?? "")
        sentences = text.sentences
        allSentences = sentences
        if sentences.count > 0 {
            speak(sentences.removeFirst())
        }
        postNotification(.startedReadingChapter)
    }
    
    /// Stops reading, clears all pending utterances
    func reset() {
        isReading = false
        isPaused = false
        playbackDurationsPerWord = []
        allSentences = []
        sentences = []
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func pause() {
        isPaused = true
        anchor = nil
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resume() {
        isPaused = false
        anchor = nil
        speechSynthesizer.continueSpeaking()
    }
    
    enum ChapterPosition {
        case next
        case previous
    }
    
    /// Loads and reads the next chapter.
    func readChapter(_ pos: ChapterPosition) {
        if let chapterToRead = pos == .next ? chapter?.nextChapter() : chapter?.prevChapter() {
            reset()
            self.chapter = chapterToRead
            func loadedChapter(_ ch: WNChapter) {
                guard ch.id == self.chapter?.id else {
                    return
                }
                ch.markAs(isRead: true)
                postNotification(.startedReadingNextChapter)
                read(chapterToRead)
            }
            if chapterToRead.isDownloaded {
                loadedChapter(chapterToRead)
            } else {
                announce("Continuing to chapter \(chapterToRead.name). Downloading chapter, please wait...")
                let spid = chapterToRead.retrieveWebNovel().serviceProviderIdentifier
                if let provider = WNServiceManager.availableServiceProviders[spid] {
                    provider.downloadChapter(chapterToRead)
                        .done(loadedChapter)
                        .catch { e in
                            print(e)
                    }
                }
            }
        } else {
            announce("No more chapters. End of web novel.")
        }
    }
    
    private func announce(_ notif: String) {
        let utterance = AVSpeechUtterance(string: notif)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1
        utterance.postUtteranceDelay = 0
        utterance.voice = voice
        announcer.speak(utterance)
    }
    
    private func speak(_ text: String) {
        speechSynthesizer.speak(makeUtterance(text))
    }
    
    /// - MARK: AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard sentences.count > 0 else {
            if isReading {
                reset()
                postNotification(.finishedReadingChapter)
                announce("End of chapter.")
                if autoNext  {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {
                        [weak self] _ in
                        self?.readChapter(.next)
                    }
                }
            }
            return
        }
        if let anchor = self.anchor {
            let numWords = utterance.speechString.words.count
            let time: TimeInterval = (.now - anchor) / Double(numWords)
            if time != .nan && !time.isInfinite {
                for _ in 0..<numWords {
                    playbackDurationsPerWord.append(time)
                }
            }
        }
        anchor = .now
        updatePlaybackProgressInfo()
        speak(sentences.removeFirst())
    }
    
    /// - Parameter progress: A number between 0 to 1
    func setPlaybackProgress(_ progress: Double) {
        guard progress <= 1 else {
            readChapter(.next)
            return
        }
        speechSynthesizer.stopSpeaking(at: .immediate)
        let idx = Int(Double(allSentences.count) * progress)
        sentences = Array(allSentences.suffix(from: idx))
        if sentences.count > 0 {
            speak(sentences.removeFirst())
        } else {
            readChapter(.next)
        }
    }
    
    private func updateNowPlayingInfo() {
        readQueue.async { [weak self] in
            guard let self = self, let chapter = self.chapter else {
                return
            }
            
            let wn = chapter.retrieveWebNovel()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: wn.title ?? "N/A",
                MPMediaItemPropertyArtist: chapter.properTitle() ?? "Entry \(chapter.id) - \(chapter.name)",
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: UIImage.coverPlaceholder.size) { _ in
                    if let url = wn.coverImageUrl,
                        let wnImage = WNCache.fetch(by: url, object: WNCoverImage.self),
                        let image = UIImage(data: wnImage.imageData) {
                        return image
                    }
                    return .coverPlaceholder
                }
            ]
        }
    }
    
    private func updatePlaybackProgressInfo() {
        readQueue.async { [weak self] in
            let infoCenter = MPNowPlayingInfoCenter.default()
            guard let self = self, infoCenter.nowPlayingInfo != nil else {
                return
            }
            let avgDuration = self.playbackDurationsPerWord.reduce(0) {$0 + $1}
                / Double(self.playbackDurationsPerWord.count)
            let totalNumWords = self.allSentences
                .map {$0.words.count}
                .reduce(0) {$0 + $1}
            let remainingNumWords = self.sentences
                .map {$0.words.count}
                .reduce(0) {$0 + $1}
            let timeElapsed = Double(totalNumWords - remainingNumWords) * avgDuration
            let duration = Double(totalNumWords) * avgDuration
            infoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = timeElapsed
            infoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        }
    }
}
