# PSX-Github
 
To compile the psx example, follow the setup found here: https://github.com/ABelliqueux/nolibgs_hello_worlds  

For this, copy and paste the following command into command prompt:  
powershell -c "& { iwr https://raw.githubusercontent.com/grumpycoders/pcsx-redux/main/mips.ps1 | iex }"  
Then do the next command:  
mips install 11.2.0  
Now open the make file and change NOLIBGSDIR to match the directory you have it at  
In command prompt, go to the PSX folder and run this last command  
make  
After this, you should have a .ps-exe file in your build folder.   
Some emulators expect this to be a disc image, so use the following command to generate one  
tools\mkpsxiso disc.xml -y  
