import Foundation
import AuthenticationServices

@available(iOS 13.0, *)
open class AppleSignInManager: NSObject {
    
    static let shared: AppleSignInManager = AppleSignInManager()
    
    var userData: LoginUserData? = nil
    var isShareImageVideo: Bool = false
    
    var image: UIImage?
    var videoURL: URL?
    
    weak var delegate: StoriCamManagerDelegate?

    var presentController: UIViewController?
    
    var isUserLogin: Bool {
        return Defaults.shared.currentUser != nil ? true : false
    }
    
    func loadUserData(completion: @escaping (_ userModel: LoginUserData?) -> ()) {
        if isUserLogin {
            if let existUserData = userData {
                completion(existUserData)
                return
            }
            if let userIdentifier = UserDefaults.standard.object(forKey: "userIdentifier") as? String {
                   let authorizationProvider = ASAuthorizationAppleIDProvider()
                   authorizationProvider.getCredentialState(forUserID: userIdentifier) { (state, error) in
                       switch (state) {
                       case .authorized:
                           print("Account Found - Signed In")
                           completion(nil)
                           break
                       case .revoked:
                           print("No Account Found")
                           completion(nil)
                           fallthrough
                       case .notFound:
                            print("No Account Found")
                            completion(nil)
                       default:
                           break
                       }
                   }
            }
        } else {
            completion(nil)
        }
    }
        
    public override init() {
        super.init()
        
    }
    
    func login(controller: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        self.presentController = controller
        handleAuthorizationAppleIDButtonPress()
    }
    
    func logout() {
        self.userData = nil
    
    }
    
    @objc func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.presentationContextProvider = self
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
}

@available(iOS 13.0, *)
extension AppleSignInManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        let id: String = appleIDCredential.user
        let email: String = appleIDCredential.email ?? ""
        let lname: String = appleIDCredential.fullName?.familyName ?? ""
        let fname: String = appleIDCredential.fullName?.givenName ?? ""
        let name: String = fname + lname
        let appleId: String = appleIDCredential.identityToken?.base64EncodedString() ?? ""
        print(appleIDCredential.email)
        let result =  String("ID:\(id),\n Email:\(email),\n  Name:\(name),\n  IdentityToken:\(appleId)")
        print(result)
        let userData = LoginUserData(userId: "\(id))", userName: name, email: email, gender: 0, photoUrl: "")
    }
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentController!.view.window!
    }
    
}
