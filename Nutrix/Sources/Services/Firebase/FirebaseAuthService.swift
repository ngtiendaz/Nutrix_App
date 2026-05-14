//
//  FirebaseAuth.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import FirebaseAuth
import SwiftUI
import Combine
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore

class FirebaseAuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var userPhotoURL: URL?
    
    private let tokenService = "com.daz.nutrix.token"
    private let account = "user-session"
    private let db = Firestore.firestore()

    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let result = result {
                    self.createNewUserInFirestore(authResult: result) // Tạo doc trên Firestore
                    self.saveUserToken()
                    completion(.success(result))
                }
            }
        }

    func signIn(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let result = result {
                    self.fetchUserData(userId: result.user.uid)
                    self.saveUserToken()
                    completion(.success(result))
                }
            }
        }
    
    // Hàm Đăng Xuất
    func logout() {
        do {
            try Auth.auth().signOut()
            // Xóa token trong Keychain khi logout
            KeychainHelper.shared.delete(service: tokenService, account: account)
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        } catch let error {
            print("Lỗi không thể đăng xuất: \(error.localizedDescription)")
        }
    }

    private func saveUserToken() {
        Auth.auth().currentUser?.getIDToken { token, error in
            if let token = token, let data = token.data(using: .utf8) {
                KeychainHelper.shared.save(data, service: self.tokenService, account: self.account)
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
            }
        }
    }
    
    func checkLoginStatus() {
            if KeychainHelper.shared.read(service: tokenService, account: account) != nil {
                if let firebaseUser = Auth.auth().currentUser {
                    self.fetchUserData(userId: firebaseUser.uid) 
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                    }
                }
            }
        }
    
    func signInWithGoogle(completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        // 1. Lấy cấu hình ClientID
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 2. Thực hiện đăng nhập thông qua Google SDK
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }

            // 3. Tạo Firebase Credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            // 4. Đăng nhập vào Firebase bằng Credential đó
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let authResult = authResult {
                    // 🔥 QUAN TRỌNG: Đồng bộ thông tin từ Firestore ngay khi đăng nhập xong
                    self?.handleGoogleUserSync(authResult: authResult)
                    
                    self?.saveUserToken()
                    completion(.success(authResult))
                }
            }
        }
    }

    // Hàm bổ trợ để đồng bộ dữ liệu Firestore sau khi Login Google
    private func handleGoogleUserSync(authResult: AuthDataResult) {
        let userId = authResult.user.uid
        
        // Kiểm tra xem User đã tồn tại trong Firestore chưa
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // Trường hợp 1: User cũ quay lại -> Chỉ cần fetch data về biến currentUser
                print("DEBUG: User cũ, đang tải dữ liệu hồ sơ...")
                self?.fetchUserData(userId: userId)
            } else {
                // Trường hợp 2: User mới đăng nhập lần đầu bằng Google -> Tạo hồ sơ mặc định
                print("DEBUG: User mới qua Google, đang tạo hồ sơ Firestore...")
                self?.createNewUserInFirestore(authResult: authResult)
            }
        }
    }
    
    private func createNewUserInFirestore(authResult: AuthDataResult) {
            let userId = authResult.user.uid
            let email = authResult.user.email ?? ""
            let name = authResult.user.displayName ?? email.components(separatedBy: "@").first ?? "Guest"
            
            let userData: [String: Any] = [
                "userId": userId,
                "email": email,
                "name": name,
                "createdAt": FieldValue.serverTimestamp()
                // Các trường age, weight... chưa có thì Firestore sẽ không tạo hoặc để null
            ]
            
            db.collection("users").document(userId).setData(userData) { error in
                if let error = error {
                    print("Lỗi tạo user: \(error.localizedDescription)")
                } else {
                    self.fetchUserData(userId: userId)
                }
            }
        }
    func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                DispatchQueue.main.async {
                    self.currentUser = User(dictionary: data)
                    
                    // Lấy ảnh từ Firebase Auth (thường có sẵn nếu login Google)
                    if let firebaseUser = Auth.auth().currentUser {
                        self.userPhotoURL = firebaseUser.photoURL
                    }
                    
                    print("DEBUG: Đã tải thông tin user: \(self.currentUser?.name ?? "")")
                }
            }
        }
    }
    // MARK: - Cập nhật thông tin cơ bản (Tên, Tuổi, Giới tính, Vận động)
    func updateBasicProfile(data: [String: Any], completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            if error == nil {
                self?.fetchUserData(userId: userId)
            }
            completion(error)
        }
    }

    // MARK: - Cập nhật Chiều cao & Cân nặng (Kèm lưu lịch sử)
    func updateBodyMetrics(height: Double, weight: Double, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userId)
        
        // 1. Lấy dữ liệu cũ để so sánh trạng thái tăng/giảm
        userRef.getDocument { [weak self] snapshot, error in
            let oldWeight = snapshot?.data()?["weight"] as? Double ?? weight
            
            // Xác định trạng thái
            var status = "Giữ nguyên"
            if weight > oldWeight { status = "Tăng" }
            else if weight < oldWeight { status = "Giảm" }
            
            let batch = self?.db.batch()
            
            // 2. Update dữ liệu chính của User
            batch?.updateData([
                "height": height,
                "weight": weight
            ], forDocument: userRef)
            
            // 3. Thêm vào sub-collection "weight_history"
            let historyRef = userRef.collection("body_metrics_history").document()
            batch?.setData([
                "height": height,
                "weight": weight,
                "status": status,
                "timestamp": FieldValue.serverTimestamp()
            ], forDocument: historyRef)
            
            // Thực thi Batch
            batch?.commit { error in
                if error == nil {
                    self?.fetchUserData(userId: userId)
                }
                completion(error)
            }
        }
    }
    func fetchBodyMetricsHistory(completion: @escaping (Result<[BodyMetrics], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("body_metrics_history")
            .order(by: "timestamp", descending: true) // Sắp xếp mới nhất lên đầu
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let metrics = snapshot?.documents.compactMap { doc in
                    BodyMetrics(id: doc.documentID, dictionary: doc.data())
                } ?? []
                completion(.success(metrics))
            }
    }
}
