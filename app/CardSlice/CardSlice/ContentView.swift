import SwiftUI

@MainActor
struct ContentView: View {
    let repository: any CardRepository
    let tagRepository: (any TagRepository)?

    var body: some View {
        CardHolderView(repository: repository, tagRepository: tagRepository)
    }
}
