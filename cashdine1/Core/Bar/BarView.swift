import SwiftUI

struct BarView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    NavigationLink(destination: RestaurantView()) {
                        Image(systemName: "fork.knife.circle")
                            .font(.title)
                    }
                    .padding()
                    
                    Spacer()
                    
                    NavigationLink(destination: CameraView()) {
                        Image(systemName: "camera.circle")
                            .font(.title)
                    }
                    .padding()
                    
                    Spacer()
                    
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct BarView_Previews: PreviewProvider {
    static var previews: some View {
        BarView()
    }
}
