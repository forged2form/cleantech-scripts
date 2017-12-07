:: Transfer user data

takeown

icacls

xcopy %olddir% /f /s /e %newdir%

for %i in (Documents,Music,Contacts,Pictures,Video,Favorites,Links,OneDrive,Podcasts,"Saved Games") do xcopy %olddir%/%i /f /s /e %newdir%/%i