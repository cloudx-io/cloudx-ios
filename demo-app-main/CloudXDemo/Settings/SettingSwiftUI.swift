//
//  SettingSwiftUI.swift
//  CloudXDemo
//
//  Created by bkorda on 17.05.2024.
//

import SwiftUI
import CloudXCore

struct SettingSwiftUI: View {
    
    let networkManager = NetworkManager()
    
    var settings = UserDefaultsSettings()
    @StateObject var locationManager = LocationManager()
    
    @State var appKey: String = ""
    @State var initURL: String = ""
    
    @State var bannerPlacement: String = ""
    @State var mrecPlacement: String = ""
    @State var interstitialPlacement: String = ""
    @State var rewardedPlacement: String = ""
    @State var nativeSmallPlacement: String = ""
    @State var nativeMediumPlacement: String = ""
    
    @State var consentString: String = ""
    @State var usPrivacyString: String = ""
    @State var gdprApplies: SettingsOption = .none
    @State var gdpr: SettingsOption = .none
    @State var age: SettingsOption = .none
    @State var dns: SettingsOption = .none
    
    @State var userTargeting: Bool = false
    @State var configLoading: Bool = false
    
    @State var localAppConfigModel: AppConfigModel = defaultConfigModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("SDK Settings")) {
                    TextInputField("App Key", text: $appKey)
                    //                        .customAlert(isPresented: $configLoading) {
                    //                            HStack(spacing: 16) {
                    //                                ProgressView()
                    //                                    .progressViewStyle(.circular)
                    //                                    .tint(.blue)
                    //                                Text("Processing...")
                    //                                    .font(.headline)
                    //                            }
                    //                        } actions: {
                    //                            Button(role: .cancel) {
                    //                                // Cancel Action
                    //                            } label: {
                    //                                Text("Cancel")
                    //                            }
                    //                        }
                        .onChange(of: appKey) {
                            //loadAppConfig()
                            
                            //                            Toggle("Loading App Config ...", isOn: $configLoading)
                            //                            if configLoading {
                            //                            ProgressAlert() {
                            //                                print("")
                            //                            }
                            //                                ActivityIndicator().frame(width: 50, height: 50)
                            //                            } else {
                            //                                ActivityIndicator().hidden()
                            //                            }
                            //.frame(width: 50, height: 50)
                            
                            settings.appKey = $0 }
                    
                    TextInputField("Init URL", text: $initURL)
                        .onChange(of: initURL) { settings.initURL = $0 }
                    //ActivityIndicator().hidden()
                }
                
                Section(header: Text("Placement Settings")) {
                    ForEach(localAppConfigModel.layout.screens.banner.standard, id: \.id) { banner in
                        TextDefaultView("Banner Placements:", text: banner.placementName)
                    }
                    //                    TextInputField("Banner Placement", text: $bannerPlacement)
                    //                        .onChange(of: bannerPlacement) { settings.bannerPlacement = $0 }
                    ForEach(localAppConfigModel.layout.screens.banner.mrec, id: \.id) { mrec in
                        TextDefaultView("MREC Placements:", text: mrec.placementName)
                    }
                    //                    TextInputField("MREC Placement", text: $mrecPlacement)
                    //                        .onChange(of: mrecPlacement) { settings.mrecPlacement = $0 }
                    ForEach(localAppConfigModel.layout.screens.native.small, id: \.id) { small in
                        TextDefaultView("Native Small Placements:", text: small.placementName)
                    }
                    //                    TextInputField("Native Small Placement", text: $nativeSmallPlacement)
                    //                        .onChange(of: nativeSmallPlacement) { settings.nativeSmallPlacement = $0 }
                    ForEach(localAppConfigModel.layout.screens.native.medium, id: \.id) { medium in
                        TextDefaultView("Native Medium Placements:", text: medium.placementName)
                    }
                    //                    TextInputField("Native Medium Placement", text: $nativeMediumPlacement)
                    //                        .onChange(of: nativeMediumPlacement) { settings.nativeMediumPlacement = $0 }
                    ForEach(localAppConfigModel.layout.screens.interstitial.def ?? [], id: \.id) { interstitial in
                        TextDefaultView("Interstitial Placements:", text: interstitial.placementName)
                    }
                    //                    TextInputField("Interstitial Placement", text: $interstitialPlacement)
                    //                        .onChange(of: interstitialPlacement) { settings.interstitialPlacement = $0 }
                    ForEach(localAppConfigModel.layout.screens.rewarded.def ?? [], id: \.id) { rewarded in
                        TextDefaultView("Rewarded Placements:", text: rewarded.placementName)
                    }
                    //                    TextInputField("Rewarded Placement", text: $rewardedPlacement)
                    //                        .onChange(of: rewardedPlacement) { settings.rewardedPlacement = $0 }
                }
                
                Section(header: Text("IAB TCFv2 (GDPR)")) {
                    Picker("GDPR Applies", selection: $gdprApplies) {
                        ForEach(SettingsOption.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .onChange(of: gdprApplies) { settings.gdprApplies = $0 }
                    
                    TextInputField("TC string", text: $consentString)
                        .onChange(of: consentString) { settings.consentString = $0 }
                }
                
                Section(header: Text("IAB CCPA")) {
                    TextInputField("US Privacy String", text: $usPrivacyString)
                        .onChange(of: usPrivacyString) { settings.usPrivacy = $0 }
                }
                
                Section(header: Text("Manual Privacy API")) {
                    Picker("GDPR Consent", selection: $gdpr) {
                        ForEach(SettingsOption.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .onChange(of: gdpr) {
                        settings.gdpr = $0
                        CloudXPrivacy.hasUserConsent = $0.boolValue
                    }
                    
                    Picker("COPPA (Age restricted)", selection: $age) {
                        ForEach(SettingsOption.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .onChange(of: age) {
                        settings.age = $0
                        CloudXPrivacy.isAgeRestrictedUser = $0.boolValue
                    }
                    
                    Picker("CCPA Do Not Sell", selection: $dns) {
                        ForEach(SettingsOption.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .onChange(of: dns) {
                        settings.dns = $0
                        CloudXPrivacy.isDoNotSell = $0.boolValue
                    }
                }
                
                Section(header: Text("Additional")) {
                    Toggle("User Targeting", isOn: $userTargeting)
                        .onChange(of: userTargeting) {
                            if $0 {
                                CloudXTargeting.shared.age = 32
                                CloudXTargeting.shared.gender = .male
                                CloudXTargeting.shared.yob = 1991
                                CloudXTargeting.shared.keywords = ["sports", "music", "movies"]
                                CloudXTargeting.shared.userID = "test_user"
                                CloudXTargeting.shared.data = ["key1": "value1", "key2": "value2"]
                            } else {
                                CloudXTargeting.shared.age = nil
                                CloudXTargeting.shared.gender = nil
                                CloudXTargeting.shared.yob = nil
                                CloudXTargeting.shared.keywords = nil
                                CloudXTargeting.shared.userID = nil
                                CloudXTargeting.shared.data = nil
                            }
                            
                            settings.userTargeting = $0
                        }
                    if locationManager.authorizationStatus == .notDetermined {
                        //ask location permission
                        Button("Ask for Location Permission") {
                            locationManager.askForLocationPermission()
                        }
                    } else {
                        Text("Location permission status: \(locationManager.authorizationStatus.debugDescription)")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                self.appKey = settings.appKey
                self.initURL = settings.initURL
                self.gdpr = settings.gdpr
                self.age = settings.age
                self.dns = settings.dns
                self.bannerPlacement = settings.bannerPlacement
                self.mrecPlacement = settings.mrecPlacement
                self.interstitialPlacement = settings.interstitialPlacement
                self.rewardedPlacement = settings.rewardedPlacement
                self.nativeSmallPlacement = settings.nativeSmallPlacement
                self.nativeMediumPlacement = settings.nativeMediumPlacement
                self.consentString = settings.consentString ?? ""
                self.usPrivacyString = settings.usPrivacy ?? ""
                
                UITextField.appearance().clearButtonMode = .whileEditing
            }
            .onSubmit {
                saveChanges()
                loadAppConfig()
            }
        }
    }
    
    func saveChanges() {
        settings.appKey = appKey
        settings.initURL = initURL
        settings.gdpr = gdpr
        settings.age = age
        settings.dns = dns
        settings.bannerPlacement = bannerPlacement
        settings.mrecPlacement = mrecPlacement
        settings.interstitialPlacement = interstitialPlacement
        settings.rewardedPlacement = rewardedPlacement
        settings.nativeSmallPlacement = nativeSmallPlacement
        settings.nativeMediumPlacement = nativeMediumPlacement
    }
    
    private func loadAppConfig() {
        configLoading.toggle()
        guard let url = URL(string: "https://cloudfront-dev.cloudx.io/demoapp/\(appKey).json") else { fatalError("Invalid URL") }
        
        networkManager.request(fromURL: url) { (result: Result<AppConfigModel, Error>) in
            
            switch result {
            case .success(let model):
                onSuccessLoad(model: model)
            case .failure(let error):
                debugPrint("We got a failure trying to get the app config. The error we got: \(error.localizedDescription)")
                onFailLoad()
            }
        }
    }
    
    private func onSuccessLoad(model: AppConfigModel) {
        localAppConfigModel = model
        appConfigModel = model
        let location = model.sdkConfiguration.location
        var initURLString = location.path + appKey + ".json"
        initURLString += "?type=\(location.type)"
        initURL = initURLString
        let ifa = model.sdkConfiguration.ifa ?? ""
        settings.ifa = ifa.contains("0000") || ifa.isEmpty ? "BDCBD082-174D-4C43-95E7-C16087356B48" : ifa
        settings.bundle = model.sdkConfiguration.bundle ?? ""
        settings.hashedUserId = model.sdkConfiguration.userInfo?.userEmailHashed
        settings.userId = model.sdkConfiguration.userInfo?.userEmail
        settings.keyValues = model.sdkConfiguration.keyValues
        if let seconds = model.sdkConfiguration.userInfo?.userIdRegisteredAtMS {
            settings.userIdMiliseconds = seconds
        }
        if let hashAlgo = model.sdkConfiguration.userInfo?.hashAlgo {
            settings.hashAlgo = hashAlgo
        }
        
        saveChanges()
        configLoading.toggle()
    }
    
    private func onFailLoad() {
        localAppConfigModel = defaultConfigModel
        appConfigModel = defaultConfigModel
        settings.ifa = ""
        settings.bundle = ""
        settings.hashedUserId = ""
        settings.userId = ""
        settings.userIdMiliseconds = 0
        settings.hashAlgo = ""
        settings.keyValues = [:]
        configLoading.toggle()
    }
    
}
#Preview {
    SettingSwiftUI()
}

struct TextInputField: View {
    
    @Binding var text: String
    let placeholder: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .foregroundStyle(text.isEmpty ? Color(.placeholderText) : Color.accentColor)
                .offset(y: text.isEmpty ? 0 : -25)
                .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
            TextField("", text: $text)
                .font(.subheadline)
        }
        .padding(.top, 13)
        .animation(.default, value: text)
    }
}

struct TextDefaultView: View {
    
    var text: String
    let placeholder: String
    
    init(_ placeholder: String, text: String) {
        self.text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .foregroundStyle(text.isEmpty ? Color(.placeholderText) : Color.accentColor)
                .offset(y: text.isEmpty ? 0 : -25)
                .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
            Text(text)
                .font(.subheadline)
        }
        .padding(.top, 13)
        .animation(.default, value: text)
    }
}



public struct ProgressAlert: View {
    public var closeAction: () -> Void

    public init(closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor(red: 0.05, green: 0.64, blue: 0.82, alpha: 1))))
                    Text("Processing...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                Divider()
                Button(action: closeAction, label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(red: 0.05, green: 0.64, blue: 0.82, alpha: 1)))
                })
                .foregroundColor(.black)
            }
            .padding(.vertical, 25)
            .frame(maxWidth: 270)
            .background(BlurView(style: .systemMaterial))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.primary.opacity(0.35)
        )
        .edgesIgnoringSafeArea(.all)
    }
}

public struct BlurView: UIViewRepresentable {
    public var style: UIBlurEffect.Style

    public func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

public struct ProgressAlert_Previews: PreviewProvider {
    static public var previews: some View {
        ProgressAlert(closeAction: {
            print("")
        })
    }
}
