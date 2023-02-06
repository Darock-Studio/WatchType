//
//  AW键盘.swift
//  WatchDic Watch App
//
//  Created by 凌嘉徽 on 2023/1/22.
//

import Foundation
import SwiftUI
import Combine

//有按钮点击的通知
let keyTap = PassthroughSubject<Void,Never>()

//用来表明输入的字符
struct charater:Identifiable,Equatable {
    var value:String
    var id = UUID()
}

struct AW键盘: View {
    var startText = ""
    let firstRow = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    let secondRow = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    let thirdRow = ["Z", "X", "C", "V", "B", "N", "M"]
    //存储输入的内容
    @State var fullText = [charater]()
    var body: some View {
        VStack(spacing:0) {
            文本显示View(fullText: $fullText, guangBiao: $guangBiao)
            //键盘上的三行按键
            EachRowView(allCharater: firstRow,dect: true,onTap: add)
            EachRowView(allCharater: secondRow,onTap: add)
            EachRowView(allCharater: thirdRow,onTap: add)
            //最底部三个按键
            BottomLine(guangBiao: $guangBiao, fullText: $fullText, upper: $upper, onTap: add)
        }
        //输入文字时带上动画
        .animation(.easeOut, value: fullText)
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("完成", action: {
                    dismiss()
                    onFinished(合成())
                })
            })
        }
        .edgesIgnoringSafeArea([.horizontal,.bottom])
        //允许从已有内容继续编辑
        .onAppear(perform: {
            startText.forEach { e in
                fullText.append(.init(value: String(e)))
            }
        })
        .onChange(of: fullText, perform: { value in
            //自动滚动（当用户把光标滑到屏幕外后，继续编辑时跳转回光标位置）
        })
    }
    //有按钮点击
    func add(_ t:String) {
        keyTap.send()
        var t = t
        if upper {
            t = (t).uppercased()
        } else {
            if 大写锁定 {
                t = (t).uppercased()
            } else {
                t = t.lowercased()
            }
        }
        //更新文本后记得移动光标
        if guangBiao == -1 {
            fullText.append(.init(value: t))
        } else {
            fullText.insert(.init(value: t), at: guangBiao)
            guangBiao += 1
        }
    }
    func 合成() -> String {
        var back = ""
        fullText.forEach { e in
            back += e.value
        }
        return back
    }
    @State var upper = false//是否大写
    @State var guangBiao = -1//光标的位置
    @Environment(\.dismiss) var dismiss
    var onFinished:(String) -> () = { _ in }
}
struct 文本显示View: View {
    @Binding var fullText : [charater]
    @Binding var guangBiao:Int
    @Namespace private var MYGuangBiao
    var body: some View {
        VStack {
            ScrollViewReader(content: { p in
                ScrollView(.horizontal, showsIndicators: false, content: {
                    HStack(spacing: 0, content: {
                        ForEach(fullText, content: { c in
                            let index = fullText.firstIndex(where: { $0.id == c.id })!
                            HStack(spacing: 0) {
                                if guangBiao == index {
                                    Color.red
                                        .frame(width: 5)
                                        .matchedGeometryEffect(id: "ID", in: MYGuangBiao)
                                        .id("光标")
                                }
                                Text(c.value)
                                    .padding(.bottom)
                                    .onTapGesture {
                                        guangBiao = index
                                    }
                            }
                            
                        })
                        if guangBiao == -1 {
                            Color.red
                                .frame(width: 5)
                                .matchedGeometryEffect(id: /*@START_MENU_TOKEN@*/"ID"/*@END_MENU_TOKEN@*/, in: MYGuangBiao)
                                .id("光标")
                        }
                        Color.black
                            .frame(width: fullWidth/2)
                        
                            .onTapGesture {
                                guangBiao = -1
                            }
                    })
                })
                .onChange(of: fullText, perform: { f in
                    withAnimation(.easeOut) {
                        p.scrollTo("光标", anchor: .trailing)
                    }
                })
            })
        }
    }
}
var 大写锁定 = false
struct EachRowView: View {
    
    var allCharater:[String]
    var dect = false
    var onTap:(String) -> ()
    var body: some View {
        HStack(spacing:0) {
            ForEach(allCharater,id: \.self) { c in
                Button(action: {
                    onTap(c)
                }) {
                    Color("Color")
                        .frame(width:fullWidth/CGFloat(10))
                        .overlay {
                            Text(c)
                        }
                }
                .buttonStyle(.plain)
            }
            
        }
        
    }
}

struct BottomLine: View {
    @Binding var guangBiao:Int
    @Binding var fullText: [charater]
    @Binding var upper:Bool
    var onTap:(String) -> ()
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    @State var lastTimeTap = Date.distantPast
    let timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
    fileprivate func 删除一个() {
        if guangBiao == -1 {
            fullText = fullText.dropLast()
        } else {
            let index = guangBiao-1
            if index >= fullText.startIndex && index <= fullText.endIndex {
                fullText.remove(at: index)
                guangBiao -= 1
            } else {
                //Drop Once
            }
            
        }
    }
    
    var body: some View {
        
        HStack(spacing:0) {
            Button( action: {
                if lastTimeTap.distance(to: .now) < 0.3 {
                    if upper {
                        print("锁定")
                        大写锁定 = true
                    } else {
                        //小写下双击，忽略
                        大写锁定 = false
                    }
                } else {
                    upper.toggle()
                    大写锁定 = false
                }
                lastTimeTap = .now
            }, label: {
                Color.green
                    .overlay {
                        if upper {
                            Image(systemName: "arrow.up.square.fill")
                        } else {
                            Image(systemName: "arrow.up.square")
                        }
                    }
            })
            .onReceive(keyTap, perform: { _ in
                if !大写锁定 {
                    upper = false
                }
            })
            Button( action: {
                onTap(" ")
            }, label: {
                HStack(spacing:0) {
                    Color.brown
                    Color.brown
                }
                .overlay {
                    Image(systemName: "space")
                }
            })
            
            Button( action: {
                删除一个()
            }, label: {
                Color.blue
                    .overlay {
                        Image(systemName: "delete.left.fill")
                    }
            })
            .simultaneousGesture(LongPressGesture(minimumDuration: 999)
                .updating($isDetectingLongPress) { currentState, gestureState,
                    transaction in
                    gestureState = currentState
                    transaction.animation = Animation.easeIn(duration: 2.0)
                    
                })
            .onChange(of: isDetectingLongPress, perform: { i in
                手势触发 = i
                if i {
                    触发时间 = .now
                }
            })
            //支持长按
        }      .buttonStyle(.plain)
            .onReceive(timer, perform: { i in
                if 手势触发 {
                    if 触发时间.distance(to: .now) > 0.3 {
                        删除一个()
                    }
                }
            })
    }
    @State var 触发时间 = Date.now
    @State var 手势触发 = false
}


private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
var h = 0.0
let fullWidth = WKInterfaceDevice.current().screenBounds.size.width

import Combine

let finalWidth = CurrentValueSubject<Double,Never>(999.0)


struct AW键盘_Previews: PreviewProvider {
    static var previews: some View {
        AW键盘()
    }
}
