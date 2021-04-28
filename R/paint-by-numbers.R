#' Colour-by-numbers image generator
#'
#' A bit of fun. Attempts to create a 'colour-by-numbers' picture from a supplied image.
#'
#' @param img Path (or URL) to image file
#' @param ncols Number of colours to select from image (if target palette is NULL)
#' @param horiz_res Desired horizontal resolution of output image (vertical resolution will be computed
#'   such that the aspect ratio of the original image is maintained)
#' @param noise_reduction noise reduction (percentage of \code{horiz_res})
#' @param despeckle_passes number of times to repeat the despeckle operation (\code{magick::image_despeckle})
#' @param line_col Colour of boundary lines in output image
#' @param number_col Colour of numbers in output image
#' @param line_size Size of boundary lines in output image
#' @param number_size Size of numbers in output image
#' @param verbose Print messages (default = TRUE)
#' @param target_palette An optional target colour palette (rather than extracting colours from the input image)
#' @param brightness modulation of brightness as percentage of the current value (100 for no change)
#' @param saturation modulation of saturation as percentage of the current value (100 for no change)
#' @param hue modulation of hue as percentage of the current value (100 for no change)
#' @param treedepth depth of the quantization color classification tree. Values of 0 or 1 allow selection
#'   of the optimal tree depth for the color reduction algorithm. Values between 2 and 8 may be used to
#'   manually adjust the tree depth.
#' @param simplify proportion of points to retain (0-1)
#'
#' @return A list with three elements
#' \itemize{
#'   \item palette = A tibble containing the colour IDs and their hexidecimal strings
#'   \item painted_picture = The ggplot2 plot with the polygons filled in
#'   \item cbn_picture = The colour-by-numbers ggplot2 plot
#'   }
#' @export
paint_by_numbers <-
  function(img,
           ncols = 10,
           horiz_res = 600,
           noise_reduction = 0.5,
           despeckle_passes = 3,
           simplify = 0.05,
           brightness = 100,
           saturation = 100,
           hue = 100,
           treedepth = 0,
           line_col = "grey30",
           number_col = "grey40",
           line_size = 0.1,
           number_size = 0.5,
           verbose = TRUE,
           target_palette = NULL){

    # img = 'https://miro.medium.com/max/1000/1*1xHqHD8Mbk-m5JviP5-lqw.jpeg'
    # ncols = 12
    # horiz_res = 600
    # despeckle_passes = 3
    # simplify = 0.05
    # brightness = 100
    # saturation = 100
    # hue = 100
    # treedepth = 0
    # line_col = "grey30"
    # number_col = "grey40"
    # line_size = 0.1
    # number_size = 0.5
    # verbose = TRUE
    # target_palette = NULL

    # Process image -----------------------------------------------------------
    if(verbose){message("Processing image ...")}
    img_raw <- magick::image_read(img)

    # Process image
    img_processed <-
      img_raw %>%
      magick::image_resize(as.character(horiz_res), filter="point") %>%
      magick::image_modulate(brightness=brightness, saturation=saturation, hue=hue) %>%
      magick::image_despeckle(despeckle_passes) %>%
      magick::image_reducenoise((horiz_res/100)*noise_reduction) %>%
      magick::image_flip()

    # Extract colours and quantise image --------------------------------------
    if(is.null(target_palette)){
      img_quantised <-
        img_processed %>%
        magick::image_quantize(max = ncols, dither=FALSE, treedepth = treedepth)
    } else {
      img_quantised <-
        img_processed %>%
        magick::image_map(magick::image_read(matrix(target_palette)), dither = FALSE)
    }

    # Convert pixel area to SF polygons ---------------------------------------
    if(verbose){message("Creating polygons ...")}

    # Convert image to dataframe with a numeric ID column for each unique colour
    img_raster <-
      img_quantised %>%
      magick::image_raster() %>%
      dplyr::group_by(col) %>%
      dplyr::mutate(z = dplyr::cur_group_id()) %>%
      dplyr::ungroup()

    # Create a dataframe of the unique colours
    cols <- dplyr::distinct(img_raster, z, col)

    # Convert to STARS
    # Then convert to SF, merging points based on identical pixel colour values
    # Join the actual colour hex code back to the data
    # Simplify the polygons using rmapshaper
    img_sf <-
      img_raster %>%
      dplyr::select(-col) %>%
      stars::st_as_stars() %>%
      sf::st_as_sf(as_points = FALSE, merge = TRUE) %>%
      # dplyr::filter(sf::st_area(.) > 2) %>%
      dplyr::left_join(cols, by="z") %>%
      rmapshaper::ms_simplify(method = NULL, keep = simplify, weighting = 1)

    # Return image ------------------------------------------------------------
    if(verbose){message("Rendering outputs ...")}

    # Colour palette
    palette <-
      cols %>%
      ggplot2::ggplot()+
      ggplot2::geom_col(ggplot2::aes(as.factor(z), 1, fill=col), col=1, size=line_size)+
      ggplot2::scale_fill_identity()+
      ggplot2::theme_void()+
      ggplot2::theme(axis.text.x = ggplot2::element_text())+
      ggplot2::coord_equal()

    # Plot painted
    painted <-
      img_sf %>%
      ggplot2::ggplot()+
      ggplot2::geom_sf(ggplot2::aes(fill=col), col=NA)+
      ggplot2::scale_fill_identity()+
      ggplot2::theme_void()

    # Plot paint by numbers
    pbn <-
      img_sf %>%
      ggplot2::ggplot()+
      ggplot2::geom_sf(fill=NA, col=line_col, size=line_size)+
      ggplot2::geom_sf_text(ggplot2::aes(label = z), size=number_size, col=number_col)+
      ggplot2::scale_fill_identity()+
      ggplot2::theme_void()

    design <- "AAAAA
             #BBB#"

    list(
      palette = cols,
      painted_picture = patchwork::wrap_plots(painted, palette, heights = c(1, 0.05), design = design),
      paint_by_numbers = patchwork::wrap_plots(pbn, palette, heights = c(1, 0.05), design = design))

  }
