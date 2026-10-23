// Terminal Plots in Odin
//
// A port of plotille lib from Python to Odin.
// Github tammoippen - plotille
// https://github.com/tammoippen/plotille
//
// License
// MIT Open Source License


package terminal_plots

import "core:math"
import "core:fmt"
import "core:strings"

// Round to nearest even integer in case of X.5
round_even :: proc( x : f64 ) -> 
                    f64 {
    
    if math.is_inf( x ) || math.is_nan( x ) {
        
        return x
    }
    return math.round( x )
}

// Create histogram bins and counts
histogram_data :: proc( X         : [ ]f64,
                        bins      : int,
                        allocator := context.allocator ) -> 
                      ( counts    : [ ]int,
                        bin_edges : [ ]f64 ) {
    
    context.allocator = allocator
    
    assert( bins > 0, "bins must be positive" )
    
    if len( X ) == 0 {
        
        counts = make( [ ]int, bins )
        bin_edges = make( [ ]f64, bins + 1 )
        for i in 0 ..= bins {
            
            bin_edges[ i ] = f64( i ) / f64( bins )
        }
        return
    }
    
    // Find min and max
    xmin, xmax := X[ 0 ], X[ 0 ]
    for x in X {
        
        xmin = min( xmin, x )
        xmax = max( xmax, x )
    }
    
    // Handle case where all values are the same
    if xmin == xmax {
        
        xmin -= 0.5
        xmax += 0.5
    }
    
    delta := xmax - xmin
    xwidth := delta / f64( bins )
    
    // Create bins
    counts = make( [ ]int, bins )
    bin_edges = make( [ ]f64, bins + 1 )
    
    for i in 0 ..= bins {
        
        bin_edges[ i ] = xmin + f64( i ) * xwidth
    }
    
    // Count values in each bin
    for x in X {
        
        x_idx := int( ( x - xmin ) / xwidth )
        x_idx = min( bins - 1, x_idx )
        x_idx = max( 0, x_idx )
        counts[ x_idx ] += 1
    }
    
    return
}

// Linear interpolation between two points
lerp :: proc ( x0 : f64,
               y0 : f64,
               x1 : f64,
               y1 : f64,
               x  : f64 ) ->
               f64 {
    
    if x1 == x0 {
        
        return y0
    }
    return y0 + ( y1 - y0 ) * ( x - x0 ) / ( x1 - x0 )
}

// Format number for display
format_number :: proc ( val   : f64,
                        width : int = 8 ) -> 
                        string {
                            
    // Handle special values
    if math.is_inf( val ) {
        
        if val > 0 {
            
            return strings.clone( "+∞", context.temp_allocator )
        }
        return strings.clone( "-∞", context.temp_allocator )
    }
    
    if math.is_nan( val ) {
        
        return strings.clone( "NaN", context.temp_allocator )
    }
    
    // Format number
    abs_val := math.abs( val )
    
    if abs_val == 0 {
        
        return fmt.tprintf( "%*.1f", width, val )
    } else if abs_val >= 1000 || abs_val < 0.01 {
        
        return fmt.tprintf( "%*.2e", width, val )
    } else if abs_val >= 100 {

        return fmt.tprintf( "%*.1f", width, val )
    } else if abs_val >= 10 {
        
        return fmt.tprintf( "%*.2f", width, val )
    } else {
        
        return fmt.tprintf( "%*.3f", width, val )
    }
}

// Calculate nice tick values for axis
calculate_ticks :: proc( min_val   : f64,
                         max_val   : f64,
                         max_ticks : int = 10 ) -> 
                         [ ]f64 {
                             
    if min_val >= max_val {
        
        return { }
    }
    
    range := max_val - min_val
    
    // Calculate nice step size
    rough_step := range / f64( max_ticks - 1 )
    magnitude  := math.pow( 10, math.floor( math.log10( rough_step ) ) )
    
    normalized      := rough_step / magnitude
    nice_normalized : f64
    
    if normalized < 1.5 {
        
        nice_normalized = 1
    } else if normalized < 3 {
        
        nice_normalized = 2
    } else if normalized < 7 {
        
        nice_normalized = 5
    } else {
        
        nice_normalized = 10
    }
    
    step := nice_normalized * magnitude
    
    // Calculate tick start and end
    tick_start := math.floor( min_val / step ) * step
    tick_end   := math.ceil( max_val / step ) * step
    
    // Generate ticks
    num_ticks := int( ( tick_end - tick_start ) / step ) + 1
    ticks     := make( [ dynamic ]f64, context.temp_allocator )
    
    for i in 0 ..< num_ticks {
        
        tick := tick_start + f64( i ) * step
        if tick >= min_val && tick <= max_val {
            
            append( & ticks, tick )
        }
    }
    
    return ticks[ : ]
}
