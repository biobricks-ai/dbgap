library(purrr)
library(rvest)
library(fs)
library(tidyverse)
library(httr)
library(arrow)
library(data.table)
library(parallel)
library(tools)

##----------------- Copy combined parquet variant association files to data/ folder
data_dir='brick'
download_dir <- "download"
mkdir = function (dir) {                                                                                                               
  if (!dir.exists(dir)) {                                                                                                              
    dir.create(dir,recursive=TRUE)                                                                                                     
  }                                                                                                                                    
}
map(data_dir,mkdir) 
checkExt<-function(x) {if(file_ext(x)=='gz'){
  tmpFile=sub("txt.gz", "parquet", x)
}
  else if(file_ext(x)=='tsv'){
    tmpFile=sub("tsv", "parquet", x)
  }
  else {
    tmpFile=sub("txt", "parquet", x)
  }
  return(tmpFile)
}

tmpdirPath <- tempdir()
combinedOutputPath <- dir_create(tmpdirPath, 'combined_files')

diffDataFiles=setdiff(list.files(combinedOutputPath),list.files(data_dir))
if(length(diffDataFiles)>0){
  arrow::copy_files(combinedOutputPath,data_dir)
}

##----------------- Process txt/tsv data overview files into parquet files in data
sapply(list.files(file.path(download_dir),pattern='pdf', full.names = TRUE), function(x) fs::file_move(x, file.path(data_dir,basename(x))))
process_dbGaP<-function(filename){
  grep(list.files(file.path(download_dir)),pattern='pdf', invert=TRUE, value=TRUE)|>
    map(function(filename) {
      df <- vroom::vroom(file.path(download_dir,filename),'\t')
      arrow::write_parquet(df,file.path(data_dir,paste0(basename(checkExt(filename)))))
    })
}
process_dbGaP()

