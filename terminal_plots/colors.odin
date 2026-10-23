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
import "core:os"
import "core:strings"

Color_Mode :: enum {

    Names,  // 3/4 bit encoding: red, blue, green, etc.
    Byte,   // 8-bit encoding: 0-255
    RGB,    // 24-bit encoding: RGB values
}

Color :: union {

    Color_Name,
    u8,        // For byte mode
    RGB_Color, // For RGB mode
}

Color_Name :: enum {

    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    Bright_Black,
    Bright_Red,
    Bright_Green,
    Bright_Yellow,
    Bright_Blue,
    Bright_Magenta,
    Bright_Cyan,
    Bright_White,
}

RGB_Color :: struct {

    r, g, b: u8,
}

// Convert RGB to byte (256-color palette approximation)
rgb_to_byte :: proc ( r, g, b : u8 ) ->
                      u8 {
                         
    if r == g && g == b {
        
        // Grayscale
        if r < 8 {
            
            return 16
        }
        if r > 248 {
            
            return 231
        }
        return u8( round( f64( r - 8 ) / 247 * 24 ) + 232 )
    }
    
    // Color
    r_idx := u8( round( f64( r ) / 255 * 5 ) )
    g_idx := u8( round( f64( g ) / 255 * 5 ) )
    b_idx := u8( round( f64( b ) / 255 * 5 ) )
    
    return 16 + 36 * r_idx + 6 * g_idx + b_idx
}

// Check if running in a TTY
is_atty :: proc ( ) ->
                 bool {
                     
    // For now, assume we're always in a TTY
    // A more sophisticated implementation would use system calls
    return true
}

// Get ANSI color code for foreground
get_fg_code :: proc ( color : Color,
                      mode  : Color_Mode ) -> 
                      string {
    
    switch mode {
    
    case .Names:
        
        if name, ok := color.( Color_Name ); ok {
            
            switch name {
            
            case .Black:          return "30"
            case .Red:            return "31"
            case .Green:          return "32"
            case .Yellow:         return "33"
            case .Blue:           return "34"
            case .Magenta:        return "35"
            case .Cyan:           return "36"
            case .White:          return "37"
            case .Bright_Black:   return "90"
            case .Bright_Red:     return "91"
            case .Bright_Green:   return "92"
            case .Bright_Yellow:  return "93"
            case .Bright_Blue:    return "94"
            case .Bright_Magenta: return "95"
            case .Bright_Cyan:    return "96"
            case .Bright_White:   return "97"
            }
        }
    case .Byte:
        
        if byte_val, ok := color.( u8 ); ok {
        
            return fmt.tprintf( "38;5;%d", byte_val )
        }
    case .RGB:
        
        if rgb, ok := color.( RGB_Color ); ok {
            
            return fmt.tprintf( "38;2;%d;%d;%d", rgb.r, rgb.g, rgb.b )
        }
    }
    return ""
}

// Get ANSI color code for background
get_bg_code :: proc ( color : Color,
                      mode  : Color_Mode ) -> 
                      string {
    
    switch mode {
    
    case .Names:
        
        if name, ok := color.( Color_Name ); ok {
            
            switch name {
            
            case .Black:          return "40"
            case .Red:            return "41"
            case .Green:          return "42"
            case .Yellow:         return "43"
            case .Blue:           return "44"
            case .Magenta:        return "45"
            case .Cyan:           return "46"
            case .White:          return "47"
            case .Bright_Black:   return "100"
            case .Bright_Red:     return "101"
            case .Bright_Green:   return "102"
            case .Bright_Yellow:  return "103"
            case .Bright_Blue:    return "104"
            case .Bright_Magenta: return "105"
            case .Bright_Cyan:    return "106"
            case .Bright_White:   return "107"
            }
        }
    case .Byte:
        
        if byte_val, ok := color.( u8 ); ok {
        
            return fmt.tprintf( "48;5;%d", byte_val )
        }
    case .RGB:
        
        if rgb, ok := color.( RGB_Color ); ok {
            
            return fmt.tprintf( "48;2;%d;%d;%d", rgb.r, rgb.g, rgb.b )
        }
    }
    return ""
}

// Apply color to text with ANSI escape codes
apply_color :: proc ( text     : string,
                      fg       : Maybe( Color ) = nil,
                      bg       : Maybe( Color ) = nil, 
                      mode     := Color_Mode.Names,
                      no_color := false ) -> 
                      string {
                          
    fg_val, has_fg := fg.?
    bg_val, has_bg := bg.?
    
    if !has_fg && !has_bg {
        
        return text
    }

    env_buf: [ 32 ]byte

    // Check NO_COLOR environment variable
    if no_color || os.get_env_buf( env_buf[ : ], "NO_COLOR" ) != "" {

        return text
    }
    
    // Check FORCE_COLOR environment variable
    force_color := os.get_env_buf( env_buf[ : ], "FORCE_COLOR" )
    if force_color != "" {
        
        force_lower := strings.to_lower( force_color, context.temp_allocator )
        if force_lower == "0" || force_lower == "false" || force_lower == "none" {
            
            return text
        }
    }
    
    // Check if we're in a TTY
    if force_color == "" && !is_atty() {
        
        return text
    }
    
    // Build ANSI escape sequence
    codes := make( [ dynamic ]string, context.temp_allocator )
    
    if has_fg {
        
        fg_code := get_fg_code( fg_val, mode )
        if fg_code != "" {
            
            append( & codes, fg_code )
        }
    }
    
    if has_bg {
        
        bg_code := get_bg_code( bg_val, mode )
        if bg_code != "" {
            
            append( & codes, bg_code )
        }
    }
    
    if len( codes ) == 0 {
        
        return text
    }
    
    // Join codes with semicolon
    code_str := strings.join( codes[ : ], ";", context.temp_allocator )
    
    // Return colored text with reset at end
    return fmt.tprintf( "\x1b[%sm%s\x1b[0m", code_str, text )
}

// Helper function for rounding
round :: proc ( x : f64 ) -> 
                f64 {
    
    return x >= 0 ? x + 0.5 : x - 0.5
}

// Helper to create color from name string
color_from_name :: proc ( name : string ) -> 
                          Maybe( Color ) {
    switch name {
    
    case "black":          return Color_Name.Black
    case "red":            return Color_Name.Red
    case "green":          return Color_Name.Green
    case "yellow":         return Color_Name.Yellow
    case "blue":           return Color_Name.Blue
    case "magenta":        return Color_Name.Magenta
    case "cyan":           return Color_Name.Cyan
    case "white":          return Color_Name.White
    case "bright_black":   return Color_Name.Bright_Black
    case "bright_red":     return Color_Name.Bright_Red
    case "bright_green":   return Color_Name.Bright_Green
    case "bright_yellow":  return Color_Name.Bright_Yellow
    case "bright_blue":    return Color_Name.Bright_Blue
    case "bright_magenta": return Color_Name.Bright_Magenta
    case "bright_cyan":    return Color_Name.Bright_Cyan
    case "bright_white":   return Color_Name.Bright_White
    }
    return nil
}

// Helper to create color from RGB values
color_from_rgb :: proc ( r, g, b: u8 ) -> 
                         Maybe( Color ) {
                             
    return RGB_Color{ r, g, b }
}

// Helper to create color from 8-bit index
color_from_byte :: proc ( c : u8 ) ->
                          Maybe( Color ) {

    return c
}
