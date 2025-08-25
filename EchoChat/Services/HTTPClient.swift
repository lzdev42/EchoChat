import Foundation
import Alamofire

// MARK: - HTTP 方法枚举
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - 网络错误
enum HTTPError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(Int, String?)
    case requestFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .noData:
            return "服务器未返回数据"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP 错误 \(code): \(message ?? "未知错误")"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 通用 HTTP 客户端
class HTTPClient {
    
    private let session: Session
    private let decoder: JSONDecoder
    
    init() {
        // 配置 URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 120.0
        
        self.session = Session(configuration: configuration)
        self.decoder = JSONDecoder()
    }
    
    /// 通用请求方法
    /// - Parameters:
    ///   - url: 请求 URL 字符串
    ///   - method: HTTP 方法
    ///   - headers: 请求头
    ///   - body: 请求体数据
    ///   - responseType: 响应类型
    /// - Returns: 解码后的响应对象
    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        // 验证 URL
        guard let requestURL = URL(string: url) else {
            throw HTTPError.invalidURL
        }
        
        // 构建请求头
        var httpHeaders = HTTPHeaders()
        for (key, value) in headers {
            httpHeaders[key] = value
        }
        
        // 创建 Alamofire 请求
        let alamofireMethod: Alamofire.HTTPMethod
        switch method {
        case .GET:
            alamofireMethod = .get
        case .POST:
            alamofireMethod = .post
        case .PUT:
            alamofireMethod = .put
        case .DELETE:
            alamofireMethod = .delete
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var request = session.request(
                requestURL,
                method: alamofireMethod,
                headers: httpHeaders
            )
            
            // 如果有请求体，添加请求体
            if let body = body {
                request = session.upload(body, to: requestURL, method: alamofireMethod, headers: httpHeaders)
            }
            
            request
                .validate()
                .responseData { response in
                    
                    switch response.result {
                    case .success(let data):
                        do {
                            let decoder = JSONDecoder()
                            let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            continuation.resume(throwing: HTTPError.decodingError(error))
                        }
                        
                    case .failure(let error):
                        if let httpResponse = response.response {
                            let statusCode = httpResponse.statusCode
                            let errorMessage = response.data.flatMap { String(data: $0, encoding: .utf8) }
                            continuation.resume(throwing: HTTPError.httpError(statusCode, errorMessage))
                        } else {
                            continuation.resume(throwing: HTTPError.requestFailed(error))
                        }
                    }
                }
        }
    }
    
    /// 便捷的 POST JSON 请求方法
    /// - Parameters:
    ///   - url: 请求 URL
    ///   - headers: 请求头
    ///   - jsonBody: 可编码的请求体对象
    ///   - responseType: 响应类型
    /// - Returns: 解码后的响应对象
    func postJSON<RequestBody: Codable, ResponseBody: Codable>(
        url: String,
        headers: [String: String] = [:],
        jsonBody: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        
        // 编码 JSON 请求体
        let encoder = JSONEncoder()
        let bodyData: Data
        do {
            bodyData = try encoder.encode(jsonBody)
        } catch {
            throw HTTPError.decodingError(error)
        }
        
        // 添加 JSON 请求头
        var jsonHeaders = headers
        jsonHeaders["Content-Type"] = "application/json"
        
        return try await request(
            url: url,
            method: .POST,
            headers: jsonHeaders,
            body: bodyData,
            responseType: responseType
        )
    }
}
