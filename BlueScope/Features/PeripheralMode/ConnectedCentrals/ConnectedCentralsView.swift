import SwiftUI

/// Stub — the real Connected Centrals feature (live central list + request
/// log, backed by connectedCentralsPublisher/requestLogPublisher) isn't
/// built yet. This is only a navigation placeholder so AdvertiseView has
/// somewhere to push to.
struct ConnectedCentralsView: View {
    var body: some View {
        Text("Connected Centrals")
            .navigationTitle("Connected Centrals")
    }
}

#Preview {
    NavigationStack {
        ConnectedCentralsView()
    }
}
