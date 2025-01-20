import AsyncHTTPClient
import NIO
import NIOHTTP1

struct AsyncHTTPClient {
    let client: HTTPClient
    let eventLoopGroup: EventLoopGroup

    init() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.client = HTTPClient(eventLoopGroupProvider: .shared(self.eventLoopGroup))
    }

    func shutdown() {
        try? self.client.syncShutdown()
        try? self.eventLoopGroup.syncShutdownGracefully()
    }

    func request(url: String) async throws -> HTTPClient.Response {
        let request = try HTTPClient.Request(url: url)
        return try await self.client.execute(request: request).get()
    }

    func get(url: String, method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), body: HTTPClient.Body? = nil) async throws -> HTTPClient.Response {
        let request = try HTTPClient.Request(url: url, method: method, headers: headers, body: body)
        return try await self.client.execute(request: request).get()
    }
}