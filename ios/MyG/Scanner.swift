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
                    .onTapGesture { isPickerPresented = true }

                Text("Tap the photo to choose another")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Description (optional)", text: $foodInput)
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
        guard let image = selectedImage else { return }

        isScanning = true
        resultText = nil

        uploadFoodPhoto(image, description: foodInput) { result in
            DispatchQueue.main.async {
                isScanning = false
                switch result {
                case .success(let data):
                    if let error = data["error"] as? String {
                        resultText = "⚠️ \(error)"
                    } else {
                        let dish = data["dish"] as? String ?? "Your meal"
                        let calories = data["calories"] as? Double ?? 0
                        let protein = data["protein"] as? Double ?? 0
                        let carbs = data["carbs"] as? Double ?? 0
                        let fat = data["fat"] as? Double ?? 0

                        resultText = """
                        \(dish)
                        Calories: \(Int(calories.rounded())) kcal
                        Protein: \(Int(protein.rounded()))g
                        Carbs: \(Int(carbs.rounded()))g
                        Fat: \(Int(fat.rounded()))g
                        """
                    }
                case .failure(let error):
                    resultText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Photo upload

// Sends the photo (downscaled to at most 1024px) and optional description to the backend's food scanner
func uploadFoodPhoto(_ image: UIImage, description: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard let url = URL(string: "\(APIConfig.baseURL)/smartscan/photo-macros") else {
        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }

    let maxSide: CGFloat = 1024
    let scale = min(1, maxSide / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let jpeg = resized.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not read the photo"])))
        return
    }

    let boundary = "Boundary-\(UUID().uuidString)"
    var body = Data()
    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedDescription.isEmpty {
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"description\"\r\n\r\n".utf8))
        body.append(Data("\(trimmedDescription)\r\n".utf8))
    }
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(Data("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".utf8))
    body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
    body.append(jpeg)
    body.append(Data("\r\n--\(boundary)--\r\n".utf8))

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 90

    URLSession.shared.uploadTask(with: request, from: body) { data, _, error in
        if let error = error {
            print("❌ Photo upload failed: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
            return
        }
        completion(.success(json))
    }.resume()
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
