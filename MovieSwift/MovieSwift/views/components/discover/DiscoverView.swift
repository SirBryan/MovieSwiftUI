//
//  DiscoverView.swift
//  MovieSwift
//
//  Created by Thomas Ricouard on 19/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import SwiftUI

struct DiscoverView : View {
    
    // MARk: - State vars
    
    @EnvironmentObject private var store: AppStore
    
    @State private var draggedViewState = DraggableCover.DragState.inactive
    @State private var previousMovie: Int? = nil
    @State private var filterFormPresented = false
    @State private var movieDetailPresented = false
    private let hapticFeedback =  UINotificationFeedbackGenerator()
    
    // MARK: - Computed properties
    
    private var movies: [Int] {
        store.state.moviesState.discover
    }
    
    private var filter: DiscoverFilter? {
        store.state.moviesState.discoverFilter
    }
    
    private var currentMovie: Movie {
        return store.state.moviesState.movies[store.state.moviesState.discover.reversed()[0].id]!
    }
    
    private func scaleResistance() -> Double {
        Double(abs(draggedViewState.translation.width) / 5000)
    }
    
    private func dragResistance() -> CGFloat {
        abs(draggedViewState.translation.width) / 10
    }
    
    private func leftZoneResistance() -> CGFloat {
        -draggedViewState.translation.width / 1000
    }
    
    private func rightZoneResistance() -> CGFloat {
        draggedViewState.translation.width / 1000
    }
    
    private func draggableCoverEndGestureHandler(handler: DraggableCover.EndState) {
        if handler == .left || handler == .right {
            previousMovie = currentMovie.id
            if handler == .left {
                hapticFeedback.notificationOccurred(.success)
                store.dispatch(action: MoviesActions.AddToWishlist(movie: currentMovie.id))
            } else if handler == .right {
                hapticFeedback.notificationOccurred(.success)
                store.dispatch(action: MoviesActions.AddToSeenList(movie: currentMovie.id))
            }
            store.dispatch(action: MoviesActions.PopRandromDiscover())
            fetchRandomMovies()
        }
    }
    
    private func fetchRandomMovies() {
        if movies.count < 10 {
            store.dispatch(action: MoviesActions.FetchRandomDiscover(filter: filter))
        }
    }
    
    // MARK: - Modals
    
    private var filterFormModal: Modal {
        Modal(DiscoverFilterForm(isPresented: $filterFormPresented).environmentObject(store),
              onDismiss: {
            self.filterFormPresented = false
        })
    }
    
    private var movieDetailModal: Modal {
        Modal(NavigationView{ MovieDetail(movieId: currentMovie.id).environmentObject(store) }) {
            self.movieDetailPresented = false
        }
    }
    
    private var currentModal: Modal? {
        if filterFormPresented {
            return filterFormModal
        } else if movieDetailPresented {
            return movieDetailModal
        }
        return nil
    }
    
    // MARK: Body views
    private var filterView: some View {
        var text = String("")
        if let startYear = filter?.startYear, let endYear = filter?.endYear {
            text = text + "\(startYear)-\(endYear)"
        } else {
            text = text + "\(filter?.year != nil ? String(filter!.year) : "Loading") · Random"
        }
        if let genre = filter?.genre,
            let stateGenre = store.state.moviesState.genres.first(where: { (realGenre) -> Bool in
            realGenre.id == genre
        }) {
            text = text + " · \(stateGenre.name)"
        }
        if let region = filter?.region {
            text = text + " · \(region)"
        }
        return BorderedButton(text: text,
                              systemImageName: "line.horizontal.3.decrease",
                              color: .steam_blue,
                              isOn: false) {
                                self.filterFormPresented = true
        }
    }
    
    private var actionsButtons: some View {
        ZStack(alignment: .center) {
            if !self.movies.isEmpty {
                Text(self.currentMovie.userTitle)
                    .color(.primary)
                    .multilineTextAlignment(.center)
                    .font(.FHACondFrenchNC(size: 18))
                    .lineLimit(2)
                    .opacity(self.draggedViewState.isDragging ? 0.0 : 1.0)
                    .offset(x: 0, y: -15)
                    .animation(.basic())
                    .tapAction {
                        self.movieDetailPresented = true
                }
                
                
                Circle()
                    .strokeBorder(Color.pink, lineWidth: 1)
                    .background(Image(systemName: "heart.fill").foregroundColor(.pink))
                    .frame(width: 50, height: 50)
                    .offset(x: -70, y: 0)
                    .opacity(self.draggedViewState.isDragging ? 0.3 + Double(self.leftZoneResistance()) : 0)
                    .animation(.fluidSpring())
                
                Circle()
                    .strokeBorder(Color.green, lineWidth: 1)
                    .background(Image(systemName: "eye.fill").foregroundColor(.green))
                    .frame(width: 50, height: 50)
                    .offset(x: 70, y: 0)
                    .opacity(self.draggedViewState.isDragging ? 0.3 + Double(self.rightZoneResistance()) : 0)
                    .animation(.fluidSpring())
                
                
                Circle()
                    .strokeBorder(Color.red, lineWidth: 1)
                    .background(Image(systemName: "xmark").foregroundColor(.red))
                    .frame(width: 50, height: 50)
                    .offset(x: 0, y: 30)
                    .opacity(self.draggedViewState.isDragging ? 0.0 : 1)
                    .animation(.fluidSpring())
                    .tapAction {
                        self.hapticFeedback.notificationOccurred(.error)
                        self.previousMovie = self.currentMovie.id
                        self.store.dispatch(action: MoviesActions.PopRandromDiscover())
                        self.fetchRandomMovies()
                }
                
                Button(action: {
                    self.store.dispatch(action: MoviesActions.PushRandomDiscover(movie: self.previousMovie!))
                    self.previousMovie = nil
                }, label: {
                    Image(systemName: "gobackward").foregroundColor(.steam_blue)
                }) .frame(width: 50, height: 50)
                    .offset(x: -50, y: 30)
                    .opacity(self.previousMovie != nil && !self.draggedViewState.isActive ? 1 : 0)
                    .animation(.fluidSpring())
                
                Button(action: {
                    self.store.dispatch(action: MoviesActions.ResetRandomDiscover())
                    self.fetchRandomMovies()
                }, label: {
                    Image(systemName: "arrow.swap")
                        .foregroundColor(.steam_blue)
                })
                    .frame(width: 50, height: 50)
                    .offset(x: 50, y: 30)
                    .opacity(self.draggedViewState.isDragging ? 0.0 : 1.0)
                    .animation(.fluidSpring())
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            GeometryReader { reader in
                    self.filterView
                        .position(x: reader.frame(in: .global).midX, y: 30)
                        .frame(height: 50)
            }
            ForEach(movies) {id in
                if self.movies.reversed().firstIndex(of: id) == 0 {
                    DraggableCover(movieId: id,
                                   gestureViewState: self.$draggedViewState,
                                   endGestureHandler: { handler in
                                    self.draggableCoverEndGestureHandler(handler: handler)
                    })
                } else {
                    DiscoverCoverImage(imageLoader: ImageLoader(poster: self.store.state.moviesState.movies[id]!.poster_path,
                                                                size: .small))
                        .scaleEffect(1.0 - Length(self.movies.reversed().firstIndex(of: id)!) * 0.03 + Length(self.scaleResistance()))
                        .padding(.bottom, Length(self.movies.reversed().firstIndex(of: id)! * 16) - self.dragResistance())
                        .animation(.spring())
                }
            }
            GeometryReader { reader in
                self.actionsButtons
                    .position(x: reader.frame(in: .global).midX,
                              y: reader.frame(in: .local).maxY - reader.safeAreaInsets.bottom - 20)
            }
            }
            .presentation(currentModal)
            .onAppear {
                self.hapticFeedback.prepare()
                self.fetchRandomMovies()
        }
    }
}

#if DEBUG
struct DiscoverView_Previews : PreviewProvider {
    static var previews: some View {
        DiscoverView().environmentObject(store)
    }
}
#endif
