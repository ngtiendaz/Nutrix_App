//
//  LoginViewModel.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isCheckingAuth: Bool = true
    
    private var router: AppRouter?
    
    
    
    var authService = FirebaseAuthService()
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func login(email: String, password: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        authService.signIn(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func register(email: String, password: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        authService.signUp(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loginWithGoogle() {
        self.isLoading = true
        authService.signInWithGoogle { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(_):
                    print("Google Login thành công")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func logout(){
        authService.logout()
        router?.changeRoot(to: .login)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.router?.resetAllPaths()
        }
    }
    
    func setRouter(_ router: AppRouter) {
            self.router = router
            setupBindings()
        }
    private func setupBindings() {
        authService.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                guard let self = self else { return }
                
                if loggedIn {
                    if self.router?.currentRoot == .splash {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.router?.changeRoot(to: .main)
                        }
                    } else {
                        self.router?.changeRoot(to: .main)
                    }
                } else {
                    if self.router?.currentRoot == .splash {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.router?.changeRoot(to: .login)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
