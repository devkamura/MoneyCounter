//
//  LogView.swift
//  MoneyCounter
//
//  Created by 嘉村勇輝 on 2023/07/01.
//

import SwiftUI
import RealmSwift

struct LogView: View {
    @State var userName = ""
    
    @State var payFlag = false
    
    @State var payYesFlag = false
    
    @State var deleteFlag = false
    
    @State var deleteYesFlag = false
    
    @State var userLogList: Results<MoneyModelV3>?
    
    @State var recordId = 0
    
    var body: some View {
        ZStack{
            VStack{
                Text("User Log")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .top)
                
                List {
                    Section(header:
                                HStack {
                        Text("Date")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                        Text("User")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                        Text("Money")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                        .font(.headline)
                    ) {
                        if let userLogList =  getUserLog() {
                            if let frozenUserLogList = userLogList.freeze() {
                                ForEach(frozenUserLogList.prefix(5), id: \.self) { record in
                                    HStack{
                                        Text(record.date)
                                            .font(.system(size: 12))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .lineLimit(1)
                                        Text(record.name)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .lineLimit(1)
                                        Text("¥\(record.money)")
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .lineLimit(1)
                                    }
                                }
                                .onDelete { indices in
                                    if let userLogList = getUserLog(),  !userLogList.isEmpty {
                                        for index in indices {
                                            if index < userLogList.count {
                                                let record = userLogList[index]
                                                recordId = record.id
                                                deleteFlag = true
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                }
                .frame(height: 5 * 60)
                
                
                HStack(spacing: -8){
                    Text("User :")
                        .font(.title)
                        .foregroundColor(.black)
                    
                    Picker(selection: $userName, label: Text("ユーザーを選択")) {
                        Text("Select User").font(.largeTitle).tag("")
                        Text("R.O").font(.largeTitle).tag("R.O")
                        Text("Y.K").font(.largeTitle).tag("Y.K")
                        Text("Y.M").font(.largeTitle).tag("Y.M")
                        Text("N.K").font(.largeTitle).tag("N.K")
                        Text("R.Y").font(.largeTitle).tag("R.Y")
                    }
                }
                
                if userName != "" {
                    Text("Total : ¥\(getShouldPayMoney(userName: userName) ?? 0)")
                        .font(.title)
                    
                    if let shouldPayMoney = getShouldPayMoney(userName: userName){
                        if shouldPayMoney != 0 {
                            Button {
                                payFlag = true
                                
                            } label: {
                                Text("PAY")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 140, height: 140)
                                    .background(Color("payColor"))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Spacer()
            } // VStack
        } // ZStack
        
        .alert("確認", isPresented: $payFlag) {
            HStack {
                Button("はい") {
                    payYesFlag = true
                    payMoney(userName: userName)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.payYesFlag = false
                    }
                    
                }
                Button("いいえ") {
                    
                }
                
            }
            
        } message: {
            Text("本当に支払いますか？")
            
        }
        
        .alert("", isPresented: $payYesFlag) {
            Button("OK") {
                
            }
            
        } message: {
            Text("支払いました")
            
        }
        
        .alert("確認", isPresented: $deleteFlag) {
            HStack {
                Button("はい") {
                    deleteYesFlag = true
                    deleteUserLog(id: recordId)
                    recordId = 0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.deleteYesFlag = false
                        
                    }
                    
                }
                
                Button("いいえ") {
                    
                }
            }
        } message: {
            Text("本当に削除しますか？")
        }
        
        .alert("", isPresented: $deleteYesFlag) {
            Button("OK") {
                
            }
        } message: {
            Text("削除しました")
        }
    }
}

func getUserLog() -> Results<MoneyModelV3>? {
    let config = Realm.Configuration(schemaVersion: 2)
    Realm.Configuration.defaultConfiguration = config
    
    var userLogList: Results<MoneyModelV3>?
    do {
        let realm = try Realm()
        userLogList = realm.objects(MoneyModelV3.self).filter("deleted == false").sorted(byKeyPath: "id", ascending: false)
        if userLogList?.isEmpty == false {
        } else {
            print("レコードが見つかりませんでした")
        }
    } catch {
        print("Realmの初期化に失敗しました: \(error)")
    }
    return userLogList
}

func deleteUserLog(id: Int) {
    do {
        let config = Realm.Configuration(schemaVersion: 2)
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        
        let targetUserLog = realm.objects(MoneyModelV3.self).filter("id == \(id)")
        if !targetUserLog.isEmpty {
            print(targetUserLog[0])
            try realm.write {
                targetUserLog[0].deleted = true
            }
        } else {
            print("レコードが見つかりませんでした")
        }
    }catch {
        print("Error \(error)")
    }
}

func getShouldPayMoney(userName: String) -> Int? {
    let config = Realm.Configuration(schemaVersion: 2)
    Realm.Configuration.defaultConfiguration = config
    var shouldPayMoney: Int?
    do {
        let realm = try Realm()
        shouldPayMoney = realm.objects(MoneyModelV3.self).filter("name == %@ && deleted == false", userName).sum(ofProperty: "money")as Int?
    } catch {
        print("Realmの初期化に失敗しました: \(error)")
    }
    return shouldPayMoney
}

func payMoney(userName: String) {
    let config = Realm.Configuration(schemaVersion: 2)
    Realm.Configuration.defaultConfiguration = config
    
    do {
        let realm = try Realm()
        let userLog = realm.objects(MoneyModelV3.self).filter("name == %@ && deleted == false", userName)
        if !userLog.isEmpty {
            for record in userLog {
                do {
                    try realm.write {
                        record.deleted = true
                    }
                } catch {
                    print("レコードの更新中にエラーが発生しました: \(error)")
                }
            }
        } else {
            print("レコードが見つかりませんでした")
        }
    } catch {
        print("Realmの初期化に失敗しました: \(error)")
    }
    
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
    }
}
