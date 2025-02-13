@preconcurrency import ArgumentParser
import Foundation
import AsyncHTTPClient
import NIO

@main
struct Swurl: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "swurl",
        abstract: "A command-line tool to make HTTP requests."
    )

    @Argument(help: "The URL(s) to request.")
    var urls: [String] = []

    @Flag(name: .shortAndLong, help: "Enable verbose output.") 
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Enable interactive mode.")
    var interactive: Bool = false

    static func main() async throws {
        let command: Swurl = Self.parseOrExit()
        if command.interactive {
            while true {
                print("Enter a URL (or type 'exit' to quit): ", terminator: "")
                guard let input = readLine(), !input.isEmpty else {
                    continue
                }
                if input.lowercased() == "exit" {
                    break
                }
            }
        } else {
            try await command.runAsync()
        }
    }

    func runAsync() async throws {

        let client: AsyncHTTPClient = AsyncHTTPClient()
        defer {
            client.shutdown()
        }
        // Create an array of tasks to run concurrently
        let tasks: [Task<((url: String, response: String)), Error>] = urls.map { url in
            Task {
                do {
                    let response: HTTPClient.Response = try await client.get(url: url)
                    guard let body: ByteBuffer = response.body else {
                        print("No body for URL: \(url)")
                        return (url: "\(url)", response: "")
                    }
                    let data = Data(body.readableBytesView)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        return (url: "\(url)", response: "\(jsonString)")
                    } else {
                        print("Failed to convert response body to string for URL: \(url)")
                        throw SwurlError.failed(url: url, error: "Failed to convert response body to string")
                    }
                } catch {
                    print("Failed to fetch URL: \(url), error: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        // Wait for all tasks to complete
        for task in tasks {
            let result = try await task.value
            print(result)
        }
    }

    enum SwurlError: Error {
        case invalidURL
        case invalidResponse
        case failed(url: String, error: String)
    }
}