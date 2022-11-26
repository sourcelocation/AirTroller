import CoreGraphics
import Foundation

func browserCallbackFunction(browser: TDKSFBrowser, node: TDKSFNode, children: CFArray, _: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    let controller = Unmanaged.fromOpaque(context).takeUnretainedValue() as TrollController
    controller.handleBrowserCallback(browser: browser, node: node, children: children)
}

func operationCallback(operation: TDKSFOperation, rawEvent: TDKSFOperationEvent.RawValue, results: AnyObject, context: UnsafeMutableRawPointer?) {
    guard let event = TDKSFOperationEvent(rawValue: rawEvent) else { return }
    guard let context = context else { return }
    let controller = Unmanaged.fromOpaque(context).takeUnretainedValue() as TrollController
    controller.handleOperationCallback(operation: operation, event: event, results: results)
}

public class TrollController: ObservableObject {
    private enum Trolling {
        case operation(TDKSFOperation)
        case workItem(DispatchWorkItem)
        
        func cancel() {
            switch self {
            case .operation(let operation):
                TDKSFOperationCancel(operation)
            case .workItem(let workItem):
                workItem.cancel()
            }
        }
    }
    
    public class Person {
        var displayName: String?
        var node: TDKSFNode
        
        init(node: TDKSFNode) {
            self.displayName = TDKSFNodeCopyDisplayName(node) as? String ?? TDKSFNodeCopyComputerName(node) as? String ?? TDKSFNodeCopySecondaryName(node) as? String
            self.node = node
        }
    }
    
    /// The current browser
    private var browser: TDKSFBrowser?
    
    /// Currently known people
    @Published public var people: [Person]
    
    /// A map between known people and a Trolling (a currently running operation or a delayed work item)
    private var trollings: Dictionary<TDKSFNode, Trolling>
    
    /// The duration to wait after trolling before trolling again.
    public var rechargeDuration: TimeInterval
    
    /// The local file URL with which to troll. Defaults to a troll face image.
    public var sharedURL: URL
    
    /// Whether the scanner is currently active.
    @Published public var isRunning: Bool = false
    
    /// A block handler that allows for fine-grained control of whom to troll.
    public var shouldTrollHandler: (Person) -> Bool
    
    /// A handler to pass data about trolling back to UI
    private var eventHandler: ((TrollEvent) -> Void)?
    
    public enum TrollEvent {
        case cancelled
        case operationEvent(TDKSFOperationEvent)
    }
    
    public init(sharedURL: URL, rechargeDuration: TimeInterval) {
        TDKInitialize()
        people = []
        trollings = [:]
        self.rechargeDuration = rechargeDuration
        self.shouldTrollHandler = { _ in return true }
        self.sharedURL = sharedURL
    }
    
    deinit {
        stopBrowser()
    }
    
    /// Start the browser.
    public func startBrowser() {
        guard !isRunning else { return }
        
        var clientContext: TDKSFBrowserClientContext = (
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let browser = TDKSFBrowserCreate(kCFAllocatorDefault, kTDKSFBrowserKindAirDrop)
        TDKSFBrowserSetClient(browser, browserCallbackFunction, &clientContext)
        TDKSFBrowserSetDispatchQueue(browser, .main)
        TDKSFBrowserOpenNode(browser, nil, nil, 0)
        self.browser = browser
    }
    
    /// Start trolling nodes
    public func startTrolling(shouldTrollHandler: @escaping (Person) -> Bool, eventHandler: @escaping (TrollEvent) -> Void) {
        self.eventHandler = eventHandler
        for person in people {
            if shouldTrollHandler(person) {
                troll(node: person.node)
            }
        }
    }
    
    /// Stop the browser and clean up browsing state.
    public func stopBrowser() {
        guard isRunning else { return }
        
        // Cancel pending operations.
        stopTrollings()
        
        // Remove all known people
        people = []
        
        // Invalidate the browser.
        TDKSFBrowserInvalidate(browser!)
        browser = nil
    }
    
    public func stopTrollings() {
        for trolling in trollings.values {
            trolling.cancel()
        }
        
        // Empty operations map.
        trollings.removeAll()
    }
    
    /// Troll the person/device identified by \c node (\c TDKSFNodeRef)
    func troll(node: TDKSFNode) {
        guard trollings[node] == nil else { return } // only troll non-trolled people
        
        remLog("trolling \(node)")
        
        var fileIcon: CGImage?
        if let dataProvider = CGDataProvider(url: sharedURL as CFURL), let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
            fileIcon = image
        }
        
        var clientContext: TDKSFBrowserClientContext = (
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        // Create airdrop request
        let operation = TDKSFOperationCreate(kCFAllocatorDefault, kTDKSFOperationKindSender, nil, nil)
        TDKSFOperationSetClient(operation, operationCallback, &clientContext)
        TDKSFOperationSetProperty(operation, kTDKSFOperationItemsKey, [sharedURL] as AnyObject)
        
        // Set preview if possible
        if let fileIcon = fileIcon {
            TDKSFOperationSetProperty(operation, kTDKSFOperationFileIconKey, fileIcon)
        }
        
        // Set url of image
        TDKSFOperationSetProperty(operation, kTDKSFOperationNodeKey, Unmanaged.fromOpaque(UnsafeRawPointer(node)).takeUnretainedValue())
        TDKSFOperationSetDispatchQueue(operation, .main)
        TDKSFOperationResume(operation)
        
        // Add airdrop request to trollings to allow its cancellation later
        trollings[node] = .operation(operation)
    }
    
    func handleBrowserCallback(browser: TDKSFBrowser, node: TDKSFNode, children: CFArray) {
        let nodes = TDKSFBrowserCopyChildren(self.browser!, nil) as [AnyObject]
        var currentNodes = Set<TDKSFNode>(minimumCapacity: nodes.count)
        
        for nodeObject in nodes {
            let node = OpaquePointer(Unmanaged.passUnretained(nodeObject).toOpaque())
            currentNodes.insert(node)
        }
        
        // If we no longer know about a person, cancel their trolling.
        for oldID in Set(self.people.map { $0.node }).subtracting(currentNodes) {
            if let trolling = trollings.removeValue(forKey: oldID) {
                trolling.cancel()
            }
        }
        
        self.people = currentNodes.map { .init(node: $0 )}
    }
    
    func handleOperationCallback(operation: TDKSFOperation, event: TDKSFOperationEvent, results: CFTypeRef) {
        remLog("handleOperationCallback \(operation) event \(event)")
        eventHandler?(.operationEvent(event))
        
        switch event {
        case .askUser:
            // Seems that .askUser requires the operation to be resumed.
            TDKSFOperationResume(operation)
            
        case .waitForAnswer:
            // user started received data from attacker
            let nodeObject = TDKSFOperationCopyProperty(operation, kTDKSFOperationNodeKey)
            let node = OpaquePointer(Unmanaged.passUnretained(nodeObject).toOpaque())
            
            let workItem = DispatchWorkItem { [weak self] in
                self?.eventHandler?(.cancelled)
                self?.trollings[node]?.cancel() // cancelation of airdrop request
                self?.trollings[node] = nil
                
                if self?.isRunning ?? false { // dumb fix of a bug
                    self?.troll(node: node) // troll again :troll:
                }
            }
            // wait for airdrop to appear on target device. afaik there isn't a way to know when the alert appeared.
            DispatchQueue.main.asyncAfter(deadline: .now() + rechargeDuration, execute: workItem) // rechargeDuration is controlled via UI
        default:
            break
        }
    }
}
