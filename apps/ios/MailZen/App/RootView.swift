import SwiftUI
import MailZenKit

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.tab) {
            NavigationStack { HomeView() }
                .tabItem { Label(tr("Accueil", "Home", "Inicio"), systemImage: "shield.lefthalf.filled") }
                .tag(Tab.home)
            NavigationStack { ScannerView() }
                .tabItem { Label(tr("Scanner", "Scanner", "Escáner"), systemImage: "dot.radiowaves.left.and.right") }
                .tag(Tab.scanner)
            NavigationStack { HistoryView() }
                .tabItem { Label(tr("Historique", "History", "Historial"), systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)
            NavigationStack { LearnView() }
                .tabItem { Label(tr("Apprendre", "Learn", "Aprender"), systemImage: "graduationcap") }
                .tag(Tab.learn)
            NavigationStack { SettingsView() }
                .tabItem { Label(tr("Réglages", "Settings", "Ajustes"), systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .sheet(isPresented: $model.showSOS) {
            NavigationStack { SOSView() }
        }
    }
}
