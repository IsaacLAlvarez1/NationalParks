import SwiftUI
struct IntroView: View {
    @EnvironmentObject var parks : NationalParksViewModel
    var onFinish : () -> Void = { }
    var body: some View {
        VStack {
            TabView {
                ForEach(parks.introPages) { page in
                    VStack(spacing: 10) {
                        Spacer()
                        Image(page.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 500)
                        Text(page.caption)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding()
            Button(action: {
                onFinish()
            }) {
                Text("Start Exploring")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea(.all)
        .onAppear {
            parks.loadIntroPages()
        }
    }
}
#Preview {
    IntroView()
        .environmentObject(NationalParksViewModel())
}
