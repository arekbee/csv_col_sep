

location <- '.'
infile <- 'Brake_Discs_Drums.csv'

outfile <- 'DACO_all.csv'

library(openxlsx)
library(tidyr)
library(dplyr)
library(stringr)

#dsingle <- openxlsx::read.xlsx(file.path(location, infile), startRow=2)
dsingle <- read.csv(file.path(location, infile), sep=":", skip=2, check.names=FALSE, stringsAsFactors = FALSE )
dsingle <- dsingle[,c(2, 8)]

brand.enum <- c('ALFA', 'AUDI', 'BMW', 'Fiat', 'Daewoo')

brand.enum <- c("Acura","Alfa","Aston Martin","Audi","Austin","Avia","Bentley","BMW","Buick","Cadillac","Chevrolet","Chrysler","Citroen","Dacia","Daewoo","Daihatsu","Dodge","Eagle","Ferrari","Fiat","Ford","FS Lublin","FSM","FSO","FSR","Gaz","GMC","Honda","Hummer","Hyundai","Infiniti","Innocenti","Intrall","Isuzu","Iveco","Jaguar","Jeep","JMC","Kia","Lada","Lamborghini","Lancia","Land Rover","LDV","Lexus","Lincoln","Lotus","LTI","Maruti","Maserati","Mazda","Mercedes-Benz","Mercury","MG","MINI","Mitsubishi","Moskwicz","Nissan","Oldsmobile","Oltcit","Opel","Peugeot","Plymouth","Pontiac","Porsche","Renault","Rolls-Royce","Rover","Saab","Saturn","Scion","SEAT","Skoda","Smart","Ssangyong","Subaru","Suzuki","Talbot","Tata","Toyota","Trabant","Uaz","Volkswagen","Volvo","Wartburg","Yugo")


brandregex <- regex(paste0('(',paste( brand.enum, collapse='|'), ')' ), ignore_case = TRUE)
brand.detect<- str_detect(dsingle$Description,  brandregex)
dsingle$brand <-  str_extract(dsingle$Description, brandregex)

dsingle$Brand <- dsingle$Description

tidyr::separate_rows(dsingle, Description, sep = brandregex)
              
wymiary.regex <- '(\\d+/)?\\d+[\\.\\,]?\\d*[xX]\\d+[\\.\\,]?\\d*'
dsingle$metric<- str_extract(dsingle$Description, wymiary.regex)

frontRear.enum <- c("Front", "Rear", "Left", "Right")
frontRear.regex <- paste0('(',paste( frontRear.enum , collapse='|'), ')' )
dsingle$frontRear <- str_extract(dsingle$Description, frontRear.regex)






dsingle.brandFirst <- dsingle[brandFirst, ]

dsingle.metricFirst <- dsingle[!brandFirst, ]

dsingle.metricFirst$Description


#  (?<brand>(ALFA|AUDI))\W(?<model>[A-Z0-9a-z]*\W\d+-\W)+

str_match(dsingle.brandFirst$Description, "((AUDI)\w)(\,)?")

str_extract(dsingle.brandFirst$Description[1], "(?<brand>(ALFA|AUDI))")

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
