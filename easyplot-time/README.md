SimplePlot
==========

A simple plotting library for Haskell, using gnuplot for rendering.

Developed and tested using Mac OS X 10.7.3 with gnuplot 4.4 (via MacPorts). Compiles using GHC 7.0.4

Features
--------

A simple wrapper to the gnuplot command line utility. Make sure gnuplot is in your path and everything should work.

Typically you will invoke a plot like so:

    plot X11 $ Data2D [Title "Sample Data"] [] [(1, 2), (2, 4), ...]

To plot a function, use the following:

    plot X11 $ Function2D [Title "Sine and Cosine"] [] (\x -> sin x * cos x)

There is also a shortcut available - the following plots the sine function:

    plot X11 sin

Output can go into a file, too (See TerminalType):

    plot (PNG "plot.png") (sin . cos)

Haskell functions are plotted via a set of tuples obtained form the function. If you want to make use of gnuplots mighty function plotting functions you can pass a Gnuplot2D or Gnuplot3D object to plot.

    plot X11 $ Gnuplot2D [Color Blue] [] "2**cos(x)"

For 3D-Plots there is a shortcut available by directly passing a String:

    plot X11 "x*y"

Multiple graphs can be shown simply by passing a list of these:

    plot X11 [ Data2D [Title "Graph 1", Color Red] [] [(x, x ** 3) | x <- [-4,-3.9..4]]
             , Function2D [Title "Function 2", Color Blue] [] (\x -> negate $ x ** 2) ]

For 3D Graphs it is useful to be able to interact with the graph (See plot' and GnuplotOption):

    plot' [Interactive] X11 $ Gnuplot3D [Color Magenta] [] "x ** 2 + y ** 3"

If you want to know the command that SimplePlot uses to plot your graph, turn on debugging:

    plot' [Debug] X11 $ Gnuplot3D [Color Magenta] [] "x ** 4 + y ** 3"
    > set term x11 persist; splot x ** 4 + y ** 3 lc rgb "magenta"

