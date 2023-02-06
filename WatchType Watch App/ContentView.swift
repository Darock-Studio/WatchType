//
//  ContentView.swift
//  WatchType Watch App
//
//  Created by 凌嘉徽 on 2023/2/6.
//

import SwiftUI

struct ContentView: View {
    @State var show键盘 = false
    @State var 输入内容 = "Hello, world!"
    var body: some View {
        VStack {
            Button(action: {
                show键盘 = true
            }, label: {
                Text(输入内容)
            })
        }
        .padding()
        .sheet(isPresented: $show键盘, content: {
            AW键盘(startText: 输入内容) { finishedText in
                输入内容 = finishedText
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
