# RandomLogicRadio (rlr)
Processing sketch that creates a whimsical radio station which plays back a song to you based on (random) logic. 
Developed in 24 hours during Secret Life of Objects course week 1 of the IDP at CIID 2015.
More info: http://ciid.dk/education/portfolio/idp15/courses/secret-life-of-objects/projects/random-logic-radio/

## Running demo
![ScreenShot](/data/main.gif)

## Logic
1. Pick a random verb from the most popular article on New York Times at the moment
2. Find a random Twitter user that just tweeted a tweet containing that verb
3. Match the user's amount of either followers, statuses, faviourited tweets or people the user is following to the height of the top 500 tallest mountains in the world
4. Find the flag of the country where the mountain is located
5. Extract the dominant color (RGB) of the flag and match that to color names of the web
6. Look for a song on SoundCloud which is similar to the color name
7. Extract listening statistic of the specific song from Last.fm
8. Play the song and show the user all the above information in a couple of sentences

## APIs used
- New York Times (Temboo)
- Twitter (Temboo)
- Wikipedia (Kimono Labs)
- GeoNames
- SoundCloud
- Last.fm
