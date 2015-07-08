/*
**  Program that creates a whimsical radio station which plays back a song to you based on the following (random) logic:
**  1) Pick a random verb from the most popular article on New York Times at the moment
**  2) Find a random Twitter user that just tweeted a tweet containing that verb
**  3) Match the user's amount of either followers, statuses, faviourited tweets or people the user is following to the height of the top 500 tallest mountains in the world
**  4) Find the flag of the country where the mountain is located
**  5) Extract the dominant color (RGB) of the flag and match that to color names of the web
**  6) Look for a song on SoundCloud which is similar to the color name
**  7) Extract listening statistic of the specific song from Last.fm
**  8) Play the song and show the user all the above information in a couple of sentences

**  API dependencies: Temboo (New York Times, Twitter), Kimono Labs (Wikipedia), GeoNames, SoundCloud, Last.fm 
**  Developed in 24 hours during Secret Life of Objects course week 1 of the IDP at CIID 2015. 
**  by Michael-Owen Liston, Vihanga Gore and Håvard Lundberg 
**  Project details: http://ciid.dk/education/portfolio/idp15/courses/secret-life-of-objects/random-logic-radio/
*/

import de.voidplus.soundcloud.*;
import ddf.minim.*;
import com.temboo.core.*;
import com.temboo.Library.NYTimes.MostPopular.*;
import com.temboo.Library.Twitter.Search.*;
import com.temboo.Library.Flickr.Photos.*; // Not in use, but included as reference
import java.net.URLEncoder;
import java.net.URLDecoder;
import rita.*;
import processing.core.PImage;

PFont myFont;

// Rita
RiString rs;
String[] myVerbs = new String[0];

Minim minim;
AudioPlayer player;

String abst, type, title, byline, source, url, section, column, adx_keywords; 
int assetId;
boolean step1, step2, step3, step4, step5, step6 = false;
boolean trackPlayed = false;
boolean runIt, showInfo = false;

int twitterStatusesCount, twitterFollowersCount, twitterFriendsCount, twitterFavouritesCount;
String twitterDescription, twitterScreenName;
int twitterRange = 10; //Range (+/-) for comparing twitter stats and mountain heights 
boolean twitterStatusesCountMatch, twitterFollowersCountMatch, twitterFriendsCountMatch, twitterFavouritesCountMatch = false;

String mountainName, mountainLocation;

String countryCode, countryName, countryFlag;

PImage img;
int r;
int g;
int b;
String colorName;
int colorRange = 20; // Range (+/-) for comparing rgb color of a picture and color chart lookup
Table table;

String string1, string2, string3;

ArrayList<Track> trackResults;

String sourceName = "";

// Last.fm
int lastFmtotalResults = 0;
int lastFmListeners = 0;
ArrayList<String> lastFmUsers = new ArrayList<String>();
ArrayList<lastFmUser> lastFmDemographics = new ArrayList<lastFmUser>();
double sumAge, averageAge = 0;
int sumMale, sumFemale = 0;

// Create a session using your Temboo account application details - change these
TembooSession session = new TembooSession("username", "appName", "key");
SoundCloud soundcloud = new SoundCloud("key", "key");

void setup() {
  size(1200, 900);
  background(170, 240, 209);

  myFont = loadFont("MuseoSlab-700-48.vlw");
  textFont(myFont, 48);
}

// Fetch data. This function is run as a thread to be able to feed back data to the draw() function
void executeQueries() {
  runGetMostViewedChoreo();
  if (step1) runLatestTweetChoreo();
  if (step2) runGetMountain();
  if (step3) runGetCountryCode();
  if (step4) runGetSoundcloud();
  if (step5) runGetLastfm();
}

// Function to get the verbs from a specific sentence
void parseText(String incoming) {
  rs = new RiString(incoming);
  rs.analyze();

  int wc = rs.wordCount();

  for (int i=0; i < wc; i++) {
    String pos = rs.posAt(i);
    //println("pos: "+pos);

    if (pos.startsWith("v")) {
      myVerbs = append(myVerbs, rs.wordAt(i));
    }
  }
}

// Get most popular article from NYTimes and find the verbs in it's abstract
void runGetMostViewedChoreo() {
  step1 = false;
  sourceName = "New York Times";
  // Create the Choreo object using your Temboo session
  GetMostViewed getMostViewedChoreo = new GetMostViewed(session);

  // Set inputs
  getMostViewedChoreo.setSection("all-sections");
  getMostViewedChoreo.setAPIKey("your-key");
  getMostViewedChoreo.setResponseFormat("json");
  getMostViewedChoreo.setTimePeriod("1");

  // Run the Choreo and store the results
  GetMostViewedResultSet getMostViewedResults = getMostViewedChoreo.run();

  JSONObject json = JSONObject.parse(getMostViewedResults.getResponse());
  JSONArray results = json.getJSONArray("results");
  JSONObject topResult =  results.getJSONObject(0);

  abst = topResult.getString("abstract");
  byline = topResult.getString("byline");

  parseText(abst);
  string1 = myVerbs[(int) random(myVerbs.length)];
  println("NYTimes: ", string1);
  step1 = true;
}

// Get recent tweet based on a certain word
void runLatestTweetChoreo() {
  step2 = false;
  sourceName = "Twitter";
  // Create the Choreo object using your Temboo session
  LatestTweet latestTweetChoreo = new LatestTweet(session);

  // Set inputs
  latestTweetChoreo.setAccessToken("your-token");
  latestTweetChoreo.setQuery(string1);
  latestTweetChoreo.setAccessTokenSecret("your-secret-token");
  latestTweetChoreo.setConsumerSecret("your-secret");
  latestTweetChoreo.setConsumerKey("your-key");
  latestTweetChoreo.setResultType("recent");

  // Run the Choreo and store the results
  LatestTweetResultSet latestTweetResults = latestTweetChoreo.run();

  JSONObject json1 = JSONObject.parse(latestTweetResults.getResponse());
  JSONArray statuses = json1.getJSONArray("statuses");
  JSONObject s = statuses.getJSONObject(0);
  JSONObject user = s.getJSONObject("user");
  String location = user.getString("location");

  twitterStatusesCount = user.getInt("statuses_count");
  twitterFollowersCount = user.getInt("followers_count");
  twitterFriendsCount = user.getInt("friends_count");
  twitterFavouritesCount = user.getInt("favourites_count");
  twitterDescription = user.getString("description");
  twitterScreenName = user.getString("screen_name"); 

  println("Twitter: ", location, twitterStatusesCount, twitterFollowersCount, twitterFriendsCount, twitterFavouritesCount);
  step2 = true;
}

// Get mountain based on statistics from twitter
void runGetMountain() {
  step3 = false;
  sourceName = "Wikipedia";
  boolean match = false;
  JSONObject json = loadJSONObject("https://www.kimonolabs.com/api/7fkc8e2w?&apikey=6fNA31wCgAbfAVVHFgl0YGCvNEzNwpGx&kimmodify=1");
  JSONObject results = json.getJSONObject("results");
  JSONArray collection1 = results.getJSONArray("collection1");

  twitterStatusesCountMatch = false;
  twitterFollowersCountMatch= false;
  twitterFriendsCountMatch = false;
  twitterFavouritesCountMatch = false;
  mountainName = "";
  mountainLocation = "";

  for (int i=0; i<collection1.size (); i++) {
    JSONObject mountain = collection1.getJSONObject(i);
    String elevation = mountain.getString("mountainElevation");
    float elv = float(elevation);  
    if (elv == (float)twitterFollowersCount && !match || elv > (float)twitterFollowersCount - twitterRange && elv < (float)twitterFollowersCount + twitterRange && !match) {
      mountainName = mountain.getJSONObject("mountain").getString("text");
      mountainLocation = mountain.getJSONObject("mountainRange").getString("text");
      match = true;    
      twitterFollowersCountMatch = true;
    } else if (elv == (float)twitterStatusesCount && !match || elv > (float)twitterStatusesCount - twitterRange && elv < (float)twitterStatusesCount + twitterRange && !match) {
      mountainName = mountain.getJSONObject("mountain").getString("text");
      mountainLocation = mountain.getJSONObject("mountainRange").getString("text");
      match = true;          
      twitterStatusesCountMatch = true;
    } else if (elv == (float)twitterFriendsCount && !match || elv > (float)twitterFriendsCount - twitterRange && elv < (float)twitterFriendsCount + twitterRange && !match) {
      mountainName = mountain.getJSONObject("mountain").getString("text");
      mountainLocation = mountain.getJSONObject("mountainRange").getString("text");
      match = true;                
      twitterFriendsCountMatch = true;
    } else if (elv == (float)twitterFavouritesCount && !match || elv > (float)twitterFavouritesCount - twitterRange && elv < (float)twitterFavouritesCount + twitterRange && !match) {
      mountainName = mountain.getJSONObject("mountain").getString("text");
      mountainLocation = mountain.getJSONObject("mountainRange").getString("text");
      match = true;        
      twitterFavouritesCountMatch = true;
    }
  }

  println("Wiki: ", mountainName, mountainLocation);
  step3 = true;
}

// Get country based on a mountain name or mountain location and extract the main color from the country flag
void runGetCountryCode() {
  step4 = false;
  sourceName = "GeoNames";
  mountainName = URLEncoder.encode(mountainName); 
  mountainLocation = URLEncoder.encode(mountainLocation); 

  JSONObject json2 = loadJSONObject("http://api.geonames.org/searchJSON?q="+mountainName+"&username=YOUR-USERNAME&maxRows=1");
  int searchCount = json2.getInt("totalResultsCount");

  if (searchCount > 0) {
    JSONArray results = json2.getJSONArray("geonames");
    JSONObject country = results.getJSONObject(0);
    countryCode = country.getString("countryCode");
    countryName = country.getString("countryName");
    countryFlag = "http://www.geonames.org/flags/x/" + countryCode + ".gif";
  } else {
    json2 = loadJSONObject("http://api.geonames.org/searchJSON?q="+mountainLocation+"&username=YOUR-USERNAME&maxRows=1");
    searchCount = json2.getInt("totalResultsCount");
    if (searchCount > 0) {
      JSONArray results = json2.getJSONArray("geonames");
      JSONObject country = results.getJSONObject(0);
      countryCode = country.getString("countryCode");
      countryName = country.getString("countryName");
      countryFlag = "http://www.geonames.org/flags/x/" + countryCode.toLowerCase() + ".gif";
    }
  }

  img = loadImage(countryFlag.toLowerCase(), "gif");
  extractColorFromImageRGB();
  getCSV();  

  println("GeoNames: " + colorName, countryName);

  step4 = true;
}

// Get song from soundcloud based on colorName
void runGetSoundcloud() {
  step5 = false;
  sourceName = "SoundCloud";
  trackResults = soundcloud.findTrack(colorName);
  if (trackResults!=null && trackPlayed == false) {
    //println("Tracks: "+trackResults.size());

    minim = new Minim(this);  
    int ran = (int)random(trackResults.size()-trackResults.size()/2);
    //int ran = 0; // Use this to get the top song instead of random
    string3 = trackResults.get(ran).getTitle();
    player = minim.loadFile(trackResults.get(ran).getStreamUrl());
  } 
  println("SoundCloud: " + string3);
  step5 = true;
}

// Get listening details about the song from Last.fm. Generate some demographic statistics
void runGetLastfm() {
  step6 = false;
  sourceName = "Last.fm";  

  if (string3 != "null") {
    println("Last.fm searching for: ", string3); 
    JSONObject json = loadJSONObject("http://ws.audioscrobbler.com/2.0/?method=track.search&track="+URLEncoder.encode(string3)+"&api_key=YOUR-KEY&format=json");
    JSONObject results = json.getJSONObject("results");
    lastFmtotalResults = results.getInt("opensearch:totalResults");
    if (lastFmtotalResults > 0) {
      JSONObject trackmatches = results.getJSONObject("trackmatches");
      //println(trackmatches);
      JSONArray track = trackmatches.getJSONArray("track"); // Gives an error when only one match
      JSONObject track1 = track.getJSONObject(0); 
      lastFmListeners = track1.getInt("listeners");
      String name = track1.getString("name");
      String artist = track1.getString("artist");
      //println(name, artist, listeners);  

      JSONObject json2 = loadJSONObject("http://ws.audioscrobbler.com/2.0/?method=track.gettopfans&artist="+URLEncoder.encode(artist)+"&track="+URLEncoder.encode(name)+"&api_key=YOUR-KEY&format=json");
      JSONObject topfans = json2.getJSONObject("topfans");
      JSONArray users = topfans.getJSONArray("user");

      for (int i = 0; i < users.size (); i++) {
        JSONObject user = users.getJSONObject(i);
        String userName = user.getString("name");
        lastFmUsers.add(userName);
      }
    }

    if (lastFmUsers.size() > 0) {
      for (int i = 0; i < lastFmUsers.size (); i++) {
        String lastFmUser = lastFmUsers.get(i);
        JSONObject jsonUser = loadJSONObject("http://ws.audioscrobbler.com/2.0/?method=user.getinfo&user="+URLEncoder.encode(lastFmUser)+"&api_key=YOUR-KEY&format=json");
        JSONObject userDetails = jsonUser.getJSONObject("user");
        String lastFmRealName = userDetails.getString("realname");
        String lastFmCountry = userDetails.getString("country");
        String lastFmAge = userDetails.getString("age");
        String lastFmGender = userDetails.getString("gender");
        int lastFmPlaycount = userDetails.getInt("playcount");
        int lastFmPlaylists = userDetails.getInt("playlists");
        if (lastFmAge.equals("")) lastFmAge = "0";
        lastFmDemographics.add(new lastFmUser(lastFmUser, lastFmRealName, lastFmCountry, Integer.parseInt(lastFmAge), lastFmGender, lastFmPlaycount, lastFmPlaylists));
      }
    }
    println("Size of Last.fm user DB: ", lastFmDemographics.size());
    if (lastFmDemographics.size() > 0) {
      int wrongAge = 0;
      for (int i = 0; i < lastFmDemographics.size (); i++) {

        if (lastFmDemographics.get(i).age == 0) wrongAge++;
        sumAge += lastFmDemographics.get(i).age;
        if (lastFmDemographics.get(i).gender.equals("m")) sumMale++;
        if (lastFmDemographics.get(i).gender.equals("f")) sumFemale++;
      }
      averageAge = sumAge / (lastFmDemographics.size() - wrongAge);
    }
  }
  println(averageAge, sumMale, sumFemale);
  step6 = true;
}

// Show 
void draw() {
  background(170, 240, 209);  
  textFont(myFont, 48); 

  if (!showInfo) text("Press [enter] to fetch data", 70, 70, width-width/7, height-height/7);
  if (!step6 && showInfo) text("Fetching data from: " + sourceName, 70, 70, width-width/7, height-height/7);

  if (runIt) {
    String sentence = "A article written ";
    if (step1) {
      sentence = sentence +fixString(byline.toLowerCase()) + " in the New York Times uses the verb " + fixString(string1);
    }
    if (step2) { 
      sentence = sentence + " which |@" +twitterScreenName + " just mentioned in a tweet. This user ";
      if (twitterStatusesCountMatch) {
        sentence = sentence + "has as many status updates as the height of ";
      } else if (twitterFollowersCountMatch) {
        sentence = sentence + "has as many followers as the height of ";
      } else if (twitterFriendsCountMatch) {
        sentence = sentence + "follows as many people as the height of ";
      } else if (twitterFavouritesCountMatch) {
        sentence = sentence + "has as many favourited tweets as the height of ";
      }
    }
    if (step3) sentence = sentence + fixString(URLDecoder.decode(mountainName)) + ". ";
    if (step4) sentence = sentence + "This mountain is located in " + fixString(countryName) + " where the average color of the flag is *" +colorName + ". ";
    
    if (step6) {
      if(trackResults!=null && lastFmtotalResults > 0) {
        sentence = sentence + "A song with |" + lastFmListeners + " listeners on last.fm reminds me of that color:";
      } else if(trackResults!=null) {
        sentence = sentence + "That color reminds me of a song:";
      }
      
      String[] t = split(sentence, " "); 
      String word = "";
      int wordX = 70;
      int wordY = 70;
      int yIncrease = 0;
      boolean changeFill = false;
      for (int i = 0; i < t.length; i++) {
        word = t[i];
        char c = word.charAt(0);
        if (str(c).equals("|")) {
          fill(0); 
          word = word.substring(1, word.length());
          changeFill = true;
        } else if (str(c).equals("*")) {
          fill(r, g, b);
          word = word.substring(1, word.length());
          changeFill = true;
        } else {
          fill(255);
        }

        text(word, wordX, wordY, width-width/7, height-height/7);

        wordX += textWidth(word);
        wordX += textWidth(" ");    
        yIncrease = wordX;

        if (yIncrease >= 900) {
          wordY = wordY + 60;
          wordX = 70;
          yIncrease = 0;
        }
      }      

      if (trackResults!=null && trackPlayed == false) {
        player.play();
        trackPlayed = true;
      } 

      if (trackPlayed) {
        if (string3.length() > 40) textFont(myFont, 35);  
        if (string3.length() > 60) textFont(myFont, 25);  
        text(string3, 70, 730, width-width/8, height-height/8);

        stroke(255);
        for (int i = 0; i < player.bufferSize () - 1; i++)
        {
          float x1 = map( i, 0, player.bufferSize(), 0, width );
          float x2 = map( i+1, 0, player.bufferSize(), 0, width );
          line( x1, height-height/4 + player.left.get(i)*50, x2, height-height/4 + player.left.get(i+1)*50 );
          line( x1, height-height/11 + player.right.get(i)*50, x2, height-height/11 + player.right.get(i+1)*50 );
        }    
        noStroke();
      }

      String mainGender = "";
      if (lastFmDemographics.size() > 0) {
        if (sumMale > sumFemale) {
          mainGender = "male";
        } else {
          mainGender = "female";
        }
      }
      textFont(myFont, 25);  
      text("The average listener to this song is " + (int) averageAge + " years old and " + mainGender + ".", 70, 850, width-width/8, height-height/8);
      minim = new Minim(this);
    }
  }
}

// Stop minim player
void stopMinim() {
  if (trackResults!=null)
    player.close();
  minim.stop();
}

// Use enter to start and end the program
void keyPressed() {
  if (key == ENTER) {
    if (!runIt) {
      showInfo = true;
      thread("executeQueries");
      runIt = true;
    } else {
      showInfo = false;
      runIt = false;
      step1 = false;
      step2 = false;
      step3 = false;
      step4 = false;
      step5 = false;
      step6 = false;
      trackPlayed = false;
      string1 = "";
      string2 = "";
      string3 = "";
      stopMinim();
    }
  }

  if (key == TAB) {
    if (player.isPlaying()) {
      player.pause();
    } else {
      player.play();
    }
  }

  if (key == BACKSPACE) {
    if (player.isPlaying()) {
      player.rewind();
    }
  }
}

// Do a lookup on color names based on a RGB value. Limited amount of color names, but works okay.
void getCSV() {
  int csvR, csvG, csvB;
  String csvColor;
  table = loadTable("rgb2.csv", "header");
  boolean match = false; // take the first matching value we find.
  colorName = "this";

  for (TableRow row : table.rows ()) {
    csvR = row.getInt("R");
    csvG = row.getInt("G");
    csvB = row.getInt("B");
    csvColor = row.getString("Name");
    if (r == csvR && g == csvG && b == csvB && !match) {
      colorName = csvColor;
      match = true;
    } else if (r > csvR-colorRange && r < csvR+colorRange && g > csvG-colorRange && g < csvG+colorRange && b > csvB-colorRange && b < csvB+colorRange && !match) {
      colorName = csvColor;
      match = true;
    }
  }
}

// Get the dominant RGB of a picure
void extractColorFromImageRGB() {
  img.loadPixels();
  int numberOfPixels = img.pixels.length;
  float totalRed = 0f;
  float totalGreen = 0f;
  float totalBlue = 0f;

  for (int i = 0; i < numberOfPixels; i++) {
    int pixel = img.pixels[i];
    totalRed += red(pixel);
    totalGreen += green(pixel);
    totalBlue += blue(pixel);
  }

  // Set the vars for displaying the color.
  r = (int) totalRed / numberOfPixels;
  g = (int) totalGreen / numberOfPixels;
  b = (int) totalBlue / numberOfPixels;
}

// Hack to be able to set custom color to certain words
String fixString(String string) {
  String[] s = split(string, " ");
  for (int i = 0; i < s.length; i++) {
    s[i] = "|"+s[i];
  }
  String fixedString = join(s, " "); 
  return fixedString;
}


// Flickr. Not in use here, but included for future reference
void runSearchPhotosChoreo() {
  sourceName = "Flickr";
  // Create the Choreo object using your Temboo session
  SearchPhotos searchPhotosChoreo = new SearchPhotos(session);

  // Set credential
  searchPhotosChoreo.setCredential("Flicrk");
  searchPhotosChoreo.setAPIKey("your-key");
  searchPhotosChoreo.setText(countryName); 
  searchPhotosChoreo.setAccuracy(3); 
  searchPhotosChoreo.setPerPage(10);

  // Run the Choreo and store the results
  SearchPhotosResultSet searchPhotosResults = searchPhotosChoreo.run();

  JSONObject json = JSONObject.parse(searchPhotosResults.getResponse());
  JSONObject photos = json.getJSONObject("photos");
  JSONArray s = photos.getJSONArray("photo");
  JSONObject photo = s.getJSONObject((int)random(10));

  String url = URLDecoder.decode(photo.getString("url_m"));  

  img = loadImage(url, "gif");
}

