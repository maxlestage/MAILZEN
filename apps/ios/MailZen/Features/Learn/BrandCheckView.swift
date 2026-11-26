import SwiftUI
import MailZenKit

/// Brand Check: is this domain really the brand's? Only verified official domains are
/// listed; without evidence, no verdict.
struct BrandCheckView: View {
    @State private var query = ""

    private var result: Brands.Check? {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? nil : Brands.check(q)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(eyebrow: "Brand Check", title: tr("Vérifier une marque ou un domaine", "Check a brand or a domain", "Verificar una marca o un dominio"))
                TextField(tr("ex. impots.gouv.fr, paypaI-secure.example, La Poste", "e.g. paypal.com, amaz0n-orders.example, Netflix", "p. ej. correos.es, paypaI-secure.example, Amazon"), text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Theme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
                if let result {
                    resultCard(result)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .id(query)
                }
                SectionTitle(eyebrow: tr("Domaines officiels connus", "Known official domains", "Dominios oficiales conocidos"), title: tr("La liste vérifiée", "The verified list", "La lista verificada"))
                ForEach(Brands.all, id: \.self) { brand in
                    HStack(alignment: .top) {
                        Text(brand.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                        Spacer()
                        Text(brand.domains.joined(separator: "\n"))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.trailing)
                    }
                    .card(padding: 12)
                }
            }
            .padding()
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: query)
        }
        .background(AppBackground())
        .navigationTitle("Brand Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func resultCard(_ check: Brands.Check) -> some View {
        switch check {
        case .official(let brand):
            row("checkmark.seal.fill", Theme.safe,
                tr("Domaine officiel de \(brand.name)", "Official domain of \(brand.name)", "Dominio oficial de \(brand.name)"),
                tr("Vérifiez quand même l’adresse complète dans la barre du navigateur.", "Still check the full address in the browser bar.", "Comprueba igualmente la dirección completa en la barra del navegador."))
        case .imitation(let brand, let reason):
            row("xmark.octagon.fill", Theme.danger,
                tr("Ce n’est pas \(brand.name)", "This is not \(brand.name)", "No es \(brand.name)"),
                reason.localized + " " + tr("Officiel : ", "Official: ", "Oficial: ") + brand.domains.joined(separator: ", "))
        case .brand(let brand):
            row("building.2.fill", Theme.cyan, brand.name,
                tr("Domaine(s) officiel(s) : ", "Official domain(s): ", "Dominio(s) oficial(es): ") + brand.domains.joined(separator: ", "))
        case .unknown:
            row("questionmark.circle.fill", Theme.caution,
                tr("Inconnu de MailZen", "Unknown to MailZen", "Desconocido para MailZen"),
                tr("Sans preuve, pas de verdict : contactez l’organisme par un canal que vous connaissez déjà.", "No evidence, no verdict: contact the organization through a channel you already know.", "Sin pruebas, no hay veredicto: contacta con el organismo por un canal que ya conozcas."))
        }
    }

    private func row(_ symbol: String, _ tint: Color, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.text)
                Text(text).font(.subheadline).foregroundStyle(Theme.muted)
            }
        }
        .card(tint: tint.opacity(0.45))
    }
}
