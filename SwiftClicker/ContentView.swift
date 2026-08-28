//
//  ContentView.swift
//  SwiftClicker v3.0
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var numberper = 1
    @State private var numbernum = 0
    @State private var numberpercost = 10
    @AppStorage("customCode") private var code = "123"
    @AppStorage("backgroundImagePath") private var backgroundImagePath = ""
    @State private var incode = ""
    @State private var developeractive = false
    @State private var showsDeveloperCodeField = false
    @State private var numberadd = ""
    @State private var addclicksstatus = false
    @State private var errorMessage = ""
    @State private var showsSettings = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 5) {
                Image(systemName: "gearshape")
                    .imageScale(.large)
                    .foregroundStyle(.white)
                Text("SwiftClicker v3.0")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("")
                Text("Clicks: \(numbernum)")
                Text("Per Click: \(numberper)")
                Button("Click") {
                    Task {
                        let (result, overflow) = numbernum.addingReportingOverflow(numberper)
                        numbernum = overflow ? Int.max : result
                    }
                }
                .buttonStyle(.glass)
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
                                } else {
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
                                let (result, overflow) = numbernum.addingReportingOverflow(clicksToAdd)
                                numbernum = overflow ? Int.max : result
                                errorMessage = ""
                            } else {
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
        .overlay(alignment: .bottomLeading) {
            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
            }
            .buttonStyle(.glass)
            .padding(12)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if !backgroundImagePath.isEmpty, let nsImage = NSImage(contentsOfFile: backgroundImagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 8, opaque: true)
                .ignoresSafeArea()
        } else {
            Image("AppBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 8, opaque: true)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
