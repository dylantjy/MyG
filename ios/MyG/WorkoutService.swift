//
//  WorkoutService.swift
//  MyG
//
//  Created by Dylan Teo on 18/6/25.
//
//  WorkoutService.swift
//  MyG

import Foundation

struct VolumeEntry: Codable {
    let date: String
    let volume: Double
}

class WorkoutService {
    static let shared = WorkoutService()
    private let baseURL = APIConfig.baseURL

    func getExerciseProgress(userId: String, exerciseName: String, completion: @escaping ([String: Double]) -> Void) {
        let normalized = exerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let encodedName = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("❌ Failed to encode exercise name")
            completion([:])
            return
        }
        
        print("🔍 Fetching progress for exercise name:", encodedName)

        let urlString = "\(baseURL)/workout/\(userId)/\(encodedName)/progress"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion([:])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error:", error)
                completion([:])
                return
            }

            guard let data = data else {
                print("❌ No data returned")
                completion([:])
                return
            }

            do {
                let decoded = try JSONDecoder().decode([VolumeEntry].self, from: data)
                var result: [String: Double] = [:]
                for entry in decoded {
                    result[entry.date] = entry.volume
                }
                completion(result)
            } catch {
                print("❌ JSON decoding error:", error)
                completion([:])
            }
        }.resume()
    }

    func getAllWorkouts(userId: String, completion: @escaping ([Workout]) -> Void) {
        guard let url = URL(string: "\(baseURL)/workout/\(userId)") else {
            print("❌ Invalid URL")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error:", error)
                completion([])
                return
            }

            guard let data = data else {
                print("❌ No data returned")
                completion([])
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                let decoded = try decoder.decode([Workout].self, from: data)
                completion(decoded)
            } catch {
                print("❌ JSON decoding error:", error)
                completion([])
            }
        }.resume()
    }

    func startWorkout(userId: String, date: String, name: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/workout/start") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "date": date,
            "name": name
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let workoutId = json["workoutId"] as? String {
                    completion(.success(workoutId))
                } else {
                    completion(.failure(NSError(domain: "", code: -2)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func addExercise(
        workoutId: String,
        exercise: Exercise,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/workout/\(workoutId)/add-exercise") else {
            print("❌ Invalid URL")
            completion(.failure(NSError(domain: "", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": exercise.name,
            "sets": exercise.sets,
            "reps": exercise.reps,
            "weights": exercise.weights
        ]
        
        print("📤 Sending exercise to backend with name:", exercise.name)

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Network error:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                print("❌ Server returned error")
                completion(.failure(NSError(domain: "", code: -2)))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func removeExercise(
        workoutId: String,
        exerciseName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let normalized = exerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")

        guard let encodedName = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/workout/\(workoutId)/remove-exercise") else {
            completion(.failure(NSError(domain: "", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": normalized
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                completion(.failure(NSError(domain: "", code: -2)))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func removeWorkout(workoutId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/workout/\(workoutId)") else {
            print("❌ Invalid URL")
            completion(.failure(NSError(domain: "", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Network error:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                print("❌ Server error or non-200 response")
                completion(.failure(NSError(domain: "", code: -2)))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func logWorkout(workoutId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/workout/\(workoutId)/log") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // AI feedback can take a while, especially the first call to a local model
        request.timeoutInterval = 120

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            if let decoded = try? JSONDecoder().decode(WorkoutLogResponse.self, from: data) {
                completion(.success(decoded.suggestions))
            } else {
                // Surface the server's message, e.g. "Invalid workout logged!" or the AI error
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let message = json?["message"] as? String ?? "Unexpected server response (HTTP \(status))"
                let detail = json?["error"] as? String
                print("❌ Log workout failed with HTTP \(status): \(message) \(detail ?? "")")
                completion(.failure(NSError(domain: "", code: status, userInfo: [NSLocalizedDescriptionKey: detail.map { "\(message) (\($0))" } ?? message])))
            }
        }.resume()
    }

    struct WorkoutLogResponse: Codable {
        let suggestions: String
    }

    func getExerciseList(userId: String, completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: "\(baseURL)/workout/\(userId)/exercise-list") else {
            print("❌ Invalid URL")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error:", error)
                completion([])
                return
            }

            guard let data = data else {
                print("❌ No data")
                completion([])
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String].self, from: data)
                completion(decoded.sorted())
            } catch {
                print("❌ Decoding error:", error)
                completion([])
            }
        }.resume()
    }
    
    func analyzeMuscleTiers(userId: String, completion: @escaping ([String: String]) -> Void) {
        guard let url = URL(string: "\(baseURL)/ai/muscle-tier-analysis") else {
            print("❌ Invalid URL")
            completion([:])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["userId": userId]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion([:])
                return
            }

            guard let data = data else {
                print("❌ No data received")
                completion([:])
                return
            }

            do {
                /// Outer JSON with dictionary inside `response`
                let wrapper = try JSONDecoder().decode([String: [String: String]].self, from: data)

                if let tiers = wrapper["response"] {
                    print("✅ Parsed tiers: \(tiers)")
                    completion(tiers)
                } else {
                    print("❌ `response` key not found")
                    completion([:])
                }

            } catch {
                print("❌ Decoding error: \(error)")
                completion([:])
            }
        }.resume()
    }


    
    func calculateMacros(for foodInput: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/ai/macros-calculator") else {
            print("❌ Invalid URL")
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["foodInput": foodInput]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                completion(.success(json))
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = Double(int)
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let int = value as? Int {
            try container.encode(int)
        }
    }
}
