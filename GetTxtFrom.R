library(readtext)

##FUNCTION TO READ TEXT FILES AUTOMATICALLY INTO R
##inout is foldername (in double quotes); folder must be in current dir. 
# function checks if the folder exists in the current directory, if not warns user .

GetTxtFrom<- function (foldername) {
    
    wd<-setwd(Sys.getenv("API_BASE"))
    
    foldername<-as.character(foldername)
    
    directory<-sprintf("%s/%s", wd, foldername)
    
    message<-print(paste0("REQUIRED: YOUR DATA FOLDER '", foldername, "' MUST BE IN ", wd))
    
    check<- ifelse (dir.exists(foldername), 
                    print("Great! Folder is in required location!....Getting your data...."),
                    print(paste0("Error: Folder was not found in required location. Please move folder '", foldername, "' to  ", wd)))
    
    textdata<-readtext(directory)
    
    return(textdata)  
  }
