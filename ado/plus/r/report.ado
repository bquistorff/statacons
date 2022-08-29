/*

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
	
	DESCRIPTUIN
	==============================
	
	create PDF report and opens it up, if the execute option is specified
*/

	program define report
		version 11
		//syntax [anything] [, Export(name) Printer(name)  SETpath(str) ]
						
		********************************************************************
		*CHECKING THE REQUIRED SOFTWARE
		********************************************************************
		reportcheck		
			
		********************************************************************
		*PRINTING THE HTML LOG
		********************************************************************
		// Microsoft Windows		
		if "`c(os)'"=="Windows" {	
			if "$printer" == "wkhtmltopdf" & "$weaverMarkup" == "html" {
				shell "$setpath" 												///
				$doc_paper $doc_orientation /*$gray_scale*/  					///
				$margin_top $margin_right $margin_left $margin_bottom  			///
				$footer_font --footer-center [page] --footer-font-size 10 		///
				--no-stop-slow-scripts --javascript-delay 2000 					///
				--enable-javascript  $doc_toc --debug-javascript 				///
				"$weaverFullPath" "$pdfdoc"
			}		
		}
				
		// Macintosh
		if "`c(os)'"=="MacOSX" {		
			if "$printer" == "wkhtmltopdf" & "$weaverMarkup" == "html" {
				shell "$setpath" 												///
				$doc_paper $doc_orientation /*$gray_scale*/  						///
				$margin_top $margin_right $margin_left $margin_bottom  			///
				$footer_font --footer-center [page] --footer-font-size 10 		///
				--no-stop-slow-scripts --javascript-delay 2000 					///
				--enable-javascript  $doc_toc --debug-javascript 				///
				"$weaverFullPath" "$pdfdoc"					
			}
		}
			
		// UNIX
		if "`c(os)'"=="Unix" {
			if "$printer" == "wkhtmltopdf" & "$weaverMarkup" == "html" {
				shell "$setpath" 												///
				$doc_paper $doc_orientation /*$gray_scale*/  						///
				$margin_top $margin_right $margin_left $margin_bottom  			///
				$footer_font --footer-center [page] --footer-font-size 10 		///
				--no-stop-slow-scripts --javascript-delay 2000 					///
				--enable-javascript  $doc_toc --debug-javascript 				///
				"$weaverFullPath" "$pdfdoc"	
			}
		}

		
		********************************************************************
		*PRINTING THE LATEX LOG
		********************************************************************
		if "$weaverMarkup" == "latex" {
			
			//Check for the current working directory
			*"$weaverFullPath"
			tempfile tmp
			tempname testcanvas needle
			qui file open `testcanvas' using "`tmp'", write text append 
			*qui file open `needle' using "$htmldoc", read
			file open `needle' using "$weaverFullPath", read
			file read `needle' line
			while r(eof)==0 {
				file write `testcanvas' `"`macval(line)'"' _n  
				file read `needle' line
			}
			
			file write `testcanvas' _n "\end{document}" _n(2) 
			qui file close `needle'
			qui file close `testcanvas'
			
			
			if !missing("$setpath") {
				*shell "$setpath" "$htmldoc" "$pdfdoc" 
				qui shell "$setpath"  -jobname="$using" "`tmp'"
			}
			
			else {
				if "`c(os)'"=="Windows" {
					di as txt "{p}(WARNING: The path to $printer PDF driver is not defined...)"
					*quietly error 601
					*shell pdflatex "`tmp'" "$pdfdoc"
					*shell "C:\Program Files\MiKTeX 2.9\miktex\bin\x64\pdflatex.exe"  -jobname="$using" "`tmp'"
					shell "pdflatex.exe"  -jobname="$using" "`tmp'"
				}
				if "`c(os)'"=="MacOSX" {
					local noprint 1
					di as error "{p}{the path to $printer PDF driver was not "  ///
					"defined."
					quietly error 601
				}
				
				if "`c(os)'" == "Unix" {
					local noprint 1
					di as error "{p}{the path to $printer PDF driver was not "  ///
					"defined."
					quietly error 601 
				}
				//shell pdflatex "`tmp'" "$pdfdoc"
				
			}
		}
		
		
		********************************************************************
		*PRINT THE NOTIFICATION IN STATA WINDOW
		********************************************************************		
		// SEARCH FOR THE PDF
		cap quietly findfile "$pdfdoc"
		if "`r(fn)'" != "" & missing("`noprint'") {
			di as txt _newline(2)
			di as txt "| |     / /__  ____ __   _____  _____ "       
			di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
			di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
			di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' 				///
			`"{it:produced {bf:{browse `"${pdfdoc}"'}} dynamic document}"'
			
			local d : pwd
			if "`d'" != "$weaverDir" {
				di as txt _n "{p}(The PDF was created in your current working directory)"
			}
		}
		
		//IF THERE IS NO PDF, SEARCH FOR THE HTML DOCUMENT
		if "`r(fn)'" == "" {
			cap quietly findfile "$htmldoc"
			if "`r(fn)'" != "" {
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${htmldoc}"'}} dynamic document}"'
				
				if !missing("$setpath") {
					local further "PDF was not generated. Specify the file " 	///
					"path to $printer on your machine..."
				}
				else di as error "{p}PDF was not generated. Probably, due" 	///
				"to a problem in accessing the $printer driver. " 
			}
		}
				
		********************************************************************
		* OPEN THE PDF DOCUMENT
		********************************************************************
		//if !missing("$weaverexecute") {
		//	cap quietly findfile "$pdfdoc" 
		//    if "`r(fn)'" != "" {
		// 		if "`c(os)'"=="Windows" {
		// 			winexec explorer "$pdfdoc"
		// 		}
		 		
		// 		if "`c(os)'"=="MacOSX" {
		// 			shell open "$pdfdoc"
		// 		}
		 		
		// 		if "`c(os)'"=="Unix" {
		// 			shell xdg-open "$pdfdoc"
		// 		}	
		// 	}
		//}
				
end	
	
	
	
	
	
	
