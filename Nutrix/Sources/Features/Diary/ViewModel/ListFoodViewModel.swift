import Foundation
import Combine

@MainActor
class ListFoodViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Thêm biến để bind với Search Bar
    @Published var searchText: String = ""
    
    // Biến tính toán để trả về danh sách đã lọc
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return foods
        } else {
            return foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private let firebaseService: FirebaseService
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }
    
    func loadFoods() {
        self.isLoading = true
        self.errorMessage = nil
        
        firebaseService.fetchFoods { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let fetchedFoods):
                    self.foods = fetchedFoods
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("⚠️ Lỗi tải danh sách Food: \(error.localizedDescription)")
                }
            }
        }
    }
}
