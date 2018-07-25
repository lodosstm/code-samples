//
//  BaseSocketsManager.swift
//
//  Created by dev on 12/12/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import SocketRocket

class BaseSocketsManager: NSObject, SRWebSocketDelegate {
    static let sharedInstance = BaseSocketsManager()
    var completionBlocksDict = [String:([String : Any]) -> Void]()
    var endpointsBlocksDict = [String : Any]()
    var socket : SRWebSocket = SRWebSocket()
    var reconnectTimer : Timer? = Timer()
    var sessionID = ""
    var reconnectInterval = TimeInterval()
    var isSocketOpen = false
    var completionHandler : (([String : Any]) -> Void)?
    
    override init() {
        super.init()
        subscribe()
    }
    
    deinit {
        unsubscribe()
    }
    
    //MARK: - Notifications -
    
    func subscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(BaseSocketsManager.handleApplicationDidEnterBackground(notification:)), name: Notification.Name("UIApplicationDidEnterBackgroundNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BaseSocketsManager.handleApplicationWillEnterForeground(notification:)), name: Notification.Name("UIApplicationWillEnterForegroundNotification"), object: nil)
    }
    
    func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleApplicationDidEnterBackground(notification: Notification) {
        disconnectSocketOnBackground()
    }
    
    func handleApplicationWillEnterForeground(notification: Notification) {
        if !sessionID.isEmpty {
            connectSocket()
        }
    }
    
    //MARK: - Socket methods -
    
    func refreshSessionID() {
        if let cookies = CookiesManager.getCookiesFromUserDefaults() {
            sessionID = cookies[DictionaryKey.kSessionIDParameter] as! String
            reconnectInterval = SocketsData.kSocketReconnectIntervalStartValue
        }
    }
    
    func connectSocketWithCurrentSessionID() {
        refreshSessionID()
        
        let isCurrentlyConnected = (socket.readyState != .OPEN)
        if isCurrentlyConnected {
            socket.close()
        }
        
        connectSocket()
    }
    
    func connectSocket() {
        cancelSocketReconnection()
        
        if sessionID.isEmpty {
            print("Tried to connect socket with empty session ID.")
            return
        }
        let request : NSMutableURLRequest = NSMutableURLRequest(url: URL(string: SocketsData.kSocketHost)!)
        request.setValue(String(format:"%@=%@", DictionaryKey.kSessionIDParameter, sessionID), forHTTPHeaderField: DictionaryKey.kCookieParameter)
        socket = SRWebSocket(urlRequest: request as URLRequest!)
        socket.delegate = self
        socket.open()
    }
    
    func scheduleSocketReconnection() {
        cancelSocketReconnection()
        
        reconnectTimer = Timer(timeInterval: reconnectInterval, target: self, selector: #selector(BaseSocketsManager.connectSocket
            ), userInfo: nil, repeats: false)
        if let timer = reconnectTimer {
            RunLoop.current.add(timer, forMode: .commonModes)
        }
        
        reconnectInterval += SocketsData.kSocketReconnectIntervalDelta
        if (reconnectInterval > SocketsData.kSocketReconnectIntervalMax) {
            reconnectInterval = SocketsData.kSocketReconnectIntervalMax
        }
    }
    
    func cancelSocketReconnection() {
        if let timer = reconnectTimer {
            timer.invalidate()
            reconnectTimer = nil
        }
    }
    
    func closeSocket() {
        sessionID = ""
        disconnectSocketOnBackground()
    }
    
    func disconnectSocketOnBackground() {
        cancelSocketReconnection()
        socket.close()
    }
    
    //MARK: - Socket delegate methods -
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        isSocketOpen = true
        reconnectInterval = SocketsData.kSocketReconnectIntervalStartValue
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        isSocketOpen = false
        sendSocketErrorNotification()
        connectSocket()
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isSocketOpen = false
        sendSocketErrorNotification()
        scheduleSocketReconnection()
    }
    
    func sendSocketErrorNotification() {
        let isAppSleeping = UIApplication.shared.applicationState != .active
        if (!isAppSleeping) {
            NotificationCenter.default.post(name:Notification.Name(LocalNotificationKey.kSocketError), object: self)
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        isSocketOpen = true
        let responseDict = DataFormatter.dictionatyFrom(JSONString: message as! String?)
        
        if let response = responseDict {
            if response[DictionaryKey.kErrorParameter] != nil {
                print(" ### WEBSOCKET ERROR ### didReceiveMessage: %@", message as! String)
            } else {
                print(" ### WEBSOCKET didReceiveMessage: %@", message as! String)
            }
            
            if let parameter = response[DictionaryKey.kParameterKey] {
                if (parameter as! String) == DictionaryKey.kHelloValue {
                    SocketNotificationManager.handleHelloNotification()
                } else {
                    let responseIDString = String(format:"%@", response[DictionaryKey.kIDKey] as! CVarArg)
                    let completionHandler: (([String : Any]) -> Void)? = completionBlocksDict[responseIDString]
                    if let completion = completionHandler {
                        if response[DictionaryKey.kErrorParameter] != nil {
                            let errorDict = response[DictionaryKey.kErrorParameter] as! [String : Any]
                            print("Got socket error: %@ with id: %@", errorDict[DictionaryKey.kMessageKey] as! CVarArg, responseIDString)
                            let requestString = endpointsBlocksDict[responseIDString] as? String
                            if let request = requestString {
                                if (!request.isEmpty && (errorDict[responseIDString] as! String) == DictionaryKey.kMethodNotFoundValue) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        socket.send(String(format:request, responseIDString))
                                        if endpointsBlocksDict[responseIDString] != nil {
                                            endpointsBlocksDict.removeValue(forKey: responseIDString)
                                        }
                                    }
                                }
                            }
                        } else {
                            if endpointsBlocksDict[responseIDString] != nil {
                                endpointsBlocksDict.removeValue(forKey: responseIDString)
                            }
                        }
                        completion(response[DictionaryKey.kResultKey] as! [String : Any])
                        if endpointsBlocksDict[responseIDString] != nil {
                            print("Endpoint is still stored")
                        } else {
                            removeCompletionBlockWith(idString: responseIDString)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Completion handling -
    
    func generateIDForBlock() -> String {
        var blockIDString = ""
        
        repeat {
            let blockID = arc4random_uniform(99999999)+1
            blockIDString = String(format:"%d", blockID)
        } while completionBlocksDict.keys.contains(blockIDString)
        
        return blockIDString
    }
    
    func addCompletionBlock(completion:@escaping (_ responseDict: [String : Any]) -> Void) -> String {
        let idString = generateIDForBlock()
        
        if (!idString.isEmpty) {
            completionBlocksDict[idString] = completion
        }
        
        if (completionBlocksDict.count > 250) {
            completionBlocksDict.removeAll()
        }
        
        return idString
    }
    
    func removeCompletionBlockWith(idString: String) {
        if !idString.isEmpty {
            completionBlocksDict.removeValue(forKey: idString)
        }
    }
    
    func send(request:String, parameters:String?, completion:((_ responseDict: [String : Any]) -> Void)?) {
        if (!isSocketOpen) {
            print("### Socket is not open!")
            return
        }
        if (socket.readyState != .OPEN) {
            print("### Socket is not connected!")
            return
        }
        if request.isEmpty {
            return
        }
        
        var idString = "0"
        if let completionBlock = completion {
            idString = addCompletionBlock(completion: completionBlock)
        }
        
        var finalRequestWithParams = ""
        if let parametersString = parameters {
            if !parametersString.isEmpty {
                finalRequestWithParams = String(format:request, parametersString, idString)
            }
        } else {
            finalRequestWithParams = String(format:request, idString)
        }
        endpointsBlocksDict[idString] = finalRequestWithParams
        socket.send(finalRequestWithParams)
        print("Sent socket request: <\(finalRequestWithParams)> with id: \(idString)")
    }
}
