import SwiftUI
import UniformTypeIdentifiers

struct ShareView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var read: ReadStore
    @EnvironmentObject var recorder: Recorder

    @State private var format = 0          // 0 post · 1 story · 2 square · 3 carousel
    @State private var seconds = 3.0
    @State private var audioURL: URL?
    @State private var busy = false
    @State private var message = ""
    @State private var selection = 0

    private var theme: AppTheme { state.activeTheme }
    private var list: [Husna] {
        var l = read.todayNames
        if l.count < 5 { l = (0..<5).map { Names.byId((read.dayIndex + $0) % 99 + 1) } }
        return l
    }
    private var current: Husna { list[min(selection, list.count - 1)] }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                preview
                picker
                exportButtons
                audioSection
                recorderSection
                if !message.isEmpty {
                    Label(message, systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .frame(maxWidth: 900)
        }
        .disabled(!settings.shareOn)
        .overlay {
            if !settings.shareOn {
                Label("Sharing is switched off in Settings", systemImage: "eye.slash")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: preview

    private var preview: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { i, h in
                        Button { selection = i } label: {
                            Text("#\(h.id)")
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(selection == i ? theme.accent : Color.primary.opacity(0.06),
                                            in: Capsule())
                                .foregroundStyle(selection == i ? .white : .primary)
                        }.buttonStyle(.plain)
                    }
                }
            }

            GeometryReader { geo in
                let w = min(geo.size.width, format == 1 || format == 3 ? 300 : 420)
                let ratio: CGFloat = (format == 1) ? 9.0/16.0 : (format == 2 ? 1 : 4.0/5.0)
                Group {
                    ShareCard(husna: current, style: format == 1 ? .story : .post,
                              index: selection + 1, total: list.count)
                }
                .frame(width: w, height: w * ratio)
                .scaleEffect(geo.size.width / max(w, 1) > 1 ? 1 : 1)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 10)
            }
            .frame(height: format == 1 || format == 3 ? 420 : 380)
        }
    }

    private var picker: some View {
        Picker("Format", selection: $format) {
            Text("Post 4:5").tag(0)
            Text("Story / Reel 9:16").tag(1)
            Text("Square 1:1").tag(2)
            Text("Carousel").tag(3)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    // MARK: exports

    private var exportButtons: some View {
        SectionCard(title: "Export") {
            HStack(spacing: 12) {
                Button {
                    run {
                        if format == 3 {
                            let urls = ShareExport.carousel(list, settings)
                            return "Carousel saved: \(urls.count) PNGs in Desktop/AsmaulHusna"
                        }
                        let url: URL?
                        if format == 1 {
                            url = ShareExport.story(current, settings)
                        } else if format == 2 {
                            let view = ShareCard(husna: current, style: .post)
                                .environmentObject(settings).environmentObject(read)
                            let u = Capture.shareFolder()
                                .appendingPathComponent("square-\(current.id)-\(Capture.stamp()).png")
                            url = Capture.png(view, width: 1080, height: 1080, to: u) ? u : nil
                        } else {
                            url = ShareExport.post(current, settings)
                        }
                        guard let url else { return "Export failed." }
                        state.grantBadge("share1")
                        return "Saved \(url.lastPathComponent) → Desktop/AsmaulHusna"
                    }
                } label: {
                    Label(format == 3 ? "Export carousel" : "Export PNG", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)

                Button {
                    run {
                        let url = try await ShareExport.reel(list, audio: settings.audioInReel ? audioURL : nil,
                                                             secondsPerCard: seconds, settings)
                        state.grantBadge("reel1")
                        return "Reel saved: \(url.lastPathComponent) → Desktop/AsmaulHusna"
                    }
                } label: {
                    Label("Export reel (MP4)", systemImage: "video")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!settings.videoOn)
            }

            HStack {
                Text("Reel pacing: \(String(format: "%.1f", seconds))s per card")
                    .font(.caption).foregroundStyle(.secondary)
                Slider(value: $seconds, in: 1...8, step: 0.5)
                Text("\(list.count) cards · \(Int(seconds * Double(list.count)))s total")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }

            Text("1080×1350 for feed posts, 1080×1920 for stories, reels and square. "
                 + "Everything lands in Desktop/AsmaulHusna — upload straight to Instagram.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var audioSection: some View {
        SectionCard(title: "Audio for the reel") {
            HStack {
                Toggle("Add audio track", isOn: $settings.audioInReel)
                Spacer()
                if let a = audioURL {
                    Label(a.lastPathComponent, systemImage: "music.note")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Button("Clear") { audioURL = nil }.buttonStyle(.plain)
                }
                Button("Choose audio file…") { pickAudio() }
                    .disabled(!settings.audioInReel)
            }
            Text("Pick an m4a / mp3 / wav from your Mac; it is trimmed to the length of the reel. "
                 + "Leave it off for a silent reel or add music later in Instagram.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var recorderSection: some View {
        SectionCard(title: "Live window recording") {
            HStack {
                Toggle("Screen recording enabled", isOn: $settings.videoOn)
                Spacer()
                Button {
                    recorder.toggle()
                } label: {
                    Label(recorder.recording ? "Stop" : "Record window",
                          systemImage: recorder.recording ? "stop.circle.fill" : "record.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(recorder.recording ? .red : theme.accent)
                .disabled(!settings.videoOn)
            }
            if !recorder.status.isEmpty {
                Text(recorder.status).font(.caption).foregroundStyle(.secondary)
            }
            Text("Records this app's window to an MP4. macOS will ask for Screen Recording "
                  + "permission the first time (System Settings → Privacy & Security).")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: helpers

    private func run(_ work: @escaping () async throws -> String) {
        guard !busy else { return }
        busy = true
        message = "Working…"
        Task {
            do { message = try await work() }
            catch { message = error.localizedDescription }
            busy = false
        }
    }

    private func pickAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .mp3]
        panel.allowsMultipleSelection = false
        panel.message = "Choose a soundtrack for your reel"
        if panel.runModal() == .OK { audioURL = panel.url }
    }
}
