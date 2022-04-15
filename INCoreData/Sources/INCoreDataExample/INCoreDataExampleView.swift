import INCoreData
import SwiftUI
struct INCoreDataExampleView: View {
	var body: some View {
		Text(INCoreDataVersion.version.description)
	}
}

struct INCoreDataExampleView_Previews: PreviewProvider {
	static var previews: some View {
		INCoreDataExampleView()
	}
}
