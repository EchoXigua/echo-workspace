import SwiftUI

struct LMSheetHandle: View {
    var width: CGFloat = 44

    var body: some View {
        Capsule()
            .fill(LMColors.sheetHandle)
            .frame(width: width, height: 4)
            .accessibilityHidden(true)
    }
}

struct LMSheetHandle_Previews: PreviewProvider {
    static var previews: some View {
        LMSheetHandle()
            .padding()
            .background(LMColors.background)
    }
}
