//
//  ContentView.swift
//  AirTroller
//
//  Created by exerhythm on 02.11.2022.
//

import SwiftUI
import Photos

struct ContentView: View {
    // For opening donation page
    @Environment(\.openURL) var openURL
    
    // Which people are selected
    @State var selectedPeople: [TDKSFNode: Bool] = [:]
    
    // Troll Controller, manages airdrop stuff
    @StateObject var trollController = TrollController(sharedURL: Bundle.main.url(forResource: "Trollface", withExtension: "png")!, rechargeDuration: 0.5)
    @State var rechargeDuration: Double = 0.5
    @State var showingImagePicker: Bool = false
    
    @State var totalAirDrops: Int = 0
    
    /// Custom selected image
    @State var imageURL: URL?
    
    private var gridItemLayout = [GridItem(.adaptive(minimum: 90, maximum: 110))]
    
    var body: some View {
        NavigationView {
            Group {
                if trollController.people.count == 0 { // No users in radius
                    VStack {
                        ProgressView()
                        Text("Searching for devices...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack {
                        ScrollView {
                            LazyVGrid(columns: gridItemLayout, spacing: 8) {
                                ForEach(trollController.people, id: \.node) { p in
                                    PersonView(person: p, selected: $selectedPeople[p.node])
                                        .environmentObject(trollController)
                                }
                            }
                        }
                        .padding()
                        VStack {
                            if trollController.isRunning { Text("Sent AirDrops: \(totalAirDrops)") }
                            HStack { // delay control between airdrops
                                Image(systemName: "timer")
                                Slider(value: $rechargeDuration, in: 0...3.5)
                                Text(String(format: "%.1fs", rechargeDuration))
                            }
                            Button("Select custom image/file") {
                                showPicker()
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor14: UIColor.secondarySystemFill    ))
                            .cornerRadius(8)
                            .sheet(isPresented: $showingImagePicker) {
                                ImagePickerView(imageURL: $imageURL)
                            }
                            
                            Button(!trollController.isRunning ? "Start trolling" : "Stop trolling") {
//                                guard selectedPeople.values.filter({ $0 == true }).count <= 2 else {
//                                    UIApplication.shared.alert(title: "Cannot start, too many users selected", body: "AirTroller only allows trolling up to 2 people at a time. Please unselect some users to continue.")
//                                    return
//                                }
                                // MARK: ~~people are physopaths~~ people ARE physopaths
                                
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred() // mmm
                                if !trollController.isRunning {
                                    UIApplication.shared.confirmAlert(title: "\(UIDevice.current.name)", body: "This is the current name of this device and the name people will see when receiving an AirDrop. Are you sure you want to continue?", onOK: {
                                        if let imageURL = imageURL {
                                            trollController.sharedURL = imageURL
                                        }
                                        trollController.startTrolling(shouldTrollHandler: { person in
                                            return selectedPeople[person.node] ?? false // troll only selected people
                                        }, eventHandler: { event in
                                            switch event {
                                            case .operationEvent(let event1):
                                                if event1 == .canceled || event1 == .finished || event1 == .blocked {
                                                    totalAirDrops += 1
                                                    UISelectionFeedbackGenerator().selectionChanged()
                                                }
                                            case .cancelled:
                                                totalAirDrops += 1
                                                UISelectionFeedbackGenerator().selectionChanged()
                                            }
                                        }) // start trolling :troll:
                                        trollController.isRunning.toggle()
                                    }, noCancel: false)
                                } else {
                                    trollController.stopTrollings()
                                    trollController.isRunning.toggle()
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("AirTroller")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        openURL(URL(string: "https://github.com/sourcelocation/AirTroller")!)
                    }) {
                        Image("github")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                    }
                    Button(action: {
                        openURL(URL(string: "https://ko-fi.com/sourcelocation")!)
                    }) {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            trollController.startBrowser()
        }
        .onChange(of: rechargeDuration) { newValue in
            trollController.rechargeDuration = newValue
        }
        
    }
    
    // shows a privacy req dialog if needed
    func showPicker() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                // show picker if authorized
                showingImagePicker = status == .authorized
            }
        }
    }
    
    struct PersonView: View {
        @State var person: TrollController.Person
        @Binding var selected: Bool?
        @EnvironmentObject var trollController: TrollController
        
        var body: some View {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if selected == nil { selected = false }
                selected?.toggle()
                remLog("selected", selected!)
            }) {
                VStack {
                    ZStack {
                        Image((selected ?? false) ? "TrolledPerson" : "NonTrolledPerson")
                    }
                    Text(person.displayName ?? "Unknown")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.init(uiColor14: .label))
                }
            }
            .disabled(trollController.isRunning)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
