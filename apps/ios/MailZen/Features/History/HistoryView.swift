import SwiftUI
import SwiftData
import MailZenKit

/// The history of analyses: search, filters, favorites, deletion, export.
struct HistoryView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all, danger, suspicious, caution, safe, favorites
        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: tr("Tout", "All", "Todo")
            case .danger: Verdict.danger.title.localized
            case .suspicious: Verdict.suspicious.title.localized
            case .caution: Verdict.caution.title.localized
            case .safe: tr("Sans risque notable", "No notable risk", "Sin riesgo notable")
            case .favorites: tr("Favoris", "Favorites", "Favoritos")
            }
        }
    }

    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var model
    @Query(sort: \AnalysisRecord.date, order: .reverse) private var records: [AnalysisRecord]
    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var confirmClear = false

    private var shown: [AnalysisRecord] {
        records.filter { record in
            let matchesFilter: Bool = switch filter {
            case .all: true
            case .favorites: record.favorite
            case .danger: record.verdict == .danger
            case .suspicious: record.verdict == .suspicious
            case .caution: record.verdict == .caution
            case .safe: record.verdict == .safe
            }
            let matchesSearch = search.isEmpty
                || record.title.localizedCaseInsensitiveContains(search)
                || record.raw.localizedCaseInsensitiveContains(search)
            return matchesFilter && matchesSearch
        }
    }

    private var export: String {
        var csv = "date;source;titre;score;verdict\n"
        for r in records {
            let title = r.title.replacingOccurrences(of: ";", with: ",")
            csv += "\(r.date.ISO8601Format());\(r.source);\(title);\(r.score);\(r.verdict.title.localized)\n"
        }
        return csv
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Filter.allCases) { f in
                            Button { withAnimation { filter = f } } label: {
                                Chip(text: f.label, tint: filter == f ? Theme.cyan : Theme.muted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.clear)
            if shown.isEmpty {
                ContentUnavailableView(
                    tr("Aucune analyse", "No analysis", "Ningún análisis"),
                    systemImage: "clock.arrow.circlepath",
                    description: Text(tr("Vos analyses restent sur cet appareil.", "Your analyses stay on this device.", "Tus análisis se quedan en este dispositivo.")))
                    .listRowBackground(Color.clear)
            }
            ForEach(shown) { record in
                NavigationLink {
                    RecordReportView(record: record, onSOS: { model.showSOS = true })
                } label: {
                    HistoryRow(record: record)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { context.delete(record) } label: {
                        Label(tr("Supprimer", "Delete", "Eliminar"), systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button { record.favorite.toggle() } label: {
                        Label(tr("Favori", "Favorite", "Favorito"), systemImage: record.favorite ? "star.slash" : "star")
                    }
                    .tint(Theme.caution)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Historique", "History", "Historial"))
        .searchable(text: $search, prompt: tr("Rechercher", "Search", "Buscar"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: export) { Image(systemName: "square.and.arrow.up") }
                    .disabled(records.isEmpty)
                Button(role: .destructive) { confirmClear = true } label: { Image(systemName: "trash") }
                    .disabled(records.isEmpty)
            }
        }
        .confirmationDialog(tr("Effacer tout l’historique ?", "Erase the whole history?", "¿Borrar todo el historial?"), isPresented: $confirmClear, titleVisibility: .visible) {
            Button(tr("Effacer", "Erase", "Borrar"), role: .destructive) {
                for record in records { context.delete(record) }
            }
        }
    }
}
