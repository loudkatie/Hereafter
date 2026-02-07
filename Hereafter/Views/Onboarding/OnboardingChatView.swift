//
//  OnboardingChatView.swift
//  Hereafter
//
//  The first-launch experience. No tutorial. No carousel. Just a conversation.
//
//  "Hi. Welcome to Hereafter. What's your first name?"
//

import SwiftUI

struct OnboardingChatView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var chatItems: [ChatItem] = []
    @State private var inputText: String = ""
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isInputEnabled: Bool = false
    @State private var showQuickReplies: Bool = false
    
    enum OnboardingStep {
        case welcome
        case askName
        case greet
        case explain
        case askFirstMessage
        case waitingForFirstMessage
        case askPermission
        case complete
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                    .padding(.top, 60)
                    .padding(.bottom, 16)
                }
                .onChange(of: chatItems.count) { _, _ in
                    if let lastItem = chatItems.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastItem.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Compose bar
            if isInputEnabled {
                composeBar
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            startOnboarding()
        }
    }
    
    // MARK: - Chat Bubbles
    
    @ViewBuilder
    private func chatBubble(for item: ChatItem) -> some View {
        switch item {
        case .system(let msg):
            systemBubble(msg.text)
            
        case .quickReply(let reply):
            quickReplyButtons(reply.options)
            
        case .typing:
            typingIndicator
            
        case .userMessage:
            EmptyView() // Not used in onboarding
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
                ForEach(0..<3) { i in
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
        HStack(spacing: 12) {
            TextField("Type here...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .submitLabel(.send)
                .onSubmit {
                    handleUserInput()
                }
            
            if !inputText.isEmpty {
                Button {
                    handleUserInput()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Onboarding Flow
    
    private func startOnboarding() {
        // Beat 1: Welcome
        addSystemMessage("Hi. Welcome to Hereafter.", delay: 0.8)
        
        // Beat 2: Ask name
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            addSystemMessage("What's your first name?")
            isInputEnabled = true
            currentStep = .askName
        }
    }
    
    private func handleUserInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Show user's reply as a right-aligned bubble
        addUserReply(text)
        inputText = ""
        isInputEnabled = false
        
        switch currentStep {
        case .askName:
            handleNameInput(text)
        case .waitingForFirstMessage:
            // Future: handle first message composition
            break
        default:
            break
        }
    }
    
    private func handleNameInput(_ name: String) {
        currentStep = .greet
        
        // Beat 3: Greet by name
        addSystemMessage("Hey \(name). ✦", delay: 1.0)
        
        // Beat 4: Explain
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            addSystemMessage("Hereafter is simple. You leave a message to future-you, right where you are.")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                addSystemMessage("We lock it to this place and a date you choose. When you come back after that date — we'll let you know it's here.")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    addSystemMessage("That's it.")
                    currentStep = .askFirstMessage
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        chatItems.append(.quickReply(QuickReply(options: ["Leave my first one", "Not yet"])))
                        showQuickReplies = true
                    }
                }
            }
        }
    }
    
    private func handleQuickReply(_ option: String) {
        // Remove the quick reply buttons
        chatItems.removeAll { item in
            if case .quickReply = item { return true }
            return false
        }
        
        // Show their choice
        addUserReply(option)
        
        if option == "Leave my first one" {
            handleReadyToPlant()
        } else {
            handleNotYet()
        }
    }
    
    private func handleReadyToPlant() {
        // Request location permission conversationally
        if !locationManager.hasLocationPermission {
            addSystemMessage("To anchor your message here, I need to know where \"here\" is.", delay: 1.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.chatItems.append(.quickReply(QuickReply(options: ["Share my location"])))
                self.currentStep = .askPermission
                
                // When they tap, we'll request permission and complete onboarding
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func handleNotYet() {
        addSystemMessage("No rush. I'll be here when you're ready.", delay: 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        // Extract the name from the conversation
        let name = extractName()
        appState.completeOnboarding(firstName: name)
    }
    
    private func extractName() -> String {
        // Find the first user reply — that's their name
        for item in chatItems {
            if case .userMessage(let msg) = item {
                return msg.messageText
            }
        }
        // Fallback: look for user reply in our simple tracking
        return userReplies.first ?? "friend"
    }
    
    // MARK: - Chat Helpers
    
    @State private var userReplies: [String] = []
    
    private func addSystemMessage(_ text: String, delay: TimeInterval = 0.5) {
        // Show typing indicator
        let typingID = UUID()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay - 0.5)) {
            chatItems.append(.typing(id: typingID))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Remove typing indicator
            chatItems.removeAll { item in
                if case .typing(let id) = item { return id == typingID }
                return false
            }
            // Add the message
            chatItems.append(.system(SystemMessage(text)))
        }
    }
    
    private func addUserReply(_ text: String) {
        userReplies.append(text)
        // We use a dummy HereafterMessage to display user bubbles in onboarding
        let msg = HereafterMessage(
            id: UUID(),
            threadID: UUID(),
            parentMessageID: nil,
            latitude: 0, longitude: 0,
            placeName: nil,
            messageText: text,
            photoAssetID: nil,
            createdAt: Date(),
            unlockDate: Date(),
            creatorID: "onboarding",
            isRead: true
        )
        chatItems.append(.userMessage(msg))
    }
}

// MARK: - Preview

#Preview {
    OnboardingChatView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
