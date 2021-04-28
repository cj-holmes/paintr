
<!-- README.md is generated from README.Rmd. Please edit that file -->

# paintr <img src='man/figures/logo.png' align="right" height="160" /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

<!-- badges: end -->

The goal of `paintr` is to convert images to paint-by-numbers pictures.
It’s intended to be a bit of fun!

All image processing and colour picking is done by the splendid `magick`
package. The image polygons are processed using the equally splendid
`sf` package with simplification handled by `rmapshaper`.

``` r
library(paintr)
```

Noise reduction, smoothing and polygon simplification are applied by
default through the `noise_reduction`, `despeckle_passes` and `simplify`
arguments. These arguments (along with `ncols`) make the biggest changes
to the overall ‘feel’ of the image and should be experimented with in
order to achieve the desired results.

## Use

Use of the `paint_by_numbers()` function is demonstrated with Hadley
Wickham’s photo

Path to image

``` r
img <- 'https://miro.medium.com/max/450/1*1xHqHD8Mbk-m5JviP5-lqw.jpeg'
```

``` r
hadley <- paint_by_numbers(img)
```

``` r
hadley$paint_by_numbers
```

![](man/figures/README-unnamed-chunk-5-1.png)<!-- -->

``` r
hadley$painted_picture
```

![](man/figures/README-unnamed-chunk-6-1.png)<!-- -->

## Supply a palette

It’s tough to get a good selection of colours to use as a target palette
for the output image. If the automatically chosen colours just don’t cut
it, you can supply your own target colour palette. The colours in the
original image will be mapped to the ‘closest’ colour in the supplied
target palette. Here demonstrated with a palette of grey colours.

Other cool packages for creating colour palettes (such as `colorfindr`)
could also be used to supply a target palette.

``` r
paint_by_numbers(img, target_palette = grey.colors(3))
#> $palette
#> # A tibble: 3 x 2
#>   col           z
#>   <chr>     <int>
#> 1 #e6e6e6ff     3
#> 2 #aeaeaeff     2
#> 3 #4d4d4dff     1
#> 
#> $painted_picture
#> 
#> $paint_by_numbers
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="50%" /><img src="man/figures/README-unnamed-chunk-7-2.png" width="50%" />
