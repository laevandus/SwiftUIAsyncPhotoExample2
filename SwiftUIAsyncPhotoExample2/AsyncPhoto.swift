//
//  AsyncPhoto.swift
//  AsyncPhotoExample
//
//  Created by Toomas Vahter on 04.12.2023.
//

import SwiftUI

struct AsyncPhoto<ID, Content, Progress, Placeholder>: View where ID: Hashable, Content: View, Progress: View, Placeholder: View {
    @State private var phase: Phase = .loading

    let id: ID
    let scaledSize: CGSize
    let cache: AsyncPhotoCaching
    let data: (ID) async -> Data?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let progress: () -> Progress

    init(id value: ID = "",
         scaledSize: CGSize,
         cache: AsyncPhotoCaching = AsyncPhotoCache.shared,
         data: @escaping (ID) async -> Data?,
         content: @escaping (Image) -> Content = { $0 },
         progress: @escaping () -> Progress = { ProgressView() },
         placeholder: @escaping () -> Placeholder = { Color(white: 0.839) }) {
        self.id = value
        self.cache = cache
        self.content = content
        self.data = data
        self.placeholder = placeholder
        self.progress = progress
        self.scaledSize = scaledSize
    }

    var body: some View {
        VStack {
            switch phase {
            case .success(let image):
                content(image)
            case .loading:
                progress()
            case .placeholder:
                placeholder()
            }
        }
        .frame(width: scaledSize.width, height: scaledSize.height)
        .task(id: id) {
            await load()
        }
    }

    @MainActor func load() async {
        if let image = cache.image(for: id, size: scaledSize) {
            phase = .success(Image(uiImage: image))
        }
        else {
            phase = .loading
            if let image = await prepareScaledImage(for: id) {
                guard !Task.isCancelled else { return }
                phase = .success(image)
            }
            else {
                guard !Task.isCancelled else { return }
                phase = .placeholder
            }
        }
    }

    private func prepareScaledImage(for id: ID) async -> Image? {
        guard let photoData = await data(id) else { return nil }
        guard let originalImage = UIImage(data: photoData) else { return nil }
        let scaledImage = await originalImage.scaled(toFill: scaledSize)
        guard let finalImage = await scaledImage.byPreparingForDisplay() else { return nil }
        cache.store(finalImage, forID: id)
        return Image(uiImage: finalImage)
    }
}

extension AsyncPhoto {
    enum Phase {
        case success(Image)
        case loading
        case placeholder
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    return Group {
        AsyncPhoto(id: "",
                   scaledSize: CGSize(width: 64, height: 64),
                   data: { _ in
            UIImage.filled(size: CGSize(width: 500, height: 500), fillColor: .systemOrange).pngData()
        })
        AsyncPhoto(scaledSize: CGSize(width: 64, height: 64),
                   data: { _ in
            UIImage.filled(size: CGSize(width: 500, height: 500), fillColor: .systemCyan).pngData()
        },
                   content: { image in
            image
                .clipShape(Circle())
        })
        AsyncPhoto(scaledSize: CGSize(width: 64, height: 64),
                   data: { _ in nil })
    }
}
