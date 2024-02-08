//
//  VideoCallApp.swift
//  VideoCall
//
//  Created by Liam Cashel on 2/7/24.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

@main
struct VideoCallApp: App {
    @State var call: Call
    @ObservedObject var state: CallState
    @State var callCreated: Bool = false

    //for a demo go to this link: https://getstream.io/video/sdk/ios/tutorial/video-calling/ then step 3 and there is sample api keys and tokens and stuff
    
    private var client: StreamVideo
    private let apiKey: String = "mmhfdzb5evj2" // The API key can be found in the Credentials section
    private let userId: String = "Exar_Kun" // The User Id can be found in the Credentials section
    private let token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiRXhhcl9LdW4iLCJpc3MiOiJodHRwczovL3Byb250by5nZXRzdHJlYW0uaW8iLCJzdWIiOiJ1c2VyL0V4YXJfS3VuIiwiaWF0IjoxNzA3MzUzMTA1LCJleHAiOjE3MDc5NTc5MTB9.w_mJEtX9HqC0RHH5aUaZsLHHspLh3aT78GM5GtftCcM" // The Token can be found in the Credentials section
    private let callId: String = "uOo9Yie6GjD5" // The CallId can be found in the Credentials section

    init() {
        let user = User(
            id: userId,
            name: "BOB SAGET", // name and imageURL are used in the UI
            imageURL: .init(string: "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/a3911/martin-mitrevski.webp")
        )

        // Initialize Stream Video client
        self.client = StreamVideo(
            apiKey: apiKey,
            user: user,
            token: .init(stringLiteral: token)
        )

        // Initialize the call object
        let call = client.call(callType: "default", callId: callId)

        self.call = call
        self.state = call.state
    }
    

    var body: some Scene {
        WindowGroup {
            VStack {
                if callCreated {
                    ZStack {
                        ParticipantsView(
                            call: call,
                            participants: call.state.remoteParticipants,
                            onChangeTrackVisibility: changeTrackVisibility(_:isVisible:)
                        )
                        FloatingParticipantView(participant: call.state.localParticipant)
                    }
                } else {
                    Text("loading...")
                }
            }.onAppear {
                Task {
                    guard callCreated == false else { return }
                    try await call.join(create: true)
                    callCreated = true
                }
            }
        }
    }

    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    private func changeTrackVisibility(_ participant: CallParticipant?, isVisible: Bool) {
        guard let participant else { return }
        Task {
            await call.changeTrackVisibility(for: participant, isVisible: isVisible)
        }
    }
}

struct ParticipantsView: View {

    var call: Call
    var participants: [CallParticipant]
    var onChangeTrackVisibility: (CallParticipant?, Bool) -> Void

    var body: some View {
        GeometryReader { proxy in
            if !participants.isEmpty {
                ScrollView {
                    LazyVStack {
                        if participants.count == 1, let participant = participants.first {
                            makeCallParticipantView(participant, frame: proxy.frame(in: .global))
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        } else {
                            ForEach(participants) { participant in
                                makeCallParticipantView(participant, frame: proxy.frame(in: .global))
                                    .frame(width: proxy.size.width, height: proxy.size.height / 2)
                            }
                        }
                    }
                }
            } else {
                Color.black
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private func makeCallParticipantView(_ participant: CallParticipant, frame: CGRect) -> some View {
        VideoCallParticipantView(
            participant: participant,
            availableFrame: frame,
            contentMode: .scaleAspectFit,
            customData: [:],
            call: call
        )
        .onAppear { onChangeTrackVisibility(participant, true) }
        .onDisappear{ onChangeTrackVisibility(participant, false) }
    }
}

struct FloatingParticipantView: View {

    var participant: CallParticipant?
    var size: CGSize = .init(width: 120, height: 120)

    var body: some View {
        if let participant = participant {
            VStack {
                HStack {
                    Spacer()

                    VideoRendererView(id: participant.id, size: size) { videoRenderer in
                        videoRenderer.handleViewRendering(for: participant, onTrackSizeUpdate: { _, _ in })
                    }
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Spacer()
            }
            .padding()
        }
    }
}

