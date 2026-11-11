import CoreAudio
import Foundation
import Observation

struct SoundDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
}

@Observable
final class AudioDevices {
    private(set) var outputs: [SoundDevice] = []
    private(set) var inputs: [SoundDevice] = []
    private(set) var output: AudioDeviceID = 0
    private(set) var input: AudioDeviceID = 0
    private(set) var error: String?
    @ObservationIgnored private var listeners: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
    private let preview: Bool
    private let system = AudioObjectID(kAudioObjectSystemObject)

    init(preview: Bool = false) {
        self.preview = preview
        if preview {
            outputs = [.init(id: 1, name: "MacBook Pro Speakers"), .init(id: 2, name: "Studio Display")]
            inputs = [.init(id: 3, name: "MacBook Pro Microphone")]
            output = 1
            input = 3
            return
        }
        refresh()
        for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultOutputDevice,
                         kAudioHardwarePropertyDefaultInputDevice] {
            var address = Self.address(selector)
            // CoreAudio is explicitly told to deliver on main; the block is also Sendable.
            let listener: AudioObjectPropertyListenerBlock = { @Sendable [weak self] _, _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
            if AudioObjectAddPropertyListenerBlock(system, &address, .main, listener) == noErr {
                listeners.append((address, listener))
            }
        }
    }

    var outputName: String { outputs.first { $0.id == output }?.name ?? "No output device" }

    func refresh() {
        guard !preview else { return }
        var address = Self.address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else {
            error = "Unable to read sound devices."
            return
        }
        guard size > 0 else {
            outputs = []; inputs = []; output = 0; input = 0; error = nil
            return
        }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        let status = ids.withUnsafeMutableBytes { AudioObjectGetPropertyData(system, &address, 0, nil, &size, $0.baseAddress!) }
        guard status == noErr else { error = "Unable to read sound devices (\(status))."; return }
        outputs = ids.filter { hasStreams($0, scope: kAudioObjectPropertyScopeOutput) }.map(device).sorted { $0.name < $1.name }
        inputs = ids.filter { hasStreams($0, scope: kAudioObjectPropertyScopeInput) }.map(device).sorted { $0.name < $1.name }
        output = defaultDevice(kAudioHardwarePropertyDefaultOutputDevice)
        input = defaultDevice(kAudioHardwarePropertyDefaultInputDevice)
        error = nil
    }

    func select(_ id: AudioDeviceID, isInput: Bool) {
        guard !preview, id != 0 else { return }
        var id = id
        var address = Self.address(isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice)
        let status = AudioObjectSetPropertyData(system, &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
        guard status == noErr else {
            error = "Unable to change sound \(isInput ? "input" : "output") (\(status))."
            Toast.shared.show(error!)
            refreshDevicesKeepingError()
            return
        }
        if !isInput {
            address = Self.address(kAudioHardwarePropertyDefaultSystemOutputDevice)
            _ = AudioObjectSetPropertyData(system, &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
        }
        refresh()
        let name = (isInput ? inputs : outputs).first { $0.id == id }?.name ?? "Device"
        Toast.shared.show("Sound \(isInput ? "input" : "output"): \(name)")
    }

    private func refreshDevicesKeepingError() {
        let last = error
        refresh()
        error = last
    }

    func shutdown() {
        for (var address, listener) in listeners {
            AudioObjectRemovePropertyListenerBlock(system, &address, .main, listener)
        }
        listeners.removeAll()
    }

    private func defaultDevice(_ selector: AudioObjectPropertySelector) -> AudioDeviceID {
        var address = Self.address(selector)
        var id: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        _ = AudioObjectGetPropertyData(system, &address, 0, nil, &size, &id)
        return id
    }

    private func hasStreams(_ id: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = Self.address(kAudioDevicePropertyStreams, scope: scope)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr && size > 0
    }

    private func device(_ id: AudioDeviceID) -> SoundDevice {
        var address = Self.address(kAudioObjectPropertyName)
        var name: CFString = "Unknown Device" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        _ = withUnsafeMutablePointer(to: &name) { AudioObjectGetPropertyData(id, &address, 0, nil, &size, $0) }
        return .init(id: id, name: name as String)
    }

    private static func address(_ selector: AudioObjectPropertySelector,
                                scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        .init(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
