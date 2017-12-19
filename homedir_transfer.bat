:: Transfer user data

takeown /r /a /f FILE

icacls /t FILE

xcopy %olddir% /f /s /e %newdir%

for %i in (Documents,Music,Contacts,Pictures,Video,Favorites,Links,OneDrive,Podcasts,"Saved Games") do xcopy %olddir%/%i /f /s /e %newdir%/%i