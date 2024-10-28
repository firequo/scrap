Use to convert copypasted tables (in the form of .txt files) to csvs.
instructions:
download the executable and place it in a directory
copy a table from a report
(windows)
paste the table into notepad
save as a txt
(mac)
open text edit
click format -> use plain text
paste the table
save as a txt

DO NOT USE GOOGLE DOCS AND SAVE AS TXT, it strips new lines for some reason and everything will be on one line

move the txt file to the same directory as the executable
open terminal or powershell to the directory you placed the executable into 
run the following command
./scrap_win.exe path/to/your_txt_name.txt (on windows)
./scrap_mac path/to/your_txt_name.txt (on mac)
if in same dir
./scrap_win.exe your_txt_name.txt (on windows)
./scrap_mac your_txt_name.txt (on mac)
if you have multiple txt files in the directory you can list them one by one or do
./scrap *.txt
this will cover all txts in the current directory
the program will make one new csv per text file
