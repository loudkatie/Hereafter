//
//  ChatView.swift
//  Hereafter
//
//  THE primary UI. The app IS this chat thread.
//  Everything happens here: composing, reading, replying, location prompts.
//

import SwiftUI
import CoreLocation

struct ChatView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var chatItems: [ChatItem] = []
    @State private var inputText: String = ""
    @State private var showDatePicker: Bool = false
    @State private var selectedUnlockDate: Date = Date.oneYearFromNow
    @State private var composeState: ComposeState = .idle
    @State private var pendingMessageText: String = ""
    
    enum ComposeState {
        case idle
        case typing          // User is writing their message
        case pickingDate     // Message typed, picking unlock date
        case confirming      // Date picked, confirming
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Chat thread
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatItems) { item in
                            chatBubble(for: item)
                                .id(item.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
                .onChange(of: chatItems.count) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            
            // Date picker (slides up when needed)
            if showDatePicker {
                datePickerSheet
            }
            
            // Compose bar
            composeBar
        }
        .background(Color(.systemBackground))
        .onAppear {
            onAppear()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hereafter")
                        .font(.headline)
                    if let place = locationManager.currentPlaceName {
                        Text(place)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Chat Bubbles
    
    @ViewBuilder
    private func chatBubble(for item: ChatItem) -> some View {
        switch item {
        case .system(let msg):
            systemBubble(msg.text)
            
        case .userMessage(let msg):
            userMessageBubble(msg)
            
        case .quickReply(let reply):
            quickReplyButtons(reply.options)
            
        case .typing:
            typingIndicator
        }
    }
    
    private func systemBubble(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 280, alignment: .leading)
            Spacer()
        }
    }
    
    private func userMessageBubble(_ message: HereafterMessage) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.messageText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: 280, alignment: .trailing)
                
                // Metadata line
                if message.isUnlocked {
                    HStack(spacing: 4) {
                        if let place = message.placeName {
                            Text(place)
                        }
                        Text("·")
                        Text(message.createdAt.hereafterShortDate)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Unlocks \(message.unlockDate.hereafterShortDate)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func quickReplyButtons(_ options: [String]) -> some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(options, id: \.self) { option in
                Button {
                    handleQuickReply(option)
                } label: {
                    Text(option)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }
    
    // MARK: - Compose Bar
    
    private var composeBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Photo button (future — stubbed)
                // Button { } label: {
                //     Image(systemName: "camera.fill")
                //         .foregroundColor(.secondary)
                // }
                
                TextField(composePlaceholder, text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .submitLabel(.send)
                    .onSubmit {
                        handleSend()
                    }
                
                if !inputText.isEmpty {
                    Button {
                        handleSend()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var composePlaceholder: String {
        switch composeState {
        case .idle:
            return "Write to future-you..."
        case .typing:
            return "What do you want to say?"
        case .pickingDate, .confirming:
            return "Type here..."
        }
    }
    
    // MARK: - Date Picker
    
    private var datePickerSheet: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("When should this unlock?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DatePicker(
                "Unlock date",
                selection: $selectedUnlockDate,
                in: Date.tomorrow...,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Button {
                confirmDateAndPlant()
            } label: {
                Text("Lock it")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Actions
    
    private func onAppear() {
        locationManager.startUpdating()
        
        // Welcome back message based on context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showContextualGreeting()
        }
    }
    
    private func showContextualGreeting() {
        if let place = locationManager.currentPlaceName {
            let nearbyMessages = appState.messageStore.messages(
                near: locationManager.currentLocation ?? CLLocationCoordinate2D(),
                radiusMeters: 150
            )
            
            let unlockedHere = nearbyMessages.filter { $0.isUnlocked && !$0.isRead }
            let lockedHere = nearbyMessages.filter { !$0.isUnlocked }
            
            if !unlockedHere.isEmpty {
                addSystemMessage("You're at \(place). Something you left here just unlocked.")
            } else if !lockedHere.isEmpty {
                if let next = lockedHere.sorted(by: { $0.unlockDate < $1.unlockDate }).first {
                    addSystemMessage("You're at \(place). You have something locked here that unlocks \(next.unlockDate.hereafterShortDate).")
                }
            } else {
                addSystemMessage("You're at \(place).")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    chatItems.append(.quickReply(QuickReply(options: ["Leave a message here"])))
                }
            }
        } else {
            addSystemMessage("Hey \(appState.firstName).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                chatItems.append(.quickReply(QuickReply(options: ["Leave a message"])))
            }
        }
    }
    
    private func handleSend() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        switch composeState {
        case .idle:
            // Start composing — store the message text, show date picker
            pendingMessageText = String(text.prefix(500))
            inputText = ""
            
            // Show user's message as a preview bubble
            let previewMsg = HereafterMessage(
                id: UUID(), threadID: UUID(), parentMessageID: nil,
                latitude: locationManager.currentLocation?.latitude ?? 0,
                longitude: locationManager.currentLocation?.longitude ?? 0,
                placeName: locationManager.currentPlaceName,
                messageText: pendingMessageText,
                photoAssetID: nil,
                createdAt: Date(), unlockDate: Date.tomorrow,
                creatorID: appState.creatorID, isRead: true
            )
            chatItems.append(.userMessage(previewMsg))
            
            // Ask for date
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                addSystemMessage("When should this unlock?")
                withAnimation(.easeOut(duration: 0.3)) {
                    showDatePicker = true
                    composeState = .pickingDate
                }
            }
            
        default:
            inputText = ""
        }
    }
    
    private func handleQuickReply(_ option: String) {
        // Remove quick reply buttons
        chatItems.removeAll { if case .quickReply = $0 { return true }; return false }
        
        if option == "Leave a message here" || option == "Leave a message" {
            addSystemMessage("What do you want to say to future-you?", delay: 0.5)
            composeState = .typing
        }
    }
    
    private func confirmDateAndPlant() {
        guard !pendingMessageText.isEmpty else { return }
        
        withAnimation { showDatePicker = false }
        
        // Create and save the real message
        let message = HereafterMessage.create(
            text: pendingMessageText,
            unlockDate: selectedUnlockDate.startOfDay,
            coordinate: locationManager.currentLocation ?? CLLocationCoordinate2D(),
            placeName: locationManager.currentPlaceName,
            creatorID: appState.creatorID
        )
        
        appState.messageStore.save(message: message)
        
        // Remove the preview bubble and replace with the real one
        chatItems.removeAll { item in
            if case .userMessage(let msg) = item, msg.creatorID == appState.creatorID && msg.messageText == pendingMessageText {
                return true
            }
            return false
        }
        chatItems.append(.userMessage(message))
        
        // Confirmation from Hereafter
        let place = locationManager.currentPlaceName ?? "this place"
        addSystemMessage("Locked. You'll find this here when you come back after \(selectedUnlockDate.hereafterDateString). ✦", delay: 1.0)
        
        // Reset compose state
        pendingMessageText = ""
        selectedUnlockDate = Date.oneYearFromNow
        composeState = .idle
    }
    
    // MARK: - Helpers
    
    private func addSystemMessage(_ text: String, delay: TimeInterval = 0) {
        if delay > 0 {
            let typingID = UUID()
            chatItems.append(.typing(id: typingID))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                chatItems.removeAll { if case .typing(let id) = $0 { return id == typingID }; return false }
                chatItems.append(.system(SystemMessage(text)))
            }
        } else {
            chatItems.append(.system(SystemMessage(text)))
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastItem = chatItems.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastItem.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
