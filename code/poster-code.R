### ---- init-map ----
library(maps)
library(ggplot2)
source("code/poster-functions.R")

inat <- read.csv(file="data/echinoderms.all.csv", stringsAsFactors=FALSE)
inatThin <- thinCoords(inat)
wrld <- map_data("world")

## Color definition
library(wesanderson)
zissouPal <- wes.palette(name = "Zissou", type="continuous")
zissouPalDisc <- wes.palette(5, name="Zissou")
zissouPerClass <- zissouPalDisc[c(5, 1, 4, 3, 2)]

seaCol <- "#dfeff2" #"#d6e6e9" #"70B8C3"
landCol <- "#b0ccad" # a6cca2" #"#c5f2c1" #"#e1f2df"

## Higher classification
uniqSpp <- unique(inat$scientific_name)
## library(taxize)
## ## higherClass <- classification(uniqSpp, db="itis") ## very incomplete
## higherClassNCBI <- classification(uniqSpp, db="ncbi") # much better
## save(higherClassNCBI, file="data/higherClassNBCI.RData")

load("data/higherClassNBCI.RData")
higherClass <- rbind(higherClassNCBI)
classTaxa <- subset(higherClass, rank == "class")

## dealing manually with species not in NCBI
## write.csv(uniqSpp[! uniqSpp %in% classTaxa$taxonid], file="/tmp/missingTaxa.csv",
##          row.names=FALSE)
## after manual editing
missingTaxa <- read.csv(file="data/missingTaxa-classes.csv", stringsAsFactors=FALSE)

## after updating data, will need to check that all data is included

classTaxa <- rbind(classTaxa, missingTaxa)
addClass <- merge(inatThin, classTaxa, by.x="scientific_name", by.y="taxonid", all.x=TRUE)
names(addClass)[match("name", names(addClass))] <- "class"

## Fix error in NCBI database
addClass[addClass$class == "Gymnolaemata" & !is.na(addClass$class), "class"] <- "Echinoidea"

## sum(is.na(addClass$class)) ## currenly only 2 missing

## Below,  too messy to be useful
## ggplot(addClass) + annotation_map(wrld, color="NA", fill=landCol) +
##     geom_point(aes(x=longitude, y=latitude, colour=class), size=3, position= position_jitter(width=2)) +
##     coord_map(projection="mercator") + ylim(-35, 58) +
##     scale_colour_manual(values = zissouPerClass) +                        
##     theme(legend.position="top", legend.title = element_blank(),
##           panel.background = element_rect(fill = seaCol),
##           panel.grid.major = element_line(colour = "white", size=0.1))
    
### Map of all observations thinned (at 200km scale), grouped by classes.
### ---- all-observations ----
uniqGPS <- paste(addClass$class, addClass$Lat2, addClass$Long2, sep="/")
tableGPS <- table(uniqGPS)
coordsGPS <- strsplit(names(tableGPS), "/") 
nbObsTable <- data.frame(class = sapply(coordsGPS, function(x) x[1]),
                         latitude=as.numeric(sapply(coordsGPS, function(x) x[2])),
                         longitude=as.numeric(sapply(coordsGPS, function(x) x[3])),
                         nbObs=tableGPS[, drop=TRUE],
                         stringsAsFactors=FALSE, row.names=NULL)
nbObsTable <- subset(nbObsTable, class != "NA")

ggplot(nbObsTable) + annotation_map(wrld, color="NA", fill=landCol) +
    geom_point(aes(x=longitude, y=latitude, size=nbObs, colour=class),
               position=position_jitter(width=1)) +
    scale_size(range=c(4, 15)) + ylab("Latitude") + xlab("Longitude") +
    coord_map(projection="mercator") + ylim(c(-35, 58)) +
    scale_colour_manual(values = zissouPerClass) +    
    theme(legend.position = c(.97,.9), legend.title = element_blank(),
          legend.direction = "horizontal", legend.justification = "right",
          panel.background = element_rect(fill = seaCol),
          panel.grid.major = element_line(colour = "white", size=0.1))


## user stats
## number of people have submitted observation
## mean/median numbers

### ---- abundance-per-class ----
tabClass <- table(addClass$class)
tabClass <- tabClass[c("Asteroidea", "Crinoidea", "Echinoidea", "Holothuroidea", "Ophiuroidea")]

par(mar=c(2, 7, 0, 1))
barplot(sort(tabClass), col=zissouPalDisc, horiz=TRUE, las=1, xlim=c(0, 350))        

### Top species
### ---- top-species ----
topSpp <- table(inatThin$scientific_name)
topSpp <- sort(topSpp, decreasing=TRUE)
topSpp <- data.frame(species=names(topSpp), nbObs=topSpp[,drop=TRUE])

par(mar=c(2,13,0,1))
bp <- barplot(rev(topSpp[1:15, "nbObs"]), horiz=TRUE, las=1,
              col=zissouPal(15), names.arg="")
axis(2, labels=rev(topSpp[1:15, "species"]), at=bp, las=1, font=3, tick=FALSE,
     lty=0)

## par(mar=c(13,2,1,1))
## bp <- barplot(topSpp[1:15, "nbObs"],  
##               col=rev(zissouPal(15)), names.arg="")
## axis(1, labels=topSpp[1:15, "species"], at=bp, las=2, font=3, tick=FALSE,
##      lty=0)

### Pisaster + Strongylocentrotus map
### ---- map-pisaster-strongylo ----
pisoch <- subset(inatThin, scientific_name == "Pisaster ochraceus")
strpur <- subset(inatThin, scientific_name == "Strongylocentrotus purpuratus")

states <- map_data("world", regions=c("Canada", "Mexico", "USA"))

pisochMap <- ggplot(pisoch) + annotation_map(states, color=landCol, fill=landCol) +
    geom_point(aes(x=longitude, y=latitude), position="jitter", size=4, colour=zissouPerClass[1]) +
    coord_map(projection="mercator", xlim=c(-130, -112.5), ylim=c(25, 50)) +
    xlab("Longitude") + ylab("Latitude") +
    theme(legend.position = "none",
          panel.background = element_rect(fill = seaCol)) +
    ggtitle(expression(italic("Pisaster ochraceus")))

strpurMap <- ggplot(strpur) + annotation_map(states, color=landCol, fill=landCol) +
    geom_point(aes(x=longitude, y=latitude), position="jitter", size=4, colour=zissouPerClass[3]) +
    coord_map(projection="mercator", xlim=c(-130, -112.5), ylim=c(25, 50)) +
    xlab("Longitude") + ylab("Latitude") +
    theme(legend.position = "none",
          panel.background = element_rect(fill = seaCol)) +
    ggtitle(expression(italic("Strongylocentrotus purpuratus")))

multiplot(pisochMap, strpurMap, cols=2)

