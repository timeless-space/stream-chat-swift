//
//  PollSelectLine.swift
//  StreamChatUI
//
//  Created by Phu Tran on 26/05/2022.
//

import SwiftUI

@available(iOS 15.0, *)
struct PollSelectLine: View {
    // MARK: - Input Parameter
    var item: PollBubbleView.AnswerRes
    var multipleChoices = true
    var hideTally = false
    var isPreview = false
    var isSender: Bool
    var listVotedAnswer: [String]
    @Binding var selectedAnswersID: [String]
    @Binding var voted: Bool
    @Binding var answers: [PollBubbleView.AnswerRes]
    @Binding var pollVotedCount: Double

    // MARK: - Properties
    @State private var chartLength: CGFloat = 0

    // MARK: - Computed Variables
    private var percent: CGFloat {
        pollVotedCount <= 0 ? 0 : (CGFloat(item.votedCount) / CGFloat(pollVotedCount) * 100)
    }

    private var checkMarkIcon: String {
        if !isPreview && (listVotedAnswer.contains(item.id) || selectedAnswersID.contains(item.id)) {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }

    private var hideCheckMark: Bool {
        voted && !selectedAnswersID.contains(item.id) && !listVotedAnswer.contains(item.id)
    }

    private var showPercent: Bool {
        !isPreview && (!hideTally || voted)
    }

    private var didSelected: Bool {
        listVotedAnswer.contains(item.id) || selectedAnswersID.contains(item.id)
    }

    // MARK: - Body view
    var body: some View {
        Button(action: {
            if selectedAnswersID.contains(item.id) {
                if multipleChoices {
                    selectedAnswersID.removeAll(where: { $0 == item.id })
                } else {
                    selectedAnswersID.removeAll()
                }
            } else {
                if !multipleChoices {
                    selectedAnswersID.removeAll()
                }
                selectedAnswersID.append(item.id)
            }
        }) {
            HStack(alignment: .top, spacing: !hideTally || voted ? 3.5 : 6) {
                Image(systemName: checkMarkIcon)
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 15, height: 15)
                    .opacity(hideCheckMark ? 0 : 1)
                ZStack(alignment: .topLeading) {
                    Text(item.content)
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white)
                        .opacity(didSelected ? 0 : 1)
                    Text(item.content)
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white)
                        .opacity(didSelected ? 1 : 0)
                }
            }
            .padding(.trailing, 34)
            .offset(x: showPercent ? 35 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity)
                    .foregroundColor(didSelected ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                    .frame(width: chartLength == 0 ?
                           2 : (UIScreen.main.bounds.width * chartLength / 375),
                           height: 2)
                    .opacity(showPercent ? 1 : 0)
                    .padding(.leading, 54)
                    .offset(y: 7), alignment: .bottomLeading
            )
            .overlay(
                Text("\(String(format: "%.0f", percent))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white)
                    .opacity(showPercent ? 1 : 0)
                    .padding(.leading, 1.5), alignment: .topLeading
            )
            .onChange(of: percent) { value in
                chartLength = CGFloat(value * 150 / 100)
            }
        }
    }
}
