// NOVA Voice Banking AI
// AudioBufferProcessor - Audio buffer analysis utilities

import AVFoundation
import Accelerate

enum AudioBufferProcessor {

    /// Extract Float samples from an AVAudioPCMBuffer
    static func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        return samples
    }

    /// Convert AVAudioPCMBuffer to raw Data
    static func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data {
        guard let channelData = buffer.floatChannelData else { return Data() }
        let frameLength = Int(buffer.frameLength)
        let data = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Float>.size)
        return data
    }

    /// Calculate Root Mean Square (RMS) amplitude
    static func calculateRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var meanSquare: Float = 0
        vDSP_measqv(samples, 1, &meanSquare, vDSP_Length(samples.count))
        return sqrtf(meanSquare)
    }

    /// Calculate peak amplitude
    static func calculatePeak(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var peak: Float = 0
        vDSP_maxmgv(samples, 1, &peak, vDSP_Length(samples.count))
        return peak
    }

    /// Apply noise gate - zero out samples below threshold
    static func applyNoiseGate(_ samples: [Float], threshold: Float = 0.01) -> [Float] {
        samples.map { abs($0) < threshold ? 0 : $0 }
    }

    /// Normalize samples to range [-1, 1]
    static func normalize(_ samples: [Float]) -> [Float] {
        let peak = calculatePeak(samples)
        guard peak > 0 else { return samples }
        var result = [Float](repeating: 0, count: samples.count)
        var scale = 1.0 / peak
        vDSP_vsmul(samples, 1, &scale, &result, 1, vDSP_Length(samples.count))
        return result
    }

    /// Calculate zero-crossing rate (useful for voice detection)
    static func zeroCrossingRate(_ samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0 }
        var crossings: Float = 0
        for i in 1..<samples.count {
            if (samples[i] >= 0 && samples[i - 1] < 0) || (samples[i] < 0 && samples[i - 1] >= 0) {
                crossings += 1
            }
        }
        return crossings / Float(samples.count - 1)
    }

    /// Calculate spectral energy in a frequency band
    static func bandEnergy(_ magnitudes: [Float], sampleRate: Float, lowFreq: Float, highFreq: Float) -> Float {
        let binCount = magnitudes.count
        let binWidth = sampleRate / (2.0 * Float(binCount))
        let lowBin = Int(lowFreq / binWidth)
        let highBin = min(Int(highFreq / binWidth), binCount - 1)
        guard lowBin < highBin, lowBin >= 0 else { return 0 }
        let band = Array(magnitudes[lowBin...highBin])
        return band.reduce(0, +) / Float(band.count)
    }
}
