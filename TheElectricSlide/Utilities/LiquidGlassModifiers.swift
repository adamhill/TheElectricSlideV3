//
//  LiquidGlassModifiers.swift
//  TheElectricSlide
//
//  Liquid Glass design system modifiers for consistent styling
//  Modern SwiftUI 6.3 and macOS 26 glass effects
//

import SwiftUI

// MARK: - Glass Container Modifier

/// Applies a subtle glass material background to a container
/// Perfect for grouping controls or displaying information with depth
struct GlassContainerModifier: ViewModifier {
    let cornerRadius: CGFloat
    let material: Material
    
    init(cornerRadius: CGFloat = 12, material: Material = .ultraThinMaterial) {
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Interactive Glass Effect Modifier

/// Applies the new Liquid Glass interactive effect for custom controls
/// Uses the modern .glassEffect() API from macOS 26
struct InteractiveGlassModifier: ViewModifier {
    let tintColor: Color?
    let shape: AnyShape
    
    init(tint: Color? = nil, shape: some Shape = Capsule()) {
        self.tintColor = tint
        self.shape = AnyShape(shape)
    }
    
    func body(content: Content) -> some View {
        if #available(macOS 26, iOS 26, *) {
            content
                .glassEffect(
                    tintColor.map { Glass.regular.tint($0).interactive() } ?? .regular.interactive(),
                    in: shape
                )
        } else {
            // Fallback for older OS versions
            content
                .background(Material.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Glass Background Effect Modifier

/// Applies a glass material background with shape
/// Creates depth and translucency for backgrounds
struct GlassBackgroundModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let material: Material
    
    init(shape: S, material: Material = .regularMaterial) {
        self.shape = shape
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .background(material, in: shape)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a subtle glass container background
    func glassContainer(cornerRadius: CGFloat = 12, material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassContainerModifier(cornerRadius: cornerRadius, material: material))
    }
    
    /// Applies interactive Liquid Glass effect with optional tint
    func interactiveGlass(tint: Color? = nil, shape: some Shape = Capsule()) -> some View {
        modifier(InteractiveGlassModifier(tint: tint, shape: shape))
    }
    
    /// Applies glass background material with shape
    func glassBackground<S: InsettableShape>(shape: S = RoundedRectangle(cornerRadius: 12), material: Material = .regularMaterial) -> some View {
        modifier(GlassBackgroundModifier(shape: shape, material: material))
    }
}
