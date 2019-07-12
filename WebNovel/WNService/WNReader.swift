//
//  WNReader.swift
//  WebNovel
//
//  Created by Jiachen Ren on 7/12/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import AVFoundation

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
    var chapter: WNChapter?
    
    /// Sentences pending to be spoken
    var sentences: [String] = []
    
    /// Rate at which utterances are spoken, default is 0.5 while max is 1
    var rate: Float = 0.5
    
    /// Pitch for the syntehsized speech.
    /// Default is 1, possible values are from 0.5 to 2
    var pitchMultiplier: Float = 1
    
    /// Whether to automatically start reading the next chapter
    var autoNext: Bool = false
    
    /// Amount of time to wait in seconds after speaking each utterance.
    var postUtteranceDelay: TimeInterval = 0
    
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
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        return utterance
    }
    
    /// Reads the chapter, verbatim.
    func read(_ chapter: WNChapter) {
        isReading = true
        self.chapter = chapter
        // Merge chapter title and chapter content
        let text = (chapter.article?.title ?? "") + (chapter.article?.textContent ?? "")
        self.sentences = text.sentences
        if sentences.count > 0 {
            speak(sentences.removeFirst())
        }
        postNotification(.startedReadingChapter)
    }
    
    /// Stops reading, clears all pending utterances
    func reset() {
        isReading = false
        isPaused = false
        speechSynthesizer.stopSpeaking(at: .immediate)
        sentences = []
    }
    
    func pause() {
        isPaused = true
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resume() {
        isPaused = false
        speechSynthesizer.continueSpeaking()
    }
    
    /// Loads and reads the next chapter.
    private func readNextChapter() {
        if let nextChapter = chapter?.nextChapter() {
            func loadedChapter(_ ch: WNChapter) {
                reset()
                ch.markAsRead()
                postNotification(.chapterReadStatusUpdated)
                postNotification(.startedReadingNextChapter)
                read(nextChapter)
            }
            if nextChapter.isDownloaded {
                loadedChapter(nextChapter)
            } else {
                announce("Continuing to chapter \(nextChapter.name). Downloading chapter, please wait...")
                let spid = nextChapter.retrieveWebNovel().serviceProviderIdentifier
                if let provider = WNServiceManager.availableServiceProviders[spid] {
                    provider.loadChapter(nextChapter, cachePolicy: .overwritesCache)
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
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        announcer.speak(utterance)
    }
    
    private func speak(_ text: String) {
        speechSynthesizer.speak(makeUtterance(text))
    }
    
    /// - MARK: AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard !synthesizer.isPaused && sentences.count > 0 else {
            announce("End of chapter.")
            reset()
            postNotification(.finishedReadingChapter)
            if autoNext && sentences.count == 0 {
                readNextChapter()
            }
            return
        }
        speak(sentences.removeFirst())
    }
}
