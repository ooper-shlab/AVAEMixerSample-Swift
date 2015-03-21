//
//  AudioEngine.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/25.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    AudioEngine is the main controller class that creates the following objects:
                    AVAudioEngine       *_engine;
                    AVAudioPlayerNode   *_marimbaPlayer;
                    AVAudioPlayerNode   *_drumPlayer;
                    AVAudioUnitDelay    *_delay;
                    AVAudioUnitReverb   *_reverb;
                    AVAudioPCMBuffer    *_marimbaLoopBuffer;
                    AVAudioPCMBuffer    *_drumLoopBuffer;

                 It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
*/

import Foundation
import AVFoundation
import Accelerate

// effect strip 1 - Marimba Player -> Delay -> Mixer
// effect strip 2 - Drum Player -> Distortion -> Mixer

@objc(AudioEngineDelegate)
protocol AudioEngineDelegate: NSObjectProtocol {
    
    optional func engineConfigurationHasChanged()
    optional func mixerOutputFilePlayerHasStopped()
    
}

@objc(AudioEngine)
class AudioEngine: NSObject {
    
    weak var delegate: AudioEngineDelegate?
    
    
    //MARK: AudioEngine class extensions
    
    private var _engine: AVAudioEngine!
    private var _marimbaPlayer: AVAudioPlayerNode
    private var _drumPlayer: AVAudioPlayerNode
    private var _delay: AVAudioUnitDelay
    private var _reverb: AVAudioUnitReverb
    private var _marimbaLoopBuffer: AVAudioPCMBuffer!
    private var _drumLoopBuffer: AVAudioPCMBuffer!
    
    // for the node tap
    private var _mixerOutputFileURL: NSURL?
    private var _mixerOutputFilePlayer: AVAudioPlayerNode
    private var _mixerOutputFilePlayerIsPaused: Bool = false
    private var _isRecording: Bool = false
    
    //MARK: AudioEngine implementation
    
    override init() {
        // create the various nodes
        
        /*  AVAudioPlayerNode supports scheduling the playback of AVAudioBuffer instances,
        or segments of audio files opened via AVAudioFile. Buffers and segments may be
        scheduled at specific points in time, or to play immediately following preceding segments. */
        
        _marimbaPlayer = AVAudioPlayerNode()
        _drumPlayer = AVAudioPlayerNode()
        
        /*  A delay unit delays the input signal by the specified time interval
        and then blends it with the input signal. The amount of high frequency
        roll-off can also be controlled in order to simulate the effect of
        a tape delay. */
        
        _delay = AVAudioUnitDelay()
        
        /*  A reverb simulates the acoustic characteristics of a particular environment.
        Use the different presets to simulate a particular space and blend it in with
        the original signal using the wetDryMix parameter. */
        
        _reverb = AVAudioUnitReverb()
        
        
        _mixerOutputFilePlayer = AVAudioPlayerNode()
        super.init()
        
        _mixerOutputFileURL = nil
        _mixerOutputFilePlayerIsPaused = false
        _isRecording = false
        
        // create an instance of the engine and attach the nodes
        self.createEngineAndAttachNodes()
        
        var error: NSError? = nil
        
        // load marimba loop
        let marimbaLoopURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("marimbaLoop", ofType: "caf")!)!
        let marimbaLoopFile = AVAudioFile(forReading: marimbaLoopURL, error: &error)
        _marimbaLoopBuffer = AVAudioPCMBuffer(PCMFormat: marimbaLoopFile.processingFormat, frameCapacity: AVAudioFrameCount(marimbaLoopFile.length))
        assert(marimbaLoopFile.readIntoBuffer(_marimbaLoopBuffer, error: &error), "couldn't read marimbaLoopFile into buffer, \(error!.localizedDescription)")
        
        // load drum loop
        let drumLoopURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("drumLoop", ofType: "caf")!)!
        let drumLoopFile = AVAudioFile(forReading: drumLoopURL, error: &error)
        _drumLoopBuffer = AVAudioPCMBuffer(PCMFormat: drumLoopFile.processingFormat, frameCapacity: AVAudioFrameCount(drumLoopFile.length))
        assert(drumLoopFile.readIntoBuffer(_drumLoopBuffer, error: &error), "couldn't read drumLoopFile into buffer, \(error!.localizedDescription)")
        
        // sign up for notifications from the engine if there's a hardware config change
        NSNotificationCenter.defaultCenter().addObserverForName(AVAudioEngineConfigurationChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) {note in
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            NSLog("Received a %@ notification!", AVAudioEngineConfigurationChangeNotification)
            NSLog("Re-wiring connections and starting once again")
            self.makeEngineConnections()
            self.startEngine()
            
            // post notification
            self.delegate?.engineConfigurationHasChanged?()
        }
        
        // AVAudioSession setup
        self.initAVAudioSession()
        
        // make engine connections
        self.makeEngineConnections()
        
        // settings for effects units
        _reverb.loadFactoryPreset(.MediumHall3)
        _delay.delayTime = 0.5
        _delay.wetDryMix = 0.0
        
        // start the engine
        self.startEngine()
    }
    
    private func createEngineAndAttachNodes() {
        /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
        an audio signal generation, processing, or input/output task.
        
        Nodes are created separately and attached to the engine.
        
        The engine supports dynamic connection, disconnection and removal of nodes while running,
        with only minor limitations:
        - all dynamic reconnections must occur upstream of a mixer
        - while removals of effects will normally result in the automatic connection of the adjacent
        nodes, removal of a node which has differing input vs. output channel counts, or which
        is a mixer, is likely to result in a broken graph. */
        
        _engine = AVAudioEngine()
        
        /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
        externally to the engine, but are not usable until they are attached to the engine via
        the attachNode method. */
        
        _engine.attachNode(_marimbaPlayer)
        _engine.attachNode(_drumPlayer)
        _engine.attachNode(_delay)
        _engine.attachNode(_reverb)
        _engine.attachNode(_mixerOutputFilePlayer)
    }
    
    private func makeEngineConnections() {
        /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
        when this property is first accessed. You can then connect additional nodes to the mixer.
        
        By default, the mixer's output format (sample rate and channel count) will track the format
        of the output node. You may however make the connection explicitly with a different format. */
        
        // get the engine's optional singleton main mixer node
        let mainMixer = _engine.mainMixerNode
        
        // establish a connection between nodes
        
        /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
        establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
        many-to-one.
        
        Note that any pre-existing connection(s) involving the source's output bus or the
        destination's input bus will be broken.
        
        @method connect:to:fromBus:toBus:format:
        @param node1 the source node
        @param node2 the destination node
        @param bus1 the output bus on the source node
        @param bus2 the input bus on the destination node
        @param format if non-null, the format of the source node's output bus is set to this
        format. In all cases, the format of the destination node's input bus is set to
        match that of the source node's output bus. */
        
        // marimba player -> delay -> main mixer
        _engine.connect(_marimbaPlayer, to: _delay, format: _marimbaLoopBuffer.format)
        _engine.connect(_delay, to: mainMixer, format: _marimbaLoopBuffer.format)
        
        // drum player -> reverb -> main mixer
        _engine.connect(_drumPlayer, to: _reverb, format: _drumLoopBuffer.format)
        _engine.connect(_reverb, to: mainMixer, format: _drumLoopBuffer.format)
        
        // node tap player
        _engine.connect(_mixerOutputFilePlayer, to: mainMixer, format: mainMixer.outputFormatForBus(0))
    }
    
    private func startEngine() {
        // start the engine
        
        /*  startAndReturnError: calls prepare if it has not already been called since stop.
        
        Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
        the engine. Audio begins flowing through the engine.
        
        This method will return YES for sucess.
        
        Reasons for potential failure include:
        
        1. There is problem in the structure of the graph. Input can't be routed to output or to a
        recording tap through converter type nodes.
        2. An AVAudioSession error.
        3. The driver failed to start the hardware. */
        
        var error: NSError? = nil
        assert(_engine.startAndReturnError(&error), "couldn't start engine, \(error!.localizedDescription)")
    }
    
    func toggleMarimba() {
        if !self.marimbaPlayerIsPlaying {
            _marimbaPlayer.scheduleBuffer(_marimbaLoopBuffer, atTime: nil, options: .Loops, completionHandler: nil)
            _marimbaPlayer.play()
        } else {
            _marimbaPlayer.stop()
        }
    }
    
    func toggleDrums() {
        if !self.drumPlayerIsPlaying {
            _drumPlayer.scheduleBuffer(_drumLoopBuffer, atTime: nil, options: .Loops, completionHandler: nil)
            _drumPlayer.play()
        } else {
            _drumPlayer.stop()
        }
    }
    
    func startRecordingMixerOutput() {
        // install a tap on the main mixer output bus and write output buffers to file
        
        /*  The method installTapOnBus:bufferSize:format:block: will create a "tap" to record/monitor/observe the output of the node.
        
        @param bus
        the node output bus to which to attach the tap
        @param bufferSize
        the requested size of the incoming buffers. The implementation may choose another size.
        @param format
        If non-nil, attempts to apply this as the format of the specified output bus. This should
        only be done when attaching to an output bus which is not connected to another node; an
        error will result otherwise.
        The tap and connection formats (if non-nil) on the specified bus should be identical.
        Otherwise, the latter operation will override any previously set format.
        Note that for AVAudioOutputNode, tap format must be specified as nil.
        @param tapBlock
        a block to be called with audio buffers
        
        Only one tap may be installed on any bus. Taps may be safely installed and removed while
        the engine is running. */
        
        var error: NSError? = nil
        if _mixerOutputFileURL == nil {
            _mixerOutputFileURL = NSURL(string: NSTemporaryDirectory() + "mixerOutput.caf")
        }
        
        let mainMixer = _engine.mainMixerNode
        let mixerOutputFile = AVAudioFile(forWriting: _mixerOutputFileURL, settings: mainMixer.outputFormatForBus(0).settings, error: &error)
        assert(mixerOutputFile != nil, "mixerOutputFile is nil, \(error!.localizedDescription)")
        
        if !_engine.running {
            self.startEngine()
        }
        mainMixer.installTapOnBus(0, bufferSize: 4096, format: mainMixer.outputFormatForBus(0)) {buffer, when in
            var error: NSError? = nil
            
            // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
            // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
            assert(mixerOutputFile.writeFromBuffer(buffer, error: &error), "error writing buffer data to file, \(error!.localizedDescription)")
        }
        _isRecording = true
    }
    
    func stopRecordingMixerOutput() {
        // stop recording really means remove the tap on the main mixer that was created in startRecordingMixerOutput
        if _isRecording {
            _engine.mainMixerNode.removeTapOnBus(0)
            _isRecording = false
        }
    }
    
    func playRecordedFile() {
        if _mixerOutputFilePlayerIsPaused {
            _mixerOutputFilePlayer.play()
        } else {
            if _mixerOutputFileURL != nil {
                var error: NSError? = nil
                let recordedFile = AVAudioFile(forReading: _mixerOutputFileURL, error: &error)
                assert(recordedFile != nil, "recordedFile is nil, \(error!.localizedDescription)")
                _mixerOutputFilePlayer.scheduleFile(recordedFile, atTime: nil) {
                    self._mixerOutputFilePlayerIsPaused = false
                    
                    // the data in the file has been scheduled but the player isn't actually done playing yet
                    // calculate the approximate time remaining for the player to finish playing and then dispatch the notification to the main thread
                    let playerTime = self._mixerOutputFilePlayer.playerTimeForNodeTime(self._mixerOutputFilePlayer.lastRenderTime)
                    let delayInSecs = Double(recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSecs) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.delegate?.mixerOutputFilePlayerHasStopped?()
                        self._mixerOutputFilePlayer.stop()
                    }
                }
                _mixerOutputFilePlayer.play()
                _mixerOutputFilePlayerIsPaused = false
            }
        }
    }
    
    func stopPlayingRecordedFile() {
        _mixerOutputFilePlayer.stop()
        _mixerOutputFilePlayerIsPaused = false
    }
    
    func pausePlayingRecordedFile() {
        _mixerOutputFilePlayer.pause()
        _mixerOutputFilePlayerIsPaused = true
    }
    
    var marimbaPlayerIsPlaying: Bool {
        return _marimbaPlayer.playing
    }
    
    var drumPlayerIsPlaying: Bool {
        return _drumPlayer.playing
    }
    
    // 0.0 - 1.0
    var marimbaPlayerVolume: Float {
        set(marimbaPlayerVolume) {
            _marimbaPlayer.volume = marimbaPlayerVolume
        }
        
        get {
            return _marimbaPlayer.volume
        }
    }
    
    // 0.0 - 1.0
    var drumPlayerVolume: Float {
        set(drumPlayerVolume) {
            _drumPlayer.volume = drumPlayerVolume
        }
        
        get {
            return _drumPlayer.volume
        }
    }
    
    // 0.0 - 1.0
    var outputVolume: Float {
        set(outputVolume) {
            _engine.mainMixerNode.outputVolume = outputVolume
        }
        
        get {
            return _engine.mainMixerNode.outputVolume
        }
    }
    
    // -1.0 - 1.0
    var marimbaPlayerPan: Float {
        set(marimbaPlayerPan) {
            _marimbaPlayer.pan = marimbaPlayerPan
        }
        
        get {
            return _marimbaPlayer.pan
        }
    }
    
    // -1.0 - 1.0
    var drumPlayerPan: Float {
        set(drumPlayerPan) {
            _drumPlayer.pan = drumPlayerPan
        }
        
        get {
            return _drumPlayer.pan
        }
    }
    
    // 0.0 - 1.0
    var delayWetDryMix: Float {
        set(delayWetDryMix) {
            _delay.wetDryMix = delayWetDryMix * 100.0
        }
        
        get {
            return _delay.wetDryMix/100.0
        }
    }
    
    // 0.0 - 1.0
    var reverbWetDryMix: Float {
        set(reverbWetDryMix) {
            _reverb.wetDryMix = reverbWetDryMix * 100.0
        }
        
        get {
            return _reverb.wetDryMix/100.0
        }
    }
    
    var bypassDelay: Bool {
        set(bypassDelay) {
            _delay.bypass = bypassDelay
        }
        
        get {
            return _delay.bypass
        }
    }
    
    var bypassReverb: Bool {
        set(bypassReverb) {
            _reverb.bypass = bypassReverb
        }
        
        get {
            return _reverb.bypass
        }
    }
    
    //MARK: AVAudioSession
    
    private func initAVAudioSession() {
        // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
        // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
        
        // Configure the audio session
        let sessionInstance = AVAudioSession.sharedInstance()
        var error: NSError? = nil
        
        // set the session category
        var success = sessionInstance.setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
        if !success {
            NSLog("Error setting AVAudioSession category! \(error!.localizedDescription)\n")
        }
        
        let hwSampleRate = 44100.0
        success = sessionInstance.setPreferredSampleRate(hwSampleRate, error: &error)
        if !success {
            NSLog("Error setting preferred sample rate! \(error!.localizedDescription)\n")
        }
        
        let ioBufferDuration: NSTimeInterval = 0.0029
        success = sessionInstance.setPreferredIOBufferDuration(ioBufferDuration, error: &error)
        if !success {
            NSLog("Error setting preferred io buffer duration! \(error!.localizedDescription)\n")
        }
        
        // add interruption handler
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleInterruption:",
            name: AVAudioSessionInterruptionNotification,
            object: sessionInstance)
        
        // we don't do anything special in the route change notification
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleRouteChange:",
            name: AVAudioSessionRouteChangeNotification,
            object: sessionInstance)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleMediaServicesReset:",
            name: AVAudioSessionMediaServicesWereResetNotification,
            object: sessionInstance)
        
        // activate the audio session
        success = sessionInstance.setActive(true, error: &error)
        if !success {
            NSLog("Error setting session active! \(error!.localizedDescription)\n")
        }
    }
    
    func handleInterruption(notification: NSNotification) {
        let theInterruptionType = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue ? "Begin Interruption" : "End Interruption")
        
        if theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue {
            // the engine will pause itself
        }
        if theInterruptionType == AVAudioSessionInterruptionType.Ended.rawValue {
            // make sure to activate the session
            var error: NSError? = nil
            let success = AVAudioSession.sharedInstance().setActive(true, error: &error)
            if !success {
                NSLog("AVAudioSession set active failed with error: \(error!.localizedDescription)")
            }
            
            // start the engine once again
            self.startEngine()
        }
    }
    
    func handleRouteChange(notification: NSNotification) {
        var reasonValue = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        var routeDescription = notification.userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription
        
        NSLog("Route change:")
        switch reasonValue {
        case AVAudioSessionRouteChangeReason.NewDeviceAvailable.rawValue:
            NSLog("     NewDeviceAvailable")
        case AVAudioSessionRouteChangeReason.OldDeviceUnavailable.rawValue:
            NSLog("     OldDeviceUnavailable")
        case AVAudioSessionRouteChangeReason.CategoryChange.rawValue:
            NSLog("     CategoryChange")
            NSLog(" New Category: \(AVAudioSession.sharedInstance().category)")
        case AVAudioSessionRouteChangeReason.Override.rawValue:
            NSLog("     Override")
        case AVAudioSessionRouteChangeReason.WakeFromSleep.rawValue:
            NSLog("     WakeFromSleep")
        case AVAudioSessionRouteChangeReason.NoSuitableRouteForCategory.rawValue:
            NSLog("     NoSuitableRouteForCategory")
        default:
            NSLog("     ReasonUnknown")
        }
        
        NSLog("Previous route:\n")
        NSLog("%@", routeDescription)
    }
    
    func handleMediaServicesReset(notification: NSNotification) {
        // if we've received this notification, the media server has been reset
        // re-wire all the connections and start the engine
        NSLog("Media services have been reset!")
        NSLog("Re-wiring connections and starting once again")
        
        self.createEngineAndAttachNodes()
        self.makeEngineConnections()
        self.startEngine()
        
        // post notification
        self.delegate?.engineConfigurationHasChanged?()
    }
    
}