//
//  AudioEngine.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/1/25.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 AudioEngine is the main controller class that creates the following objects:
                 AVAudioEngine               *_engine;
                 AVAudioUnitSampler          *_sampler;
                 AVAudioUnitDistortion       *_distortion;
                 AVAudioUnitReverb           *_reverb;
                 AVAudioPlayerNode           *_player;

                 AVAudioSequencer            *_sequencer;
                 AVAudioPCMBuffer            *_playerLoopBuffer;

             It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
 */

import Foundation
import AVFoundation
import Accelerate

//Other nodes/objects can listen to this to determine when the user finishes a recording
let kRecordingCompletedNotification = "RecordingCompletedNotification";

@objc(AudioEngineDelegate)
protocol AudioEngineDelegate: NSObjectProtocol {
    
    optional func engineWasInterrupted()
    optional func engineConfigurationHasChanged()
    optional func mixerOutputFilePlayerHasStopped()
    
}

@objc(AudioEngine)
class AudioEngine: NSObject {
    
    private var _distortionPreset: AVAudioUnitDistortionPreset = .DrumsBitBrush
    private var _reverbPreset: AVAudioUnitReverbPreset = .SmallRoom
    
    weak var delegate: AudioEngineDelegate?
    
    
    //MARK: AudioEngine class extensions
    
    private var _engine: AVAudioEngine!
    private var _sampler: AVAudioUnitSampler!
    private var _distortion: AVAudioUnitDistortion!
    private var _reverb: AVAudioUnitReverb!
    private var _player: AVAudioPlayerNode!
    
    // the sequencer
    private var _sequencer: AVAudioSequencer?
    private var  _sequencerTrackLengthSeconds: Double = 0.0
    
    // buffer for the player
    private var _playerLoopBuffer: AVAudioPCMBuffer!
    
    // for the node tap
    private var _mixerOutputFileURL: NSURL?
    private var _isRecording: Bool = false
    private var _isRecordingSelected: Bool = false
    
    // mananging session and configuration changes
    private var _isSessionInterrupted: Bool = false
    private var _isConfigChangePending: Bool = false
    
    //MARK: AudioEngine implementation
    
    override init() {
        super.init()
        
        // AVAudioSession setup
        self.initAVAudioSession()
        
        _isSessionInterrupted = false
        _isConfigChangePending = false
        
        // create the various nodes
        
        /*  AVAudioPlayerNode supports scheduling the playback of AVAudioBuffer instances,
        or segments of audio files opened via AVAudioFile. Buffers and segments may be
        scheduled at specific points in time, or to play immediately following preceding segments. */
        
        _player = AVAudioPlayerNode()
        
        /* The AVAudioUnitSampler class encapsulates Apple's Sampler Audio Unit. The sampler audio unit can be configured by loading different types of instruments such as an “.aupreset” file, a DLS or SF2 sound bank, an EXS24 instrument, a single audio file or with an array of audio files. The output is a single stereo bus. */
        
        let bankURL = NSURL(fileURLWithPath: NSBundle(forClass: self.dynamicType).pathForResource("gs_instruments", ofType: "dls")!)
        _sampler = AVAudioUnitSampler()
        do {
            try _sampler.loadSoundBankInstrumentAtURL(bankURL, program: 0, bankMSB: 0x79, bankLSB: 0)
        } catch _ {}
        
        /* An AVAudioUnitEffect that implements a multi-stage distortion effect */
        
        _distortion = AVAudioUnitDistortion()
        
        /*  A reverb simulates the acoustic characteristics of a particular environment.
        Use the different presets to simulate a particular space and blend it in with
        the original signal using the wetDryMix parameter. */
        
        _reverb = AVAudioUnitReverb()
        
        // load drumloop into a buffer for the playernode
        let drumLoopURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("drumLoop", ofType: "caf")!)
        let drumLoopFile = try! AVAudioFile(forReading: drumLoopURL)
        _playerLoopBuffer = AVAudioPCMBuffer(PCMFormat: drumLoopFile.processingFormat, frameCapacity: AVAudioFrameCount(drumLoopFile.length))
        do {
            //        success = [drumLoopFile readIntoBuffer:_playerLoopBuffer error:&error];
            try drumLoopFile.readIntoBuffer(_playerLoopBuffer)
        } catch let error as NSError {
            //        NSAssert(success, @"couldn't read drumLoopFile into buffer, %@", [error localizedDescription]);
            fatalError("couldn't read drumLoopFile into buffer, \(error.localizedDescription)")
        }
        
        _mixerOutputFileURL = nil
        _isRecording = false
        _isRecordingSelected = false
        
        // create engine and attach nodes
        self.createEngineAndAttachNodes()
        
        // make engine connections
        self.makeEngineConnections()
        
        //create the audio sequencer
        self.createAndSetupSequencer()
        
        // settings for effects units
        _reverb.wetDryMix = 100;
        _reverb.loadFactoryPreset(AVAudioUnitReverbPreset.MediumHall)
        
        _distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.DrumsBitBrush)
        _distortion.wetDryMix = 100;
        self.samplerEffectVolume = 0.0;
        
        // sign up for notifications from the engine if there's a hardware config change
        NSNotificationCenter.defaultCenter().addObserverForName(AVAudioEngineConfigurationChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) {note in
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            
            self._isConfigChangePending = true
            
            if !self._isSessionInterrupted {
                NSLog("Received a %@ notification!", AVAudioEngineConfigurationChangeNotification)
                NSLog("Re-wiring connections and starting once again")
                self.makeEngineConnections()
                self.startEngine()
            } else {
                NSLog("Session is interrupted, deferring changes")
            }
            
            // post notification
            self.delegate?.engineConfigurationHasChanged?()
        }
        
        // start the engine
        self.startEngine()
    }
    
    //MARK: AVAudioSequencer Setup
    
    private func createAndSetupSequencer() {
        /* A collection of MIDI events organized into AVMusicTracks, plus a player to play back the events.
        NOTE: The sequencer must be created after the engine is initialized and an instrument node is attached and connected
        */
        _sequencer = AVAudioSequencer(audioEngine: _engine)
        
        // load sequencer loop
        guard let midiFileURL = NSBundle(forClass: self.dynamicType).URLForResource("bluesyRiff", withExtension: "mid") else {
            fatalError("couldn't find midi file")
        }
        do {
            try _sequencer!.loadFromURL(midiFileURL, options: AVMusicSequenceLoadOptions.SMF_PreserveTracks)
        } catch let error as NSError {
            fatalError("couldn't load midi file, \(error.localizedDescription)")
        }
        
        // enable looping on all the sequencer tracks
        _sequencerTrackLengthSeconds = 0;
        _sequencer!.tracks.forEach{track in
            track.loopingEnabled = true;
            track.numberOfLoops = AVMusicTrackLoopCount.Forever.rawValue
            let trackLengthInSeconds = track.lengthInSeconds
            if _sequencerTrackLengthSeconds < trackLengthInSeconds {
                _sequencerTrackLengthSeconds = trackLengthInSeconds
            }
        }
        
        _sequencer!.prepareToPlay()
        
    }
    
    //MARK: AVAudioEngine Setup
    
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
        
        _engine.attachNode(_sampler)
        _engine.attachNode(_distortion)
        _engine.attachNode(_reverb)
        _engine.attachNode(_player)
    }
    
    private func makeEngineConnections() {
        /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
        when this property is first accessed. You can then connect additional nodes to the mixer.
        
        By default, the mixer's output format (sample rate and channel count) will track the format
        of the output node. You may however make the connection explicitly with a different format. */
        
        // get the engine's optional singleton main mixer node
        let mainMixer = _engine.mainMixerNode
        
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
        
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        
        // establish a connection between nodes
        
        // connect the player to the reverb
        _engine.connect(_player, to: _reverb, format: stereoFormat)
        
        // connect the reverb effect to mixer input bus 0
        _engine.connect(_reverb, to: mainMixer, fromBus: 0, toBus: 0, format: stereoFormat)
        
        // connect the distortion effect to mixer input bus 2
        _engine.connect(_distortion, to: mainMixer, fromBus: 0, toBus: 2, format: stereoFormat)
        
        // fan out the sampler to mixer input 1 and distortion effect
        let destinationNodes = [AVAudioConnectionPoint(node: _engine.mainMixerNode, bus: 1), AVAudioConnectionPoint(node: _distortion, bus: 0)]
        _engine.connect(_sampler, toConnectionPoints: destinationNodes, fromBus: 0, format: stereoFormat)
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
        
        if !_engine.running {
            do {
                try _engine.start()
            } catch let error as NSError {
                fatalError("couldn't start engine, \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: AVAudioSequencer Methods
    
    func toggleSequencer() {
        if !self.sequencerIsPlaying {
            self.startEngine()
            _sequencer?.currentPositionInSeconds = 0.0
            do {
                try _sequencer?.start()
            } catch _ as NSError {
                fatalError("couldn't start sequencer")
            }
        } else {
            _sequencer!.stop()
        }
    }
    
    var sequencerIsPlaying: Bool {
        return _sequencer?.playing ?? false
    }
    
    var sequencerCurrentPosition: Double {
        get {
            return fmod(Double(_sequencer?.currentPositionInSeconds ?? 0.0), _sequencerTrackLengthSeconds) / _sequencerTrackLengthSeconds
        }
        
        set {
            _sequencer?.currentPositionInSeconds = newValue * _sequencerTrackLengthSeconds
        }
    }
    
    var sequencerPlaybackRate: Float {
        get {
            return _sequencer?.rate ?? 0.0
        }
        
        set {
            _sequencer?.rate = newValue
        }
    }
    
    //MARK: AudioMixinDestination Methods
    
    // 0.0 - 1.0
    var samplerDirectVolume: Float {
        set {
            // get all output connection points from sampler bus 0
            let connectionPoints = _engine.outputConnectionPointsForNode(_sampler, outputBus: 0)
            for conn in connectionPoints {
                // if the destination node represents the main mixer, then this is the direct path
                if conn.node! === _engine.mainMixerNode {
                    // get the corresponding mixing destination object and set the mixer input bus volume
                    if let mixingDestination = _sampler.destinationForMixer(conn.node!, bus: conn.bus) {
                        mixingDestination.volume = newValue
                    }
                    break
                }
            }
        }
        
        get {
            var volume: Float = 0.0
            let connectionPoint = _engine.outputConnectionPointsForNode(_sampler, outputBus: 0)
            for conn in connectionPoint {
                if conn.node! === _engine.mainMixerNode {
                    if let mixingDestination = _sampler.destinationForMixer(conn.node!, bus: conn.bus) {
                        volume = mixingDestination.volume
                    }
                    break
                }
            }
            return volume
        }
    }
    
    // 0.0 - 1.0
    var samplerEffectVolume: Float {
        set {
            // get all output connection points from sampler bus 0
            let connectionPoints = _engine.outputConnectionPointsForNode(_distortion, outputBus: 0)
            for conn in connectionPoints {
                // if the destination node represents the distortion effect, then this is the effect path
                if conn.node === _engine.mainMixerNode {
                    // get the corresponding mixing destination object and set the mixer input bus volume
                    if let mixingDestination = _sampler.destinationForMixer(conn.node!, bus: conn.bus) {
                        mixingDestination.volume = newValue
                    }
                    break
                }
            }
        }
        
        get {
            var distortionVolume: Float = 0.0
            let connectionPoint = _engine.outputConnectionPointsForNode(_distortion, outputBus: 0)
            for conn in connectionPoint  {
                if (conn.node! === _engine.mainMixerNode) {
                    if let mixingDestination = _sampler.destinationForMixer(conn.node!, bus: conn.bus) {
                        distortionVolume = mixingDestination.volume;
                    }
                    break
                }
            }
            return distortionVolume
        }
    }
    
    //MARK: Mixer Methods
    
    // 0.0 - 1.0
    var outputVolume: Float {
        set {
            _engine.mainMixerNode.outputVolume = newValue
        }
        
        get {
            return _engine.mainMixerNode.outputVolume
        }
    }
    
    //MARK: Effect Methods
    
    // 0.0 - 1.0
    var distortionWetDryMix: Float {
        set {
            _distortion.wetDryMix = newValue * 100.0
        }
        
        get {
            return _distortion.wetDryMix/100.0
        }
    }
    
    var distortionPreset: AVAudioUnitDistortionPreset {
        get {return _distortionPreset}
        set {
            _distortion?.loadFactoryPreset(newValue)
        }
    }
    
    // 0.0 - 1.0
    var reverbWetDryMix: Float {
        set {
            _reverb.wetDryMix = newValue * 100.0
        }
        
        get {
            return _reverb.wetDryMix/100.0
        }
    }
    
    var reverbPreset: AVAudioUnitReverbPreset {
        get {return _reverbPreset}
        set {
            _reverb?.loadFactoryPreset(newValue)
        }
    }
    
    //MARK: player Methods
    
    var playerIsPlaying: Bool {
        return _player.playing
    }
    
    // 0.0 - 1.0
    var playerVolume: Float {
        set {
            _player.volume = newValue
        }
        
        get {
            return _player.volume
        }
    }
    
    // -1.0 - 1.0
    var playerPan: Float {
        set {
            _player.pan = newValue
        }
        
        get {
            return _player.pan
        }
    }
    
    func togglePlayer() {
        if !self.playerIsPlaying {
            self.startEngine()
            self.schedulePlayerContent()
            _player.play()
        } else {
            _player.stop()
        }
    }
    
    func toggleBuffer(recordBuffer: Bool) {
        _isRecordingSelected = recordBuffer
        
        if self.playerIsPlaying {
            _player.stop()
            self.startEngine() //start the engine if it's not already started
            self.schedulePlayerContent()
            _player.play()
        } else {
            self.schedulePlayerContent()
        }
    }
    
    func schedulePlayerContent() {
        //schedule the appropriate content
        if _isRecordingSelected {
            let recording = self.createAudioFileForPlayback()
            _player.scheduleFile(recording, atTime: nil, completionHandler: nil)
        } else {
            _player.scheduleBuffer(_playerLoopBuffer, atTime: nil, options: .Loops, completionHandler: nil)
        }
    }
    
    func createAudioFileForPlayback() -> AVAudioFile {
        do {
            let recording = try AVAudioFile(forReading: _mixerOutputFileURL!)
            return recording
        } catch let error as NSError {
            fatalError("couldn't create AVAudioFile, \(error.localizedDescription)")
        }
    }
    
    //MARK: Recording Methods
    
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
        
        if _mixerOutputFileURL == nil {
            _mixerOutputFileURL = NSURL(string: NSTemporaryDirectory() + "mixerOutput.caf")
        }
        
        let mainMixer = _engine.mainMixerNode
        let mixerOutputFile: AVAudioFile
        do {
            mixerOutputFile = try AVAudioFile(forWriting: _mixerOutputFileURL!, settings: mainMixer.outputFormatForBus(0).settings)
        } catch let error as NSError {
            fatalError("mixerOutputFile is nil, \(error.localizedDescription)")
        }
        
        self.startEngine()
        mainMixer.installTapOnBus(0, bufferSize: 4096, format: mainMixer.outputFormatForBus(0)) {buffer, when in
            
            // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
            // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
            do {
                try mixerOutputFile.writeFromBuffer(buffer)
            } catch let error as NSError {
                fatalError("error writing buffer data to file, \(error.localizedDescription)")
            } catch _ {
                fatalError()
            }
        }
        _isRecording = true
    }
    
    func stopRecordingMixerOutput() {
        // stop recording really means remove the tap on the main mixer that was created in startRecordingMixerOutput
        if _isRecording {
            _engine.mainMixerNode.removeTapOnBus(0)
            _isRecording = false
            
            if self.recordingIsAvailable {
                //Post a notificaiton that the record is complete
                //Other nodes/objects can listen to this update accordingly
                NSNotificationCenter.defaultCenter().postNotificationName(kRecordingCompletedNotification, object: nil)
            }
        }
    }
    
    var recordingIsAvailable: Bool {
        return _mixerOutputFileURL != nil
    }
    
    //MARK: AVAudioSession
    
    private func initAVAudioSession() {
        // Configure the audio session
        let sessionInstance = AVAudioSession.sharedInstance()
        
        // set the session category
        do {
            try sessionInstance.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            NSLog("Error setting AVAudioSession category! \(error.localizedDescription)\n")
        }
        
        let hwSampleRate = 44100.0
        do {
            try sessionInstance.setPreferredSampleRate(hwSampleRate)
        } catch let error as NSError {
            NSLog("Error setting preferred sample rate! \(error.localizedDescription)\n")
        }
        
        let ioBufferDuration: NSTimeInterval = 0.0029
        do {
            try sessionInstance.setPreferredIOBufferDuration(ioBufferDuration)
        } catch let error as NSError {
            NSLog("Error setting preferred io buffer duration! \(error.localizedDescription)\n")
        }
        
        // add interruption handler
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(AudioEngine.handleInterruption(_:)),
            name: AVAudioSessionInterruptionNotification,
            object: sessionInstance)
        
        // we don't do anything special in the route change notification
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(AudioEngine.handleRouteChange(_:)),
            name: AVAudioSessionRouteChangeNotification,
            object: sessionInstance)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(AudioEngine.handleMediaServicesReset(_:)),
            name: AVAudioSessionMediaServicesWereResetNotification,
            object: sessionInstance)
        
        // activate the audio session
        do {
            try sessionInstance.setActive(true)
        } catch let error as NSError {
            NSLog("Error setting session active! \(error.localizedDescription)\n")
        }
    }
    
    @objc func handleInterruption(notification: NSNotification) {
        let theInterruptionType = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue ? "Begin Interruption" : "End Interruption")
        NSLog("All userInfo: %@", notification.userInfo!)
        
        if theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue {
            _isSessionInterrupted = true
            _player.stop()
            _sequencer?.stop()
            self.stopRecordingMixerOutput()
            
            self.delegate?.engineWasInterrupted?()
        }
        if theInterruptionType == AVAudioSessionInterruptionType.Ended.rawValue {
            // make sure to activate the session
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                _isSessionInterrupted = false
                if _isConfigChangePending {
                    //there is a pending config changed notification
                    NSLog("Responding to earlier engine config changed notification. Re-wiring connections and starting once again");
                    self.makeEngineConnections()
                    self.startEngine()
                    
                    _isConfigChangePending = false
                } else {
                    // start the engine once again
                    self.startEngine()
                }
            } catch let error as NSError {
                NSLog("AVAudioSession set active failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func handleRouteChange(notification: NSNotification) {
        let reasonValue = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        let routeDescription = notification.userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription
        
        NSLog("Route change:")
        switch reasonValue {
        case AVAudioSessionRouteChangeReason.NewDeviceAvailable.rawValue:
            NSLog("     NewDeviceAvailable")
        case AVAudioSessionRouteChangeReason.OldDeviceUnavailable.rawValue:
            NSLog("     OldDeviceUnavailable")
        case AVAudioSessionRouteChangeReason.CategoryChange.rawValue:
            NSLog("     CategoryChange")
            NSLog("     New Category: New Category: \(AVAudioSession.sharedInstance().category)")
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
    
    @objc func handleMediaServicesReset(notification: NSNotification) {
        // if we've received this notification, the media server has been reset
        // re-wire all the connections and start the engine
        NSLog("Media services have been reset!")
        NSLog("Re-wiring connections and starting once again")
        
        _sequencer = nil; //remove this sequencer since it's linked to the old AVAudioEngine
        self.initAVAudioSession()
        self.createEngineAndAttachNodes()
        self.makeEngineConnections()
        self.createAndSetupSequencer() //recreate the sequencer with the new AVAudioEngine
        self.startEngine()
        
        // notify the delegate
        self.delegate?.engineConfigurationHasChanged?()
    }
    
}