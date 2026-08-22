//
//  ContentView.swift
//  SwiftClicker v1.02
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var numberper = 1
    @State private var numbernum = 0
    @State private var numberpercost = 10
    @State private var code = "123"
    @State private var incode = ""
    @State private var developeractive = false
    @State private var showsDeveloperCodeField = false
    @State private var numberadd = ""
    @State private var addclicksstatus = false
    @State private var errorMessage = ""
    var body: some View {
        VStack {
            Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("SwiftClicker v1.2")
            Text("")
            Text("Clicks: \(numbernum)")
            Text("Per Click: \(numberper)")
            Button("Click") {
                Task {
                    
                    numbernum += numberper
                    
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            
            Button("+1 per click. Cost \(numberpercost) Clicks") {
                
                numbernum -= numberpercost
                numberpercost *= 2
                numberper += 1
                
            }
            .disabled(numbernum < numberpercost)
            if !developeractive {
                Button("Custom mode") {
                    showsDeveloperCodeField = true
                }
                .font(.caption)
                .controlSize(.small)

                if showsDeveloperCodeField {
                    TextField("Code for custom mode", text: $incode)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onSubmit {
                            if incode == code {
                                print("Custom mode activated")
                                developeractive = true
                                showsDeveloperCodeField = false
                                errorMessage = ""
                            }
                            else {
                                errorMessage = "Error: Invalid code"
                                Task {
                                    try? await Task.sleep(for: .seconds(1))
                                    errorMessage = ""
                                }
                            }
                        }
                }
            }
            if developeractive {
                Text("Custom mode active")
                TextField("Add clicks", text: $numberadd)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        if let clicksToAdd = Int(numberadd) {
                            numbernum += clicksToAdd
                            errorMessage = ""
                        }
                        else {
                            errorMessage = "Error: Not a number"
                            Task {
                                try? await Task.sleep(for: .seconds(1))
                                errorMessage = ""
                            }
                        }
                    }
            }
            
        }
        .overlay(alignment: .bottom) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, -24)
            }
        }
        
    }
    
}

#Preview {
    ContentView()
}
