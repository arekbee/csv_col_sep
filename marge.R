library(openxlsx)
library(tidyr)
library(dplyr)
library(stringr)

options("encoding" = "UTF-8")
options(stringAsFactor=FALSE)

files <- c(
  "DACO Brake Discs Drums v.2019 (123).xlsx",
  "DACO Brake Pads v.2019 (123).xlsx",
  #"DACO Coil Sprrings v.2019 (123).xlsx",
  #"DACO Gas Springs v.2019 (123).xlsx",
  #"DACO Protection Kits v.2019 (123).xlsx",
  #"DACO Shock Absorbers v.2019 (123).xlsx",
  "DACO Suspension v.2019 (123).xlsx"
)

location <- '.'

brand.enum <- c("Acura","Alfa","Aston Martin","Audi","Austin","Bentley","BMW","Buick","Cadillac","Chevrolet","Chrysler","Citroen","Dacia","Daewoo","Daihatsu","Dodge","Eagle","Ferrari","Fiat","Ford","FS","FSM","FSO","FSR","Gaz","GMC","Honda","Hummer","Hyundai","Infiniti","Innocenti","Intrall","Isuzu","Iveco","Jaguar","Jeep","JMC","Kia","Lada","Lamborghini","Lancia","Land","LDV","Lexus","Lincoln","Lotus","Maruti","Maserati","Mazda","Mercedes-Benz", "MERCEDES","Mercury","MG","MINI","Mitsubishi", "MISTSUBISHI","Moskwicz","Nissan","Oldsmobile","Oltcit","Opel","Peugeot","Plymouth","Pontiac","Porsche","Renault","Rolls-Royce","Rover","Saab","Saturn","Scion","SEAT","Skoda","Smart","Ssangyong","Subaru","Suzuki","Talbot","Tata","Toyota","Trabant","Uaz","VW", "Volvo","Wartburg","Yugo")
brandregex <- regex(paste0('(',paste( brand.enum, collapse='|'), ')' ), ignore_case = TRUE)


getModelName <- function(text, brandName, idx=1) { 
  pos.start <- -1
  for(appearIdx in 1:idx) {
    text = substring(text, pos.start+1)
    gstart <- regexpr(brandName, text, ignore.case = TRUE)
    pos.start <- gstart[1]
    
  }
  rightModels <- trimws(substring(text, pos.start + nchar(brandName)))
  gend <- regexpr(brandregex, rightModels, ignore.case = TRUE)
  pos.end <- gend[1]
  if(pos.end >0 ){
    rightModels <- trimws(substring(rightModels, 1, pos.end-1  ))
  }

  return(rightModels)
}

getModelNameVec <- Vectorize(getModelName)

str_extract_all_or_empty <- function(text, pattern) {
  pattern = regex(pattern, ignore_case = TRUE)
  extracted <- str_extract_all(text, pattern  )
  count <- length(unlist(extracted))
  if(length(unlist(extracted)) == 0){
    return(list(c("")))
  }
  extracted <- extracted[[1]]
  ret <- c()
  apperaList = c()
  for (ext in extracted)
  {
        apper <- length( apperaList[ext == apperaList])
        ret <- c(ret, paste(ext, apper+1)) 
        apperaList <- c(apperaList, ext)
  }
  return (list(ret))
}
str_extract_all_or_emptyVec <- Vectorize(str_extract_all_or_empty)


addModelFromVersion <- function(models) {
  tos <- c("Peugeot 206, Peugeot 306", 'Golf II, Golf III', 'Peugeot 106 I, 106 II', 'Clio I, Clio II', 'Corsa A, Corsa B', 'VW T4','Seat Ibiza, Seat Cordoba', 'GOLF V , GOLF VI' , 'Renault', '10 Opel Vectra B 95', 'BMW 5 F10, BMW 5 F18', '1.1CRDI', 'MERCEDES', 'Peugeot 207, Peugeot 307, Peugeot 308', 'Peugeot 206, Peugeot Partner, Citroen Berlingo, Citroen Xsara',
           "Renault Laguna 95-01", "282x18 VW T4 15", '280x24 VW T4 90-03', '266x13 Peugeot Partner 96', '240x24,2 Ford Sierra 82', '260x12 Audi A3 03-, VW Golf V 03-, Skoda Octavia 04-', 'Citroen', '280x12 VW T4 90', 'CHEVROLET', 'HONDA', 'LEXUS')
  names(tos) <- c("Peugeot 206,\\W?306", 'Golf II, III', 'Peugeot 106 I, II', 'Clio I, II',  'Corsa A, B', '^T4\\W',  'Seat Ibiza, Cordoba', 'GOLF V \\/VI', 'Reanult', '10 Vectra B\\s{1,4}95', '^BMW 5 \\(F10, F18\\)', '1,1CRDI', 'MERCDES', 'Peugeot 207, 307, 308', '206, Partner, Berlingo, Xsara',
                  "Laguna 95-01", '282x18 T4 15', '280x24 T4 90-03', '266x13 Partner 96', '240x24,2 Sierra 82', '260x12 A3 03-, Golf V 03-, Octavia 04-', 'Citoren', '280x12 T4 90', 'Cheverlolet', 'HONCA', 'LECUS')
  return(str_replace_all(models, tos))
}

removeVonEnd <- function(models){
  return(str_replace_all(models, c("\\s*V$"="", '[\\"]'='')))
}





process <- function(filePath) {
  print(filePath)
  dsingle <- openxlsx::read.xlsx(filePath, startRow=2 )
  colnames(dsingle) <- make.unique(colnames(dsingle))

  if('Opis.ENG' %in% colnames(dsingle) ){
    dsingle$Description <- dsingle[, c("Opis.ENG")]
  }
  
  brand.detect<- str_detect(dsingle$Description,  brandregex)
  
  
  dsingle$Description <- addModelFromVersion(dsingle$Description)
  dsingle$Description <- str_remove(dsingle$Description, '\"')
  
  
  dsingle$BrandIdx <- dsingle$Description
  dsingle <- tbl_df(dsingle)  %>%
    transform(BrandIdx = str_extract_all_or_emptyVec(BrandIdx, brandregex)) %>%
    unnest(BrandIdx)
  
  dsingle <- dsingle %>% separate(BrandIdx, c("Brand", "Idx"), se=" " )
  
  wymiary.regex <- '(\\d+/)?\\d+[\\.\\,]?\\d*[xX]\\d+[\\.\\,]?\\d*'
  dsingle$Metric<- str_extract(dsingle$Description, wymiary.regex)
  
  FrontRear.enum <- c("Front", "Rear", "Left", "Right")
  FrontRear.regex <- paste0('(',paste( FrontRear.enum , collapse='|'), ')' )
  dsingle$FrontRear <- str_extract(dsingle$Description, FrontRear.regex)
  
  dsingle$Description <- str_remove(dsingle$Description, '"')
  
  
  dsingle <- dsingle %>% transform(modelsFromDesc= ifelse(is.na(Metric),Description, str_remove(Description, Metric)))
  dsingle$modelsFromDesc2 <- dsingle$modelsFromDesc <- as.character(dsingle$modelsFromDesc)
  for( i in 1:nrow(dsingle)){
    if(!is.na(dsingle$FrontRear[i])) {
      dsingle$modelsFromDesc2[i] <- str_remove(dsingle$modelsFromDesc[i], dsingle$FrontRear[i])
    }
  }
  
  dsingle$modelsFromDesc3 <- trimws(removeVonEnd(dsingle$modelsFromDesc2))
  
  
  dsingle2 <- dsingle %>% transform(Models=  getModelNameVec(modelsFromDesc3, Brand, Idx) )
  
  
  dsingle2 <- separate_rows(dsingle2, Models, sep=',' )
  dsingle2$Models <- trimws(dsingle2$Models)
  dsingle2 <- rename(dsingle2, Model= Models)
  dsingle2 <- dsingle2[dsingle2$Model!= '',]
  #dsingle2$modelsFromDesc <- NULL
  #dsingle2$modelsFromDesc2 <- NULL
  dsingle2 <- dsingle2 %>% transform(BrandModel = paste(Brand , Model))
  #write.table(dsingle2, file=file.path(location, infile), quote = TRUE, sep=";", row.names = FALSE)
  dsingle2$Name <- trimws(dsingle2$BrandModel)
  dsingle2$BrandModel <- NULL
  dsingle2$Active <- 1
  dsingle2$OnSale <- 1
  dsingle2$MinimalQuantity <- 1
  dsingle2$TaxrulesID <- 1
  dsingle2$WholesalepriceOnsale <- 0
  dsingle2$Price <- round(rnorm(nrow(dsingle2), mean = 10, sd=3), 2)
  if(any(dsingle2$Price < 0)){
    dsingle2[dsingle2$Price < 0, 'Price'] <- 0.01
  }
  dsingle2$ID <- rownames(dsingle2)
  
  #dsingle2 <- dsingle2 %>% select(ID, Active, Name,Categories,  Price, TaxrulesID, WholesalepriceOnsale, OnSale, Provide)
  
  
  
  tmp <- unlist(strsplit(filePath, ".",fixed = TRUE))
  outfiles <- paste0(tmp[1], ".csv")
  dsingle2$file <- outfiles
  dsingle2$Idx <- NULL
  return(dsingle2)
}

infiles <- file.path(location, files)
res <- lapply(infiles, function(x) process(x) )



lapply(res, function(x) {
  fileName <- x$file[1]
  print(fileName)
  write.table(x, file=fileName, quote = TRUE, sep=";", row.names = FALSE )
})