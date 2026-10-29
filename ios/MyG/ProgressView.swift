import SwiftUI
import Charts

struct ProgressTrackerView: View {
    @State private var selectedExercise: String = ""
    @State private var progressData: [ProgressPoint] = []
    @State private var isLoading = false
    @State private var showError = false
    @AppStorage("userId") private var userId: String = ""
    @State private var allExerciseNames: [String] = []

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("📈 Track Your Progress")
                    .font(.largeTitle.bold())
                    .padding(.top)

                Picker("Select Exercise", selection: $selectedExercise) {
                    ForEach(allExerciseNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                Button(action: {
                    fetchProgress(for: selectedExercise)
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Show Progress")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedExercise.trimmingCharacters(in: .whitespaces).isEmpty)

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Fetching data...")
                        Spacer()
                    }
                } else if showError {
                    Text("⚠️ No progress data found for “\(selectedExercise)”")
                        .foregroundColor(.red)
                        .font(.caption)
                } else if !progressData.isEmpty {
                    Text("📅 Volume Progress for \(selectedExercise.capitalized)")
                        .font(.headline)
                        .padding(.top)

                    Chart(progressData) {
                        LineMark(
                            x: .value("Date", $0.date),
                            y: .value("Volume", $0.volume)
                        )
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("Date", $0.date),
                            y: .value("Volume", $0.volume)
                        )
                    }
                    .frame(height: 300)
                    .padding(.bottom)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Progress Over Time")
        }
        .onAppear {
            WorkoutService.shared.getExerciseList(userId: userId) { names in
                DispatchQueue.main.async {
                    self.allExerciseNames = names
                    if selectedExercise.isEmpty, let first = names.first {
                        selectedExercise = first
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Data
    func fetchProgress(for exercise: String) {
        isLoading = true
        showError = false
        progressData = []

        let normalized = exercise
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        
        print("🔍 Fetching progress for exercise name: \(normalized)")
        
        WorkoutService.shared.getExerciseProgress(userId: userId, exerciseName: normalized) { result in
            DispatchQueue.main.async {
                isLoading = false
                if result.isEmpty {
                    showError = true
                } else {
                    showError = false
                    let sorted = result
                        .map { ProgressPoint(date: $0.key, volume: $0.value) }
                        .sorted { $0.date < $1.date }
                    self.progressData = sorted
                }
            }
        }
    }
}

// MARK: - Helper Struct
struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: String
    let volume: Double
}

#Preview {
    ProgressTrackerView()
}


