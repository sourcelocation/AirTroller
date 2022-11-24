//
//  ImagePickerView.swift
//  DebToIPA
//
//  Created by exerhythm on 18.10.2022.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var imageURL: URL?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            provider.loadFileRepresentation(forTypeIdentifier: "public.item") { [weak self] (url, error) in
                self?.parent.imageURL = url
            }
        }
    }
}
