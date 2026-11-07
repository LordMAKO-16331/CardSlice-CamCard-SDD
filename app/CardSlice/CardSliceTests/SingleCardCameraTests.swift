import AVFoundation
import Foundation
import Testing
@testable import CardSlice

@MainActor
struct SingleCardCameraTests {
    @Test func unavailableCameraDoesNotRequestPermission() {
        #expect(SingleCardCameraAccess.evaluate(available: false, status: .notDetermined) == .blocked(.unavailable))
    }

    @Test func cameraPermissionDistinguishesAllKnownStates() {
        #expect(SingleCardCameraAccess.evaluate(available: true, status: .notDetermined) == .request)
        #expect(SingleCardCameraAccess.evaluate(available: true, status: .authorized) == .ready)
        #expect(SingleCardCameraAccess.evaluate(available: true, status: .denied) == .blocked(.denied))
        #expect(SingleCardCameraAccess.evaluate(available: true, status: .restricted) == .blocked(.restricted))
    }

    @Test func cancelledSessionDoesNotForwardLatePhoto() {
        var completions = 0
        let coordinator = SingleCardCameraView.Coordinator { result in
            completions += 1
            #expect(result == nil)
        }
        coordinator.finish(nil)
        coordinator.finish(.success(Data([1])))
        #expect(completions == 1)
    }

    @Test func newSessionForwardsOnlyItsOwnPhotoOnce() {
        let oldSession = SingleCardCameraView.Coordinator { _ in }
        oldSession.finish(nil)
        let photo = Data([2])
        var received: [Data] = []
        let newSession = SingleCardCameraView.Coordinator { result in
            if case .success(let data) = result { received.append(data) }
        }
        oldSession.finish(.success(Data([1])))
        newSession.finish(.success(photo))
        newSession.finish(.success(Data([3])))
        #expect(received == [photo])
    }
}
