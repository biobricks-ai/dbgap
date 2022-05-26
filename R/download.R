library(purrr)
library(rvest)
library(fs)
library(tidyverse)
library(httr)
library(arrow)
library(data.table)
library(parallel)
library(tools)

# DOWNLOAD ====================================================================
options(timeout=140000) # download timeout
download_dir <- "download"
mkdir = function (dir) {
  if (!dir.exists(dir)) {  
    dir.create(dir,recursive=TRUE) 
  }
}
map(download_dir,mkdir)                                                                                                                    

##----------------- User Input location to download intermediate files
if (interactive()) {
  print("Format Example:Folder/to/File/")
  externalDriveLocation <- readline("Temporary File Storage Location:")
} else {
  cat("Temporary File Storage Location:")
  externalDriveLocation <- readLines("stdin", n = 1)
}

##----------------- Get download paths for dbgap variant association files
dbgap <- 'https://ftp.ncbi.nlm.nih.gov/dbgap/studies/'
getHref <- function(x) read_html(x) |> html_elements("a") |>html_attr("href")
getTables <- function(x) paste0(x,getHref(x), "/analyses/")
getdataTables <- function(x) paste0(x,getHref(x) |> keep(~ path_ext(.) %in% c("pdf","tsv","gz","txt")))
readHtml <- function(urlInput) {
  out <- tryCatch(
    {
      message("**Scraping Url**")
      getdataTables(urlInput)
    },
    error=function(cond) {
      message(paste0("Error scraping url:", urlInput))
      message("Original error message:")
      message(cond)
      return(NA)
    },
    finally={
      message(paste0("Scraped URL:", urlInput))
    }
  )
  return(out)
}
pathListAnalyses=getTables(dbgap) |> sapply(readHtml)|> unlist() |> tibble() |> rename_at(1, ~ "url_paths") |> filter(grepl('txt',url_paths))|>drop_na()|> mutate(file_name=basename(url_paths))


# OUTS ====================================================================

##----------------- Download dbGaP Documentation to download_dir
documentationPdfs="https://ftp.ncbi.nlm.nih.gov/dbgap/DataModels/"
dataGrouping="https://ftp.ncbi.nlm.nih.gov/dbgap/Groupings/"
tableContents="https://ftp.ncbi.nlm.nih.gov/dbgap/Analysis_Table_of_Contents.txt"
pheGeneData="https://ftp.ncbi.nlm.nih.gov/dbgap/PheGenI/PheGenIDump.20170814.txt"
docPaths=lapply(c(pheGeneData,tableContents,documentationPdfs, dataGrouping), function(x) getdataTables(x)) |> unlist()
docFileList <- function(x) dir_create('download') |> fs::path(sapply(x, basename))
docFiles=docFileList(docPaths)
walk2(docPaths, docFiles, download.file)


##----------------- Download dbGaP variant association files
checkDownload <- function(urlInput,fileInput) {
  out <- tryCatch(
    {
        download.file(urlInput,dest=fileInput)
        print(paste0("File downloaded to: ", fileInput))
    },
    error=function(cond) {
      message(paste0("Error downloading file:", urlInput))
      message("Original error message (Retrying):")
      message(cond)
      return(NA)
    },
    warning=function(cond) {
      message(paste0("URL caused a warning:", urlInput))
      message("Original warning message:")
      message(cond)
      return(NULL)
    },
    finally={
      message(paste0("Downloaded file:", urlInput))
    }
  )
  return(out)
}
download_parse_files<-function(file_path,url){
  checkDownload(url, file_path)
  tmp_file=read_tsv(file_path, comment = '#',skip_empty_rows = T)
  if (dim(tmp_file)[1]!=0){
    tmp_file$filename=basename(file_path)
  if (file.info(file_path)$size > 0){
  con <- file(file_path,"r")
  headerDesc <- readLines(con,n=6)
  dfHeader=tibble(headerDesc)
  dfHeaderInfo=dfHeader|>mutate(ColInfo=str_split_fixed(headerDesc,':\t',2)[,1],ColDesc=str_split_fixed(headerDesc,':\t',2)[,2])|>select(ColInfo, ColDesc)|>transpose()
  colnames(dfHeaderInfo)<-dfHeaderInfo[1,]
  dfHeaderInfo=dfHeaderInfo[-1,] 
  tmp_file=cbind.data.frame(tmp_file,dfHeaderInfo)
  }
  write_parquet(tmp_file, checkExt(file_path))
  file.remove(file_path)
  }
  else{
    print("File has 0 rows")
    file.remove(file_path)}
}
combineParquetDf<-function(inputFileList,outputFileName){
  tmpDf<-data.table::rbindlist(lapply(Sys.glob(inputFileList), arrow::read_parquet), fill = TRUE)
  arrow::write_parquet(tmpDf, outputFileName)
  rm(tmpDf)
}
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

urls<-pathListAnalyses$url_paths
tbls<-pathListAnalyses$file_name
files <- dir_create(paste0(externalDriveLocation,download_dir)) |> fs::path(tbls)
filePaths=tibble(urls,files,sapply(files, checkExt)) |> rename_at(3, ~ "parquet_files")
currentFiles=list.files(paste0(externalDriveLocation,'download'), full.names = TRUE)
filesToDownload=filePaths[which(filePaths$parquet_files %in% setdiff(filePaths$parquet_files, currentFiles)),]
walk2(filesToDownload$files, filesToDownload$urls, download_parse_files)

##----------------- Split list and combine variant association parquet files
file_downloads=paste0(externalDriveLocation,'download') 
combineFileList=data.frame(list.files(file_downloads,full.names = TRUE)) |> rename_at(1, ~ "parquet_files")
splitFileJoinList=split(combineFileList, rep(1:150))
combinedOutputPath=file.path(externalDriveLocation |> dir_create('combined_files'))

for( i in seq(1,length(splitFileJoinList))) {
  if(!file.exists(file.path(combinedOutputPath,paste0("dbGaP_combined_file_chunk_",i,".parquet")))){
    combineParquetDf(splitFileJoinList[[i]]$parquet_files, file.path(combinedOutputPath,paste0("dbGaP_combined_file_chunk_",i,".parquet")))
  }
  else{print(paste0("File exists:","dbGaP_combined_file_chunk_",i,".parquet"))}
}



