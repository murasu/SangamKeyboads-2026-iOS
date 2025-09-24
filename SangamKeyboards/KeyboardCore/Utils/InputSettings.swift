//
//  InputSettings.swift
//  SangamKeyboards
//
//  Created by Muthu Nedumaran on 24/09/2025.
//

import Foundation

public struct InputSettings {
    public let predictionsEnabled: Bool
    public let nextWordPredictionsEnabled: Bool
    public let autoCommitEnabled: Bool
    public let soundsEnabled: Bool
    public let emojisEnabled: Bool
    public let autoCorrectEnabled: Bool
    
    public init(
        predictionsEnabled: Bool = true,
        nextWordPredictionsEnabled: Bool = true,
        autoCommitEnabled: Bool = false,
        soundsEnabled: Bool = true,
        emojisEnabled: Bool = true,
        autoCorrectEnabled: Bool = true
    ) {
        self.predictionsEnabled = predictionsEnabled
        self.nextWordPredictionsEnabled = nextWordPredictionsEnabled
        self.autoCommitEnabled = autoCommitEnabled
        self.soundsEnabled = soundsEnabled
        self.emojisEnabled = emojisEnabled
        self.autoCorrectEnabled = autoCorrectEnabled
    }
    
    public static let `default` = InputSettings()
}

