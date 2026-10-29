import SwiftUI
import PhotosUI

struct PhotoMacroScannerView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var foodInput: String = ""
    @State private var isScanning = false
    @State private var resultText: String? = nil
    @State private var isPickerPresented = false

    var body: some View {
        VStack(spacing: 16) {
            Text("📷 Macro Calculator")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 3)

                TextField("Describition (optional but recommended)", text: $foodInput)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            } else {
                Button {
                    isPickerPresented = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)

                        Text("Select a food photo")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            if isScanning {
                ProgressView("Analyzing...")
                    .padding()
            } else if selectedImage != nil {
                Button {
                    analyzePhoto()
                } label: {
                    Label("⚡️ Analyze Macros", systemImage: "waveform.path.ecg")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            if let result = resultText {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🍽 Estimated Macros")
                        .font(.headline)
                    Text(result)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(selectedImage: $selectedImage)
        }
    }

    func analyzePhoto() {
        guard !foodInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            resultText = "Please enter what food is in the photo for better accuracy."
            return
        }

        isScanning = true
        resultText = nil

        WorkoutService.shared.calculateMacros(for: foodInput) { result in
            DispatchQueue.main.async {
                isScanning = false
                switch result {
                case .success(let data):
                    if let error = data["error"] as? String {
                        resultText = "⚠️ \(error)"
                    } else {
                        let calories = data["calories"] as? Double ?? 0
                        let protein = data["protein"] as? Double ?? 0
                        let carbs = data["carbs"] as? Double ?? 0
                        let fat = data["fat"] as? Double ?? 0

                        resultText = """
                        Calories: \(calories)
                        Protein: \(protein)g
                        Carbs: \(carbs)g
                        Fat: \(fat)g
                        """
                    }
                case .failure(let error):
                    resultText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - PhotoPicker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoMacroScannerView()
}
