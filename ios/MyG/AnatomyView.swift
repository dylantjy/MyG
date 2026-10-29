import SwiftUI

struct MuscleTierMatrixView: View {
    @AppStorage("userId") private var userId: String = ""
    @State private var muscleTiers: [String: String] = [:]
    @State private var showResults = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    Spacer()
                    ProgressView("Analyzing…")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Spacer()
                } else if showResults {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("💪 Muscle Tier Analysis")
                            .font(.title2.bold())
                            .padding(.bottom, 8)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(sortedMuscles, id: \.self) { muscle in
                                    HStack {
                                        Text(muscle.capitalized)
                                        Spacer()
                                        Text(muscleTiers[muscle] ?? "Untouched")
                                            .padding(6)
                                            .background(tierColor(for: muscle).opacity(0.2))
                                            .foregroundColor(.primary)
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        Button {
                            showResults = false
                            muscleTiers = [:]
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .padding()
                } else {
                    Spacer()

                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundColor(.blue.opacity(0.7))
                        .padding(.bottom, 8)

                    Text("Muscle Analysis")
                        .font(.title.bold())

                    Text("Press below to analyze your muscle tiers based on your logged workouts.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Button {
                        runAnalysis()
                    } label: {
                        Text("Get Analysis")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Muscle Analysis")
        }
    }

    var sortedMuscles: [String] {
        [
            "upper chest", "mid chest", "front delts", "side delts", "rear delts",
            "biceps", "triceps", "upper back", "lats", "core", "quads", "hamstrings"
        ]
    }

    func runAnalysis() {
        isLoading = true
        WorkoutService.shared.analyzeMuscleTiers(userId: userId) { tiers in
            DispatchQueue.main.async {
                self.isLoading = false
                self.showResults = true
                self.muscleTiers = tiers
            }
        }
    }

    func tierColor(for muscle: String) -> Color {
        switch muscleTiers[muscle] ?? "Untouched" {
        case "Elite": return .green
        case "Intermediate": return .yellow
        case "Beginner": return .orange
        default: return .gray
        }
    }
}

#Preview {
    MuscleTierMatrixView()
}
