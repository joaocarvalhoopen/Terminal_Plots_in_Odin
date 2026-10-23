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
import "core:strings"

Plot_Type :: enum {
    
    Line,
    Scatter,
    Histogram,
}

Plot_Data :: struct {
    
    X      : [ ]f64,
    Y      : [ ]f64,
    type   : Plot_Type,
    color  : Maybe( Color ),
    label  : string,
    marker : Maybe( rune ),
}

Figure :: struct {
    
    width       : int,
    height      : int,
    x_min       : Maybe( f64 ),
    x_max       : Maybe( f64 ),
    y_min       : Maybe( f64 ),
    y_max       : Maybe( f64 ),
    color_mode  : Color_Mode,
    with_colors : bool,
    origin      : bool,
    background  : Maybe( Color ),
    x_label     : string,
    y_label     : string,
    plots       : [ dynamic ]Plot_Data,
    color_index : int,
}

// Default colors for automatic color assignment
DEFAULT_COLORS := [ ]Color{
    
    Color_Name.White,
    Color_Name.Red,
    Color_Name.Green,
    Color_Name.Yellow,
    Color_Name.Blue,
    Color_Name.Magenta,
    Color_Name.Cyan,
}

make_figure :: proc ( allocator := context.allocator ) -> 
                      Figure {
    
    return Figure{
        
        width       = 80,
        height      = 40,
        color_mode  = .Names,
        with_colors = true,
        origin      = true,
        x_label     = "X",
        y_label     = "Y",
        plots       = make( [ dynamic ]Plot_Data, allocator ),
        color_index = 0,
    }
}

destroy_figure :: proc ( f : ^Figure ) {
    
    for plot in f.plots {
        
        delete( plot.X )
        delete( plot.Y )
    }
    delete(f.plots)
}

// Set x limits
figure_set_x_limits :: proc ( f       : ^Figure,
                              min_val : f64,
                              max_val : f64 ) {
    
    f.x_min = min_val
    f.x_max = max_val
}

// Set y limits
figure_set_y_limits :: proc( f       : ^Figure,
                             min_val : f64,
                             max_val : f64 ) {
    
    f.y_min = min_val
    f.y_max = max_val
}

// Get next automatic color
figure_next_color :: proc ( f : ^Figure ) ->
                            Color {
                                
    color := DEFAULT_COLORS[ f.color_index % len( DEFAULT_COLORS ) ]
    f.color_index += 1
    return color
}

// Add a line plot to the figure
figure_plot :: proc ( f         : ^Figure,
                      X         : [ ]f64,
                      Y         : [ ]f64,
                      color     : Maybe( Color ) = nil, 
                      label     := "", marker: Maybe( rune ) = nil, 
                      allocator := context.allocator ) {
    
    context.allocator = allocator
    
    assert( len( X ) == len( Y ), "X and Y must have same length" )
    
    // Copy data
    x_copy := make( [ ]f64, len( X ) )
    y_copy := make( [ ]f64, len( Y ) )
    copy( x_copy, X )
    copy( y_copy, Y )
    
    // Assign color if not provided
    plot_color := color
    if col, ok := color.?; !ok && f.with_colors {
        
        plot_color = figure_next_color( f )
    }
    
    plot := Plot_Data{
        
        X      = x_copy,
        Y      = y_copy,
        type   = .Line,
        color  = plot_color,
        label  = label,
        marker = marker,
    }
    
    append( & f.plots, plot )
}

// Add a scatter plot to the figure
figure_scatter :: proc ( f         : ^Figure,
                         X         : [ ]f64,
                         Y         : [ ]f64,
                         color     : Maybe( Color ) = nil,
                         label     := "",
                         marker    : Maybe( rune ) = nil,
                         allocator := context.allocator ) {
    
    context.allocator = allocator
    
    assert( len( X ) == len( Y ), "X and Y must have same length" )
    
    // Copy data
    x_copy := make( [ ]f64, len( X ) )
    y_copy := make( [ ]f64, len( Y ) )
    copy( x_copy, X )
    copy( y_copy, Y )
    
    // Assign color if not provided
    plot_color := color
    if col, ok := color.?; !ok && f.with_colors {
        
        plot_color = figure_next_color( f )
    }
    
    plot := Plot_Data{
        
        X      = x_copy,
        Y      = y_copy,
        type   = .Scatter,
        color  = plot_color,
        label  = label,
        marker = marker,
    }
    
    append( & f.plots, plot )
}

// Add a histogram to the figure
figure_histogram :: proc ( f         : ^Figure, 
                           X         : [ ]f64,
                           bins      := 160, 
                           color     : Maybe( Color ) = nil,
                           label     := "",
                           allocator := context.allocator ) {
    
    context.allocator = allocator
    
    // Compute histogram
    counts, bin_edges := histogram_data( X, bins, allocator )
    defer delete( counts, allocator )
    defer delete( bin_edges, allocator )
    
    // Convert to X, Y arrays for plotting
    x_data := make( [ ]f64, len( counts ) )
    y_data := make( [ ]f64, len( counts ) )
    
    for i in 0 ..< len( counts ) {
        
        x_data[ i ] = ( bin_edges[ i ] + bin_edges[ i + 1 ]) / 2.0
        y_data[ i ] = f64( counts[ i ] )
    }
    
    // Assign color if not provided
    plot_color := color
    if col, ok := color.?; !ok && f.with_colors {
        
        plot_color = figure_next_color( f )
    }
    
    plot := Plot_Data{
        
        X     = x_data,
        Y     = y_data,
        type  = .Histogram,
        color = plot_color,
        label = label,
    }
    
    append( & f.plots, plot )
}

// Add text labels to the figure
figure_text :: proc( f      : ^Figure, 
                     X      : [ ]f64, 
                     Y      : [ ]f64,
                     labels : [ ]string,
                     color  : Maybe( Color ) = nil ) {
                         
    // Store text as special plot type
    // We'll need to add a Text type to Plot_Type
    // For now, just store as points and handle in rendering
    
    x_copy := make( [ ]f64, len( X ) )
    y_copy := make( [ ]f64, len( Y ) )
    copy( x_copy, X )
    copy( y_copy, Y )
    
    plot_color := color
    if col, ok := color.?; !ok && f.with_colors {
        
        plot_color = figure_next_color( f )
    }
    
    // Note: labels are stored but rendering would need canvas text support
    plot := Plot_Data{
        
        X      = x_copy,
        Y      = y_copy,
        type   = .Scatter,
        color  = plot_color,
        label  = "",
        marker = nil,
    }
    
    append(&f.plots, plot)
}

// Clear all plots from figure
figure_clear :: proc ( f : ^Figure ) {
    
    for plot in f.plots {
        
        delete( plot.X )
        delete( plot.Y )
    }
    clear( & f.plots )
    f.color_index = 0
}

// Show the figure ( render to string )
figure_show :: proc ( f         : ^Figure, 
                      legend    := false,
                      allocator := context.allocator ) -> 
                      string {
                          
    context.allocator = allocator
    
    if len( f.plots ) == 0 {
        
        return ""
    }
    
    // Calculate limits if not set
    x_min_val := f.x_min.? or_else calculate_min_x( f )
    x_max_val := f.x_max.? or_else calculate_max_x( f )
    y_min_val := f.y_min.? or_else calculate_min_y( f ) 
    y_max_val := f.y_max.? or_else calculate_max_y( f )
    
    // Handle edge cases
    if x_min_val >= x_max_val {
        
        x_min_val -= 0.5
        x_max_val += 0.5
    }
    if y_min_val >= y_max_val {
        
        y_min_val -= 0.5
        y_max_val += 0.5
    }
    
    // Create canvas (use allocator, not temp_allocator)
    canvas := make_canvas( f.width, f.height,
                           x_min_val, y_min_val, x_max_val, y_max_val,
                           f.background, f.color_mode, allocator )
    defer destroy_canvas( & canvas )
    
    // Plot all data
    for plot in f.plots {
        
        switch plot.type {
        
        case .Line:
            
            // Plot line with interpolation
            for i in 0 ..< len( plot.X ) {
                
                if m, ok := plot.marker.?; ok {
                    
                    canvas_point( & canvas, plot.X[ i ], plot.Y[ i ], true, plot.color, m )
                }
                if i > 0 {
                    
                    canvas_line( & canvas, plot.X[ i - 1 ], plot.Y[ i - 1 ], plot.X[ i ], plot.Y[ i ], 
                                 true, plot.color )
                }
            }
        case .Scatter:
            
            // Plot scatter points
            for i in 0 ..< len( plot.X ) {
                
                canvas_point( & canvas, plot.X[ i ], plot.Y[ i ], true, plot.color, plot.marker )
            }
        case .Histogram:
            
            // Plot histogram bars
            for i in 0 ..< len( plot.X ) {
                
                if plot.Y[ i ] > 0 {
                    
                    canvas_line( & canvas, plot.X[ i ], 0, plot.X[ i ], plot.Y[ i ], true, plot.color )
                }
            }
        }
    }
    
    // Generate output
    output := generate_plot( & canvas, f.x_label, f.y_label, f.origin )
    
    // Add legend if requested
    if legend {
        
        legend_str := generate_legend( f )
        if legend_str != "" {
            
            output = fmt.tprintf( "%s\n%s", output, legend_str )
        }
    }
    
    return output
}

// Generate legend for figure
generate_legend :: proc ( f : ^Figure ) -> 
                          string {
    
    builder := strings.builder_make( context.temp_allocator )
    
    has_labels := false
    for plot in f.plots {
        
        if len( plot.label ) > 0 {
            
            has_labels = true
            break
        }
    }
    
    if !has_labels {
        
        return ""
    }
    
    strings.write_string( & builder, "\nLegend:\n" )
    
    for plot in f.plots {
        
        if len( plot.label ) == 0 {
            
            continue
        }
        
        // Create colored marker
        marker_char: rune = '⣿'
        if m, ok := plot.marker.?; ok {
            
            marker_char = m
        }
        
        marker_str := fmt.tprintf( "%r", marker_char )
        if f.with_colors {
            
            marker_str = apply_color( marker_str, plot.color, nil, f.color_mode )
        }
        
        strings.write_string( & builder, fmt.tprintf( "  %s %s\n", marker_str, plot.label ) )
    }
    
    return strings.to_string( builder )
}

// Helper functions to calculate limits
calculate_min_x :: proc ( f : ^Figure ) -> 
                          f64 {
    
    if len( f.plots ) == 0 do return 0
    min_val := f.plots[ 0 ].X[ 0 ]
    for plot in f.plots {
        
        for x in plot.X {
            
            min_val = min( min_val, x )
        }
    }
    // return min_val
    return min_val
}

calculate_max_x :: proc( f : ^Figure ) -> 
                         f64 {
                             
    if len( f.plots ) == 0 do return 1
    max_val := f.plots[ 0 ].X[ 0 ]
    for plot in f.plots {
        
        for x in plot.X {
            
            max_val = max( max_val, x )
        }
    }
    // return max_val
    // return max_val * 1.05
    return max_val * 1.02
}

calculate_min_y :: proc ( f: ^Figure ) ->
                          f64 {
                              
    if len( f.plots ) == 0 do return 0
    min_val := f.plots[ 0 ].Y[ 0 ]
    for plot in f.plots {
        
        for y in plot.Y {
            
            min_val = min( min_val, y )
        }
    }
    // return min_val
    return min_val
}

calculate_max_y :: proc ( f : ^Figure ) ->
                          f64 {
    
    if len( f.plots ) == 0 do return 1
    max_val := f.plots[ 0 ].Y[ 0 ]
    for plot in f.plots {
        
        for y in plot.Y {
            
            max_val = max( max_val, y )
        }
    }
    // return max_val
    // return max_val * 1.05
    return max_val * 1.02
}
