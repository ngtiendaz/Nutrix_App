import Foundation

struct EdamamService {
    let appID = AppConfig.edamamAppID
    let appKey = AppConfig.edamamAppKey
    
    // Sửa hàm để trả về EdamamResponse (Optional)
    func fetchNutrition(for foodName: String) async -> EdamamResponse? {
        guard let encodedName = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        
        let urlString = "https://api.edamam.com/api/food-database/v2/parser?app_id=\(appID)&app_key=\(appKey)&ingr=\(encodedName)&nutrition-type=logging"
        
        guard let url = URL(string: urlString) else {
            print("URL không hợp lệ")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Lỗi server hoặc sai API Key")
                return nil
            }
            print("Đang lấy dữ liệu từ API Edamam")
            // Giải mã JSON vào Model EdamamResponse
            let decodedData = try JSONDecoder().decode(EdamamResponse.self, from: data)
            return decodedData
            
        } catch {
            print("Lỗi kết nối hoặc parse data: \(error.localizedDescription)")
            return nil
        }
    }
}
