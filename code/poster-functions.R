
deg2rad <- function(deg) return(deg*pi/180)

## Calculates the geodesic distance between two points specified by
## radian latitude/longitude using the Haversine formula
gcd.hf <- function(long1, lat1, long2, lat2) {
    R <- 6371 # Earth mean radius [km]
    delta.long <- (long2 - long1)
    delta.lat <- (lat2 - lat1)
    a <- sin(delta.lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta.long/2)^2
    c <- 2 * asin(min(1,sqrt(a)))
    d = R * c
    return(d) # Distance in km
}

## Fxn to calculate matrix of distances between each two sites
CalcDists <- function(latlongs) {
    name <- list(rownames(latlongs), rownames(latlongs))
    n <- nrow(latlongs)
    z <- matrix(0, n, n, dimnames = name)
    for (i in 1:n) {
        for (j in 1:n) z[i, j] <- gcd.hf(long1 = latlongs[i, 1],
                                         lat1 = latlongs[i, 2], long2 = latlongs[j, 1], lat2 = latlongs[j,2])
    }
    z <- as.dist(z)
    return(z)
}

thinCoords <- function(coords, min.dist = 200) {       
    tmpDt <- coords 
    tmpDt <- tmpDt[!is.na(tmpDt$latitude) & !is.na(tmpDt$longitude), ]
    tmpDt$Lat2 <- tmpDt$latitude
    tmpDt$Long2 <- tmpDt$longitude 
    d <- CalcDists(cbind(deg2rad(tmpDt$longitude), deg2rad(tmpDt$latitude)))
    d <- as.matrix(d)
    d[upper.tri(d, diag = TRUE)] <- NA
    lbl <- cbind(dimnames(d)[[1]][row(d)], dimnames(d)[[1]][col(d)])
    d <- as.vector(d)
    whichDup <- lbl[which(d < min.dist), ]      
    if (length(whichDup) > 0) {
        if(length(whichDup) == 2) {
            whichDup <- matrix(whichDup, ncol = 2, byrow = TRUE) # to deal with single result
        }
        for (j in 1:nrow(whichDup)) {
            tmpDt$Lat2[as.numeric(whichDup[j,2])] <- tmpDt$Lat2[as.numeric(whichDup[j,1])]
            tmpDt$Long2[as.numeric(whichDup[j,2])] <- tmpDt$Long2[as.numeric(whichDup[j,1])]
            tmpDt$Long2.recenter[as.numeric(whichDup[j,2])] <- tmpDt$Long2.recenter[as.numeric(whichDup[j,1])]
        }
    }                                        
    tmpDt
}


## From http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_%28ggplot2%29/
## Downloaded on 2014-05-29
# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  require(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
