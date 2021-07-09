//
//  SnapCarousel.swift
//  CarouselTest
//
//  Created by Jose David Mantilla Pabon on 5/07/21.
//

import SwiftUI

//TODO: Support diferent Size-Class & Orientation
//TODO: Support IPAD
//TODO: Support MAC

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private struct SnapCarouselBuilder <Content: View> : View{
    
    let numberOfItems: Int
    let spacing: CGFloat?
    let widthOfHiddenCards: CGFloat?
    let content:  (GeometryProxy, CGFloat, CGFloat) -> Content
    @State private var bgOffset:CGFloat = 0.0
    @GestureState var screenDrag: CGFloat = 0.0
    var selection: Binding<Int>?
    
    public init(_ numberOfItems:Int,
                spacing: CGFloat? = nil,widthOfHiddenCards: CGFloat? = nil,
                selection: Binding<Int>? = nil,
                @ViewBuilder content: @escaping (GeometryProxy, CGFloat, CGFloat) -> Content){
        self.content = content
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.numberOfItems = numberOfItems
        self.selection = selection
    }
    
    public var body: some View {
        GeometryReader { g   in
            let spacing : CGFloat = {
                let spacingRange = (-g.size.width * 0.1) ... (g.size.width * 0.1)
                guard let spacing = self.spacing else {return 0}
                return spacing.clamped(to: spacingRange)
            }()
            let widthOfHiddenCards: CGFloat = {
                let widthOfHiddenCardsRange = (-g.size.width * 0.15) ... (g.size.width * 0.15)
                guard let widthOfHiddenCards = self.widthOfHiddenCards else { return 0}
                return widthOfHiddenCards.clamped(to: widthOfHiddenCardsRange)
            }()
            
            HStack(spacing:0) {
                content(g,spacing,widthOfHiddenCards)
            }
            .offset(x: -bgOffset*(g.size.width - widthOfHiddenCards * 2 - spacing ) + screenDrag)
            .animation(.default)
            .gesture(
                DragGesture()
                    .updating($screenDrag) {currentState, gestureState, transaction in
                      gestureState  = currentState.translation.width
                    }
                    .onEnded{ value in
                        if value.translation.width > 50 && bgOffset > 0{
                            bgOffset -= 1
                            selection?.wrappedValue = Int(bgOffset)
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                        }else if value.translation.width < -50 && Int(bgOffset) < numberOfItems - 1 {
                            bgOffset += 1
                            selection?.wrappedValue = Int(bgOffset)
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                        }
                    }
            )
            .onAppear{
                if let selection = selection{
                    bgOffset = CGFloat(selection.wrappedValue)
                }
            }
        }
    }
}


/// A view that switches between multiple card  views using interactive user
/// interface elements allowing to preview part of  the next view and previous view .
///
/// To create a user interface with cards, place views in a `SnapCarousel`
///
///     SnapCarousel(testData, spacing: 10, widthOfHiddenCards: 30) {  item in 
///         Text(item.description)
///             .frame(maxWidth: .infinity, maxHeight: .infinity)
///             .background(Color.black)
///             .transition(AnyTransition.slide)
///             .animation(.spring())
///     }
///     .frame(height: 320)
///
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SnapCarousel<Data, Content> where Data : RandomAccessCollection {
   
    /// The collection of underlying identified data that SwiftUI uses to create
    /// views dynamically.
    public var data: Data
    
    /// A function to create content on demand using the underlying data.
    public var content: (Data.Element) -> Content
    
    /// A property to define de spaces between  adjacent subviews
    public let spacing: CGFloat?
    
    /// A propoerty to define the width visible of adjacente sbuviews
    public let widthOfHiddenCards: CGFloat?

    /// Creates an instance that selects from content associated with
    /// `Selection` values.
    public var selection: Binding<Int>?
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SnapCarousel: View  where  Content : View,Data.Element : Hashable {
   // extension SnapCarousel: View  where  Content : View ,Data.Element : Hashable{
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// It's important that the `id` of a data element doesn't change unless you
    /// replace the data element with a new data element that has a new
    /// identity. If the `id` of a data element changes, the content view
    /// generated from that data element loses any current state and animations.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``ForEach`` instance uses to
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the stack to choose a default distance for each pair of
    ///     subviews.
    ///   - widthOfHiddenCards: The width of adjacent suibviews visible on the screen
    ///   - content: A view builder that creates the content of this stack.
    ///     create views dynamically.
    ///   - content: The view builder that creates views dynamically.
    @inlinable public init(_ data: Data,spacing: CGFloat? = nil, widthOfHiddenCards: CGFloat? = nil, selection: Binding<Int>? = nil, @ViewBuilder content: @escaping ( Data.Element) -> Content){
        self.data = data
        self.content = content
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.selection = selection
    }
    
    var numberOfItems: Int{
        data.count
    }
    var dataEnumerated:  [(Int,Data.Element)]{
        Array(data.enumerated())
    }
    
    public var body: some View {
        SnapCarouselBuilder(data.count, spacing: spacing, widthOfHiddenCards: widthOfHiddenCards, selection: selection) { g, spacing, widthOfHiddenCards in
            ForEach(dataEnumerated, id:\.1.self){ idx, item in
                content(item)
                    .frame(width:  g.size.width - (idx == numberOfItems - 1 || idx == 0 ? widthOfHiddenCards: 2 * widthOfHiddenCards ) - 2 * spacing)
                    .padding(.horizontal, spacing/2)
                    .padding(.leading, idx == 0 ? spacing/2 :0)
                    .padding(.trailing, idx == numberOfItems - 1 ? spacing/2 :0)
                    
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SnapCarousel where Data == Range<Int>, Content : View {
    /// Creates an instance that computes views on demand over a given constant
    /// range.
    ///
    /// The instance only reads the initial value of the provided `data` and
    /// doesn't need to identify views across updates. To compute views on
    /// demand over a dynamic range, use ``ForEach/init(_:id:content:)``.
    ///
    /// - Parameters:
    ///   - data: A constant range.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the stack to choose a default distance for each pair of
    ///     subviews.
    ///   - widthOfHiddenCards: The width of adjacent suibviews visible on the screen
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Range<Int>,spacing: CGFloat? = nil,  widthOfHiddenCards: CGFloat? = nil,selection: Binding<Int>?, @ViewBuilder content: @escaping (Int) -> Content){
        self.data = data
        self.content = content
        self.spacing = spacing
        self.widthOfHiddenCards = widthOfHiddenCards
        self.selection = selection
    }
    
//    var numeberOfItems: Int{
//        data.count
//    }
//        
//    public var body: some View {
//        SnapCarouselBuilder(data.count, spacing: spacing, widthOfHiddenCards: widthOfHiddenCards, selection: selection) { g, spacing, widthOfHiddenCards in
//            ForEach(data, id:\.self){ idx  in
//                content(idx)
//                    .padding(.horizontal, spacing/2)
//                    .frame(width:  g.size.width - (idx == numberOfItems - 1 || idx == 0 ? widthOfHiddenCards: 2 * widthOfHiddenCards))
//                    
//                    
//            }
//        }
//    }
}
