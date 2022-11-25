import Foundation

public enum TDKSFOperationEvent: CFIndex {
    case unknown = 0
    case newOperation
    case askUser
    case waitForAnswer
    case canceled
    case started
    case preprocess
    case progress
    case postprocess
    case finished
    case errorOccurred
    case connecting
    case information
    case conflict
    case blocked
}

typealias TDKSFBrowserClientContext = (
    version: CFIndex,
    info: UnsafeMutableRawPointer?,
    retain: CFAllocatorRetainCallBack?,
    release: CFAllocatorReleaseCallBack?,
    copyDescription: CFAllocatorCopyDescriptionCallBack?
);

typealias TDKSFOperationClientContext = (
    version: CFIndex,
    info: UnsafeMutableRawPointer?,
    retain: CFAllocatorRetainCallBack?,
    release: CFAllocatorReleaseCallBack?,
    copyDescription: CFAllocatorCopyDescriptionCallBack?
);

typealias TDKSFBrowser = OpaquePointer
typealias TDKSFNode = OpaquePointer
typealias TDKSFOperation = OpaquePointer

private(set) var kTDKSFBrowserKindAirDrop: CFString!
private(set) var kTDKSFOperationKindSender: CFString!
private(set) var kTDKSFOperationFileIconKey: CFString!
private(set) var kTDKSFOperationItemsKey: CFString!
private(set) var kTDKSFOperationNodeKey: CFString!

typealias TDKSFBrowserCreateFunction = @convention(c) (_ alloc: CFAllocator?, _ kind: CFString?) -> TDKSFBrowser
private(set) var TDKSFBrowserCreate: TDKSFBrowserCreateFunction!

typealias TDKSFBrowserCallbackFunction = @convention(c) (_ browser: TDKSFBrowser, _ node: TDKSFNode, _ children: CFArray, _: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, _ context: UnsafeMutableRawPointer?) -> Void
typealias TDKSFBrowserSetClientFunction = @convention(c) (_ browser: TDKSFBrowser, _ callback: TDKSFBrowserCallbackFunction, _ clientContext: UnsafeMutableRawPointer/*<TDKSFBrowserClientContext>*/) -> Void
private(set) var TDKSFBrowserSetClient: TDKSFBrowserSetClientFunction!

typealias TDKSFBrowserSetDispatchQueueFunction = @convention(c) (_ browser: TDKSFBrowser, _ queue: DispatchQueue) -> Void
private(set) var TDKSFBrowserSetDispatchQueue: TDKSFBrowserSetDispatchQueueFunction!

typealias TDKSFBrowserOpenNodeFunction = @convention(c) (_ browser: TDKSFBrowser, _ node: TDKSFNode?, _ protocol: UnsafeMutableRawPointer?, _ flags: CFOptionFlags) -> Void
private(set) var TDKSFBrowserOpenNode: TDKSFBrowserOpenNodeFunction!

typealias TDKSFBrowserCopyChildrenFunction = @convention(c) (_ browser: TDKSFBrowser, _ node: TDKSFNode?) -> CFArray
private(set) var TDKSFBrowserCopyChildren: TDKSFBrowserCopyChildrenFunction!

typealias TDKSFBrowserInvalidateFunction = @convention(c) (_ browser: TDKSFBrowser) -> Void
private(set) var TDKSFBrowserInvalidate: TDKSFBrowserInvalidateFunction!

typealias TDKSFBrowserGetRootNodeFunction = @convention(c) (_ browser: TDKSFBrowser) -> TDKSFNode
private(set) var TDKSFBrowserGetRootNode: TDKSFBrowserGetRootNodeFunction!

typealias TDKSFNodeCopyDisplayNameFunction = @convention(c) (_ node: TDKSFNode) -> CFString?
private(set) var TDKSFNodeCopyDisplayName: TDKSFNodeCopyDisplayNameFunction!

typealias TDKSFNodeCopyComputerNameFunction = @convention(c) (_ node: TDKSFNode) -> CFString?
private(set) var TDKSFNodeCopyComputerName: TDKSFNodeCopyComputerNameFunction!

typealias TDKSFNodeCopySecondaryNameFunction = @convention(c) (_ node: TDKSFNode) -> CFString?
private(set) var TDKSFNodeCopySecondaryName: TDKSFNodeCopySecondaryNameFunction!

typealias TDKSFNodeCopyIDSDeviceIdentifierFunction = @convention(c) (_ node: TDKSFNode) -> CFString?
private(set) var TDKSFNodeCopyIDSDeviceIdentifier: TDKSFNodeCopySecondaryNameFunction!

typealias TDKSFOperationCreateFunction = @convention(c) (_ alloc: CFAllocator?, _ kind: CFString, _: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?) -> TDKSFOperation
private(set) var TDKSFOperationCreate: TDKSFOperationCreateFunction!

typealias TDKSFOperationCallbackFunction = @convention(c) (_ operation: TDKSFOperation, _ event: TDKSFOperationEvent.RawValue, _ results: AnyObject, _ context: UnsafeMutableRawPointer?) -> Void
typealias TDKSFOperationSetClientFunction = @convention(c) (_ operation: TDKSFOperation, _ callback: TDKSFOperationCallbackFunction, _ context: UnsafeMutableRawPointer/*<TDKSFOperationClientContext>*/) -> Void
private(set) var TDKSFOperationSetClient: TDKSFOperationSetClientFunction!

typealias TDKSFOperationSetDispatchQueueFunction = @convention(c) (_ operation: TDKSFOperation, _ queue: DispatchQueue) -> Void
private(set) var TDKSFOperationSetDispatchQueue: TDKSFOperationSetDispatchQueueFunction!

typealias TDKSFOperationCopyPropertyFunction = @convention(c) (_ operation: TDKSFOperation, _ name: CFString) -> AnyObject
private(set) var TDKSFOperationCopyProperty: TDKSFOperationCopyPropertyFunction!

typealias TDKSFOperationSetPropertyFunction = @convention(c) (_ operation: TDKSFOperation, _ name: CFString, _ value: AnyObject) -> Void
private(set) var TDKSFOperationSetProperty: TDKSFOperationSetPropertyFunction!

typealias TDKSFOperationResumeFunction = @convention(c) (_ operation: TDKSFOperation) -> Void
private(set) var TDKSFOperationResume: TDKSFOperationResumeFunction!

typealias TDKSFOperationCancelFunction = @convention(c) (_ operation: TDKSFOperation) -> Void
private(set) var TDKSFOperationCancel: TDKSFOperationCancelFunction!

var TDKIsInitialized = false
func TDKInitialize() {
    guard !TDKIsInitialized else { return }
    TDKIsInitialized = true

    let bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, "/System/Library/PrivateFrameworks/Sharing.framework" as CFString, .cfurlposixPathStyle, false)
    let bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL)
    assert(CFBundleLoadExecutable(bundle))

    let stringSymbolNames = ["kSFBrowserKindAirDrop", "kSFOperationKindSender", "kSFOperationFileIconKey", "kSFOperationItemsKey", "kSFOperationNodeKey"]
    var stringSymbolDestinations = Array<UnsafeMutableRawPointer?>(repeating: nil, count: stringSymbolNames.count)
    stringSymbolDestinations.withUnsafeMutableBufferPointer { bufferPointer in
        CFBundleGetDataPointersForNames(bundle, stringSymbolNames as CFArray, bufferPointer.baseAddress!)
    }

    func stringCast<T>(_ index: Int) -> T {
        return stringSymbolDestinations[index]!.assumingMemoryBound(to: T.self).pointee
    }

    kTDKSFBrowserKindAirDrop = stringCast(0)
    kTDKSFOperationKindSender = stringCast(1)
    kTDKSFOperationFileIconKey = stringCast(2)
    kTDKSFOperationItemsKey = stringCast(3)
    kTDKSFOperationNodeKey = stringCast(4)

    let functionSymbolNames = ["SFBrowserCreate", "SFBrowserSetClient", "SFBrowserSetDispatchQueue", "SFBrowserOpenNode", "SFBrowserCopyChildren", "SFBrowserInvalidate", "SFBrowserGetRootNode", "SFNodeCopyDisplayName", "SFNodeCopyComputerName", "SFNodeCopySecondaryName", "SFNodeCopyIDSDeviceIdentifier", "SFOperationCreate", "SFOperationSetClient", "SFOperationSetDispatchQueue", "SFOperationCopyProperty", "SFOperationSetProperty", "SFOperationResume", "SFOperationCancel"]

    var functionSymbolDestinations = Array<UnsafeMutableRawPointer?>(repeating: nil, count: functionSymbolNames.count)
    functionSymbolDestinations.withUnsafeMutableBufferPointer { bufferPointer in
        CFBundleGetFunctionPointersForNames(bundle, functionSymbolNames as CFArray, bufferPointer.baseAddress!)
    }

    func functionCast<T>(_ index: Int) -> T! {
        return unsafeBitCast(functionSymbolDestinations[index]!, to: T.self)
    }

    TDKSFBrowserCreate = functionCast(0)
    TDKSFBrowserSetClient = functionCast(1)
    TDKSFBrowserSetDispatchQueue = functionCast(2)
    TDKSFBrowserOpenNode = functionCast(3)
    TDKSFBrowserCopyChildren = functionCast(4)
    TDKSFBrowserInvalidate = functionCast(5)
    TDKSFBrowserGetRootNode = functionCast(6)
    TDKSFNodeCopyDisplayName = functionCast(7)
    TDKSFNodeCopyComputerName = functionCast(8)
    TDKSFNodeCopySecondaryName = functionCast(9)
    TDKSFNodeCopyIDSDeviceIdentifier = functionCast(10)
    TDKSFOperationCreate = functionCast(11)
    TDKSFOperationSetClient = functionCast(12)
    TDKSFOperationSetDispatchQueue = functionCast(13)
    TDKSFOperationCopyProperty = functionCast(14)
    TDKSFOperationSetProperty = functionCast(15)
    TDKSFOperationResume = functionCast(16)
    TDKSFOperationCancel = functionCast(17)
}
