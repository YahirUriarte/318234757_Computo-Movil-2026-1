// ConectaFácil – Prototipo SwiftUI (MVP Movilidad Accesible)
// iOS 14+ | SwiftUI + MapKit | Compatible con Xcode 12.5.1
// Frameworks: SwiftUI, MapKit, AVFoundation, CoreLocation, Combine

import SwiftUI
import MapKit
import AVFoundation
import CoreLocation
import Foundation

// MARK: - Modelos
struct Stadium: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let city: String
    let coordinate: CLLocationCoordinate2D
    let accessibleGates: [AccessGate]
}

struct AccessGate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String // "Rampa", "Elevador", "Ambos"
    let section: String // "Norte", "Sur", "Este", "Oeste"
    let hasElevator: Bool
    let hasRamp: Bool
    let wheelchairAccessible: Bool
}

struct RouteOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let durationMinutes: Int
    let distanceMeters: Int
    let transfers: Int
    let steps: Int
    let hasRamps: Bool
    let hasElevator: Bool
    let notes: String
    let path: [CLLocationCoordinate2D]
}

struct StepInstruction: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let distanceMeters: Int}

struct AmbulanceInfo {
    let estimatedArrivalMinutes: Int
    let ambulanceLocation: CLLocationCoordinate2D
    let userLocation: CLLocationCoordinate2D
    let ambulanceId: String
    let hospitalName: String}

// MARK: - Extensiones
extension CLLocationCoordinate2D {
    static let demoUser = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
}

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Datos de ejemplo
enum DemoData {
    static let stadiums: [Stadium] = [
        Stadium(
            name: "Estadio Azteca",
            city: "Ciudad de México",
            coordinate: .init(latitude: 19.3029, longitude: -99.1506),
            accessibleGates: [
                AccessGate(name: "Puerta 1", type: "Rampa", section: "Cabecera Sur", hasElevator: false, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta 3", type: "Elevador", section: "Lateral Oriente", hasElevator: true, hasRamp: false, wheelchairAccessible: true),
                AccessGate(name: "Puerta 7", type: "Rampa", section: "Lateral Poniente", hasElevator: false, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta 11", type: "Ambos", section: "Cabecera Norte", hasElevator: true, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta 15", type: "Elevador", section: "Túnel 27", hasElevator: true, hasRamp: false, wheelchairAccessible: true)
            ]
        ),
        Stadium(
            name: "Estadio Akron",
            city: "Guadalajara",
            coordinate: .init(latitude: 20.6767, longitude: -103.3476),
            accessibleGates: [
                AccessGate(name: "Puerta A", type: "Rampa", section: "Acceso Norte", hasElevator: false, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta C", type: "Elevador", section: "Lateral Este", hasElevator: true, hasRamp: false, wheelchairAccessible: true),
                AccessGate(name: "Puerta E", type: "Rampa", section: "Acceso Sur", hasElevator: false, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta VIP", type: "Ambos", section: "Zona Preferente", hasElevator: true, hasRamp: true, wheelchairAccessible: true)
            ]
        ),
        Stadium(
            name: "Estadio BBVA",
            city: "Monterrey",
            coordinate: .init(latitude: 25.7208, longitude: -100.2883),
            accessibleGates: [
                AccessGate(name: "Puerta 1", type: "Elevador", section: "Norte", hasElevator: true, hasRamp: false, wheelchairAccessible: true),
                AccessGate(name: "Puerta 3", type: "Rampa", section: "Este", hasElevator: false, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta 5", type: "Ambos", section: "Sur", hasElevator: true, hasRamp: true, wheelchairAccessible: true),
                AccessGate(name: "Puerta 7", type: "Rampa", section: "Oeste", hasElevator: false, hasRamp: true, wheelchairAccessible: true)
            ]
        )
    ]

    static func routes(to stadium: Stadium, gate: AccessGate) -> [RouteOption] {
        [
            RouteOption(
                title: "Ruta A - 15 min (♿, 🔺)",
                durationMinutes: 15,
                distanceMeters: 1800,
                transfers: 0,
                steps: 5,
                hasRamps: true,
                hasElevator: true,
                notes: "Acceso directo a \(gate.name) - \(gate.section). \(gate.type) disponible.",
                path: [.demoUser, stadium.coordinate]
            ),
            RouteOption(
                title: "Ruta B - 18 min (🚇, 🔁)",
                durationMinutes: 18,
                distanceMeters: 2400,
                transfers: 1,
                steps: 12,
                hasRamps: gate.hasRamp,
                hasElevator: gate.hasElevator,
                notes: "Un transbordo. Llegada a \(gate.name).",
                path: [.demoUser, stadium.coordinate]
            ),
            RouteOption(
                title: "Ruta C - 20 min (🔺, ⚠️ escaleras)",
                durationMinutes: 20,
                distanceMeters: 2100,
                transfers: 0,
                steps: 18,
                hasRamps: true,
                hasElevator: false,
                notes: "Ruta alternativa a \(gate.name) - \(gate.section).",
                path: [.demoUser, stadium.coordinate]
            )
        ]
    }

    static func steps(for route: RouteOption, stadium: Stadium, gate: AccessGate) -> [StepInstruction] {
        [
            StepInstruction(text: "Camina 120 m hacia Av. Principal.", distanceMeters: 120),
            StepInstruction(text: "Toma la Línea 2 dirección Sur (2 estaciones).", distanceMeters: 1500),
            StepInstruction(text: "Baja en Estación Centro (usa elevador a nivel calle).", distanceMeters: 80),
            StepInstruction(text: "Transborda al autobús 15A (1 parada).", distanceMeters: 700),
            StepInstruction(text: "Desciende frente a \(stadium.name); sigue señalética accesible.", distanceMeters: 300),
            StepInstruction(text: "Dirígete a \(gate.name) - \(gate.section) (\(gate.type))", distanceMeters: 150)
        ]
    }
}

// MARK: - ViewModels
final class AccessibilitySettings: ObservableObject {
    @Published var highContrast: Bool = true
    @Published var voiceGuidance: Bool = true
    @Published var largeControls: Bool = true
}

final class NavigationManager: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var navigationPath: [AppScreen] = []
    
    func navigate(to screen: AppScreen) {
        navigationPath.append(currentScreen)
        currentScreen = screen
    }
    
    func goBack() {
        if let previous = navigationPath.popLast() {
            currentScreen = previous
        }
    }
    
    func goHome() {
        navigationPath.removeAll()
        currentScreen = .home
    }
}

enum AppScreen {
    case home
    case destination
    case gates
    case routeList
    case guidance
    case publicTransport
    case emergencies
    case touristMode
    case ambulanceTracker
    case travelTips
    case transportSchedules
    }

final class MobilityVM: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedStadium: Stadium? = nil
    @Published var selectedGate: AccessGate? = nil
    @Published var routes: [RouteOption] = []
    @Published var currentRoute: RouteOption? = nil
    @Published var currentSteps: [StepInstruction] = []
    @Published var currentStepIndex: Int = 0
    @Published var region = MKCoordinateRegion(center: .demoUser, span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2))
    @Published var showGuidance: Bool = false
    @Published var ambulanceInfo: AmbulanceInfo? = nil
    @Published var ambulanceETA: Int = 8
    @Published var isAmbulanceRequested: Bool = false
    
    private var speaker = AVSpeechSynthesizer()

    func loadRoutes() {
        guard let stadium = selectedStadium, let gate = selectedGate else { return }
        routes = DemoData.routes(to: stadium, gate: gate)}

    func select(route: RouteOption) {
        currentRoute = route
        if let stadium = selectedStadium, let gate = selectedGate {
            currentSteps = DemoData.steps(for: route, stadium: stadium, gate: gate)
        } else {currentSteps = []}
        currentStepIndex = 0
        showGuidance = true}

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        speaker.speak(utterance)}

    var currentStepText: String {
        guard currentStepIndex < currentSteps.count else { return "Llegaste al destino." }
        return currentSteps[currentStepIndex].text}

    func nextStep(haptics: Bool = true) {
        guard currentStepIndex < currentSteps.count - 1 else { return }
        currentStepIndex += 1
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }}

    func previousStep(haptics: Bool = true) {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        if haptics { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }}
    

    func requestAmbulance() {
        isAmbulanceRequested = true // Simulación de datos de ambulancia
        ambulanceInfo = AmbulanceInfo(
            estimatedArrivalMinutes: 8,
            ambulanceLocation: CLLocationCoordinate2D(
                latitude: 19.4200,longitude: -99.1300),
                userLocation: .demoUser,
                ambulanceId: "AMB-2026-001",
                hospitalName: "Hospital General CDMX")
            ambulanceETA = 8
            
        // Iniciar temporizador simulado
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { timer in
            if self.ambulanceETA > 0 {
                self.ambulanceETA -= 1
            } else {timer.invalidate()}
        }
    }
}

// MARK: - Estilos y Componentes
struct Pill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
    }
}

extension View {
    func pill() -> some View { modifier(Pill()) }
}

// Botón accesible reutilizable
struct AccessibleButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var backgroundColor: Color = Color.white.opacity(0.12)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Toca dos veces para navegar")
    }
}

// Botón de volver al menú
struct BackToMenuButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                Text("Menú Principal")
            }
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.25))
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .accessibilityLabel("Volver al menú principal")
    }
}

// MARK: - Vistas Principales

// Vista Home - Menú Principal
struct HomeView: View {
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var nav: NavigationManager

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.3, blue: 0.7), Color.black] :
                    [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.0, green: 0.2, blue: 0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Conecta Fácil")
                        .font(.system(size: a11y.largeControls ? 40 : 36, weight: .bold, design: .rounded))
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Movilidad accesible durante el Mundial 2026")
                        .font(.system(size: a11y.largeControls ? 18 : 16))
                        .multilineTextAlignment(.center)
                        .opacity(0.95)
                }
                .foregroundColor(.white)
                .padding(.top, 20)
                .padding(.horizontal)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Botones principales
                        AccessibleButton(
                            title: "Ir al Estadio",
                            icon: "location.fill"
                        ) {
                            nav.navigate(to: .destination)
                        }
                        
                        AccessibleButton(
                            title: "Transporte Público",
                            icon: "tram.fill"
                        ) {
                            nav.navigate(to: .publicTransport)
                        }
                        
                        AccessibleButton(
                            title: "Emergencias",
                            icon: "cross.case.fill"
                        ) {
                            nav.navigate(to: .emergencies)
                        }
                        
                        AccessibleButton(
                            title: "Modo Turista",
                            icon: "figure.wave"
                        ) {
                            nav.navigate(to: .touristMode)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Configuración de accesibilidad
                    VStack(spacing: 14) {
                        Text("Configuración de Accesibilidad")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            Toggle("Alto contraste", isOn: $a11y.highContrast)
                            Toggle("Guía por voz", isOn: $a11y.voiceGuidance)
                            Toggle("Controles grandes", isOn: $a11y.largeControls)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
                
                // Footer icon
                Image(systemName: "figure.wave")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 10)
                    .accessibilityHidden(true)
            }
        }
    }
}

// Vista de Selección de Destino
struct DestinationPickerView: View {
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var nav: NavigationManager
    @State private var showQRHint = false
    @State private var selectedStadium: Stadium? = nil

    var filtered: [Stadium] {
        if vm.searchText.isEmpty { return DemoData.stadiums }
        return DemoData.stadiums.filter {
            $0.name.localizedCaseInsensitiveContains(vm.searchText) ||
            $0.city.localizedCaseInsensitiveContains(vm.searchText)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.3, blue: 0.7), Color.black] :
                    [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.0, green: 0.2, blue: 0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con botón de regreso
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                }
                .padding()
                
                // Título
                Text("Seleccionar Destino")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)
                
                // Contenido en tarjeta
                VStack(spacing: 0) {
                    // Búsqueda
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Buscar estadio o ciudad", text: $vm.searchText)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                        }
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                        
                        Button(action: { showQRHint = true }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Escanear QR de boleto")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    // Lista de estadios
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Sedes disponibles")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            ForEach(filtered) { stadium in
                                Button(action: {
                                    vm.selectedStadium = stadium
                                    nav.navigate(to: .gates)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(stadium.name)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.blue)
                                                Text(stadium.city)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "door.left.hand.open")
                                                    .foregroundColor(.green)
                                                Text("\(stadium.accessibleGates.count) puertas accesibles")
                                                    .font(.footnote)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color.black.opacity(0.95))
                    
                }
                .background(Color.gray.opacity(0.95))
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }
        }
        .alert(isPresented: $showQRHint) {
            Alert(
                title: Text("Demo QR"),
                message: Text("En la versión completa, este botón escaneará el código QR de tu boleto para precargar el estadio y puerta accesible automáticamente."),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }
}

// Vista de Selección de Puertas/Accesos
struct GateSelectionView: View {
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var nav: NavigationManager
    
    let stadium: Stadium
    @State private var selectedGate: AccessGate? = nil
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.4, blue: 0.8),
                    Color(red: 0.0, green: 0.2, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text(stadium.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                        Color(red: 0.35, green: 0.45, blue: 0.55),  // Azul gris medio
                        Color(red: 0.25, green: 0.35, blue: 0.45)]),   // Azul gris oscuro
                        
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Selecciona tu Puerta de Acceso")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                        
                        Text("Elige la puerta más cercana a tu asiento o con mejor accesibilidad")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(stadium.accessibleGates) { gate in
                            GateCard(gate: gate) {
                                vm.selectedGate = gate
                                vm.loadRoutes()
                                nav.navigate(to: .routeList)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// Tarjeta de Puerta/Acceso
struct GateCard: View {
    let gate: AccessGate
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gate.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(gate.section)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: gate.wheelchairAccessible ? "figure.roll" : "figure.walk")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                
                // Características de accesibilidad
                HStack(spacing: 8) {
                    if gate.hasRamp {
                        Label("Rampa", systemImage: "figure.walk")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                    
                    if gate.hasElevator {
                        Label("Elevador", systemImage: "arrow.up.square.fill")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                    
                    if gate.wheelchairAccessible {
                        Label("Silla de ruedas", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Text("Ver rutas a esta puerta")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista de Lista de Rutas
struct RouteListView: View {
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var nav: NavigationManager

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.4, blue: 0.8),
                    Color(red: 0.0, green: 0.2, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text(vm.selectedStadium?.name ?? "Rutas")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.35, green: 0.45, blue: 0.55),  Color(red: 0.25, green: 0.35, blue: 0.45)]),   // Azul gris oscuro
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Mapa
                if let stadium = vm.selectedStadium {
                    MapViewRepresentable(coordinate: stadium.coordinate, stadiumName: stadium.name)
                        .frame(height: 200)
                        .overlay(
                            Text(stadium.city)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .padding(12),
                            alignment: .topLeading
                        )
                }
                
                // Lista de rutas
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Rutas Accesibles")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                        
                        ForEach(vm.routes) { route in
                            RouteCard(route: route) {
                                vm.select(route: route)
                                nav.navigate(to: .guidance)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// Vista de Guía Paso a Paso
struct GuidanceView: View {
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var nav: NavigationManager

    var body: some View {
        ZStack {
            Color(.gray)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text("Navegación Asistida")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.0, green: 0.3, blue: 0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Información de la ruta
                        if let route = vm.currentRoute {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "location.north.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text(route.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                    Text("\(route.durationMinutes) min")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                            .cornerRadius(12)
                        }
                        
                        // Paso actual
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.number")
                                    .foregroundColor(.blue)
                                Text("Paso \(vm.currentStepIndex + 1) de \(max(vm.currentSteps.count, 1))")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(vm.currentStepText)
                                .font(.system(size: a11y.largeControls ? 24 : 22, weight: .bold))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                                .accessibilityLabel("Instrucción actual: \(vm.currentStepText)")
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Botones de navegación
                        HStack(spacing: 12) {
                            Button(action: {
                                vm.previousStep()
                                if a11y.voiceGuidance { vm.speak(vm.currentStepText) }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.backward")
                                    Text("Anterior")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(vm.currentStepIndex == 0)
                            
                            Button(action: {
                                vm.nextStep()
                                if a11y.voiceGuidance { vm.speak(vm.currentStepText) }
                            }) {
                                HStack {
                                    Text("Siguiente")
                                    Image(systemName: "chevron.forward")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(vm.currentStepIndex >= vm.currentSteps.count - 1)
                        }
                        
                        // Vista AR opcional
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arkit")
                                Text("Vista AR opcional")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        
                        // Botón describir entorno
                        Button(action: {
                            if a11y.voiceGuidance {
                                vm.speak("Función de descripción de entorno. Usa la cámara para identificar señalética y leerla en voz alta.")
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Describir entorno")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        
                        // Mapa
                        MapViewRepresentable(
                            coordinate: vm.region.center,
                            stadiumName: vm.selectedStadium?.name ?? "Destino"
                        )
                        .frame(height: 220)
                        .cornerRadius(16)
                        .overlay(
                            HStack {
                                Image(systemName: a11y.voiceGuidance ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                Text(a11y.voiceGuidance ? "Voz activa" : "Voz desactivada")
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(12),
                            alignment: .topTrailing
                        )
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if a11y.voiceGuidance { vm.speak(vm.currentStepText) }
        }
    }
}

// Vista de Transporte Público
struct PublicTransportView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.3, blue: 0.7), Color.black] :
                    [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.0, green: 0.2, blue: 0.6)]),
                startPoint: .topLeading,endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack {
                HStack {BackToMenuButton {nav.goHome()}
                    Spacer()}
                .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Transporte Público")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Información de líneas, horarios y rutas accesibles del sistema de transporte.")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 12) {
                        InfoCard(icon: "tram.fill", title: "Líneas disponibles", subtitle: "Consulta líneas de metro y autobús")
                        
                        Button(action: {
                            nav.navigate(to: .transportSchedules)  // 🆕 Navega a horarios
                        }) {
                            InfoCard(icon: "clock.fill", title: "Horarios", subtitle: "Horarios actualizados en tiempo real")
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        InfoCard(icon: "figure.roll", title: "Accesibilidad", subtitle: "Estaciones con elevador y rampa")
                    }
            }
                }
                
                Spacer()
            }
        }
}

struct TransportSchedulesView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    
    let schedules = [
        TransportSchedule(
            type: "Metro",
            line: "Línea 2 (Azul)",
            destination: "Estadio Azteca",
            station: "Taxqueña",
            schedules: [
                "06:00 - Primer tren",
                "Frecuencia: cada 3-5 min",
                "Duración: 25 minutos",
                "23:30 - Último tren"
            ],
            accessible: true,
            color: Color.blue
        ),
        TransportSchedule(
            type: "Metrobús",
            line: "Línea 1",
            destination: "Estadio Azteca",
            station: "Insurgentes",
            schedules: [
                "05:00 - Primera unidad",
                "Frecuencia: cada 5-10 min",
                "Duración: 35 minutos",
                "00:00 - Última unidad"
            ],
            accessible: true,
            color: Color.pink
        ),
        TransportSchedule(
            type: "Autobús",
            line: "Ruta 15A",
            destination: "Estadio Azteca",
            station: "Centro Histórico",
            schedules: [
                "06:30 - Primera salida",
                "Frecuencia: cada 15-20 min",
                "Duración: 45 minutos",
                "22:00 - Última salida"
            ],
            accessible: true,
            color: Color.green
        ),
        TransportSchedule(
            type: "Tren Ligero",
            line: "Línea 2 (Azul) → Tren Ligero",
            destination: "Estadio Azteca",
            station: "Tasqueña (transbordo)",
            schedules: [
                "06:00 - Primer tren",
                "Frecuencia: cada 10 min",
                "Duración: 15 min (desde Tasqueña)",
                "23:00 - Último tren"
            ],
            accessible: true,
            color: Color.orange
        ),
        TransportSchedule(
            type: "Autobús Expreso",
            line: "Servicio Especial Mundial",
            destination: "Estadios (todos)",
            station: "Zócalo, Reforma, Polanco",
            schedules: [
                "Días de partido solamente",
                "4 horas antes del partido",
                "Frecuencia: cada 10 min",
                "Hasta 2 horas post-partido"
            ],
            accessible: true,
            color: Color.purple
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.3, blue: 0.7), Color.black] :
                    [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.0, green: 0.2, blue: 0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text("Horarios de Transporte")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Título
                        VStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("Horarios Actualizados")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Transporte público hacia los estadios del Mundial 2026")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Aviso importante
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("En días de partido, la frecuencia aumenta 30 minutos antes y después del evento")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Lista de horarios
                        ForEach(schedules, id: \.line) { schedule in
                            TransportScheduleCard(schedule: schedule)
                        }
                        
                        // Información adicional
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Información Adicional")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoPoint(text: "Todas las líneas cuentan con accesibilidad para sillas de ruedas")
                                InfoPoint(text: "Precio único: $6 MXN (Metro), $7 MXN (Metrobús)")
                                InfoPoint(text: "Tarjeta recargable disponible en taquillas")
                                InfoPoint(text: "Servicio especial en días de partido")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

// Modelo de horario de transporte
struct TransportSchedule {
    let type: String
    let line: String
    let destination: String
    let station: String
    let schedules: [String]
    let accessible: Bool
    let color: Color
}

// Tarjeta de horario de transporte
struct TransportScheduleCard: View {
    let schedule: TransportSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: getIcon(for: schedule.type))
                    .font(.system(size: 32))
                    .foregroundColor(schedule.color)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.type)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(schedule.line)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if schedule.accessible {
                    Image(systemName: "figure.roll")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
            }
            
            // Destino y estación
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(schedule.color)
                    Text("Destino: \(schedule.destination)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(schedule.color)
                    Text("Estación: \(schedule.station)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Horarios
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(schedule.schedules, id: \.self) { scheduleItem in
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundColor(schedule.color)
                                        .font(.system(size: 14))
                                    Text(scheduleItem)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                private func getIcon(for type: String) -> String {
                    switch type {
                    case "Metro":
                        return "tram.fill"
                    case "Metrobús":
                        return "bus.fill"
                    case "Autobús", "Autobús Expreso":
                        return "bus.doubledecker.fill"
                    case "Tren Ligero":
                        return "lightrail.fill"
                    default:
                        return "car.fill"
                    }
                }
            }

            // Componente para puntos de información
            struct InfoPoint: View {
                let text: String
                
                var body: some View {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
// Vista de Emergencias
struct EmergenciesView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    @State private var showSOSConfirmation = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.8, green: 0.0, blue: 0.0), Color.black] :
                    [Color.red.opacity(0.7), Color.orange.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Emergencias")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Botón SOS Principal
                        Button(action: {
                            showSOSConfirmation = true
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "sos.circle.fill")
                                    .font(.system(size: 50))
                                Text("Botón SOS")
                                    .font(.system(size: 24, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Botón de emergencia SOS")
                        .accessibilityHint("Toca dos veces para enviar alerta de emergencia")
                        
                        VStack(spacing: 14) {
                            EmergencyButton(icon: "phone.fill", title: "Contactos de confianza", color: .white.opacity(0.15))
                            EmergencyButton(icon: "cross.circle.fill", title: "Hospitales cercanos", color: .white.opacity(0.15))
                            EmergencyButton(icon: "doc.text.fill", title: "Protocolos rápidos", color: .white.opacity(0.15))
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .alert(isPresented: $showSOSConfirmation) {
            Alert(
                title: Text("Alerta SOS"),
                message: Text("Se compartirá tu ubicación con tus contactos de emergencia. ¿Deseas también solicitar una ambulancia?"),
                primaryButton: .destructive(Text("SOS + Ambulancia")) {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    vm.requestAmbulance()
                    nav.navigate(to: .ambulanceTracker)  // 🆕 Navega a rastreador
                },
                secondaryButton: .default(Text("Solo SOS")) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            )
        }
    }
}

// Vista de Rastreador de Ambulancia
struct AmbulanceTrackerView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var vm: MobilityVM
    @EnvironmentObject var a11y: AccessibilitySettings
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.1, blue: 0.1),
                    Color(red: 0.7, green: 0.0, blue: 0.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text("Ambulancia en Camino")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icono de ambulancia animado
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 150, height: 150)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                                .onAppear { pulseAnimation = true }
                            
                            Image(systemName: "cross.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Tiempo estimado
                        VStack(spacing: 8) {
                            Text("Tiempo estimado de llegada")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("\(vm.ambulanceETA) minutos")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                                .accessibilityLabel("Llegada en \(vm.ambulanceETA) minutos")
                            
                            Text("La ambulancia está en camino")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Información de la ambulancia
                        if let ambulance = vm.ambulanceInfo {
                            VStack(spacing: 16) {
                                InfoRow(icon: "car.fill",
                                       title: "Unidad",
                                       value: ambulance.ambulanceId)
                                
                                InfoRow(icon: "cross.case.fill",
                                       title: "Hospital",
                                       value: ambulance.hospitalName)
                                
                                InfoRow(icon: "phone.fill",
                                       title: "Contacto",
                                       value: "911 - Emergencias")
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // Mapa de ubicación
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ubicación de la ambulancia")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if let ambulance = vm.ambulanceInfo {
                                AmbulanceMapView(
                                    ambulanceLocation: ambulance.ambulanceLocation,
                                    userLocation: ambulance.userLocation
                                )
                                .frame(height: 300)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Botón de cancelar
                        Button(action: {
                            nav.goBack()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancelar solicitud")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

// Componente auxiliar para filas de información
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

// Mapa para rastrear ambulancia
struct AmbulanceMapView: UIViewRepresentable {
    let ambulanceLocation: CLLocationCoordinate2D
    let userLocation: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Configurar región para mostrar ambas ubicaciones
        let centerLat = (ambulanceLocation.latitude + userLocation.latitude) / 2
        let centerLon = (ambulanceLocation.longitude + userLocation.longitude) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        mapView.region = MKCoordinateRegion(center: center, span: span)
        
        // Anotación de usuario
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = userLocation
        userAnnotation.title = "Tu ubicación"
        mapView.addAnnotation(userAnnotation)
        
        // Anotación de ambulancia
        let ambulanceAnnotation = MKPointAnnotation()
        ambulanceAnnotation.coordinate = ambulanceLocation
        ambulanceAnnotation.title = "Ambulancia"
        mapView.addAnnotation(ambulanceAnnotation)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}
}
// Vista de Modo Turista
struct TouristModeView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.6, blue: 0.6), Color.black] :
                    [Color(red: 0.0, green: 0.6, blue:0.6).opacity(0.7), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Modo Turista")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Traducciones, consejos y guía contextual para visitantes")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 14) {
                            TouristCard(icon: "globe", title: "Traducción en tiempo real", subtitle: "Español ⇄ Inglés")
                            Button(action: {
                                nav.navigate(to: .travelTips)  // 🆕 Navega a consejos
                            }) {
                                TouristCard(icon: "info.circle.fill",
                                           title: "Consejos de viaje",
                                           subtitle: "Horarios, entradas, transporte")
                            }
                            .buttonStyle(PlainButtonStyle())
                            TouristCard(icon: "map.fill", title: "Lugares de interés", subtitle: "Atracciones cercanas a estadios")
                            TouristCard(icon: "fork.knife", title: "Restaurantes accesibles", subtitle: "Opciones con menú en varios idiomas")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
}

struct TravelTipsView: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    
    let tips = [
        TipCategory(
            icon: "clock.fill",
            title: "Horarios Recomendados",
            color: Color.blue,
            tips: [
                "Llega 2 horas antes del partido",
                "El metro opera de 5:00 AM a 12:00 AM",
                "Horario pico: 7-9 AM y 6-8 PM (evitar)",
                "Puertas del estadio abren 90 min antes"
            ]
        ),
        TipCategory(
            icon: "ticket.fill",
            title: "Boletos y Acceso",
            color: Color.green,
            tips: [
                "Imprime tu boleto o ten QR descargado",
                "Boletos digitales aceptados en todas las puertas",
                "Presenta ID oficial en acceso VIP",
                "Asientos accesibles: Sectores especiales marcados"
            ]
        ),
        TipCategory(
            icon: "tram.fill",
            title: "Transporte",
            color: Color.orange,
            tips: [
                "Metro Línea 2: Estación Taxqueña (Azteca)",
                "Metrobús Línea 1: Directo a estadios",
                "Uber/DiDi: Zona designada de ascenso",
                "Estacionamiento: Llega 3 horas antes"
            ]
        ),
        TipCategory(
            icon: "fork.knife.circle.fill",
            title: "Comida y Bebidas",
            color: Color.red,
            tips: [
                "Botellas selladas permitidas (máx 600ml)",
                "Comida: Disponible dentro del estadio",
                "Opciones vegetarianas/veganas disponibles",
                "Pagos: Efectivo y tarjeta aceptados"
            ]
        ),
        TipCategory(
            icon: "exclamationmark.triangle.fill",
            title: "Seguridad",
            color: Color.purple,
            tips: [
                "No lleves mochilas grandes (máx 30x30cm)",
                "Objetos prohibidos: Paraguas, cámaras pro",
                "Puntos de información: En cada puerta",
                "Servicio médico: Sección 100 y 200"
            ]
        ),
        TipCategory(
            icon: "globe",
            title: "Para Turistas",
            color: Color(red: 0.0, green: 0.6, blue: 0.6),
            tips: [
                "Moneda: Peso mexicano (MXN), cambio en bancos",
                "Propina: 10-15% en restaurantes",
                "Idioma: Español, inglés en zonas turísticas",
                "Emergencias: 911 (llamada gratuita)"
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: a11y.highContrast ?
                    [Color(red: 0.0, green: 0.6, blue: 0.6), Color.black] :
                    [Color(red: 0.0, green: 0.6, blue:0.6).opacity(0.7), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackToMenuButton {
                        nav.goHome()
                    }
                    Spacer()
                    Text("Consejos de Viaje")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Guía Completa para Asistentes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text("Todo lo que necesitas saber para disfrutar el Mundial 2026")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        ForEach(tips, id: \.title) { category in
                            TipCategoryCard(category: category)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// Modelo de categoría de consejos
struct TipCategory {
    let icon: String
    let title: String
    let color: Color
    let tips: [String]
}

// Tarjeta de categoría de consejos
struct TipCategoryCard: View {
    let category: TipCategory
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header de la categoría
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: category.icon)
                        .font(.system(size: 28))
                        .foregroundColor(category.color)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Lista de consejos (expandible)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(category.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(category.color)
                                .font(.system(size: 16))
                            
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Componentes Auxiliares
struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

struct EmergencyButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct TouristCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let stadiumName: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = stadiumName
        mapView.addAnnotation(annotation)
        
        // Configurar para accesibilidad
        mapView.isAccessibilityElement = true
        mapView.accessibilityLabel = "Mapa mostrando \(stadiumName)"
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}
}

struct RouteCard: View {
    let route: RouteOption
    var onGuide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(route.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("\(route.durationMinutes) min")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                    Text(metersToKm(route.distanceMeters))
                }
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(8)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("\(route.transfers)")
                }
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.7))
                .cornerRadius(8)
                
                if route.hasRamps {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.roll")
                        Text("Rampa")
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(8)
                }
                
                if route.hasElevator {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.square.fill")
                        Text("Elevador")
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.7))
                    .cornerRadius(8)
                }
            }

            Text(route.notes)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            Button(action: onGuide) {
                HStack(spacing: 8) {
                    Image(systemName: "location.north.circle.fill")
                    Text("Guíame")
                }
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .accessibilityLabel("Iniciar guía para \(route.title)")
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private func metersToKm(_ m: Int) -> String {
        if m >= 1000 { return String(format: "%.1f km", Double(m)/1000.0) }
        return "\(m) m"
    }
}

// Helper para esquinas redondeadas específicas
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Contenedor Principal con Navegación
struct MainContainer: View {
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var a11y: AccessibilitySettings
    @EnvironmentObject var vm: MobilityVM
    
    var body: some View {
        Group {
            switch nav.currentScreen {
            case .home:
                HomeView()
            case .destination:
                DestinationPickerView()
            case .gates:
                if let stadium = vm.selectedStadium {
                    GateSelectionView(stadium: stadium)
                }
            case .routeList:
                RouteListView()
            case .guidance:
                GuidanceView()
            case .publicTransport:
                PublicTransportView()
            case .emergencies:
                EmergenciesView()
            case .touristMode:
                TouristModeView()
            case .ambulanceTracker:  // 🆕 NUEVA
                AmbulanceTrackerView()
            case .travelTips:  // 🆕 NUEVA
                TravelTipsView()
            case .transportSchedules:  // 🆕 NUEVA
                TransportSchedulesView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: nav.currentScreen)
    }
}

// MARK: - App
@main
struct ConectaFacilApp: App {
    @StateObject private var a11y = AccessibilitySettings()
    @StateObject private var vm = MobilityVM()
    @StateObject private var nav = NavigationManager()

    var body: some Scene {
        WindowGroup {
            MainContainer()
                .environmentObject(a11y)
                .environmentObject(vm)
                .environmentObject(nav)
                .preferredColorScheme(a11y.highContrast ? .dark : nil)
        }
    }
}
