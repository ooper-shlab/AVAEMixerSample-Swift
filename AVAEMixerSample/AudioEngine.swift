//
//  AudioEngine.swift
//  AVAEMixerSample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/2/25.
//
//
///*
//    Copyright (C) 2015 Apple Inc. All Rights Reserved.
//    See LICENSE.txt for this sample’s licensing information
//
//    Abstract:
//    AudioEngine is the main controller class that creates the following objects:
//                    AVAudioEngine       *_engine;
//                    AVAudioPlayerNode   *_marimbaPlayer;
//                    AVAudioPlayerNode   *_drumPlayer;
//                    AVAudioUnitDelay    *_delay;
//                    AVAudioUnitReverb   *_reverb;
//                    AVAudioPCMBuffer    *_marimbaLoopBuffer;
//                    AVAudioPCMBuffer    *_drumLoopBuffer;
//
//                 It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
//*/
//
//@import Foundation;
import Foundation
import AVFoundation
import Accelerate
//
//// effect strip 1 - Marimba Player -> Delay -> Mixer
//// effect strip 2 - Drum Player -> Distortion -> Mixer
//
//@protocol AudioEngineDelegate <NSObject>
@objc(AudioEngineDelegate)
protocol AudioEngineDelegate: NSObjectProtocol {
//
//@optional
//- (void)engineConfigurationHasChanged;
    optional func engineConfigurationHasChanged()
//- (void)mixerOutputFilePlayerHasStopped;
    optional func mixerOutputFilePlayerHasStopped()
//
//@end
}
//
//@interface AudioEngine : NSObject
@objc(AudioEngine)
class AudioEngine: NSObject {
//
//@property (nonatomic, readonly) BOOL marimbaPlayerIsPlaying;
//@property (nonatomic, readonly) BOOL drumPlayerIsPlaying;
//
//@property (nonatomic) float marimbaPlayerVolume;    // 0.0 - 1.0
//@property (nonatomic) float drumPlayerVolume;       // 0.0 - 1.0
//
//@property (nonatomic) float marimbaPlayerPan;       // -1.0 - 1.0
//@property (nonatomic) float drumPlayerPan;          // -1.0 - 1.0
//
//@property (nonatomic) float delayWetDryMix;         // 0.0 - 1.0
//@property (nonatomic) BOOL bypassDelay;
//
//@property (nonatomic) float reverbWetDryMix;        // 0.0 - 1.0
//@property (nonatomic) BOOL bypassReverb;
//
//@property (nonatomic) float outputVolume;           // 0.0 - 1.0
//
//@property (weak) id<AudioEngineDelegate> delegate;
    weak var delegate: AudioEngineDelegate?
//
//
//- (void)toggleMarimba;
//- (void)toggleDrums;
//
//- (void)startRecordingMixerOutput;
//- (void)stopRecordingMixerOutput;
//- (void)playRecordedFile;
//- (void)pausePlayingRecordedFile;
//- (void)stopPlayingRecordedFile;
//
//@end
//
//#import "AudioEngine.h"
//
//@import AVFoundation;
//@import Accelerate;
//
//#pragma mark AudioEngine class extensions
//
//@interface AudioEngine() {
//    AVAudioEngine       *_engine;
    private var _engine: AVAudioEngine!
//    AVAudioPlayerNode   *_marimbaPlayer;
    private var _marimbaPlayer: AVAudioPlayerNode
//    AVAudioPlayerNode   *_drumPlayer;
    private var _drumPlayer: AVAudioPlayerNode
//    AVAudioUnitDelay    *_delay;
    private var _delay: AVAudioUnitDelay
//    AVAudioUnitReverb   *_reverb;
    private var _reverb: AVAudioUnitReverb
//    AVAudioPCMBuffer    *_marimbaLoopBuffer;
    private var _marimbaLoopBuffer: AVAudioPCMBuffer!
//    AVAudioPCMBuffer    *_drumLoopBuffer;
    private var _drumLoopBuffer: AVAudioPCMBuffer!
//
//    // for the node tap
//    NSURL               *_mixerOutputFileURL;
    private var _mixerOutputFileURL: NSURL?
//    AVAudioPlayerNode   *_mixerOutputFilePlayer;
    private var _mixerOutputFilePlayer: AVAudioPlayerNode
//    BOOL                _mixerOutputFilePlayerIsPaused;
    private var _mixerOutputFilePlayerIsPaused: Bool = false
//    BOOL                _isRecording;
    private var _isRecording: Bool = false
//}
//
//- (void)handleInterruption:(NSNotification *)notification;
//- (void)handleRouteChange:(NSNotification *)notification;
//
//@end
//
//#pragma mark AudioEngine implementation
//
//@implementation AudioEngine
//
//- (instancetype)init
//{
    override init() {
//    if (self = [super init]) {
//        // create the various nodes
//
//        /*  AVAudioPlayerNode supports scheduling the playback of AVAudioBuffer instances,
//            or segments of audio files opened via AVAudioFile. Buffers and segments may be
//            scheduled at specific points in time, or to play immediately following preceding segments. */
//
//        _marimbaPlayer = [[AVAudioPlayerNode alloc] init];
        _marimbaPlayer = AVAudioPlayerNode()
//        _drumPlayer = [[AVAudioPlayerNode alloc] init];
        _drumPlayer = AVAudioPlayerNode()
//
//        /*  A delay unit delays the input signal by the specified time interval
//            and then blends it with the input signal. The amount of high frequency
//            roll-off can also be controlled in order to simulate the effect of
//            a tape delay. */
//
//        _delay = [[AVAudioUnitDelay alloc] init];
        _delay = AVAudioUnitDelay()
//
//        /*  A reverb simulates the acoustic characteristics of a particular environment.
//            Use the different presets to simulate a particular space and blend it in with
//            the original signal using the wetDryMix parameter. */
//
//        _reverb = [[AVAudioUnitReverb alloc] init];
        _reverb = AVAudioUnitReverb()
//
//
//        _mixerOutputFilePlayer = [[AVAudioPlayerNode alloc] init];
        _mixerOutputFilePlayer = AVAudioPlayerNode()
        super.init()
//
//        _mixerOutputFileURL = nil;
        _mixerOutputFileURL = nil
//        _mixerOutputFilePlayerIsPaused = NO;
        _mixerOutputFilePlayerIsPaused = false
//        _isRecording = NO;
        _isRecording = false
//
//        // create an instance of the engine and attach the nodes
//        [self createEngineAndAttachNodes];
        self.createEngineAndAttachNodes()
//
//        NSError *error;
        var error: NSError? = nil
//
//        // load marimba loop
//        NSURL *marimbaLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marimbaLoop" ofType:@"caf"]];
        let marimbaLoopURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("marimbaLoop", ofType: "caf")!)!
//        AVAudioFile *marimbaLoopFile = [[AVAudioFile alloc] initForReading:marimbaLoopURL error:&error];
        let marimbaLoopFile = AVAudioFile(forReading: marimbaLoopURL, error: &error)
//        _marimbaLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[marimbaLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[marimbaLoopFile length]];
        _marimbaLoopBuffer = AVAudioPCMBuffer(PCMFormat: marimbaLoopFile.processingFormat, frameCapacity: AVAudioFrameCount(marimbaLoopFile.length))
//        NSAssert([marimbaLoopFile readIntoBuffer:_marimbaLoopBuffer error:&error], @"couldn't read marimbaLoopFile into buffer, %@", [error localizedDescription]);
        assert(marimbaLoopFile.readIntoBuffer(_marimbaLoopBuffer, error: &error), "couldn't read marimbaLoopFile into buffer, \(error!.localizedDescription)")
//
//        // load drum loop
//        NSURL *drumLoopURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"drumLoop" ofType:@"caf"]];
        let drumLoopURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("drumLoop", ofType: "caf")!)!
//        AVAudioFile *drumLoopFile = [[AVAudioFile alloc] initForReading:drumLoopURL error:&error];
        let drumLoopFile = AVAudioFile(forReading: drumLoopURL, error: &error)
//        _drumLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[drumLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[drumLoopFile length]];
        _drumLoopBuffer = AVAudioPCMBuffer(PCMFormat: drumLoopFile.processingFormat, frameCapacity: AVAudioFrameCount(drumLoopFile.length))
//        NSAssert([drumLoopFile readIntoBuffer:_drumLoopBuffer error:&error], @"couldn't read drumLoopFile into buffer, %@", [error localizedDescription]);
        assert(drumLoopFile.readIntoBuffer(_drumLoopBuffer, error: &error), "couldn't read drumLoopFile into buffer, \(error!.localizedDescription)")
//
//        // sign up for notifications from the engine if there's a hardware config change
//        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSNotificationCenter.defaultCenter().addObserverForName(AVAudioEngineConfigurationChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) {note in
//
//            // if we've received this notification, something has changed and the engine has been stopped
//            // re-wire all the connections and start the engine
//            NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
            NSLog("Received a %@ notification!", AVAudioEngineConfigurationChangeNotification)
//            NSLog(@"Re-wiring connections and starting once again");
            NSLog("Re-wiring connections and starting once again")
//            [self makeEngineConnections];
            self.makeEngineConnections()
//            [self startEngine];
            self.startEngine()
//
//            // post notification
//            if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
//                [self.delegate engineConfigurationHasChanged];
            self.delegate?.engineConfigurationHasChanged?()
//            }
//        }];
        }
//
//        // AVAudioSession setup
//        [self initAVAudioSession];
        self.initAVAudioSession()
//
//        // make engine connections
//        [self makeEngineConnections];
        self.makeEngineConnections()
//
//        // settings for effects units
//        [_reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall3];
        _reverb.loadFactoryPreset(.MediumHall3)
//        _delay.delayTime = 0.5;
        _delay.delayTime = 0.5
//        _delay.wetDryMix = 0.0;
        _delay.wetDryMix = 0.0
//
//        // start the engine
//        [self startEngine];
        self.startEngine()
//    }
//    return self;
//}
    }
//
//- (void)createEngineAndAttachNodes
//{
    private func createEngineAndAttachNodes() {
//    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
//		an audio signal generation, processing, or input/output task.
//
//		Nodes are created separately and attached to the engine.
//
//		The engine supports dynamic connection, disconnection and removal of nodes while running,
//		with only minor limitations:
//		- all dynamic reconnections must occur upstream of a mixer
//		- while removals of effects will normally result in the automatic connection of the adjacent
//			nodes, removal of a node which has differing input vs. output channel counts, or which
//			is a mixer, is likely to result in a broken graph. */
//
//    _engine = [[AVAudioEngine alloc] init];
        _engine = AVAudioEngine()
//
//    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
//		externally to the engine, but are not usable until they are attached to the engine via
//		the attachNode method. */
//
//    [_engine attachNode:_marimbaPlayer];
        _engine.attachNode(_marimbaPlayer)
//    [_engine attachNode:_drumPlayer];
        _engine.attachNode(_drumPlayer)
//    [_engine attachNode:_delay];
        _engine.attachNode(_delay)
//    [_engine attachNode:_reverb];
        _engine.attachNode(_reverb)
//    [_engine attachNode:_mixerOutputFilePlayer];
        _engine.attachNode(_mixerOutputFilePlayer)
//}
    }
//
//- (void)makeEngineConnections
//{
    private func makeEngineConnections() {
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
		when this property is first accessed. You can then connect additional nodes to the mixer.

		By default, the mixer's output format (sample rate and channel count) will track the format
		of the output node. You may however make the connection explicitly with a different format. */

    // get the engine's optional singleton main mixer node
//    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
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
//    [_engine connect: _marimbaPlayer to:_delay format:_marimbaLoopBuffer.format];
        _engine.connect(_marimbaPlayer, to: _delay, format: _marimbaLoopBuffer.format)
//    [_engine connect:_delay to:mainMixer format:_marimbaLoopBuffer.format];
        _engine.connect(_delay, to: mainMixer, format: _marimbaLoopBuffer.format)
//
//    // drum player -> reverb -> main mixer
//    [_engine connect:_drumPlayer to:_reverb format:_drumLoopBuffer.format];
        _engine.connect(_drumPlayer, to: _reverb, format: _drumLoopBuffer.format)
//    [_engine connect:_reverb to:mainMixer format:_drumLoopBuffer.format];
        _engine.connect(_reverb, to: mainMixer, format: _drumLoopBuffer.format)
//
//    // node tap player
//    [_engine connect:_mixerOutputFilePlayer to:mainMixer format:[mainMixer outputFormatForBus:0]];
        _engine.connect(_mixerOutputFilePlayer, to: mainMixer, format: mainMixer.outputFormatForBus(0))
//}
    }
//
//- (void)startEngine
//{
    private func startEngine() {
//    // start the engine
//
//    /*  startAndReturnError: calls prepare if it has not already been called since stop.
//
//		Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
//		the engine. Audio begins flowing through the engine.
//
//        This method will return YES for sucess.
//
//		Reasons for potential failure include:
//
//		1. There is problem in the structure of the graph. Input can't be routed to output or to a
//			recording tap through converter type nodes.
//		2. An AVAudioSession error.
//		3. The driver failed to start the hardware. */
//
//    NSError *error;
        var error: NSError? = nil
//    NSAssert([_engine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
        assert(_engine.startAndReturnError(&error), "couldn't start engine, \(error!.localizedDescription)")
//}
    }
//
//- (void)toggleMarimba {
    func toggleMarimba() {
//    if (!self.marimbaPlayerIsPlaying) {
        if !self.marimbaPlayerIsPlaying {
//        [_marimbaPlayer scheduleBuffer:_marimbaLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
            _marimbaPlayer.scheduleBuffer(_marimbaLoopBuffer, atTime: nil, options: .Loops, completionHandler: nil)
//        [_marimbaPlayer play];
            _marimbaPlayer.play()
//    } else
        } else {
//        [_marimbaPlayer stop];
            _marimbaPlayer.stop()
        }
//}
    }
//
//- (void)toggleDrums {
    func toggleDrums() {
//    if (!self.drumPlayerIsPlaying) {
        if !self.drumPlayerIsPlaying {
//        [_drumPlayer scheduleBuffer:_drumLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
            _drumPlayer.scheduleBuffer(_drumLoopBuffer, atTime: nil, options: .Loops, completionHandler: nil)
//        [_drumPlayer play];
            _drumPlayer.play()
//    } else
        } else {
//        [_drumPlayer stop];
            _drumPlayer.stop()
        }
//}
    }
//
//- (void)startRecordingMixerOutput
//{
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

//    NSError *error;
        var error: NSError? = nil
//    if (!_mixerOutputFileURL) _mixerOutputFileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"mixerOutput.caf"]];
        if _mixerOutputFileURL == nil {
            _mixerOutputFileURL = NSURL(string: NSTemporaryDirectory() + "mixerOutput.caf")
        }
//
//    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
        let mainMixer = _engine.mainMixerNode
//    AVAudioFile *mixerOutputFile = [[AVAudioFile alloc] initForWriting:_mixerOutputFileURL settings:[[mainMixer outputFormatForBus:0] settings] error:&error];
        let mixerOutputFile = AVAudioFile(forWriting: _mixerOutputFileURL, settings: mainMixer.outputFormatForBus(0).settings, error: &error)
//    NSAssert(mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
        assert(mixerOutputFile != nil, "mixerOutputFile is nil, \(error!.localizedDescription)")
//
//    if (!_engine.isRunning) [self startEngine];
        if !_engine.running {
            self.startEngine()
        }
//    [mainMixer installTapOnBus:0 bufferSize:4096 format:[mainMixer outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        mainMixer.installTapOnBus(0, bufferSize: 4096, format: mainMixer.outputFormatForBus(0)) {buffer, when in
//        NSError *error;
            var error: NSError? = nil
//
//        // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
//        // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
//        NSAssert([mixerOutputFile writeFromBuffer:buffer error:&error], @"error writing buffer data to file, %@", [error localizedDescription]);
            assert(mixerOutputFile.writeFromBuffer(buffer, error: &error), "error writing buffer data to file, \(error!.localizedDescription)")
//    }];
        }
//    _isRecording = true;
        _isRecording = true
//}
    }
//
//- (void)stopRecordingMixerOutput
//{
    func stopRecordingMixerOutput() {
//    // stop recording really means remove the tap on the main mixer that was created in startRecordingMixerOutput
//    if (_isRecording) {
        if _isRecording {
//        [[_engine mainMixerNode] removeTapOnBus:0];
            _engine.mainMixerNode.removeTapOnBus(0)
//        _isRecording = NO;
            _isRecording = false
//    }
        }
//}
    }
//
//- (void)playRecordedFile
//{
    func playRecordedFile() {
//    if (_mixerOutputFilePlayerIsPaused) {
        if _mixerOutputFilePlayerIsPaused {
//        [_mixerOutputFilePlayer play];
            _mixerOutputFilePlayer.play()
//    }
//    else {
        } else {
//        if (_mixerOutputFileURL) {
            if _mixerOutputFileURL != nil {
//            NSError *error;
                var error: NSError? = nil
//            AVAudioFile *recordedFile = [[AVAudioFile alloc] initForReading:_mixerOutputFileURL error:&error];
                let recordedFile = AVAudioFile(forReading: _mixerOutputFileURL, error: &error)
//            NSAssert(recordedFile != nil, @"recordedFile is nil, %@", [error localizedDescription]);
                assert(recordedFile != nil, "recordedFile is nil, \(error!.localizedDescription)")
//            [_mixerOutputFilePlayer scheduleFile:recordedFile atTime:nil completionHandler:^{
                _mixerOutputFilePlayer.scheduleFile(recordedFile, atTime: nil) {
//                _mixerOutputFilePlayerIsPaused = NO;
                    self._mixerOutputFilePlayerIsPaused = false

                // the data in the file has been scheduled but the player isn't actually done playing yet
                // calculate the approximate time remaining for the player to finish playing and then dispatch the notification to the main thread
//                AVAudioTime *playerTime = [_mixerOutputFilePlayer playerTimeForNodeTime:_mixerOutputFilePlayer.lastRenderTime];
                    let playerTime = self._mixerOutputFilePlayer.playerTimeForNodeTime(self._mixerOutputFilePlayer.lastRenderTime)
//                double delayInSecs = (recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate;
                    let delayInSecs = Double(recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSecs) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
//                    if ([self.delegate respondsToSelector:@selector(mixerOutputFilePlayerHasStopped)])
//                        [self.delegate mixerOutputFilePlayerHasStopped];
                        self.delegate?.mixerOutputFilePlayerHasStopped?()
//                    [_mixerOutputFilePlayer stop];
                        self._mixerOutputFilePlayer.stop()
//                });
                    }
//            }];
                }
//            [_mixerOutputFilePlayer play];
                _mixerOutputFilePlayer.play()
//            _mixerOutputFilePlayerIsPaused = NO;
                _mixerOutputFilePlayerIsPaused = false
//        }
            }
//    }
        }
//}
    }
//
//- (void)stopPlayingRecordedFile
//{
    func stopPlayingRecordedFile() {
//    [_mixerOutputFilePlayer stop];
        _mixerOutputFilePlayer.stop()
//    _mixerOutputFilePlayerIsPaused = NO;
        _mixerOutputFilePlayerIsPaused = false
//}
    }
//
//- (void)pausePlayingRecordedFile
//{
    func pausePlayingRecordedFile() {
//    [_mixerOutputFilePlayer pause];
        _mixerOutputFilePlayer.pause()
//    _mixerOutputFilePlayerIsPaused = YES;
        _mixerOutputFilePlayerIsPaused = true
//}
    }
//
    var marimbaPlayerIsPlaying: Bool {
//- (BOOL)marimbaPlayerIsPlaying
//{
//    return _marimbaPlayer.isPlaying;
            return _marimbaPlayer.playing
//}
    }
//
//- (BOOL)drumPlayerIsPlaying
//{
    var drumPlayerIsPlaying: Bool {
//    return _drumPlayer.isPlaying;
        return _drumPlayer.playing
//}
    }
//
    var marimbaPlayerVolume: Float {
//- (void)setMarimbaPlayerVolume:(float)marimbaPlayerVolume
//{
        set(marimbaPlayerVolume) {
//    _marimbaPlayer.volume = marimbaPlayerVolume;
            _marimbaPlayer.volume = marimbaPlayerVolume
//}
        }
//
//- (float)marimbaPlayerVolume
//{
        get {
//    return _marimbaPlayer.volume;
            return _marimbaPlayer.volume
//}
        }
    }
//
    var drumPlayerVolume: Float {
//- (void)setDrumPlayerVolume:(float)drumPlayerVolume
//{
        set(drumPlayerVolume) {
//    _drumPlayer.volume = drumPlayerVolume;
            _drumPlayer.volume = drumPlayerVolume
//}
        }
//
//- (float)drumPlayerVolume
//{
        get {
//    return _drumPlayer.volume;
            return _drumPlayer.volume
//}
        }
    }
//
    var outputVolume: Float {
        set(outputVolume) {
//- (void)setOutputVolume:(float)outputVolume
//{
//    _engine.mainMixerNode.outputVolume = outputVolume;
            _engine.mainMixerNode.outputVolume = outputVolume
//}
        }
//
//- (float)outputVolume
//{
        get {
//    return _engine.mainMixerNode.outputVolume;
            return _engine.mainMixerNode.outputVolume
//}
        }
    }
//
    var marimbaPlayerPan: Float {
//- (void)setMarimbaPlayerPan:(float)marimbaPlayerPan
//{
        set(marimbaPlayerPan) {
//    _marimbaPlayer.pan = marimbaPlayerPan;
            _marimbaPlayer.pan = marimbaPlayerPan
//}
        }
//
//- (float)marimbaPlayerPan
//{
        get {
//    return _marimbaPlayer.pan;
            return _marimbaPlayer.pan
//}
        }
    }
//
    var drumPlayerPan: Float {
//- (void)setDrumPlayerPan:(float)drumPlayerPan
//{
        set(drumPlayerPan) {
//    _drumPlayer.pan = drumPlayerPan;
            _drumPlayer.pan = drumPlayerPan
//}
        }
//
//- (float)drumPlayerPan
//{
        get {
//    return _drumPlayer.pan;
            return _drumPlayer.pan
//}
        }
    }
//
    var delayWetDryMix: Float {
//- (void)setDelayWetDryMix:(float)delayWetDryMix
//{
        set(delayWetDryMix) {
//    _delay.wetDryMix = delayWetDryMix * 100.0;
            _delay.wetDryMix = delayWetDryMix * 100.0
//}
        }
//
//- (float)delayWetDryMix
//{
        get {
//    return _delay.wetDryMix/100.0;
            return _delay.wetDryMix/100.0
//}
        }
    }
//
    var reverbWetDryMix: Float {
//- (void)setReverbWetDryMix:(float)reverbWetDryMix
//{
        set(reverbWetDryMix) {
//    _reverb.wetDryMix = reverbWetDryMix * 100.0;
            _reverb.wetDryMix = reverbWetDryMix * 100.0
//}
        }
//
//- (float)reverbWetDryMix
//{
        get {
//    return _reverb.wetDryMix/100.0;
            return _reverb.wetDryMix/100.0
//}
        }
    }
//
    var bypassDelay: Bool {
//- (void)setBypassDelay:(BOOL)bypassDelay
//{
        set(bypassDelay) {
//    _delay.bypass = bypassDelay;
            _delay.bypass = bypassDelay
//}
        }
//
//- (BOOL)bypassDelay
//{
        get {
//    return _delay.bypass;
            return _delay.bypass
//}
        }
    }
//
    var bypassReverb: Bool {
//- (void)setBypassReverb:(BOOL)bypassReverb
//{
        set(bypassReverb) {
//    _reverb.bypass = bypassReverb;
            _reverb.bypass = bypassReverb
//}
        }
//
//- (BOOL)bypassReverb
//{
        get {
//    return _reverb.bypass;
            return _reverb.bypass
//}
        }
    }
//
//#pragma mark AVAudioSession
//
//- (void)initAVAudioSession
//{
    private func initAVAudioSession() {
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html

    // Configure the audio session
//    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        let sessionInstance = AVAudioSession.sharedInstance()
//    NSError *error;
        var error: NSError? = nil

    // set the session category
//    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        var success = sessionInstance.setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
//    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
        if !success {
            NSLog("Error setting AVAudioSession category! \(error!.localizedDescription)\n")
        }
//
//    double hwSampleRate = 44100.0;
        let hwSampleRate = 44100.0
//    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
        success = sessionInstance.setPreferredSampleRate(hwSampleRate, error: &error)
//    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
        if !success {
            NSLog("Error setting preferred sample rate! \(error!.localizedDescription)\n")
        }
//
//    NSTimeInterval ioBufferDuration = 0.0029;
        let ioBufferDuration: NSTimeInterval = 0.0029
//    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
        success = sessionInstance.setPreferredIOBufferDuration(ioBufferDuration, error: &error)
//    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
        if !success {
            NSLog("Error setting preferred io buffer duration! \(error!.localizedDescription)\n")
        }

    // add interruption handler
//    [[NSNotificationCenter defaultCenter] addObserver:self
        NSNotificationCenter.defaultCenter().addObserver(self,
//                                             selector:@selector(handleInterruption:)
            selector: "handleInterruption:",
//                                                 name:AVAudioSessionInterruptionNotification
            name: AVAudioSessionInterruptionNotification,
//                                               object:sessionInstance];
            object: sessionInstance)

    // we don't do anything special in the route change notification
//    [[NSNotificationCenter defaultCenter] addObserver:self
        NSNotificationCenter.defaultCenter().addObserver(self,
//                                             selector:@selector(handleRouteChange:)
            selector: "handleRouteChange:",
//                                                 name:AVAudioSessionRouteChangeNotification
            name: AVAudioSessionRouteChangeNotification,
//                                               object:sessionInstance];
            object: sessionInstance)
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
            NSNotificationCenter.defaultCenter().addObserver(self,
//                                             selector:@selector(handleMediaServicesReset:)
                selector: "handleMediaServicesReset:",
//                                                 name:AVAudioSessionMediaServicesWereResetNotification
                name: AVAudioSessionMediaServicesWereResetNotification,
//                                               object:sessionInstance];
                object: sessionInstance)

    // activate the audio session
//    success = [sessionInstance setActive:YES error:&error];
        success = sessionInstance.setActive(true, error: &error)
//    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
        if !success {
            NSLog("Error setting session active! \(error!.localizedDescription)\n")
        }
//}
    }
//
//- (void)handleInterruption:(NSNotification *)notification
//{
    func handleInterruption(notification: NSNotification) {
//    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        let theInterruptionType = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
//
//    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue ? "Begin Interruption" : "End Interruption")
//
//    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        if theInterruptionType == AVAudioSessionInterruptionType.Began.rawValue {
        // the engine will pause itself
//    }
        }
//    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        if theInterruptionType == AVAudioSessionInterruptionType.Ended.rawValue {
        // make sure to activate the session
//        NSError *error;
            var error: NSError? = nil
//        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
            let success = AVAudioSession.sharedInstance().setActive(true, error: &error)
//        if (!success) NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
            if !success {
                NSLog("AVAudioSession set active failed with error: \(error!.localizedDescription)")
            }

        // start the engine once again
//        [self startEngine];
            self.startEngine()
//    }
        }
//}
    }
//
//- (void)handleRouteChange:(NSNotification *)notification
//{
    func handleRouteChange(notification: NSNotification) {
//    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
        var reasonValue = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
//    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
        var routeDescription = notification.userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription
//
//    NSLog(@"Route change:");
        NSLog("Route change:")
//    switch (reasonValue) {
        switch reasonValue {
//        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        case AVAudioSessionRouteChangeReason.NewDeviceAvailable.rawValue:
//            NSLog(@"     NewDeviceAvailable");
            NSLog("     NewDeviceAvailable")
//            break;
//        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        case AVAudioSessionRouteChangeReason.OldDeviceUnavailable.rawValue:
//            NSLog(@"     OldDeviceUnavailable");
            NSLog("     OldDeviceUnavailable")
//            break;
//        case AVAudioSessionRouteChangeReasonCategoryChange:
        case AVAudioSessionRouteChangeReason.CategoryChange.rawValue:
//            NSLog(@"     CategoryChange");
            NSLog("     CategoryChange")
//            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            NSLog(" New Category: \(AVAudioSession.sharedInstance().category)")
//            break;
//        case AVAudioSessionRouteChangeReasonOverride:
        case AVAudioSessionRouteChangeReason.Override.rawValue:
//            NSLog(@"     Override");
            NSLog("     Override")
//            break;
//        case AVAudioSessionRouteChangeReasonWakeFromSleep:
        case AVAudioSessionRouteChangeReason.WakeFromSleep.rawValue:
//            NSLog(@"     WakeFromSleep");
            NSLog("     WakeFromSleep")
//            break;
//        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        case AVAudioSessionRouteChangeReason.NoSuitableRouteForCategory.rawValue:
//            NSLog(@"     NoSuitableRouteForCategory");
            NSLog("     NoSuitableRouteForCategory")
//            break;
//        default:
        default:
//            NSLog(@"     ReasonUnknown");
            NSLog("     ReasonUnknown")
//    }
        }
//
//    NSLog(@"Previous route:\n");
        NSLog("Previous route:\n")
//    NSLog(@"%@", routeDescription);
        NSLog("%@", routeDescription)
//}
    }
//
//- (void)handleMediaServicesReset:(NSNotification *)notification
//{
    func handleMediaServicesReset(notification: NSNotification) {
//    // if we've received this notification, the media server has been reset
//    // re-wire all the connections and start the engine
//    NSLog(@"Media services have been reset!");
        NSLog("Media services have been reset!")
//    NSLog(@"Re-wiring connections and starting once again");
        NSLog("Re-wiring connections and starting once again")
//
//    [self createEngineAndAttachNodes];
        self.createEngineAndAttachNodes()
//    [self makeEngineConnections];
        self.makeEngineConnections()
//    [self startEngine];
        self.startEngine()
//
//    // post notification
//    if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
//        [self.delegate engineConfigurationHasChanged];
        self.delegate?.engineConfigurationHasChanged?()
//    }
//}
    }
//
//@end
}