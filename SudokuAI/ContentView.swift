import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("AppLogo")
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("Sudoku Helper")
                .font(.system(size: 45, weight: .bold))
                .foregroundColor(.blue)
            
            Image("Bot")
                .resizable()
                .frame(width: 100, height: 100)
            
            Button(action: {
                // Verify Sudoku action
            }) {
                Text("Verify Sudoku")
                    .font(.title3)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            
            Button(action: {
                // Solve Sudoku action
            }) {
                Text("Solve Sudoku")
                    .font(.title3)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
