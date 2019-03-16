

location <- '.'

outfile <- 'DACO_all.csv'

library(openxlsx)
library(tidyr)

dsingle <- openxlsx::read.xlsx(file.path(location, files[4]), startRow=2)

 



d1 <- sapply(files, function(x) {
  
  
  d <- openxlsx::read.xlsx(file.path(location, x), startRow=2)
  col <- colnames(d)
  
  if(any(duplicated(col))){
    colDup <- paste0(col[duplicated(col)],2)
    colnames(d)[duplicated(col)]<- colDup
  }
  return(d)
  })



d_colnames <- sapply(d1, function(x) colnames(x))
allCol <- Reduce(function(x,y) union(x,y)   , d_colnames )

d2 <- lapply(d, function(x) {
  x2 <- x
  col <- colnames(x2)

  
  dcol <- setdiff(allCol, col)
  x2[dcol] <- NA
  print(col)
  
  return(x2)
} )


res <- do.call(rbind, d2)
write.table(res, file = file.path(location, outfile), quote = TRUE, sep =';')
