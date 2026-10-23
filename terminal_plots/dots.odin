// Terminal Plots in Odin
//
// A port of plotille lib from Python to Odin.
// Github tammoippen - plotille
// https://github.com/tammoippen/plotille
//
// License
// MIT Open Source License


package terminal_plots

import "core:fmt"

// Braille dot mapping for Unicode characters
// Dot ordering : U+2800 '⠀' - U+28FF '⣿' according to ISO/TR 11548-1
// Each dot on/off is 8bit (256 possibilities)
//
// Ordering of dots:
// 1  4
// 2  5
// 3  6
// 7  8

// Map ( x, y ) coordinates to dot bit position
// Standard braille ordering ( NOT inverted ):
// Dots:  1 4    Bits: 0 3
//        2 5          1 4
//        3 6          2 5
//        7 8          6 7
XY_TO_DOT := [ 4 ][ 2 ]u8{
    { 1 << 0, 1 << 3 }, // y=0 ( top row: dots 1, 4 )
    { 1 << 1, 1 << 4 }, // y=1 ( dots 2, 5 )
    { 1 << 2, 1 << 5 }, // y=2 ( dots 3, 6 )
    { 1 << 6, 1 << 7 }, // y=3 ( bottom row: dots 7, 8 )
}

Dots :: struct {
    
    dots       : u8,
    marker     : Maybe( rune ),
    fg         : Maybe( Color ),
    bg         : Maybe( Color ),
    color_mode : Color_Mode,
}

make_dots :: proc ( marker     : Maybe( rune ) = nil,
                    fg         : Maybe( Color ) = nil,
                    bg         : Maybe( Color ) = nil, 
                    color_mode := Color_Mode.Names ) -> 
                    Dots {
    
    return Dots{
        
        dots       = 0,
        marker     = marker,
        fg         = fg,
        bg         = bg,
        color_mode = color_mode,
    }
}

// Get all set dot positions ( 1-8 )
get_dot_positions :: proc ( d : Dots ) -> 
                           [ dynamic ]int {
                               
    positions := make( [ dynamic ]int )
    x := d.dots
    bit := 1
    
    for x != 0 {
        
        if (x & 1) == 1 {
            
            append( & positions, bit )
        }
        bit += 1
        x >>= 1
    }
    
    return positions
}

// Fill all dots
dots_fill :: proc( d : ^Dots ) {
    
    d.dots = 0xFF
}

// Clear all dots
dots_clear :: proc ( d : ^Dots ) {
    
    d.dots   = 0
    d.marker = nil
}

// Update dot at position ( x, y ) where x in [ 0, 1 ] and y in [ 0, 1, 2, 3 ]
dots_update :: proc ( d      : ^Dots,
                      x      : int, 
                      y      : int,
                      set    := true,
                      marker : Maybe( rune ) = nil ) {
    
    // Bounds check with clamping instead of assertion
    if x < 0 || x > 1 || y < 0 || y > 3 {
    
        return // Silently ignore out of bounds
    }
    
    if set {
    
        d.dots |= XY_TO_DOT[ y ][ x ]
        if m, ok := marker.?; ok {
            
            d.marker = m
        }
    } else {
        
        d.dots = d.dots & ( XY_TO_DOT[ y ][ x ] ~ 0xFF )
        d.marker = nil
    }
}

// Convert dots to string representation
dots_to_string :: proc ( d         : Dots,
                         allocator := context.allocator ) -> 
                         string {
    
    context.allocator = allocator
    
    // If we have a marker, use it
    if marker, ok := d.marker.?; ok {
        
        text := fmt.tprintf( "%r", marker )
        return apply_color( text, d.fg, d.bg, d.color_mode )
    }
    
    // Otherwise, use braille character
    braille_char := rune( 0x2800 + u32( d.dots ) )
    text := fmt.tprintf( "%r", braille_char )
    return apply_color( text, d.fg, d.bg, d.color_mode )
}

// Create braille character from list of dot positions ( 1-8 )
braille_from_dots :: proc ( dots : [ ]int ) ->
                            rune {

    bin_code : u8 = 0
    
    for dot in dots {
        
        assert( dot >= 1 && dot <= 8, "Dot must be between 1 and 8" )
        bin_code |= u8( 1 << u8( dot - 1 ) )
    }
    
    return rune( 0x2800 + u32( bin_code ) )
}

// Get dot positions from braille character
dots_from_braille :: proc ( braille : rune ) -> 
                            [ dynamic ]int {
    
    assert( braille >= 0x2800 && braille <= 0x28FF, "Not a braille character" )
    
    code := u8( braille - 0x2800 )
    dots := make( [ dynamic ]int )
    
    for i in 0 ..< 8 {
        
        if ( code & (1 << u8( i ) ) ) != 0 {
            
            append( & dots, i + 1 )
        }
    }
    
    return dots
}
