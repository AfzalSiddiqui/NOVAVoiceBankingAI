// NOVA Voice Banking AI
// FFTAnalyzer - Fast Fourier Transform frequency analysis using Accelerate

import Accelerate
import Foundation

final class FFTAnalyzer {

    struct FrequencyAnalysis: Sendable {
        let magnitudes: [Float]
        let dominantFrequency: Float
        let spectralCentroid: Float
        let bandEnergies: BandEnergies
    }

    struct BandEnergies: Sendable {
        let subBass: Float   // 20-60 Hz
        let bass: Float      // 60-250 Hz
        let midRange: Float  // 250-4000 Hz
        let highRange: Float // 4000-8000 Hz
    }

    private var fftSetup: FFTSetup?
    private var log2n: vDSP_Length = 0

    init(bufferSize: Int = 1024) {
        log2n = vDSP_Length(log2f(Float(bufferSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }

    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }

    func analyze(samples: [Float], sampleRate: Float = 16000.0) -> FrequencyAnalysis {
        let n = samples.count
        guard n > 0, let setup = fftSetup else {
            return FrequencyAnalysis(
                magnitudes: [],
                dominantFrequency: 0,
                spectralCentroid: 0,
                bandEnergies: BandEnergies(subBass: 0, bass: 0, midRange: 0, highRange: 0)
            )
        }

        // Apply Hann window to reduce spectral leakage
        var windowedSamples = [Float](repeating: 0, count: n)
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
        vDSP_vmul(samples, 1, window, 1, &windowedSamples, 1, vDSP_Length(n))

        // Prepare split complex arrays for FFT
        let halfN = n / 2
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        // Pack interleaved data into split complex format
        windowedSamples.withUnsafeBufferPointer { bufferPointer in
            bufferPointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
            }
        }

        // Perform forward FFT
        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
        vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0, count: halfN)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfN))

        // Convert to dB scale
        var scaledMagnitudes = [Float](repeating: 0, count: halfN)
        var scale = Float(1.0 / Float(n))
        vDSP_vsmul(magnitudes, 1, &scale, &scaledMagnitudes, 1, vDSP_Length(halfN))

        // Find dominant frequency
        var maxMagnitude: Float = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(scaledMagnitudes, 1, &maxMagnitude, &maxIndex, vDSP_Length(halfN))

        let binWidth = sampleRate / Float(n)
        let dominantFrequency = Float(maxIndex) * binWidth

        // Calculate spectral centroid
        let spectralCentroid = calculateSpectralCentroid(magnitudes: scaledMagnitudes, sampleRate: sampleRate)

        // Calculate frequency band energies
        let bandEnergies = BandEnergies(
            subBass: AudioBufferProcessor.bandEnergy(scaledMagnitudes, sampleRate: sampleRate, lowFreq: 20, highFreq: 60),
            bass: AudioBufferProcessor.bandEnergy(scaledMagnitudes, sampleRate: sampleRate, lowFreq: 60, highFreq: 250),
            midRange: AudioBufferProcessor.bandEnergy(scaledMagnitudes, sampleRate: sampleRate, lowFreq: 250, highFreq: 4000),
            highRange: AudioBufferProcessor.bandEnergy(scaledMagnitudes, sampleRate: sampleRate, lowFreq: 4000, highFreq: sampleRate / 2)
        )

        return FrequencyAnalysis(
            magnitudes: scaledMagnitudes,
            dominantFrequency: dominantFrequency,
            spectralCentroid: spectralCentroid,
            bandEnergies: bandEnergies
        )
    }

    // Spectral centroid: weighted mean of frequencies by magnitude
    private func calculateSpectralCentroid(magnitudes: [Float], sampleRate: Float) -> Float {
        let n = magnitudes.count
        guard n > 0 else { return 0 }

        let binWidth = sampleRate / (2.0 * Float(n))
        var weightedSum: Float = 0
        var totalMagnitude: Float = 0

        for i in 0..<n {
            let frequency = Float(i) * binWidth
            weightedSum += frequency * magnitudes[i]
            totalMagnitude += magnitudes[i]
        }

        return totalMagnitude > 0 ? weightedSum / totalMagnitude : 0
    }
}
