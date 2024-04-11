//
//  ContentView.swift
//  MoneyCounter
//
//  Created by Owner on 2023/06/24.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    @State var timerHandler : Timer?
    
    @State var stopTimerHandler: Timer? //ストップしている時間を測るタイマー
    
    @State var startTime: Date?//スタートボタンを押した時の時刻
    
    @State var stopCount = 0 //Stopボタンを押して待機している状態
    
    @State var userName = ""
    
    @State var elapsedTime = 0
    
    @State var money = 0
    
    @State var startFlag = false
    
    @State var stopFlag = false
    
    @State var recordFlag = false
    
    @State var yesFlag = false
    
    
    // 遅刻した場合500円奢りからスタート
    let defaultMoney = 500
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                Image("backgroundTimer")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                
                VStack(spacing: 30.0) {
                    Text("Money Counter")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .fontWeight(.heavy)
                    
                    Text("\(getDate())")
                        .font(.title)
                    
                    HStack(spacing: -8){
                        Text("User :")
                            .font(.title)
                            .foregroundColor(.black)
                        
                        Picker(selection: $userName, label: Text("ユーザを選択")) {
                            Text("Select User").font(.largeTitle).tag("")
                            Text("R.O").font(.largeTitle).tag("R.O")
                            Text("Y.K").font(.largeTitle).tag("Y.K")
                            Text("Y.M").font(.largeTitle).tag("Y.M")
                            Text("N.K").font(.largeTitle).tag("N.K")
                            Text("R.Y").font(.largeTitle).tag("R.Y")
                        }
                        
                    }
                    
                    
                    if userName != "" {
                        if startFlag == true {
                            let hour = Int(elapsedTime / 3600)
                            let hour_remainder = elapsedTime % 3600
                            let minutes = Int(hour_remainder / 60)
                            let second = hour_remainder % 60
                            
                            Text("\(String(format: "%02d:%02d:%02d", hour, minutes, second))")
                                .font(Font(UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .regular)))
                            
                            Text("+¥\(getShouldPayMoney())")
                                .font(.title)
                        }
                        
                        HStack {
                            if startFlag == true {
                                if stopFlag == false {
                                    Button {
                                        if let unwrapedTimerHandler = timerHandler {
                                            if unwrapedTimerHandler.isValid == true {
                                                unwrapedTimerHandler.invalidate()
                                            }
                                        }
                                        
                                        stopFlag = true
                                        stopTimer()//ストップしている時間を計測
                                        
                                    } label: {
                                        Text("STOP")
                                            .font(.title)
                                            .foregroundColor(Color.white)
                                            .frame(width: 140, height: 140)
                                            .background(Color("stopColor"))
                                            .clipShape(Circle())
                                        
                                    }
                                } else {
                                    Button {
                                        //　経過時間のリセット
                                        elapsedTime = 0
                                        startTime = nil
                                        stopCount = 0
                                        userName = ""
                                        startFlag = false
                                        stopFlag = false
                                        
                                        //リセットボタン押下時、ストップカウントタイマーを停止
                                        if let unwrapedStopTimerHandler = stopTimerHandler {
                                            if unwrapedStopTimerHandler.isValid == true {
                                                unwrapedStopTimerHandler.invalidate()
                                            }
                                        }
                                        
                                    } label: {
                                        Text("RESET")
                                            .font(.title)
                                            .foregroundColor(Color.white)
                                            .frame(width: 140, height: 140)
                                            .background(Color("resetColor"))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            if stopFlag == true || startFlag == false {
                                Button {
                                    startTimer()
                                    //一番最初にスタートボタン押下時、スタート時刻を取得
                                    if startTime == nil {
                                        startTime = Date()
                                    }
                                    
                                    startFlag = true
                                    stopFlag = false
                                    
                                    //スタートボタン押下時、ストップカウントタイマーを停止
                                    if let unwrapedStopTimerHandler = stopTimerHandler {
                                        if unwrapedStopTimerHandler.isValid == true {
                                            unwrapedStopTimerHandler.invalidate()
                                        }
                                    }
                                    
                                    
                                } label: {
                                    Text("START")
                                        .font(.title)
                                        .foregroundColor(Color.white)
                                        .frame(width: 140, height: 140)
                                        .background(Color("startColor"))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    
                    if stopFlag == true {
                        Button {
                            
                            recordFlag = true
                            startTime = nil
                            stopCount = 0
                            
                            //記録ボタン押下時、ストップカウントタイマーを停止
                            if let unwrapedStopTimerHandler = stopTimerHandler {
                                if unwrapedStopTimerHandler.isValid == true {
                                    unwrapedStopTimerHandler.invalidate()
                                }
                            }
                            
                        } label: {
                            Text("Record")
                                .font(.title)
                                .bold()
                            
                        }
                    }
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        LogView()
                    } label: {
                        Text("User Log")
                        
                    }
                }
            }
            
            .alert("確認", isPresented: $recordFlag) {
                HStack {
                    
                    Button("はい") {
                        // レコードの生成
                        let moneyModel = MoneyModelV3()
                        let nextId = getNextId()
                        moneyModel.id = nextId
                        moneyModel.name = userName
                        moneyModel.date = getDate()
                        moneyModel.money = getShouldPayMoney()
                        
                        // 保存
                        do {
                            let realm = try Realm()
                            try realm.write {
                                realm.add(moneyModel)
                            }
                            
                        } catch {
                            print("データの保存に失敗しました: \(error)")
                        }
                        //　経過時間のリセット
                        elapsedTime = 0
                        userName = ""
                        startFlag = false
                        stopFlag = false
                        
                        yesFlag = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.yesFlag = false
                            
                        }
                        
                    }
                    Button("いいえ") {
                        
                    }
                    
                }
            } message: {
                Text("本当に記録しますか？")
            }
            
            .alert("", isPresented: $yesFlag) {
                Button("OK") {
                    
                }
            } message: {
                Text("記録しました")
                
            }
        } // NavigationStack
        
    }
    
    
    func getShouldPayMoney() -> Int {
        return money + defaultMoney
    }
    
    func getDate() -> String {
        let dt = Date()
        let dateFormatter = DateFormatter()
        
        // DateFormatter を使用して書式とロケールを指定する
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMdd", options: 0, locale: Locale(identifier: "ja_JP"))
        
        return dateFormatter.string(from: dt)
    }
    
    func stopCountUpTimer () {
        stopCount += 1
    }
    
    func stopTimer() {
        if let unwrapedStopTimerHandler = stopTimerHandler {
            if unwrapedStopTimerHandler.isValid == true {
                return
            }
        }
        
        stopTimerHandler = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            stopCountUpTimer()
        }
    }
    
    func moneyCalc() {
        //経過時間に対する金額を計算(10分経過毎に500円追加)
        money = elapsedTime / 600 * 500
    }
    
    func elapsedTimeCalc() {
        if let startTime = startTime {
            let currentTime = Date()//現在の時刻を取得
            elapsedTime = Int(currentTime.timeIntervalSince(startTime)) - stopCount//経過時間を計算(現在の時間 - スタート時の時間 - ストップ中の時間)
        }
        
        //経過時間に対する金額を計算する関数を起動
        moneyCalc()
    }
    
    func startTimer() {
        if let unwrapedTimerHandler = timerHandler {
            if unwrapedTimerHandler.isValid == true {
                return
            }
        }
        
        timerHandler = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTimeCalc()
        }
        
    }
    
    func getNextId() -> Int {
        do {
            let config = Realm.Configuration(schemaVersion: 2)
            Realm.Configuration.defaultConfiguration = config
            let realm = try Realm()
            let maxId = realm.objects(MoneyModelV3.self).max(ofProperty: "id") as Int?
            return (maxId ?? 0) + 1
        } catch {
            print("データの取得に失敗しました: \(error)")
            return 0
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
