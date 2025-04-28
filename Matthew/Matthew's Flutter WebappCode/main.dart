import 'dart:async'; //imports timers
import 'dart:collection';
//import 'dart:ffi';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart'; //this package is used for authentication linkup
import 'package:firebase_database/firebase_database.dart';//this package is used to connect to the firebase database.
import 'package:flutter/material.dart';
//import 'package:animated_text_kit/animated_text_kit.dart';
//import 'package:firebase_database/ui/firebase_animated_list.dart';
//These are firebase imports as specified by Firebase website
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:fl_chart/fl_chart.dart'; //imports charts


import 'package:flutter_application_2/theGlobals.dart';//this is the file of global variables

import 'package:intl/intl.dart';//this represents the package to be used



void main() async{ //async is a tool to utilize the await function, was utilized here to ensure await function properly works. This is done in main to ensure connection before other stuff occurrs.

  //The following four lines have been taken by Firebase website. These are used to ensure syncing/connectivity capabilites with Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
//there may be a const before MyApp, will see
  runApp( MyApp());
}


//These were test variables made in the app development process, these may be deleted later, will see.
String name = 'Mammoth';
int num =1;
double myNum=6.7;
List<String> myList=<String>['1','2'];
List<int> newList = <int>[1,2];
Map<String, String> theMap = {'Hello': 'there'};



class MyApp extends StatelessWidget {//this represents the instantiation of the App, and its contents.
  //there maybe a const before MyApp, will see

  const MyApp({super.key}); //constructor, instantiating the myApp class. key is part of the constructor.


  //You should use the navigation flutter library, and look into other flutter libraries as well.
  //You can use normal authentication and google authentication.

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {//this builds the widget
    return MaterialApp(debugShowCheckedModeBanner : false,//the debug banner on the app will not be shown
      title: 'Wastewater Treatment Process Control',//this is the title of the webpage bar.
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.light ), //this represents the background color scheme, you may need to adjust this later
      
      ),
      home:  
      
      

      SignInScreen1()//the sign in screen will be the default beginning of the webapp. This represents the starting point of the webapp.
    );
  }
}



























class MyHomePage extends StatefulWidget {//homepage does change with state, it is NOT stateless(static)
  //throughout this code, setState will be used, which is a property of stateful widgets to enable changes on the graphical user interface.
  //HomePage will be used for graph, displaying ofvalues, and other stuff
  const MyHomePage({super.key, required this.title});//homepage constructor
  

  final String title;//title is a property, this may be adjusted later
  //title="HelloMate";
  @override //override is used to create/destroy instances(will also be seen in the graph code). In this case, it creates a new instance of the home page state.
  State<MyHomePage> createState() => _MyHomePageState();//ensures state of homepage is able to change
}

class _MyHomePageState extends State<MyHomePage> with AutomaticKeepAliveClientMixin  { //The AutomaticKeepAliveClient is used to allow for the tab state to be maintained when moving to a different tab. 
//This is related to the switching of the tabs, and ensures that the proper states are maintained.
  
  


  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }



String adjustStringval2(String value2) {//this function removes ALL trailing zeroes(after the decimal place).

  /*
  if(value2!=null && double.parse(value2)==0.0) {//checks if the parameter value is a double, if it is, it will be returned as string.
    return "0";
  }
  */
  

  String returnVal2="";//this will be the new string.
  int iterator=value2.length-1;//the iterations works backwards, and value2.length-1 represents the index of the last character of value2
  while(value2[iterator]=='0') {//this loops backwards until a string character is hit that is not 0
    iterator--;//this subtracts iterator until the nonzero index is hit
  }
  for(int i=0;i<=iterator;i++) {//between index 0 and the string character(which is nonzero) inclusive, the string values are continously added
    returnVal2+=value2[i];
  }

  if(returnVal2[returnVal2.length-1]=='.') {//if the last index of the string is a dot
    returnVal2+='0';//this fixes an edge case by adding a 0 after the . This ensures that the last character is NOT a dot.
  }


  return returnVal2;//this returns the new string of interest.

  
}


String firstTimeStamp="HomePage4"; //represents firstTimeStamp.


//listener/display functions
String showpHData() { //This is a function in the class that is used to display realtime values. It returns a pH of type String.
    DatabaseReference myDatabase=FirebaseDatabase.instance.ref('data'); //This is the instance of the database. This code will read/write from this instance. 'data' is the name of the data stored in the database.


    //In the .json format, the database is structured with header 'data', unique ID tags(which are randomized combinations of letters and numbers), and the associated pH string value, lime dispension string value, and timestamp with each ID
    //Later, it will be seen that lime dispension will follow an identical pattern, and flouride follows a different type of updating pattern.
    
    //each value represents a pH string value, and each ID is a 'child' of data.
    //the purpose of this is to listen to changes in the children(if different children values are added), and evantually display(print) these changes in realtime to the Flutter App.
    
    myDatabase.onChildAdded.listen((DatabaseEvent event)   { //the database listens if any child is added(aka, a new ID is added). This is conditioned on an 'event' which will be specified in the body.
        
      if(event.snapshot.key!="Flouride Data(ppm) added at " && event.snapshot.key!="Flouride Data(ppm) value ") {//ensures that flouride values are not added. event.snapshot is the current part of the event, and .key is the identifier. For flouride values, they have this identifier, and these values should be disregarded. {
      final pH = event.snapshot.child('pHvalue').value; //the new pH is the upcoming(realtime) event's child's value. 'pHvalue' is the property that specifies pH value, and is why it is used here.
      //this final value is a dynamic value
        
      setState(() { //adjusts value of origpH dynamically on the screenstate
      if(pH!=null) {//checks to ensure that final pH is not null. This check is placed here, as when adjusting flouride values(simaltaneously as the pH and lime dispension change in real-time), it causes pH to be null. This check ensures that the value displayed on the screen will NEVER be null.
        origpH = pH.toString(); //ensures origpH is in terms of string of dynamic pH.
      }
  });
  } 
}
);

  return adjustStringval2(origpH);//origpH is returned, and updated in realtime on Flutter. Decimal places are also truncated, and the decimal values are formatted nicely for display by calling the adjustval2string.
}


String showlimedispensionData() { //This is a function in the class that is used to display realtime values. It returns a limedispension value of type String.
    DatabaseReference myDatabase=FirebaseDatabase.instance.ref('data'); //This is the instance of the database. This code will read/write from this instance. 'data' is the name of the data stored in the database.
    //In the .json format, the database is structured with header 'data', unique ID tags(which are randomized combinations of letters and numbers)
    //These tags contain pH, limedispension, and time being sent
    //each value represents a lime dispension string value, and each ID is a 'child' of data.
    //the purpose of this is to listen to changes in the children(if different children values are added), and evantually display(print) these changes in realtime to the Flutter App.
    myDatabase.onChildAdded.listen((DatabaseEvent event)   { //the database listens if any child is added(aka, a new ID is added). This is conditioned on an 'event' which will be specified in the body.
        if(event.snapshot.key!="Flouride Data(ppm) added at " && event.snapshot.key!="Flouride Data(ppm) value ") { //ensures that flouride values are not added. event.snapshot is the current part of the event, and .key is the identifier. For flouride values, they have this identifier.
        final limedispension=event.snapshot.child('LimeDispensionRate').value; //the new lime dispension is the upcoming(realtime) event's child's value. 'limedispensionValue' is the property that specifies limedispension value in the database.
        setState(() { //adjusts value of origFlouride dynamically
        if(limedispension!=null) {//checks to ensure that final limedispension is not null. This check is placed here, as when adjusting flouride values, it causes limedispension to be null. This check ensures that the value displayed on the screen will NEVER be null.
        origlimedispension = limedispension.toString(); //ensures origlimedispension is in terms of string of dynamic limedispension.
      }
  });
  }
});
  return adjustStringval2(origlimedispension);//origlimedispension is returned, and updated in realtime on Flutter. Similar to pH decimal places are truncated and the decimal values are formatted nicely for display by calling the adjustval2String function.
}




//This function may be deleted..... Will need to see possible use of this...
//This function is kept in case of it being needed, it represents the realtime that the data values were sent to the database.
String showRealTime() {
  DatabaseReference myDatabase=FirebaseDatabase.instance.ref('data'); //This is the instance of the database. This code will read/write from this instance. 'data' is the name of the data stored in the database.
    //In the .json format, the database is structured with header 'data', unique ID tags(which are randomized combinations of letters and numbers)
    //These tags contain pH, limedispension, and time being sent
    //each value represents a time string value, and each ID is a 'child' of data.
    //the purpose of this is to listen to changes in the children(if different children values are added), and evantually display(print) these changes in realtime to the Flutter App.

    myDatabase.onChildAdded.listen((DatabaseEvent event)   { //the database listens if any child is added(aka, a new ID is added). This is conditioned on an 'event' which will be specified in the body.
        final myTime=event.snapshot.child('Created at').value; //the new time is the upcoming(realtime) event's child's value. 'Createdat' is the property that specifies the current time value.
        setState(() { //adjusts value of origTime dynamically
        if(myTime!=null) {//checks to ensure that final myTime is not null. This check is placed here, as when adjusting flouride values, it causes myTime to be null. This check ensures that the value displayed on the screen will NEVER be null.
        origTime=myTime.toString();//ensures original time is now the time value of interest.
      }
  });
});
  //print(origTime);
  return origTime;//origTime is returned, and updated in realtime on Flutter. This function is more so used in the case of needing values in flutter
}

//The following begins the basic implmenetation of the dynamic graph(finally....)


List<FlSpot> theData=[]; //Flspot is a class in Flutter that creates datapairs which can be used for later use. theData in this case, represents the datapoints to be added to the realtime graph
//this list will be used for the dynamic graph, along with its associated UI

List<FlSpot> theData2=[]; //this is going to be used to add paused datapoints to it(for the sake of a paused datapoint table).

List<DataRow> theData3=[];//this represents the list of the row to be added(for the paused datapoint variable).

final myStopWatch=Stopwatch(); //this represents the instantiation of the StopWatch. This stopwatch will be used for the creation of the graph

final myStopWatch2=Stopwatch(); //This stopwatch will be used for determining time gap between play and previous pause.



Timer? forPeriodic; //instantiates a Timer object, which will later be used for sake of sampling period. 
//Question mark is used to effectively set this initally to null(as setting it null directly led to some errors).



@override //this is an annotation, it is used to specify that this overrides the current state. This is used in the creation, and destruction of objects
void initState() { //this is like an allocating memory function. It creates an instance of an object
  super.initState(); //this function is used when adding a new object to the State(runtime of program). This is required for initState functions.
  
  starttheWatch(0); //this Starts the watch. Each time a new object is created, theWatch is started at t=0s.
  //the stopwatch is only started in starttheWatch, bc its state needs to properly change.
}

double pause=0; //this is used to determine when the stopwatch was paused. This is also used to figure out when the stopwatch should be started.
//This is also used as a point of interest in the code in the sense that the user can use this to determine when they want to save a point of interest(to the paused data table).

//Note: before ANY presses of the switch, the state is default in the on position(light on). This bc that naturally, the graph is always running.
bool light=true; //this is for the switch. light=true means on(play), while light=false means off(pause). The default state of the switch is play(as the data will be running)

double previousTimeplayed=0;//this is set as the beginning point. This variable is going to be used as way of saving the previous time value when the switch was flicked to the on position.
//this variable is also being used for the sake of switch cooldown, which will be shown later.


bool showMessage=false;//this is the for message displayed for cooldown purposes. This changes based on whether or not button spamming occurs
bool currentStateProg=false;//this represents the current program state. This will be set to the state of the current Message that needs to be displayed

void switchState(bool val) { //boolean value is switched on/off. This is the underlying logic when the user presses the switch.
//This function essentially connects the frontend switch to the backend code.
  setState((){ //dynamically sets the state of light to val. Val is a dynamically changing parameter, which represents the user inputted state of the switch.
    light=val; 
  });
  if(!light) { //if the light is off, this means that the switch is in the off state. This means that the watch should be paused
    pausetheWatch(); //calls the pausetheWatch function
  }

  //The following code represents when to play the watch. There are checks in place to ensure that cooldown does occur.
  else { //if the light is not off(is on), this means that the switch is in the on state. This means that the watch should be played.
    
    DateTime currentTimePlayed=DateTime.now();//represents the current time played
    double currentTimePlayednum=double.parse(currentTimePlayed.millisecondsSinceEpoch.toString());//this obtains the currentTime that was played in terms of a double MILLISECONDS SINCE EPOCH.
    //if it is too soon, the user must pause, then play to redo data sampling as normal. This ensures that spamming does not occur.
    //this cool off ensures data crashing does not occur, nor lagtimes to occur.
    if(currentTimePlayednum-previousTimeplayed>=500) {//ensures that there is some cool off time before calling the playthewatch function. The cool off time is 500ms. This time was chosen as it had the best results.
    //This essentially ensures that there is a 500ms gap between the currenttime played, and the previous time played.
        playtheWatch(); //calls the playtheWatch function
        showMessage=false;//there will be no message displayed.
    }

    else {//If there is button spamming(switch spamming), this message will be displayed to alert the user to calm down on the button spamming. Also, the watch will not be played
        showMessage=true;//there will be a message displayed.
    }
    
    setState(() {
      currentStateProg=showMessage;//this sets the currentProgram state to whether or not to show the message.
      previousTimeplayed=currentTimePlayednum;//this is used to set the current time as the previous time(which will be used as the basis for the next instance of comparison)
    });
    
  }
}


double samplingTime=3; //sets samplingTime to initial default value(which as of now is its smallest value). Sampling time can be between 3-6s.

void sliderState(double val2) {//Need to look into how this changes, when adjusting the slider.
  
  
  setState(() { //dynamically sets the state of samplingTime to val2. Val2 is a dynamically changing parameter, which represents the user inputted sampling time.
    samplingTime=val2;//similar to the switch, the slider's sampling Time value is also changed based on user input..
  });

  /*
  for(int i=theData.length-1;i>=0;i--) {
    if(theData[i].x.toDouble()>=myStopWatch.elapsedMilliseconds/1000) {
      theData.removeAt(i);
    }
  }

  */


  //starttheWatch(myStopWatch.elapsedMilliseconds/1000);
  
}

int count=0; //this variable is an indicator for determining if the starttime is 0.

//for graphs, add table of paused values(besides that, this should be fine).

void starttheWatch(double startTime) { //tickticktick.... This starts the watch's time keeping
 
  myStopWatch.start(); //the stopwatch is now started for the graph. The stopwatch upcounts in time
  
  
  
      forPeriodic = Timer.periodic(Duration(seconds: samplingTime.toInt()), (timer) { //sampling time of user input. Starts up the timer.
      setState(() { //sets dynamically changing values in time. Ensures changes are reflected in realtime on webapp.
        
        //This is a special case made for t=0s.
        if(count==0) { //this is an if statement specially made for t=0s(if startTime=0s). Other values of startime are added in the pausethewatch function.
          double myDouble=double.parse(showpHData()); //takes in the pH data
          theData.add(FlSpot(startTime.toDouble(), myDouble)); //adds the pH data at time t=0s(starting time). 
        }
        count++; //since the first datapoint(at t=0s) is added, it should not be added again.

        double currentTime=myStopWatch.elapsedMilliseconds/1000.toDouble(); //current stopwatch time. .toDouble()'s purpose is to convert the default time in int to a double. This will be the xdata of the graph.

        theData.add(FlSpot(currentTime, double.parse(showpHData()))); //this adds a new datapoints: xvalue: stopwatch elapsed time, yvalue: pH
        
        //displays corresponding pH value to the specific realtime since stopwatch started. It is important to note that this measured based on the sampling time.
        //when the user presses pause, it takes an instantaneous value(allowing for flexibility in the visualization/storage of this value for later). This is done in the pausethewatch function.
        
        if (theData.length > 20) { //limits the number of points displayed on the realtime graph to be 20 at once.
          theData.removeAt(0);// Removes the first point to ensure enough points fit on the graph. This dynamically changes the size of the graph, and ensures that the size is maintained.
        }
      });
    });
}

//Keep this for userinput
void resettheWatch() {//resets time keeping back to 0, and goes from there. This is called after pressing the RESET BUTTON.
  forPeriodic?.cancel(); //cancels the timer from the previous run. ? is used here to mainly avoid errors(and also, it is unknown as to the nullability of the variable).
  myStopWatch.stop(); //stops the watch temporarily(to do analyses).
  setState(() {
  //removes all the previous data traces by looping through all the dataTraces being made
  //The loop is done backwards to ensure values are properly indexed and all values are removed.
  //Looping forwards shifts the indices during the removal process, which in of itself is an issue.
  for(int i=theData.length-1;i>=0;i--) { //removes all of the graph's datapoints. Going backwards is done primarily to avoid indexing issues
    theData.removeAt(i); //uses the removeAt function
  }

  for(int j=theData2.length-1;j>=0;j--) { //theData2 will be a list used evantually(in the pausethewatch function). This will be used to add paused datapoints(timestamps and pH values)
  //similar to the actual datapoints on the graph(theData), reset removes all of these as well.
    theData2.removeAt(j); //uses the removeAt function, removes the paused values of previous run(this is so the new Data run can start from scratch).
  }

  for(int k=theData3.length-1;k>=0;k--) {//theData3 is almost identical to the Data2, however it is just in form of a DataRow instead of a FlSpot
  //What this means is that one cell in the row will be pH, while the other will be timestamp
    theData3.removeAt(k);//this removes the data table entry(row).
  }


}); 


  myStopWatch.reset(); //resets the watch back to 0s temporarily.
  light=true; //sets the value of the on/off switch light to true(force resets it).
  
  count=0; //is used as indicator for t=0s, as after reset, start time will be 0 again.

  starttheWatch(0); //starts theWatch from the beginning again.


  showMessage=false;//this ensures that the spamming play/pause message is not shown(as the graph is restarted)
  setState(() {
    currentStateProg=showMessage;//the currenmessage state will not be shown
  });

  timeGap=0;//this ensures that the value of timegap is set to 0, as it is important to ensure that it is renewed after reset.
}


//There will be one function called play, and one function called pause.
//It is going to be conditioned that play can only be an option after pause has been chosen
//As of now, the play/pause button will be an on/off switch(this will be changed later accordingly)
void pausetheWatch() { //pauses the timer/stopwatch. If the light is off, that means that it is paused. 
  //setState(() {
  forPeriodic?.cancel(); //cancels the timer from the previous run. ? is used here to mainly avoid errors(as it is not known whether or not the object is null). This is mainly canceled to ensure the sampling is stopped.
  myStopWatch.stop(); //stops this watch temporarily. This is stopped as the starttheWatch function relies on this for upcounting.
  
  pause=myStopWatch.elapsedMilliseconds/1000; //obtains value when the stopwatch was paused.


  setState(() {//setState is used to dynamically change the value in realtime on the webapp
    if(theData2.isEmpty || (pause>=theData2.last.x+0.3)) //if the paused data list does not contain anything(first paused datapoint) or if the current paused datapoint is at least 0.3s more than the previous, show this on the graph. 
    //This 0.3s buffer is made to avoid any spamming errors(to avoid adding excess datapoints overlayed onto the graph).
    
    {
      //the paused point will be displayed on the graph, if it is greater than or equal to the previous paused point + 0.3.
      //Doing this ensures the user can not excessively spam press the button
      //you want to add the first paused point always

    if(theData.isEmpty) {//checks if the regular data is empty.
      theData.add(FlSpot(0, double.parse(showpHData()))); //adds 0 if the paused point occurs between 0 and sampling time. This resolves an edge case bug(where a person decides to press pause before the first sampling time period has been completed).
      
      //this ensures that 0 is still added in this situation.
    }

    theData.add(FlSpot(pause, double.parse(showpHData()))); //this represents the datapoint at which it is paused at. This adds the paused value to the graph.
    //It is added here and NOT in stopthewatch to ensure it is added before the graph stops. Otherwise, it will not be added(in a timely way).
    //This is also a storage datapoint for the user to be able to save for later. It will always be stored, but it will only conditionally be displayed
    //A table implementation will be used later for the paused datapoints.
    if(theData.length>20) {
      theData.removeAt(0); //checks if there is more than 20 datapoints. Removes the first datapoint if there is more than 20 datapoints.
      //This check is done in this function as well, as values are still being added.
    }

    }
  });

  setState(() {//ensures values are properly changed on GUI.
    theData2.add(FlSpot(pause, double.parse(showpHData()))); //adds the paused point to a seperate list(this list will be used/displayed with a table)

    theData3.add(DataRow(cells:[DataCell(Text(showpHData())), DataCell(Text(DateTime.now().toString()))]));
    //DateTime.now() represents the current realtime
    //this adds a pasued data value to the list.
    //this paused data value is not excessively spaced apart, and the graph is properly working.
    //}
  });
  
  myStopWatch2.start(); //starts counting the amount of time that is paused.

}

double timeGap=0; //this is used to determine the amount of time the associated stopwatch was paused for
void playtheWatch()  {
  //plays the timer/stopwatch. If the light is on that means that it is played
  //this continues logic as the user wishes.
  //play logic goes here

  myStopWatch2.stop(); //finds the amount of time elapsed during pausing of data value intake. This stopwatch is stopped here, as this stopwatch runs between the time of pausing then playing.
  
  

  timeGap=(myStopWatch2.elapsedMilliseconds)/1000; //this gives number of time between pausing of button and playing of button.
  //play=timeGap+pause; //represents the time when it was played.


  starttheWatch(pause); //calls starttheWatch with a new starting time: a startingTime of where the user paused the value
  
  pause=0; //pause is set back to 0, as the paused state is over. This is done as an indicator for obtaining a different pausedtime(in the next datarun.)
  
  myStopWatch2.reset(); //the duration of pausing is reset back to 0, as the button is now played(and the measurement of the duration of pausing HAS been taken).

}

//This function will be used to obtain the list of paused data values. This is a getter function that will be used by the paused data value table.
List<FlSpot> pausedData() {
  return theData2;//theData2 represents the list of paused data values.
}

//This function will be used to return pH type
String returnpHType() {


String returnMessage="";//this represents the message to be returned
  if(double.tryParse(showpHData())!=null) {//this is checked, as when the program is first initalized, the values could be null. It is important to ensure that the values of interest are NOT null at runtime.

  if(double.parse(showpHData())==7) {//if the pH for display is equal to 7, then it is classified as neutral
    returnMessage= "pH is neutral";
  }

  else if(double.parse(showpHData())<7) {//if the pH for display is less than 7, then it is classified as acidic
    returnMessage= "pH is acidic";
  }
  else {//if pH is anything greater than 7 it is considered as basic. 14 is an implied upper bound, as all values to be displayed are capped at 14 prexxisitingly in the C++ program.
    returnMessage="pH is basic";
  }
  
  }

  return returnMessage;
}



@override
  void dispose() { //this is like a deleting memory function.
    myStopWatch.stop(); //stops the currently running stopWatch(which is used for the graph data)
    myStopWatch.reset(); //resets the watch back to 0 for later use.
    forPeriodic?.cancel(); //Cancels the timer. ? is used bc it may or may not be null(there is an error without the question mark). This timer is used for the graph data
    myStopWatch2.stop(); //stops the currently running stopWatch(which is used for the gap between pause and play)
    myStopWatch2.reset(); //resets the watch back to 0 for later use.
    super.dispose(); //Destroys the built instance. The destroy is only done at the end, as that is when all of the memory based objects(stopwatches/timers) are disabled/stopped/cancelled/resetted.
}


  @override//override is used here to force this parameter.
  bool get wantKeepAlive=>true; //this ensures that the widget should be kept alive(this logic is used for changing tabs, and keeping state.)

  @override
  Widget build(BuildContext context) {
    super.build(context); //this is used along side the above wantkeepalive to ensure the state is maintained when switching tabs.
    

    return Scaffold(//framework for building this webapp. This is going to especially used as the body of the webapp.

      //appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        //showData;
        //if(origTime!="HomePage3")
        //title: Text("Realtime pH is: ${showpHData()}. Realtime Lime DispensionValue(g/L) is: ${showlimedispensionData()}. StopWatch1 Time is Value is: ${myStopWatch.elapsedMilliseconds/1000} Sending Value in s after epoch is: ${showRealTime()}"), //origpH and origFlouride is printed here, and updated in realtime. The $ and brackets are part of an interpolation process that allows for the embeddedment of strings. This text will later be formatted when the app building process is started.
        
        //leading: Icon(Icons.notification_add, color: Colors.amber)
      //),
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        
        //Containers are blocks in code
        //boxdecoration is used for boxes.

        //This was used to obtain the image.
        //Image.asset('assets/images/samsung_logo_PNG9.png', fit: BoxFit.cover, cacheHeight:4 ,), //This was a test for image placement.



        //THIS WILL BE USED FOR THE CONSTRUCTION OF GRAPHS
        body: Stack( //stack is used here for the sake of overlaying widgets, and ensuring that the widgets can all be placed together in a row and other portions as well.

        children: <Widget>[
          Text('                                                                              pH Value vs Time(seconds)                                                                    ', style: TextStyle(fontSize: 20, color: Colors.purple),), //this represents the chart title
          //the spaces are there, for sake of spacing out the title.
          Padding(padding: EdgeInsets.only(left:5, bottom:0),//this padding gives space to the left for the row to be used.
          child:Row(
             //row is used for the: graph, reset button, play/pause, sampling time slider
        children: <Widget>[
          SizedBox(//the sized box will be used, to restrict dimensions of the realtime graph.
          
          width: 1000, height: 635, 
          //the width and height represents the size of the graph itself.
          //child: Stack(
            child:Padding(padding: EdgeInsets.only(top:27, bottom: 0,),//this is the padding on top of the line chart. It is padded relative from the top of the page
            child:

            LineChart(LineChartData(//declares instance of LineChart

            minY: 0, //minimum y is 0 as this is the lowest possible pH value
            maxY: 14,//maximum y is 14 as this is the highest possible pH value.
            
            //This is also placed here as a design choice, as it is important for the user to view the differet levels of pH comparaitvely.
            //Not having this, causes the data to have issues in display, and it becomes less clear as to the differences in levels of pH.
            //This is aesthetically more pleasing, and there is no need of having a decimal scaled y axis, as the user can already see decimal values by hovering over datapoints.

            gridData: FlGridData(show: true),//this ensures that graph grids will be shown in the graph  
            titlesData: FlTitlesData(//this represents the title data to be shown
            topTitles: AxisTitles( //specifies settings of topTitle. In this case, there is no toptitle to be shown, as the title has been instantiated earlier with the stack.
              sideTitles: SideTitles(showTitles: false) //there will be no values displayed on the top, thus this is hidden(aka false)
            ),
            rightTitles: AxisTitles(//there is no need for titles on the right hand sign
              sideTitles: SideTitles(showTitles: false) //there will be no values displayed on the right, thus this is hidden(aka false)
            ),
            leftTitles: AxisTitles(//For the left title, in the scope of this project, this will be the yaxis.
              axisNameWidget: Text('pH Value'),//the leftAxis(y-axis) will be declared as the pHvalue
              sideTitles: SideTitles(showTitles: true, reservedSize: 37)//reservedSize ensures y axis labels are properly displayed(and they have enough space). 
              //This makes sure that they arent stacked on top of each other, and ensure that they don't interefere with the yaxis title 'pH Value'.
            ),
            bottomTitles: AxisTitles(//the bottom title, in the scope of this project, will be the xaxis
              
              axisNameWidget: 
              //Padding(padding: EdgeInsets.only(top:10, ), child: 
              Text('Time(seconds)')//the bottomAxis(x-axis) will be declared as the time(in seconds)
              //)
              ,

              sideTitles: SideTitles(showTitles: true, reservedSize: 25)//this is set to ensure that the x axis title and the x axis labels DO NOT OVERLAP!! This provided size also ensures that each of the labels have enough space
            ),



            ),
            borderData: FlBorderData(show: true), //shows clear border around the chart
            //clipData: FlClipData(top: false, bottom: false, right: false, left: false),//this clips the borders, to ensure datapoints do not go beyond borders.
            
            lineBarsData: [ //this is done to create the value's points(creates lines for the user to view points).
            //these lines connect the intermediate points
              LineChartBarData(
                spots: theData, //plots points(gives Data that the points will be based on). Spots really just means data
                isCurved: true, //allows for plot to be curved
                color: Colors.green, //color of lines and points is green.
              ),
            ],
            )
            )
            //)
            ) 
            
            
            

            ),

            //),
            
            //Padding(padding: EdgeInsets.only(bottom: 40, left: 0), child: Text("               Hello")),


            Padding(padding: EdgeInsets.only(top: 15, left: 35), //this padding space is provided to ensure there is space from the grpah
            child: ElevatedButton( //represents the reset button, this a button the user can always press. Padding is placed here to create space between the reset button and the realtime graph.
            
              style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 20),//you can adjust color later
             ),
            onPressed: resettheWatch, //after the button is pressed, resettheWatch is called
            child: const Text('Reset') //the button is labeled as Reset
  ),
            
  ),
            
  //Padding(padding: EdgeInsets.only(bottom: 4), child: Text("Play/Pause"),),
  
  //Padding(padding: EdgeInsets.only(bottom: 40, left: 0), child: Text("               Hello")),
  Padding(padding: EdgeInsets.only(top: 15, left: 35), //this padding space is provided to ensure there is space from the grpah
  child:  

/*

  Switch(
  // This bool value toggles the switch.
  value: light, //light is value of interest
  activeColor: Colors.purple, //sets color of switch to purple when on
  onChanged: switchState //calls the switchState function above
  // This is called when the user toggles the switch.

      
  ),

  */

IconButton(//this icon shows the symbol at the end of the text field(suffix)
        icon: Icon(light ?  Icons.pause_presentation_outlined : Icons.smart_display_outlined), //when light is true, pause is shown. When light is false, play is shown
        onPressed: () {
          switchState(!light);//this ensures that the state is properly switched. !light just means that it is the opposite of the previous value of light
        } ,
        color:Colors.purple,//this is the color of the play/pause button
        iconSize: 45,//this is the size of that button
        
)
  
  ),

  
  Padding(padding: EdgeInsets.only(top: 15, left: 35), //this padding space is provided to ensure there is space from the grpah
  child:
  Slider(
    value: samplingTime,//this represents the currently selected value. samplingTime changes based on user input.
    min:3, //the minimum sampling time is 3 seconds
    max: 6, //the maximum sampling time is 6 seconds
    divisions: 3,//3-6 is the range
    label: "${samplingTime}s",//the label of the current State will of course be the sampling time
    onChanged: sliderState //when the slider is shifted, it will call the sliderState function which is earlier in the code.
  ),
  )

    ]
    )
          //)
    
    ),


    Positioned( //this positions text in specific places
      top:7, //40 pixels below the very top
      right:30, //30 pixels left of the very right
      //This text contains all the important characteristics: changing color/font size will be done later. This removes the need of putting these values in the dashboard(thedashboard will now be used for switching between different parts(navigation).)
      //The stuff that are included is: timegap between play and previous pause, stopwatch elapsed time, Real-time pH value, Real-Time Lime Delivery Value, display message of button spamming, and then of course, the text style.
      //This text may be formatted more later.
      //children:<Widget>[
      child: Text('TimeGapBetween Play and Previous Pause: ${timeGap}s\n\nStopWatch Elapsed Time: ${myStopWatch.elapsedMilliseconds/1000}s\n\nReal-Time pH Value: ${showpHData()}\n\nReal-Time Lime Delivery Value(g/L): ${showlimedispensionData()}\n\npH type: ${returnpHType()}\n${currentStateProg ? "ChillOut with the presses!":""}',
      
      style:TextStyle(fontSize:20, color:Colors.purple),//this represents the text color.
      
      ),
      //]
      //This shows the output onto the console.

      //child:,
    ),
    Positioned(bottom: 333, right: 298, child: Text("Play/Pause"),),//label for the play/pause button
    Positioned(bottom:333, right: 112, child: Text("SamplingTime Slider")),//label for sampling time slider.


    Positioned(bottom:70, right: 100, //positioned is used here, to position this dynamically changing datatable. This datatable will be used for filtering, the datatable will be used for paused values.
    child: 
    SizedBox(height:225, //this limits 
    //width: 100, 
    child:
    SingleChildScrollView(//singlechild scroll view is used here to ensure that the datatable will be scrollable.
      child: 
      DataTable(
      columns: [
        DataColumn(label: Text("Paused pH Data Value:")),//the first column is the dataValue
        DataColumn(label: Text("Time of Pausing: ")),//the second column is the TimeStamp(time of pausing)
      ],
      
      rows:(theData3)//data3 has different cells: cell for pH value and cell for pausing time.
      //[
        //DataRow(cells: [
          //DataCell(Text("90.0")),
          //DataCell(Text("April 1st 2004"))
        //])
      //]

    )
    )
    )
    )
    ]),
//}




        
    )
    ;

    //return Switch(
      //value: isOn,
      //mouseCursor: ,

    //)



  }
}








































//class TablePage
class TablePage extends StatefulWidget {//tablepage does change with state, it is NOT stateless(static)
  //throughout this code, setState will be used, which is a property of stateful widgets to enable changes on the graphical user interface.
  const TablePage({super.key, required this.title2});//tablepage constructor. title may or may not be deleted.
  
  
  final String title2;//title is a property of this class, this may be adjusted later
  //title="HelloMate";
  @override //override is used to create/destroy instances(will also be seen in the table code). In this case, it creates a new instance of the table page state.
  State<TablePage> createState() => _TablePageState();//ensures state of tablepage is able to change
}


typedef ValueEntry=DropdownMenuEntry<SelectedVal>;//this defines the type for the dropdown menu entry.

//The following enum(constants and constructor declaration) will be used for the dropdown menu of what value to choose.
//This dropwdown menu will be used for SelectedVal
enum SelectedVal {
  pH('pH'),//represents choice description if pH

  limedispensionrate('Lime Dispension Rate');//represents choice description if lime dispension rate

  const SelectedVal(this.label);//this is a constructor that represents the specific values to be used
  final String label;//this represents the variable of interest, which is label.

  //unmodifiable list is used here to ensure that the list does not change. 
  //Same logic as to static final, as the descriptions/values in this dropdown list will not change in name
  static final List<ValueEntry> listEntries = UnmodifiableListView<ValueEntry>(
    values.map<ValueEntry>(//a map is used here to correspond an interator with its respective value
      (SelectedVal theVal)//this is an iterator of type SelectedVal(the enum)
      =>ValueEntry(label: theVal.label, value:theVal)//this shows both the value and label associated with the dropdown menu entry.
      //This creates an entry with specific properties

    )
  );
}


typedef TimeEntry=DropdownMenuEntry<TimeVal>;//this defines the type for the dropdown menu entry.

//The following enum(constants and constructor declaration) will be used for the dropdown menu of what time span to choose
//This dropwdown menu will be used for TimeVal
enum TimeVal {
  lastSecond('Last Second'),//represents choice description if time duration is last second.
  lastMinute('Last Minute'),//represents choice description if time duration is last minute
  lastHour('Last Hour'),//represents choice description if time duration is last hour
  lastDay('Last Day'),//represents choice description if time duration is last day
  lastWeek('Last Week'),//represents choice description if time duration is last week
  entireData('Entire Database');//this represents the entire database completely

  //lastAllTime('Entire Database');//represents if the user wants to see the entire database.

  const TimeVal(this.label);//this is a constructor that represents the specific time values to be used
  final String label;//this represents the variable of interest.

  //unmodifiable list is used here to ensure that the list does not change. 
  //Same logic as to static final, as the descriptions/values in this dropdown list will not change in name
  static final List<TimeEntry> listEntries2 = UnmodifiableListView<TimeEntry>(
    values.map<TimeEntry>(//a map is used here to correspond an iterator with its respective value
      (TimeVal theVal2)//this is an iterator of type TimeVal(the enum)
      =>TimeEntry(label: theVal2.label, value:theVal2)//this shows both the value and label associated with the dropdown menu entry.

    )
  );
}


class _TablePageState extends State<TablePage> with AutomaticKeepAliveClientMixin{//this extends the statefulwidget, to ensure changes in state are possible.
 //The AutomaticKeepAliveClient is used to allow for the tab state to be maintained when moving to a different tab. This related to the tabs

  
  @override//override is used here to force this parameter.
  bool get wantKeepAlive=>true; //this ensures that the widget should be kept alive(this logic is used for changing tabs, and keeping state.)
  
//put pH and limedispension state changing functions(from HomePageState) here.





//Planned logic:
//Widget to be used: data table
//Make a UI dropdown menu that asks the user what value of interest they would like to observe
//Make a UI textfield that asks the user how many entries they would like to see
//Make a UI dropdown menu of the amount of time they would like to check the data for: last minute, last hour, or last day
//Display a message in the case that the number of entries is greater than the amount in that time frame. Display the max amount of entries.


//Show the values using datatable, and use the vales of datetime duration.

//For example: the person says they want to see 30 entries from the last day.
//You want to get the first entry of the last day, and then the next entry is 86400/30. This should be the first value at that time. Then the next entry is 86400/30 of the previous, etc.


final TextEditingController theController = TextEditingController(); //this controls the editing of the text of the flouride value. This may be deleted

final TextEditingController theController2 = TextEditingController(); //this controls the editing of the text of the amount of entries. This may be deleted



//flouride validity checker, and sending to firebase
bool isValid=false; //instantiates an indicator variable that is used to check for validity of user input
int count2=0; //this is an indicator to obtain the number of variables checked. This is also used to ensure a label in the userinput.

void readInandWriteFlouride(String inputFlouride) async { //inputFlouride is the value coming in from the Flutter webapp. async is used here to ensure it is properly added.
  isValid=false;//the value is invalid, until proven if true
  setState(() {//setState is used here to ensure the proper changes are being shown on the UserInterface.
  
  if(double.tryParse(inputFlouride)!=null) { //tryparse is a function routine in flutter that is used to check if the string is able to convert to a double
  //in this case, the double indicator is used to check if it can convert to a double
  //if the value is able to be converted to a decimal value, it is valid
    isValid=true; 
  }
  
  else {//If the value is not able to be converted to a decimal value, it is false
    isValid=false;
  }

  count2++;//each time a new flouride value is being interpreted, the amount of values interpreted increases. This variable is used for the intention of changing the textbox label.
  
  });
  

  if(isValid) { //only sends/invokes database if the string value has the capability to convert to a decimal.
  DatabaseReference myDatabase=FirebaseDatabase.instance.ref('data'); //This is an instance of the database.
  //Unlike the displaying of pH and lime dispension values, this will be read in. Also, unlike the pH and lime dispension values(which are added as seperate children), this will be updated as the last value.

  await myDatabase.update({ //this updates the values in .json format. 
    "Fluoride Data(ppm) added at ": ((DateTime.now()).toString()),//this represents the currentDate and Time(which will be sent to Firebase as a String). dateFormat is used here to make a consistent formatting scheme.
    "Fluoride Data(ppm) value ": inputFlouride//this is the Flouride value that the user gave in. It is important to consider that it is only sent if it is valid.
    
  });
  }
}


String returnLabel() {//this returns the label in the textbox
  if(isValid||count2==0) {//CHECKS if this is before the first value being inputted, or, if the value is valid. Shows Flouride Value(ppm). 
  //If the first value that the user puts in is invalid, it is not sent to firebase. If it is invalid, there is also a display message on the textbox as well.
    return "Fluoride Value(ppm)";//returns the flouridevalue(ppm)
  }
  return "Invalid Input"; //notifies the user that the input is invalid, and that they must try again. When this happens, the value is also not sent to the database.
  
}

//The following 5 functions are used as backend connections to the frontend user filters. They adjust original values to new values.

//this function is used for the value choice based dropdown menu. The values of choice are: pH, lime dispension, and flouride
//pH and lime dispension are handled identically, however flouride will be handled differently.

SelectedVal? currentChoice;//this represents the currently selected value from the dropdown menu. ? is used here as it is unknown whether or not this value could be null.
void changeChoice(SelectedVal? choice) {//question mark is used here, as it is unknown whether or not the value is null
  setState(() {//changes are reflected UI.
    currentChoice=choice;//changes the value of the currentchoice to choice(this ensures a change in state)
  });
  addRows();//after the change in choice, the addRows function is called. This is to ensure that the selected value of interest is properly filtered in the datatable(and so that the UI will be updated).
}


String displayVal() {//this function is used to display the different values in the value column of the data table
  if(currentChoice!=null) {
    return currentChoice!.label;//if the currentChoice is not null(an option has been selected), then the label for the currentChoice will be selected
  }
  return "";//otherwise, empty string shall be returned.
}



int numEntries=0;//this represents the current number of entries in the table.
bool isValid2=false;//this value checks to make sure the user inputted number of entries can be converted to a nonzero integer, if not, an error message will be displayed
int count3=0;//this represents a counting indicator for the number of Table Entries

void numTableEntries(String newNum) {//this function connected the number of entries frontend textbox to this backend.
  isValid2=false;//false until proven if true
  setState(() {//setState is used here to ensure the proper changes are being shown on the UserInterface.
    if(int.tryParse(newNum)!=null && int.tryParse(newNum)!=0) { //tryparse is a function routine in flutter that is used to check if the string is able to convert to a int
  //in this case, the int indicator is used to check if it can convert to a int
  //if the value is able to be converted to an integer value(which is nonzero as there can not be 0 rows), it is valid
    isValid2=true; 
  }
  else {//Otherwise, it is false
    isValid2=false;
  }
  count3++;//each time a new user inputted entry value is entered, this value increments.
  });
  if(isValid2) {//if the value is able to convert to a nonzero integer...
    setState(() {
      numEntries=int.parse(newNum);//the state of the current number of entries is set to the integer version of the number of rows. This will be used in the addRows function.
    });
  }
  //print(numEntries);//you need to check to ensure that num entries DOES NOT EQUAL 0. There can not be 0 rows in the table. The number of rows are integers greater than or equal to one.
  
  addRows();//addRows is called here, as the state of the row will change based on the number of entries in the data table.
}


String returnLabel2() {//this returns the label in the textbox for the number of entries
  if(isValid2||count3==0) {//CHECKS if this is the first value being inputted, or, if the value is valid. Shows Nuber of Table Entries(Rows). 
    return "Number of Table Rows";//returns label saying: "Number of Table Rows"
  }
  return "Invalid Input, try again"; //notifies the user that the input is invalid, and that they must try again. 
  
}





//this function is used for the time choice based dropdown menu
TimeVal? currentChoice2;//this represents the currently selected value from the dropdown menu. ? is used here as it is unknown whether or not this value could be null.
void changeChoice2(TimeVal? choice2) {//question mark is used here, as it is unknown whether or not the value is null
  setState(() {
    currentChoice2=choice2;//changes the value of the currentchoice2 to choice2(this ensures a change in state)
  });
  addRows();//addRows is called here, as the state of the row will change based on the time duration to be used.
}

//Now, it is time to begin the transfer of values
//For this table, there are two columns: value and timestamp
//At the beginning if the user does not choose a value from the dropdown menu, there will be no values shown in the table.
//For pH and lime dispension, the process is similar: loop through the entire database with spacings based on the number of entries and the amount of time gap


List<DataRow> theRows=[];//this is a list of the Data Rows that will go into the DataTable
DatabaseReference myDatabase=FirebaseDatabase.instance.ref('data');//This is the instance of the database. This code will read/write from this instance. 'data' is the name of the data stored in the database.
 

//String currLabel="Cheers";


@override
void initState() {//initstate is used here to initalize a new state for the table. This is done when the program has first begun
  super.initState();
  addRows();//calling this function creates a new datatable at runtime
  
}

//The following function will be used later on, when there needs to be checks for time duration.
bool returninRange(DateTime time2, DateTime time1) {//this takes in 2 datetime values
  if(currentChoice2!.label=="Last Second") {//if the user wants to see values from the last second
    return ((time2.difference(time1))<=Duration(seconds: 1));//Duration is used here to ensureaccuracy concerns.
  }

  if(currentChoice2!.label=="Last Minute") {//if the user wants to see values from the last minute
    return ((time2.difference(time1))<=Duration(minutes: 1));
  }

  if(currentChoice2!.label=="Last Hour") {//if the user wants to see values from the last hour
    return ((time2.difference(time1))<=Duration(hours: 1));
  }

  if(currentChoice2!.label=="Last Day") {//if the user wants to see values from the last day
    return ((time2.difference(time1))<=Duration(days: 1));
  }

  if(currentChoice2!.label=="Last Week") {//if the user wants to see values from the last week.
    return ((time2.difference(time1))<=Duration(days: 7));
  }
  //if(currentChoice2==null) {
    //return true;
  //}

  return true;//if the user has not entered in time based input
}

String returnErrorMessageTime() {//this function returns error message time based on time settings the user placed
//In the case the user enters a number of entries greater than the specific time specified, that is when this function will be invoked.

  if(currentChoice2!.label=="Last Second") {//if the user enters in more entries than are possible for the last second.
    return "one second";
  }
  if(currentChoice2!.label=="Last Minute") {//if the user enters in more entries than are possible for the last minute.
    return "one minute";
  }
  if(currentChoice2!.label=="Last Hour") {//if the user enters in more entries than are possible for the last hour.
    return "one hour";
  }
  if(currentChoice2!.label=="Last Day") {//if the user enters in more entries than are possible for the last day.
    return "one day";
  }
  if(currentChoice2!.label=="Last Week") {//if the user enters in more entries than are possible for the last week.
    return "one week";
  }

  return "";//if the choice is empty than there is an empty string.
}

//void initalizeTable() {//this function is used to initialize the datatable in the flutter webapp

//}
String errorMessage="";//this error message will be used to show whether or not something will be displayed

bool showExceedMessage=false;//this message will be shown whenever, the user enters in more rows, than the database already has.


int databaselength=0;//this variable is used for the function/purpose of ensuring that the database length is greater than or equal to the user inputted entry amount.

//this checkbox has the intention of removing the milliseconds in the time entries.
bool checkBool=true;//check bool is the indicator variable for the checkbox. true means that the check is there and false means there is no check.
void checkBoxFunc(bool? val) {//this function is used to set the state of the checkbox to be used.
  setState(() {
    checkBool=val!;//sets the currentcheckbox variable to the user inputted checkbox variable
  });
  if(!checkBool) {//this checks if the check has been clicked
    //logic for data table filtration goes here.
    List<DataRow> filtrationList=[];//this list will be used to filter out the milliseconds of the data.

    for(int i=0;i<theRows.length;i++) {//this traverses through the list of datarows.
      String? currTimeStamp=(theRows[i].cells[1].child as Text).data;//this represents the currentimestamp, cells[1] is the timestamp. 
      //The data could be nullable due to theRows list being empty. That is why question mark is being used.
      int iterator=0;//this iterates through the while loop.
      String newstr="";//new string represents the string to be used now
      while(currTimeStamp![iterator]!='.') {//continously adds newstr until the decimal point is hit
        newstr+=currTimeStamp[iterator];
        iterator++;
      }
      while(currTimeStamp[iterator]!=' ') {//finds the space. This space distingushes the year from the milliseconds portion
        iterator++;//when iterator hits the index of the ' ', it breaks out of the loop.
      }

      for(int k=iterator;k<currTimeStamp.length;k++) {//the string should continue adding at that element(of space).
        newstr+=currTimeStamp[k];//this adds the string between the space to the end of the string.
      }
      filtrationList.add(DataRow(cells: [
        DataCell(theRows[i].cells[0].child as Text), DataCell(Text(newstr))//this adds the row's associated value, and this timestamp to the filtration list
      ]));
      theRows[i]=filtrationList[i];//this reinstatiates the value of this specific row(it causes the row to be new).

    }
  }
  
  
  else {
  addRows();//this is done to show the changes in UI(it also reverts to the original state.)
  }
  

  //as of now, this doesn't filter
}








String adjustStringval(String value) {//this function removes ALL trailing zeroes. An identical function was used for the homepage

/*
  if(double.parse(value)==0.0) {
    return "0";
  }

*/


  String returnVal="";//this will be the string to be returned(the adjusted string).
  int iterator=value.length-1;//the iterator will work backwards, that is why it is the index of the last element.

  while(value[iterator]=='0') {//this loops backwards until a string character is hit that is not 0
    iterator--;//this subtracts iterator until the nonzero '0' index is hit
  }
  for(int i=0;i<=iterator;i++) {//between index 0 and the string character(which is nonzero) inclusive, the string values are continously added
    returnVal+=value[i];
  }

  if(returnVal[returnVal.length-1]=='.') {//if the last index of the string is a dot. This is done to resolve an edge case, and ensure that the last element is not a .
    returnVal+='0';
  }
  return returnVal;//this returns the new string of interest.
}





void addRows(){//this function continously updates the list, and changes when new additions are made to the database, or on a new runtime.
  
  checkBool=true;//this means that the state of the checkbox will be changed(back to checked)
  //The checkbox is intentionally changed based on each adjustment of the rows to ensure that the user can filter values as they wish.



  myDatabase.onValue.listen((DatabaseEvent currEvent) {//onValue detects any change to the 'data' node of the database. 
  //It also just generally includes the entire database as a whole.
    DataSnapshot currSnapshot=currEvent.snapshot;//this snapshot represents the current state of the database.
    
    Object? currData=currSnapshot.value;//this represents the currentData in its entirety. It will be used evantually for transferring values
    //Object? is used here, as this is the datatype of this value

    showExceedMessage=false;//this message will be shown whenever, the user enters in more rows, than the database already has.
    //until the logic is checked, the showExceedMessage is false.
   
    //bool isflouride=false;
  //if(displayVal()!="Flouride Value") {

  List<String> flouridetimelist=[];//this represents a list of flouride timestamps
  List<String> flouridelist=[];//this represents a list of flouride values.
  
  theRows=[];//this sets theRows empty each time, as it needs to be empty for each adjustment of user input(as long as the value is not flouride related).
  

  //It is important for theRows to be empty, as otherwise, issues occurr when adding values.

  
  

  if(currData is Map) { //this is checking if the currentSnapshot's value(which is the entire database) is a map. 
  //This is checked to ensure conversion from database to myMap1 is possible.
      
      Map<String, dynamic> myMap1={};//this is the currentState of the map. This map is used as an intermediate transfer variable.
      //The map used later will be for filtering, and data processing in this function.

      currData.forEach((key, value) {//this for loop iterates through each key-value pair. This does the transferring of values.
        myMap1[key.toString()]=value;//this transfers over the original data to a new map(which will be used later in the implementation)
      }
      );

      //print(myMap1.length);
      //print(currentChoice2!.label);

      int entryCount=0;//this counter is used to determine whether or not the specific number of entries were traversed or not. and if statement will be made in the outerloop to check if it has exceeded the actual number of entries in the database.
      databaselength=0;//this variable is used for the function/purpose of ensuring that the database length is greater than or equal to the user inputted entry amount.
      String lastVal="";//this variable represents the latest timestamp in the database. A loop will later be used to determine this value
      

      errorMessage="";//in the case the user has exceeded the max value, an error message will be displayed

      //the following code has the purpose of generating an initalized database in its entirety.
      //It's overall logic is like this: it takes in the value of interest and the user inputted number of entries, 
      //and then based on those fields, it displays output. 
      //For example if the user inputted number of entries
      //exceeds or is equal to the database length, then only the database length of entries will be shown.

      //if it is less than the database length, then the number of user inputted entries will be shown
      //This provides an initial setup, before the user chooses to select time range values.

      //print("${currentChoice!.label} Cheers");
      
      myMap1.forEach((key,val) {//this iterates through the values that were transferred
      if(key!="Fluoride Data(ppm) added at " && key!="Fluoride Data(ppm) value ") {//this checks to ensure that flouride and its associated time is not being considered(as these already have exactly one value per key)
      //For flouride, there are not multiple properties for each key.
      //Flouride will be considered seperately. This if statement may be changed later.

      
      
      if(entryCount<numEntries) {//this only displays values if the Entrycounter is less than the number of entries(where number of entries is user input)
      //(less than bc entrycounter starts off being equal to 0.)
      
      String pH="";//this represents the string pH value of the specific key
      String limedisp="";//this represents the string limedispension value of the specific key
      String time="";//this represents the string time value of the specific key

      
      
      val.forEach((propertyKey, propertyVal) {//this iterates through the properties("pH","limedispension", and"TimeCreated") 
      //This value has 3 properties(pH, lime dispension, and time), and each property has its own value
      
      
        if(propertyKey=="pHvalue") {//if the property is pH, then this will be done
        pH=propertyVal.toString();//toString is used here, to ensure conversion is proper. propertyVal in this case is pH
        }

        if(propertyKey=="LimeDispensionRate") {//checks if the current property is lime dispension
        limedisp=propertyVal.toString();//sets the display value as the corresponding value of the limedispensionrate properly. propertyVal in this case is lime dispension.
        //print(limedisp);
        }

        if(propertyKey=="Created at") {//if the property is time, then this will be done
        time=propertyVal.toString();//toString is used here to ensure conversion is proper. propertyVal in this case is the corresponding time stamp
        
        }

      });

      setState(() {//setState is used here, to ensure that the changes of these rows will be reflected in the UI.
      //it is used specifically here, as this is after the child(the three properties) has been traversed through.


      String valtoDisplay="";//this resets valtodisplay as empty string on each runtime.
      if(displayVal()=="pH") {//this checks if the user choice is pH
        valtoDisplay=pH;//sets valtoDisplay to be pH
      }
      if(displayVal()=="Lime Dispension Rate") {//this checks if the user choice is lime dispension.
        valtoDisplay=limedisp;//sets valtoDisplay to limedisp
      }
        if(valtoDisplay!="") {//this check is used to ensure that only nonempty values are added to theRow. 
        //For example, if either the pH/lime dispension is empty, but the time is not, 
        //the row should still NOT be added(this is based on the time that the pH/lime dispension were added, it varies significantly). 
        //Earlier entries into the database varied from later ones.
        
        //the following algorithm will be used to remove the .values of the string.

        String newVal=adjustStringval(valtoDisplay);//this adjusts the string to ensure that it is properly formatted.

        theRows.add(DataRow(cells: [//this adds a row after going through that key-value pair
          DataCell(Text(newVal)),//prints the valtoDisplay value in the first column of the data table. Note this implementation works for pH/lime dispension. 
          DataCell(Text(time)),//prints the associated date/time in the second column of the data table.
        ]));
        //hasbeenAdded=true;
         
        }
        
      });

      
      }
      
      entryCount=theRows.length;//this represents the length of theRows list after adding associated values. 

      //This will be the indicator increasing entryCount, as this determines whether or not theRow has been adding stuff.
      //this is also used with respect to the outer if statement.
      }

      

  });




  databaselength=entryCount;//this represents the length of the database(it is adjusted for the user inputted number of entries logic which is in the loop)
  if(numEntries>databaselength){//if the number of user inputted entries is greater than the database length, then this error message will be displayed. 
  //On April 7th 2025, the database length is 5465 entries.
        //print("You asked for more entries than are possible for the associated value, only $databaselength entries are shown");
        //print(databaselength);
        errorMessage="You asked for more entries than are possible for the associated value,\nonly $databaselength entries are shown";
        showExceedMessage=true;//this means that the message will be displayed to the logic later.
  }

//the following loop is used to determine the last timestamp value
myMap1.forEach((key7, val7) {//similar to the loop above, this loops through each child, and its respective value(the value has 3 properties: pH, lime dispension, and timestamp)
  if(key7!="Fluoride Data(ppm) added at " && key7!="Fluoride Data(ppm) value ") {//this checks to ensure that flouride and its associated time is not being considered(as these already have exactly one value per key)
  //flouride is being checked here, as flouride has a different format.
  val7.forEach((key9, val9) {//this loops through the 3 associated values of the child: pH, lime dispension, and timestamp
    if(key9=="Created at") {//this checks if the key is Created at, indicating the associated value will be timestamp
      lastVal=val9.toString();//this iterates through all the keys/values, until the last String value represents the the last time value.
    }
  });
  }
});



//The above logic had the intention of initializing the data table.





//The logic below will be used for filtration.




List<String> allTime=[];//this list represents the set of all times within the specific time range

List<String> allVal=[];//this is a list that represents all of the pH values OR lime dispension values



//the following creates a list of values for the last minute
//if(currentChoice2!.label=="Last Minute") {//this logic is used to ensure that the user wants the last minute


int amount=0;//this counter represents the amount of times that there were in the time range duration

String firstVal="";//this represents the first String time value that is within the associated duration.


//lastVal=(theRows.last.cells.last as Text).data;//this represents the very last timestamp.

print(lastVal);//this is a testprint of the lastvalue





if(currentChoice2!.label=="Last Second" || currentChoice2!.label=="Last Minute" || currentChoice2!.label=="Last Hour" || currentChoice2!.label=="Last Day" || currentChoice2!.label=="Last Week"
) {//this checks to see if the label is one of the time related ones.
  


  //the above if statement is used, when filtration is used with time
  //When filtration is not used with time, there will be no entry time spacing: it will just show the first y entries of the entire database's x entries(where y<x)
  //In this case with time filtration, there will be an entry time spacing algorithm being used,
  
  theRows=[];//this resets the rows to be empty before the loop.
  //amount=0;


  myMap1.forEach((key,val) {//this iterates through the values that were transferred
      if(key!="Fluoride Data(ppm) added at " && key!="Fluoride Data(ppm) value ") {//this checks to ensure that flouride and its associated time is not being considered(as these already have exactly one value per key)
      

      String currtime="";//this represents the current time in the database(since the duration has elapsed for)
      String pH="";//this represents the pH value
      String limedisp="";//this represents the lime dispension value


      
      bool shouldAddVal=false;//this indicator is used to determine whether or not to add the pH/lime dispension along with its corresponding timestamp
      //this logic is triggered based on time duration being within a specific margin.
      
      val.forEach((propertyKey, propertyVal)     {//this loops through the individual keys in the database, and look for associated keys/values
      //val has 3 propertyVals: pH, lime dispension, and timestamp.
       

        if(propertyKey=="Created at") {//this checks if the indicator is "Created at". "Created at" is the indicator for time values.
          String actualString2 = lastVal.toString().replaceAll(RegExp(r'\s+'), ' ');//this normalizes the string to ensure there is only one space between each entry of the times. This is done to ensure that it is consistent with the dateformat
          //This represents the last time value in the database
          String actualString1 = propertyVal.toString().replaceAll(RegExp(r'\s+'), ' ');//this does the same as above. This is the currentString. This represents the currentTime in the database. This is reformatted to ensure that it is consistent with the dateformat

          DateTime time2=dateFormat.parse(actualString2);//this represents the very last time. dateFormat is used here, as the format of the time in firebase is different from usualy flutter time.
          DateTime time1=dateFormat.parse(actualString1);//this does the same thing above, but for the currentTime.
          //the DateFormat declaration can be found in the global variables list.          


          if(returninRange(time2, time1)) {//this checks to see whether or not the value is in the proper range. 
          //User input is used to determine the ranges.

          //if((time2.difference(time1)).inMinutes<=1) {
            
            currtime=propertyVal.toString();//this sets the currentime to be this value of the time
            
            if(amount==0) {//in the case the amount is 0, then this means that it is the first value within x time gap.
            //This also means that it should be the first value to be added.
              firstVal=currtime;//this means that this is going to be the value for firstVal. firstVal is the first time stamp for this duration 
            }

            allTime.add(currtime);//this adds the currentTime value(which is within the region to the list of the last minute)

            
            amount++;//this increments the amount, as now, the currentime has been found. This represents the total number of entries that are within this time range.


            shouldAddVal=true;//bc the time is in this region and it is within the entry timegap, it should be added(along with the associated pH and/or lime dispension value).
          }

          
        }
        
          if(propertyKey=="pHvalue") {//if the property is pH, then this will be done
          pH=propertyVal.toString();//toString is used here, to ensure conversion is proper
        }

          if(propertyKey=="LimeDispensionRate") {//checks if the current property is lime dispension
          limedisp=propertyVal.toString();//sets the display value as the corresponding value of the limedispensionrate properly.
          //print(limedisp);
        }
        
      });
      //print(shouldAddVal);
      if(shouldAddVal) {//this logic should only be triggered if the value shouldbe Added. if shouldAddVal==false, then this logic will NOT be triggered.
     

      setState(() {//setState is used here, to ensure that the changes of these rows will be reflected in the UI.
      //it is used specifically here, as this is after the child has been traversed through.
      

      String valtoDisplay="";//this resets valtodisplay as empty string on each runtime.
      if(displayVal()=="pH") {//this checks if the user choice is pH
        valtoDisplay=pH;//sets valtoDisplay to be pH
      }
      if(displayVal()=="Lime Dispension Rate") {//this checks if the user choice is lime dispension.
        valtoDisplay=limedisp;//sets valtoDisplay to limedisp
      }
      
      if(valtoDisplay!="") {//this check is used to ensure that only nonempty values are added to theRow. 
      String newVal2=adjustStringval(valtoDisplay);
      //If either the pH/lime dispension is empty, but the time is not, the row should still NOT be added(this is based on the time that the pH/lime dispension were added, it varies significantly).
        theRows.add(DataRow(cells: [//this adds a row after going through that key-value pair
          DataCell(Text(newVal2)),//prints the valtoDisplay value in the first column of the data table. Note this implementation works for pH/lime dispension. It evantually needs to be more generalized for flouride.
          DataCell(Text(currtime)),//prints the associated date/time in the second column of the data table.
        ]));
        //hasbeenAdded=true;
         //lastVal=time;//this obtains the last time value when choosing pH or choosing lime dispension.
        }

      //amount=theRows.length;//this sets amount to the value of theRows.length

      });


      }
      
      
      }
  });

  //databaselength=entryCount;//this represents the length of the database
  print(numEntries);//this is a test print of the user inputted number of entries
  print(amount);//this represents the total number of rows within the specific time duration.
  //print(allTime.length);

  if(numEntries>amount){//if the number of user inputted entries is greater than the amount of rows
  //The logic here should show all values of amount within that specific time duration


        errorMessage="You asked for more entries than are possible for the associated value\nfor the past ${returnErrorMessageTime()}, only $amount entries are shown";
        //this represents the error message to be displayed
        //There will be at most, that value of amount of stuff to be displayed
        showExceedMessage=true;//this means that the message will be displayed to the logic later.
        //print(allTime.length);

        int counter9=0;
        //in this case, it will print all associated time stamps for this within the last period of time.
       
  }

  if(numEntries<amount){//in the case the number of entries is less than the value of amount.
  //for this situation, a filtration algorithm will be used to space out the number of entries that the user inputs.

    //setState(() {
      //theRows=[];
    //});
    //theRows=[];
    String adjustlastVal=lastVal.toString().replaceAll(RegExp(r'\s+'), ' ');//this adjusts lastVal and ensures spaces are proper
    String adjustfirstVal=firstVal.toString().replaceAll(RegExp(r'\s+'), ' ');//this adjusts firstVal and ensures spaces are proper

    DateTime actlastVal=dateFormat.parse(adjustlastVal);//this converts the lastTime value to a DateTime object
    DateTime actfirstVal=dateFormat.parse(adjustfirstVal);//this converts the firstTime value to a DateTime object.

    double totalTimeGap=((actlastVal.difference(actfirstVal)).inMilliseconds).toDouble();//this obtains the difference between the very last value, and the first value within the time duration of interest.

    double gapbetweenEntry=(totalTimeGap)/(numEntries-1);//this value represents the IDEAL gap between each entry.
    //The loop that is below will essentially search for time values that provide timegaps somewhat close to this.

    //the next step, is to search for the value that is nearest to the firstVal+(gapBetweenEntry*i)
    //i starts off being 0, and should be incremented on each iteration.
    //int i=0;//i represents the incrementation variable
    


//print(uniqueEntries);
int uniqueEntries=1;//this represents the number of unique entries. Each cell will check if its timestamp is identical or different from the previous
//it is set as 1, as the very first set of cells are a uniqueEntry.
for(int i=0;i<theRows.length;i++) {//loops the rowsList
  if(i>=1) {
    if((theRows[i].cells[1].child as Text).data!=(theRows[i-1].cells[1].child as Text).data) {//this checks if the current cell's timestamp is different from the previous.
      //cells[1] represents the time stamp, .child is used to obtain the data, as Text type converts it, and .data is used to avoid any errors
      uniqueEntries++;
    }
  }
}

print(uniqueEntries);//this prints the number of unique entries
print("Hello");



    if(numEntries==1) {//if it is just 1 entry, meaning that differences can not be determined...
    //Then only the last row will be displayed.
      for(int i=theRows.length-2;i>=0;i--) {//this traverses backwards, and it does NOT remove theRows.length-1
        theRows.removeAt(i);
      }
      errorMessage="Because of this input, only the latest data value is shown";
      
      
    }




    //You must consider if user inputted number of entries is greater than the number of distinct time stamps, or if it is equal to 1.
    //now it is important to determine the number of unique timestamps.


/*    
    else if(numEntries>uniqueEntries){ //if the user inputted number of entries is greater than the number of unique entries, this causes a lot of issues.
    //in this case, you have to check for the number of entries being in between the amount of unique entries and the max number of entries
    //it will show the first y amount of entries(where y is less than the number amount).
    //For example, if there 8 unique timestamps, and the user enters in the number 9, there should be shown the first 9 entries of that time span.
    for(int i=theRows.length-1;i>=(numEntries);i--) {//i starts at the last element, and ends at numEntries
        theRows.removeAt(i);
    }
    errorMessage="In order to see even spacing of values for the last ${returnErrorMessageTime()}, \nyou must enter in a value less than or equal to the number of unique timestamps and greater than 1.\nThe number of unique timestamps is $uniqueEntries\nBecause of this input, only the first $numEntries values are shown";
  }

  */


    else//this is for the case when numEntries is <=uniqueEntries and greater than 1.
    {
    //errorMessage="The number of unique entries is: $uniqueEntries.";
    theRows=[];//this resets the rows to be empty. New data rows will be added in each iteration of this loop.
    List<String> wasused=[];//this represents a list of all string timestamps that have been added. This avoids repeats in the displayed data.

    for(int i=0;i<numEntries;i++) {//this traverses through the number of user entries.
      //print(allTime[i]);

      double targTime=(((actfirstVal.millisecondsSinceEpoch))+(i*gapbetweenEntry));
      //this determines the targettime(in milliseconds since epoch, by obtaining the first time in seconds since epoch +(iterator value*gapBetweenEntry))
      //This value is rounded primarily in order to convert to int.


      int minimumDifference=99999999999999;//this represents the variable called minimumDifference. It starts off as an arbitarily high number.
      //This is an indicator variable which is used to determine the smallest difference between times.

      String closestTime="";//this represents the time that was found which is closest to targTime

      
      myMap1.forEach((key10, val10) {
        if(key10!="Fluoride Data(ppm) added at " && key10!="Fluoride Data(ppm) value ") {//checks to ensure flouride is not considered, as flouride has a different data structure.
        val10.forEach((key11, val11) {
          if(key11=="Created at") {//checks to make sure only timevalues are considered.
            DateTime timeDate=dateFormat.parse(val11.toString().replaceAll(RegExp(r'\s+'), ' '));//this represents the current time of interest. .replaceAll is used to ensure format is consisten across all strings.
            int actualdiff=((timeDate.millisecondsSinceEpoch)-targTime).round().abs();//this determines the difference between the currentTime stamp's second value, and subtracts it from the other targettimestamp.
            if((actualdiff<minimumDifference) 
            && (wasused.isEmpty || (!wasused.contains(val11.toString()) && (timeDate.isAfter(dateFormat.parse(wasused.elementAt(wasused.length-1))))))
            
            ) {//this checks if the actual difference is less than the minimum difference. It also checks whether or not the list is empty(if this is the first time value being added to the list OR if the list does not contain this value AND this time value is after the previous used time value)
            //this: minimizes error(difference between desired time difference, and actual time difference), avoids repeats, and ensures the time is always going forwards.
            //These 3 parts are all important, to ensure the display is proper and smooth.


              minimumDifference=actualdiff;//this resets the value of actualdifference
              closestTime=val11.toString();//this sets closestTime to this value
              //print(actualdiff);
            }
          }
          //if(key11=="pHvalue" && val11==3.46) {
            //print()
          //}
          
        });
        
        }
      });


      //The following logic is to find the corresponding pH and/or lime dispension value with respect to the timestamp
      
      
      bool valofInterest=false;//val of interest is an indicator variable which is set based on whther or not the closest time stamp was found
      String pHfound="";//for that corresponding closest timestamp, pHfound represents the corresponding pH value
      String limedispfound="";//for that corresponding closest timestamp, pHfound represents the corresponding lime dispension value

      
      myMap1.forEach((key12, val12) {
        if(key12!="Fluoride Data(ppm) added at " && key12!="Fluoride Data(ppm) value ") {//checks to ensure flouride is not considered, as flouride has a different data structure.
        val12.forEach((key13, val13) {
          if(key13=="Created at") {//checks to make sure only timevalues are considered.
            if(val13==closestTime) {//if a match is found to closest time, then this will be added. This will be the last entry containing the same time as closest time
              valofInterest=true;
            }
            else {
              valofInterest=false;
            }
          }
          if(valofInterest) {
            if(key13=="pHvalue") {//if the property is pH, then this will be done
          pHfound=val13.toString();//toString is used here, to ensure conversion is proper
        }

          if(key13=="LimeDispensionRate") {//checks if the current property is lime dispension
          limedispfound=val13.toString();//sets the display value as the corresponding value of the limedispensionrate properly.
          //print(limedisp);
        }

          }
          
        });
        }
      });



      setState(() {//setState is used here, to ensure that the changes of these rows will be reflected in the UI.
      //it is used specifically here, as this is after the child has been traversed through.
      

      String valtoDisplay="";//this resets valtodisplay as empty string on each runtime.
      if(displayVal()=="pH") {//this checks if the user choice is pH
        valtoDisplay=pHfound;//sets valtoDisplay to be pH
      }
      if(displayVal()=="Lime Dispension Rate") {//this checks if the user choice is lime dispension.
        valtoDisplay=limedispfound;//sets valtoDisplay to limedisp
      }
      
      if(valtoDisplay!="") {//this check is used to ensure that only nonempty values are added to theRow. 
      String newVal3=adjustStringval(valtoDisplay);//this adjusts the string value to ensure it is properly formatted.

      //If either the pH/lime dispension is empty, but the time is not, the row should still NOT be added(this is based on the time that the pH/lime dispension were added, it varies significantly).

        theRows.add(DataRow(cells: [//this adds a row after going through that key-value pair
          DataCell(Text(newVal3)),//prints the valtoDisplay value in the first column of the data table. Note this implementation works for pH/lime dispension. It evantually needs to be more generalized for flouride.
          DataCell(Text(closestTime)),//prints the associated date/time in the second column of the data table.
        ]));
        //hasbeenAdded=true;
         //lastVal=time;//this obtains the last time value when choosing pH or choosing lime dispension.
        }

      //amount=theRows.length;//this sets amount to the value of theRows.length

      });



      
      wasused.add(closestTime);//this adds the closest time to the list of used timestamps. This will be used in the next iteration as a basis of iteration.


      print(wasused.elementAt(i));
    }

    //print(firstVal);
    //print(lastVal);
    //print(totalTimeGap);
  }


  

  //if numEntries==amount, then it simply behaves as norma

///}

  }


}



//filteroutMS();//filters out milliseconds based on user input
  }
//print(amount);

//print(lastVal);
//print(firstVal);


  

  });

}

@override
void dispose() {//destroys the current instance. This is done(similarly to the realtime graphs) to avoid any memory leaks.
  super.dispose();//this is done to dispose of the instance made
}



  @override
  Widget build(BuildContext context) {//widget build line identical to home screen, except, there is no need for the super.context(), as it does not need to override this. This is because this class is purely used for toggling/switching between tabs, and instantitating tab labels.
  super.build(context); //this is used along side the above wantkeepalive to ensure the state is maintained when switching tabs.
  return Scaffold //this is used to show different layout options. This is going to be intended for use for the tabs.
  (
    //appBar: AppBar //this instantiates the AppBar on the top, this was originally in the homepage class, but now this will be here for organization purposes.
    //(

    //)

    body: 
    /*
    Positioned(left: 6, 
    child:
*/


    Row(children: <Widget>[ //Row is used here(at least initially) for the testing purposes. Row means horizantal values
    
    //Padding(padding:EdgeInsets.only(left: 0.4), child:
    Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[//this column is for the Flouride Input Field and its associated title
      Padding(padding: EdgeInsets.only(left:40, top: 40, bottom: 10), child:Text("Enter your flouride value(ppm) here(be sure to press Enter): ",style: TextStyle(fontSize: 17, color: Colors.purple,),)),//this represents the title. Padding is placed to ensure that it is placed nicely into the UI
      SizedBox( //this box will be used to limit size of the text field
  width:230, //the textfield width is 230
  //child:Padding(padding: EdgeInsets.only(left:40,),//this inserts some padding from the left edge of the webapp for the textfield
  child:TextField(
    controller: theController, //textinput controller(may not be used, will see)
    decoration: InputDecoration( //Represents the label to be shown in the input field
      border: OutlineInputBorder(), //rounded rectangle border
      labelText: returnLabel(), //this is conditioned on the returnLabel function
    ),
    maxLength: 9, //max amount of characters for flouride input
    onSubmitted: readInandWriteFlouride, //this is conditioned on the flouride sending function(the user has to press submit for the state to update)
    

  ),

  //)
  ),

    
    Padding(padding: EdgeInsets.only(left:32.5, top: 10, bottom: 10), child:Text("Choose the value that you would like to observe in the Data Table: ",style: TextStyle(fontSize: 17, color: Colors.purple),)),//this represents the title. Padding is placed to ensure that it is placed nicely into the UI
    SizedBox(width:230, //similar to the first textbox, there is a limited width to be used.
      child:
      DropdownMenu<SelectedVal>(//the second child in this column, will be a dropdown menu of the value choice
        requestFocusOnTap: true,//when the user hovers over a value in the dropdown menu list, there is more focus to it. This is an aesthetic choice
        label:Text("Choose a value"),//this represents the internal label of the dropdown menu
        onSelected: changeChoice,//when a value in the dropdown menu is selected, the previous value is changed to the selectedvalue. This calls the changeChoice
        dropdownMenuEntries: //insert dropdown menu stuff here.
        SelectedVal.listEntries,//listEntries was declared in the enum as a map. This is the entries from the dropdown menu
        expandedInsets: EdgeInsets.only(),//this creates a left offset effectively increasing length of the DropDown Menu. This ensures that Lime Dispension Rate doesn't cutoff its end
      )
      
          

      )

      //this represents the user inputted number of table rows.
      ,Padding(padding: EdgeInsets.only(left:20, top: 25, bottom: 10), child:Text("Enter the amount of entries you would like to see here(be sure to press Enter): ",style: TextStyle(fontSize: 17, color: Colors.purple),)),//this represents the title. Padding is placed to ensure that it is placed nicely into the UI
      //Note: in the case the amount of entries is not possible, an error message will popup explaining why its not. It will also state how many entries were ACTUALLY shown.
      SizedBox( //this box will be used to limit size of the text field
  width:230, //the textfield width is 230
  //child:Padding(padding: EdgeInsets.only(left:40,),//this inserts some padding from the left edge of the webapp for the textfield
  child:TextField(
    controller: theController2, //textinput controller(may not be used, will see)
    decoration: InputDecoration( //Represents the label to be shown in the input field
      border: OutlineInputBorder(), //rounded rectangle border
      labelText: returnLabel2(), //this returns the number of entries
    ),
    maxLength: 5, //max amount of characters for the number of entries is 5.
    onSubmitted: numTableEntries, //this is conditioned on the flouride sending function(the user has to press submit for the state to update)
    

  ),

  //)
  ),


    Padding(padding: EdgeInsets.only(left:40, top: 10, bottom: 10), child:Text("Choose how far back you would like to see the values: ",style: TextStyle(fontSize: 17, color: Colors.purple),)),//this represents the title. Padding is placed to ensure that it is placed nicely into the UI
    SizedBox(width:230, 
      child:
      DropdownMenu<TimeVal>(//the fourth child in this column, will be a dropdown menu of the time span choice.
      //The choices: one second ago, one minute ago, one hour ago, one day ago, and one week ago.

        requestFocusOnTap: true,//when the user hovers over a value in the dropdown menu list, there is more focus to it. This is an aesthetic choice
        label:Text("Choose a time span"),//this represents the internal label of the dropdown menu
        onSelected: changeChoice2,//when a value in the dropdown menu is selected, the previous value is changed to the selectedvalue
        dropdownMenuEntries: //insert dropdown menu stuff here.
        TimeVal.listEntries2,//listEntries2 was declared in the enum as a map.
        expandedInsets: EdgeInsets.only(),//this creates a left offset effectively increasing length of the DropDown Menu. This ensures values do not overgo the length of the textbox.
      )
      
          

      ),




      //The TimeStamp precision is a user choice of the amount of decimal places they want to see.
      //Padding is placed to ensure that it is properly working.
    Padding(padding: EdgeInsets.only(left:35, top: 25, bottom: 0, right: 0), child:Text("Timestamp Precision in Milliseconds?",style: TextStyle(fontSize: 17, color: Colors.purple),)),//this represents the title. Padding is placed to ensure that it is placed nicely into the UI
    SizedBox(width:230, //this provides the width of the checkbox.
      child:
      
      Checkbox(activeColor: Colors.purple,checkColor: Colors.white, value: checkBool, onChanged: checkBoxFunc)
      //Checkbox active color is purple when checked, the check is white, the value is checkBool(as this is the value that determines the state of the checkbox), onChanged changes the states of the boolean variable(checkbool).
      
          

      ),


      Text(errorMessage, style: TextStyle(color: Colors.red))//this represents the display of the error message.
      //more logic error messages will go here as needed
      ],

    ),
    //),
    //this represents the beginning of the actual table
    
    SingleChildScrollView(//singlechild scroll view is used here to ensure that the datatable will be scrollable.
      child: 
      DataTableTheme(data: DataTableThemeData(dataRowMinHeight: 75, dataRowMaxHeight: 75), //this is used to adjust height of the datarow.
      child: DataTable(
      columns: [
        DataColumn(label: Text("Value: ${displayVal()}")),//the first column is the dataValue
        DataColumn(label: Text("Date/Time of Measurement: ")),//the second column is the TimeStamp
      ],
      
      rows:(theRows)//this is from the Rows list.
      //[
        //DataRow(cells: [
          //DataCell(Text("90.0")),
          //DataCell(Text("April 1st 2004"))
        //])
      //]

    ))

      
    )
    
    
    //this text is used as the TablePage Instructions.
    ,Padding(padding: EdgeInsets.only(left: 15, top: 6), child: SizedBox(height: 450, child: Text("Tables Page Instructions:\n\nIf you enter in all settings except for time\n(or if you enter Entire Database), the first x user \ninputted entries will be shown.\n\nIf you choose a time span, and you just put 1 entry, \nit will show the latest time value.\n\nIf you use a time value,\nand you enter in a number of entries\nwhich doesn't exceed the amount of entries\nfor the timespan, the entries\nwill be evenly spaced.\n\nDateTime Format:\nDay Month Date Hours:Minutes:Seconds.Milliseconds Year")))
    
    ],)
  //)
    

  );

  }



}



























//The following begins the code implementation for the TopTabs class, this is part of the user interface to switch between different tabs
//This tab class is dynamic, as the state should always be changing of its children: the different pages..

class TopTabs extends StatefulWidget { //creates a new instance state
  const TopTabs({super.key}); //constructor(declared identically to the other 3 classes)
  //final List<FlSpot> pausedData2;
  @override //ensures that a new tab state is created with new changes
  State<TopTabs> createState() => _TopTabsState(); //similar to the home page, and other pages soon to be added, this will be used to change the tabs
}
class _TopTabsState extends State<TopTabs> {//this extends the statefulwidget, to ensure changes in state are possible.

//this function is used to signout the user. The tab has the way for the user to signout.
  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();//this signs the user out from firebase.
    Navigator.pushReplacement( //pushReplacement means that it returns back to the sign-in page. Replacement is used here, as it force resets to the original state(and pop was having issues keeping the password on file, while push was having lag issues.)
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const MyApp())//goes back to the sign-in screen startinng point. Starting point force restarts to the beginning.
            );
  }


  @override
  Widget build(BuildContext context) {//widget build line identical to home screen, except, there is no need for the super.context(), as it does not need to override this. This is because this class is purely used for toggling/switching between tabs, and instantitating tab labels.
  return Scaffold //this is used to show different layout options. This is going to be intended for use for the tabs.
  (
    appBar: AppBar //this instantiates the AppBar on the top, this was originally in the homepage class, but now this will be here for organization purposes.
    (toolbarHeight: 35,//this adjusts the height of the appbar
      bottom: const TabBar(//this goes on the bottom of the AppBar
      tabs:[//this instantiates a list of 3 tabs. These tabs are on the bottom of the appbar.
            //Icon is a display symbol used to represent the purpose of something.
        Tab(icon: Icon(Icons.home)), //this is the tab icon on the top left, it represents the home page
        Tab(icon: Icon(Icons.table_chart)), //represents the icon of a chart. This will be table page
        //Tab(icon: Icon(Icons.directions_bike))//need to find other icons. May not be here: WILL SEE.
      ],



    ),
    title: const Text('Want to sign-out? Click this button.'), //this is the text for app bar(temporary for now.)

    leading: IconButton(//leading means at the beginning
      onPressed:signout//this function is used to sign the user out.
      
      , icon: Icon(Icons.logout_rounded)),//this is the sign-out button. This signout button can be used to signout of the webapp.

    ),
    body: 
    PreferredSize(preferredSize: Size.fromHeight(18),//this is used to adjust the height of the tabs
    child:TabBarView(//tab bar view is used to show what is going to be shown when pressing the tab. body is used here to effectively specificy what content will be in the scaffold(body of the tab).
      children: [//tab values
        //Icon(Icons.directions_car),
        const MyHomePage(title: 'Cheers',), //when the home tab is clicked, the home page is displayed. Cheers is a placeholder for now, as there needs to be a title in the homepage.
        const TablePage(title2: 'Mate'),//when the tables tab is clicked, the table page is displayed. It will show the body of the tables tab.
        //const Icon(Icons.directions_bike)
      ]

    )
    )
  );

  }



}















































//User Signin Overview
//There is going to be a signin page for the user. This signin page will offer these options: email, password, forget password, or make new account
//Make a bool that says if the value is correct, navigate to the home page of the webapp
//if the value is incorrect, print out invalid something.
//it has been decided to use firebase_auth. This primarily for cutomization/creativity control

//The Signinpage will be the default page for the web application. There will be options such as: forget password, and first time registration
//Navigation will be used to navigate to those respective pages.



class SignInScreen1 extends StatefulWidget { //creates a new instance state. This state will be SignInScreen
  const SignInScreen1({super.key}); //constructor(declared identically to the other 3 classes)
  //final List<FlSpot> pausedData2;
  @override 
  State<SignInScreen1> createState() => _SignInScreenState(); //similar to the home page, and other pages soon to be added, this will be used for the sign in screen
}



class _SignInScreenState extends State<SignInScreen1> {//this extends the statefulwidget, to ensure changes in state are possible.


  String currentEmail="";//represents the email that the user has inputted
  String currentPassword="";//represents the password that the user has inputted


  void adjustEmail(String newEmail) {//this is used to dynamically adjust the value of the original email. This is a setter method based on userinputted email
    setState(() {
      currentEmail=newEmail;//previous email is now new email
    });
  }

  void adjustPassword(String newPassword) {//this is used to dynamically adjust the value of the original password. This is a setter method based on userinputted password
    setState(() {
      currentPassword=newPassword;//previous password is now newpassword
    });
  }

  bool signinSuccessful=false;//this is an indicator variable used to detect whether or not the sign-in went through
  String message="";//this message is the message displayed based on the incorrect user input criteria

  final TextEditingController theController2 = TextEditingController(); //this controls the editing of the email. This may be deleted
  final TextEditingController theController3 = TextEditingController(); //this controls the editing of the password. This may be deleted


  Future<void> signin() async {//this is used to connect the usersignin with firebase(firebase integration of Sign-In authentication)
    
    setState(() {
    signinSuccessful=false;//until the signin is checked, it will be set to false.
    message="";//no message will be displayed yet
    });
    
  try {//seeing if there are any errors by checking this info
  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(//its awaiting to see if firebase has this information already stored
    email: currentEmail,//does firebase already have the currentEmail?
    password: currentPassword//does firebase already have the currentPassword?
  );

  setState(() {
    signinSuccessful=true;//bc the firebase matched the record to a current record, the signin is successful
    message="";//there is no incorrect message bc the sign-in was successful.
  });

  theController2.clear();//the text field(email) will be cleared after signing in.
  theController3.clear();//the text field(password) will be cleared after signing in.
  //Both of these are cleared, as a new page will be navigated to.  

  Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const DefaultTabController(length: 2, child: TopTabs())), //this means it wants to go to the next page, which is going to be the tab controller(aka, the parts of the app that is not authentication).
            //The TabController controls the tabs, which controls the display of the different pages.
  );

  

  
  

} on FirebaseAuthException catch (e) {//if firebase does not have both of them(the username and password), this will be thrown.
  String errorMessage="";//this string will be used to set the current message to the error message at the end(using setState)
  print(e.code);//testing console output

  

  if(e.code=='invalid-email') {//this checks if the error is being thrown based on an invalid email
    errorMessage='The email you entered does not follow the required format: @provider.com. Please try again';
  }
  else if(e.code=='invalid-credential') {//invalid-credential is thrown whenever the email is in proper format(but still not found in Firebase), and when the password is not found in Firebase
    errorMessage='Incorrect Email or Password! Please try again!';
  }
  else if(e.code=='missing-password') {//if the password field is blank, it will call for this error.
    errorMessage='Missing Password. Please enter your password';
  }
  else if(e.code=='too-many-requests') {//if the user spam presses the signin button
    errorMessage="Too many requests! Please wait a little until next sign-in";
  }


  setState(() {
    signinSuccessful=false;//bc the firebase did not match the record to a current record, the signin is not successful
    message=errorMessage;//the message now contains the value of errorMessage
  });
  
  //});
  
}
}

//Google handles the error catching within its framework.
Future<void> signinwithGoogle() async {//this function is used to signin with google
  GoogleAuthProvider myProvider=GoogleAuthProvider();//creates a new instance of a google auth provider
  await FirebaseAuth.instance.signInWithPopup(myProvider);//Google takes care of invalid logic already with its popup
  //after successful sign-in, the tab controller will be nevigated to. 
    Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const DefaultTabController(length: 2, child: TopTabs())), //this means it wants to go to the next page, which is going to be the tab controller(aka, the parts of the app that is not authentication).
  );
}

bool dontshowPass=true;//this is an indicator used whether or not to show the hidden password. If it is set to true, then that means the password will not be shown.

  @override
  Widget build(BuildContext context) {//widget build line identical to home screen, except no need for super.build, as the state of this class doesn't need to be preserved
  return Scaffold //this is used to show the UI of the SignInScreen
  (

    body: 
    Column//columns run vertically
    (mainAxisAlignment: MainAxisAlignment.center, //ensures both of the text fields are in the center of the screen
    children:[
      Text("Sign-In Page", style: TextStyle(fontSize:30, color: Colors.purple ),) , //SigninpageText
      
      Text("\nDon't have an account? Sign-Up here: "),//Gives information on how to signup/make an account.
      ElevatedButton(//this is a prompt to the next screen
        child: Text("Sign-Up"),
        onPressed: () {
          theController2.clear();//ensures text field is cleared when going to other screen
          theController3.clear();//ensures text field is cleared when going to other screen.
          Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const SignUpScreen()), //this means it wants to go to the next page, which is going to be the signupScreen.
  );

        }) 

      ,Text("\nEnter Email Here:",),//this text needs to be realigned to be the left....this needs to be edited later during the aesthetics process.
      Padding(padding: EdgeInsets.only(top:20, left: 40, right: 40, bottom: 20), //the padding allocates space of 40 to the left and right and 20 to the bottom for this widget specifically.
      
      //sized box is used here, to force limit the length of the textfield for aesthetics purposes.
      child:SizedBox(width: 270, child: TextField(controller: theController2, decoration:InputDecoration(
        //creates a curved rectangle border
        border:OutlineInputBorder(),
        //Email is the label inside the textbox
        labelText: "Email", 
        
      )
      ,
      
      onChanged: adjustEmail, //if the text changes, adjust the email. this ensures that the very last change will be the value of the email. 
      
      )
      )
      //)
      ),
      //),
      Text("Enter Password Here:",),//identical comments/issues as username.
      Padding(padding: EdgeInsets.only(top:20, left: 40, right: 40, bottom: 10), child: Center(child:SizedBox(width: 270, child: TextField(controller: theController3, decoration:InputDecoration(
        border:OutlineInputBorder(),//rounded rectangular border
        labelText: "Password", //this represents the background text in the textbox.
        suffixIcon: IconButton(//this icon shows the symbol at the end of the text field(suffix)
        icon: Icon(dontshowPass ?  Icons.visibility_outlined : Icons.visibility_off_outlined)//when the password is not shown, the icon will be open eye. When the password is shown, the icon will be eye with cross through it.
        //Clicking the icon, triggers changes in state.
      ,onPressed: () {
        if(dontshowPass==false) {//if not showing the password was previously false, it should now be changed to true
          setState(() {
            dontshowPass=true;//the password is now hidden
          });
        }//if not showing the password was previously true, it should now be changed to false. This has to do with clicking the icon
        else {
          setState(() {
            dontshowPass=false;//the password is now shown
          });
        }
      }
      )
        
      )
      ,
      onChanged: adjustPassword //if the text changes, adjust the password. this ensures that the very last change will be the value of the password
      //onEditingComplete: ,
      //onSubmitted: adjustPassword
      //obscureText: ,
      ,obscureText:dontshowPass, //not showing the password depends on the dontshowPass variable(when dontshowPass=true, the password will be hidden)
      )

      )
      )
      //)
      ),
      Padding(padding: EdgeInsets.only(bottom: 10), child:
      ElevatedButton(//this is a prompt for signing in
        onPressed: 
            signin//this calls the signinfunction, there is no opening parentheses and brackets near onPressed, as this is a void function to be called.
        
        ,child: Text("Sign-In"),),
      ), //Padding is placed on the bottom of this, to ensure enough space between this and above button.
        

        ElevatedButton(//this is a prompt fir googlesign-in
        
        onPressed: signinwithGoogle, style:ElevatedButton.styleFrom(backgroundColor: Colors.green),//this sets the background color of the button as green, and the text on it as white.
        child: Text("Sign-In With Google", style:TextStyle(color: Colors.white)),//the button is called signin with google
        

  

      ),


      Text("\nForget your password? You can reset your password here: "),//Gives information on how to reset password.
      ElevatedButton(//this is a prompt to the next screen
        child: Text("Reset Password"),
        onPressed: () {
          //Logic for reset password goes here.
          Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const ResetPasswordScreen1()), //this means it wants to go to the next page, which is going to be the resetPasswordScreen.
  );
        }), 
        //Text("\n$signinSuccessful") //it prints out the state of the siginin if invalid. Invalid message prints need to be working soon.
        Text("\n$message", style:TextStyle(color: Colors.red))//displays the message
      //this prompt is setting up a button called the signup button

    ]
    

    )


      //]
      //)
  );

  }
}

















class SignUpScreen extends StatefulWidget { //creates a new instance state
  const SignUpScreen({super.key}); //constructor(declared identically to the other 3 classes)
  //final List<FlSpot> pausedData2;
  @override //ensures that a new tab state is created with new changes
  State<SignUpScreen> createState() => _SignUpScreenState(); //similar to the home page, and other pages soon to be added, but this will be used for the signup screen
}



class _SignUpScreenState extends State<SignUpScreen> {//this extends the statefulwidget, to ensure changes in state are possible(main changes in state will be text changes, and text deletion upon exiting).

  String currentEmail="";//represents the email that the user has inputted
  String currentPassword="";//represents the password that the user has inputted
  String currentPassword2="";//represents the re-entered(verified) password.

  bool signupSuccessful=false;//this is an indicator variable used to detect whether or not the sign-up went through
  String message="";//this message is the message displayed based on the incorrect value criteria

  final TextEditingController theController2 = TextEditingController(); //this controls the editing of the email. This may be deleted
  final TextEditingController theController3 = TextEditingController(); //this controls the editing of the password. This may be deleted
  final TextEditingController theController4 = TextEditingController(); //this controls the editing of the verified password. This may be deleted
  
  bool indicator=false;//this indicator is used for checking if the second field is entered before the first. This needs to be checked, before even clicking sign-in.
  
  User? currentAccount2;//this represents a filler variable used to detect whether or not the user has returned back to the sign-in screen(account setup is successful)

  void adjustEmail(String newEmail) {//this is used to dynamically adjust the value of the original email. This is a setter method based on userinputted email
    setState(() {
      currentEmail=newEmail;//previous email is now newemail
    });
  }

  void adjustPassword(String newPassword) {//this is used to dynamically adjust the value of the original password. This is a setter method based on userinputted password
    setState(() {
      currentPassword=newPassword;//previous password is now newpassword
    });

    if(currentPassword!="") {
    setState(() {
      message="";//once something is entered for the first password, the message for entering the first before second goes away.
    });

  }
  }


  void adjustPassword2(String newPassword2) {//this is used to dynamically adjust the value of the password for verification purposes. This is a setter method based on userinputted password
    //ensurefirstbeforesecond;
    indicator=false;//this is set to false each time the password2 is adjusted, so it can be checked again. This indicator will be used, to check if the verify field is being edited before the first password field.
    //else{
    setState(() {
      currentPassword2=newPassword2;//previous verified password is now newpassword2
    });
    //}
    //ensurefirstbeforesecond;

    if(currentPassword2!="" && currentPassword=="") {//if the user attempts to edit the re-entered password, before the first password
      theController4.clear(); //clears the value in textfield3(verified password)
      setState(() {
        //signupSuccessful=false;//sets signupsuccessful to be false
        message="Please enter your password, then only re-verify it";//ensures normal password is entered first, then verified one will be entered
        indicator=true;//does not return anything for password equality. This indicator is used as a way of checking if the second password is entered before the first
      });
  }

  }

  //bool passwordsnull = currentPassword=="" && currentPassword2=="";//

  String returnPasswordEquality() {//this function is used to show whether or not both passwords are equal. This changes in Realtime
    if((currentPassword=="" && currentPassword2=="") ||indicator) { //if both variables are empty, or if the second password is entered before the first, do not return a message for output
      return "";//does not return a message for output purposes
    }
    if(currentPassword!=currentPassword2) {//if the passwords do not match, it returns this statement in realtime
      return "Warning!: Passwords do not match";
    }
    return "Passwords match";//if the passwords match, it returns this statement
  }



  //Signup screen logic: if the email has already been in the system, prompt the user to signin or add a forget password option.
  Future<void> signup() async {//this is used to connect the usersignup with firebase(firebase integration of authentication)

    setState(() {
    signupSuccessful=false;//until the signup is checked, it will be set to false.
    message="";//no message will be displayed yet
    });

    
  //}


  try {
    //an if statement is placed here, to ensure that both passwords do in fact match. Only then, will this create an instance with firebase
  if(returnPasswordEquality()=="Passwords match") {
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(//its awaiting for firebase to attempt to create a record of this username and its associated password
    email: currentEmail,//does firebase already have the currentEmail?
    password: currentPassword//does firebase already have the currentPassword?
  );
  //}

  


  final currentAccount=FirebaseAuth.instance.currentUser;//This creates an instance of the currentUser. It is important to note that this is only created after the user successfulyy created an account.
  
  final actionCodeSettings = ActionCodeSettings(//represents what to be done with the email for verification
  url: "http://www.SamsungProject.com/verify?email=${currentAccount?.email}", //? is used here as it is unknown whether or not the current user is null. This link is added to firebase as authorized providers to ensure no errors occur when sending it.
  handleCodeInApp: true
  
  
);


await currentAccount?.sendEmailVerification(actionCodeSettings);//this sends an email verification with the code settings as the parameter.



//Figure out some way to open back up the webapp from the email.
setState(() {
    signupSuccessful=true;//bc the firebase was able to create an account, the signup is successful
    message="Account successfully created. Please open verification email to finalize account";//there is no incorrect message bc the sign-in was successful. This is an open verification email message.
    
});


}



  else if(returnPasswordEquality()=="Warning!: Passwords do not match")
  {//this is the situation when both passwords do not equal each other, nor, do not both equal to empty characters
    setState(() {
    signupSuccessful=false;//this is set as false, as this means that the passwords do not match, nor are both empty
    message="Please make sure the passwords match. Sign-Up occurs only when both passwords match.";//Because the passwords do not match, sign up is not successful.
  });
  }

  else //if neither password has been entered in yet
  {
    setState(() {
    message="Please enter, and re-verify your password";//if the user enters both passwords as blank, then there will be no output.
    signupSuccessful=false;//this is set as false, as this means that both passwords do match, however, do not actually exist.
  });
  }

  
  

} on FirebaseAuthException catch (e) {//if firebase does not have both of them(the username and password) this will be thrown. This catches errors from the if statements from above

  String errorMessage="";//this string will be used to set the current message to the error message at the end(using setState)
  //setState(() {//setState is used to ensure that these values are dynamically shown on screen.
  print(e.code);//testing for console output

  
  if(e.code=='invalid-email') {//this checks if the error is being thrown based on an invalid email
    errorMessage='The email you entered does not follow the required format: @provider.com, please try again';
  }

  else if(e.code=='missing-email') {//this checks if the email is missing
    errorMessage='Please be sure to enter your email';
  }

  else if(e.code == 'email-already-in-use') {//the email has already been in use. 
  //You want to prompt the user for forget password here(this is where forget password will go.) This logic for forget password is accomplished by a visibility function in this widget's build
      errorMessage='The account already exists for that email';
  }

  else if (e.code == 'weak-password' || e.code=='password-does-not-meet-requirements') {//the password was weak.
      errorMessage='Your password is too weak. Please be sure to review the password requirements.';
    //});
  } 


  setState(() {
    signupSuccessful=false;//bc the firebase did not match the record to a current record, the signup is not successful
    message=errorMessage;//the message now contains the value of errorMessage
  });
  
  //});
}
}


//These variables follow an identical logic to the ones in the signinscreen page logic.
bool dontshowPass=true;//this is an indicator used to show the state of whether or not the password should be shown. 
//When dontshowPass is true, the password should not be shown, when it is false, the password should be shown. 
//The eye icons on the right hand side help to toggle this logic.
bool dontshowPass2=true;//same as dontshowPass, but this is for the verified password


  @override
  Widget build(BuildContext context) {//widget build line identical to home screen, except, there is no need for the super.context(), as it does not need to override this.
  
  bool resetPassforSignUp=message=="The account already exists for that email";//this indicator is a way of determeining whether or not the reset password option button should be there.
  
  return Scaffold //this is used to show different layout options. This is going to be intended for use for the signuppage.
  (
    body: 
    //Padding(padding: EdgeInsets.all(40), 
    Column//columns run vertically
    (mainAxisAlignment: MainAxisAlignment.center, //ensures both of the text fields are in the center of the screen
    children:[
       

      Text("Sign-Up Page", style: TextStyle(fontSize:30, color: Colors.purple )), //this represents the SignupPage label

    Text("\nAlready have an account? Sign-In here: "),//Gives information on how to signin/make an account.
      ElevatedButton(//this is a prompt to the next screen
        child: Text("Sign-In"),//the button is called signin
        onPressed: () {
          Navigator.push( //pop means go to back to the signinpage
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const SignInScreen1()), //this means it wants to go to the next page, which is going to be the signinScreen.
  );
  })

      ,Text("\nEnter Email Here:",),//this text needs to be realigned to be the left....this needs to be edited later during the aesthetics process.

      Padding(padding: EdgeInsets.only(top:10,left: 40, right: 40, bottom: 20), //the padding allocated space of 40 to the left and right and 10 to the bottom and top for this widget specifically.
      
      //sized box is used here, to force limit the length of the textfield for aesthetics purposes.
      child:SizedBox(width: 270, child: TextField(controller: theController2, decoration:InputDecoration(
        //creates a curved rectangle border
        border:OutlineInputBorder(),
        //Email is the label inside the textbox
        labelText: "Email", 
        
      )
      ,
      
      onChanged: adjustEmail, //if the text changes, adjust the email. this ensures that the very last change will be the value of the email. This logic may be adjusted when testing for functionality, will see.
      
      )
      )
      //)
      ),
      //Text(currentEmail),
      //),
      Text("Enter Password Here:",),//identical comments/issues as username.
      Padding(padding: EdgeInsets.only(top:10, left: 40, right: 40, bottom: 20), child: Center(child:SizedBox(width: 270, child: TextField(controller: theController3,decoration:InputDecoration(
        border:OutlineInputBorder(),
        labelText: "Password", //consider making some hiding password implementation here.
      suffixIcon: IconButton(//this icon shows the symbol at the end of the text field(suffix)
        icon: Icon(dontshowPass ?  Icons.visibility_outlined : Icons.visibility_off_outlined)////when the password is not shown, the icon will be open eye. When the password is shown, the icon will be eye with cross through it.
        //Clicking the icon, triggers changes in state.
      ,onPressed: () {
        if(dontshowPass==false) {//if not showing the password was previously false, it should now be changed to true
          setState(() {
            dontshowPass=true;
          });
        }//if not showing the password was previously true, it should now be changed to false(the password should be shown).
        else {
          setState(() {
            dontshowPass=false;
          });
        }
      }
      )
        
      )
      ,
      onChanged: adjustPassword //if the text changes, adjust the password. this ensures that the very last change will be the value of the password
      
      
      ,obscureText:dontshowPass,//when dontshowpass is true, the text becomes obscure.
      )
      )
      )
      //)
      ),

      Text("Verify Your Password Here:",),
      Padding(padding: EdgeInsets.only(top:10, left: 40, right: 40, bottom: 10), child: Center(child:SizedBox(width: 270, child: TextField(controller: theController4, decoration:InputDecoration(
        border:OutlineInputBorder(),
        labelText: "Re-Enter Password", //consider making some hiding password implementation here(this will be for later).
        suffixIcon: IconButton(//this icon shows the symbol at the end of the text field(suffix)
        icon: Icon(dontshowPass2 ?  Icons.visibility_outlined : Icons.visibility_off_outlined)////when the password is not shown, the icon will be open eye. When the password is shown, the icon will be eye with cross through it.
        //Clicking the icon, triggers changes in state.
        //the ? is used to toggle between true and false logic. when dontshowPass2 is true it displays the first icon. When it is false, it displays the second icon.
      ,onPressed: () {
        if(dontshowPass2==false) {//if not showing the password was previously false, it should now be changed to true
          setState(() {
            dontshowPass2=true;
          });
        }//if not showing the password was previously true, it should now be changed to false(the password should be shown).
        else {
          setState(() {
            dontshowPass2=false;
          });
        }
      }
      )
      )
      ,
      onChanged: adjustPassword2//this represents the password of the second field(for verification purposes.)
      

      ,obscureText:dontshowPass2,)
      )
      )
      //)
      ),
      Text(returnPasswordEquality()), //the text output shows if both passwords match or not.
      ElevatedButton(//this is a prompt for signing up
        //in order to click the signup, both passwords must be equivalent.
        onPressed: signup, child: Text("Sign-Up"),//calls the signup function, and the button is called signup.
        ),
      Text("$message", style:(TextStyle(color:Colors.red)))//this prints the error message 
      //this prompt is setting up a button called the signup button
      ,//put boolean conditional of returning back to sign in screen here.
      //currentAccount2!.emailVerified ? Navigator.push( //push means go to other page
            //context, //the context is the build context
            //MaterialPageRoute(builder: (context) => const ResetPasswordScreen1()), //this means it wants to go to the next page, which is going to be the resetpasswordScreen.
  //) : null,


      //Visibility is a widget in Flutter that either shows the child or not, based on a condition
      //In this case, if the user already exists in the system(their email already exists), this will provide the user to navigate to the reset password page from the sign-up page
      //put this logic here.
      Visibility(visible: resetPassforSignUp, child:Text("\nIf you forgot your password, please click this button:", style:TextStyle(color:Colors.green))),//this is shown only when the error from finding an identical user account is found.
      Visibility(visible: resetPassforSignUp, child:ElevatedButton(//this is a prompt to the next screen
        child: Text("Reset Password"),
        onPressed: () {
          theController2.clear();//ensures email text field is cleared when going to other screen
          theController3.clear();//ensures password text field is cleared when going to other screen.
          theController4.clear();//ensures verify password text field is cleared when going to other screen.
          Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const ResetPasswordScreen1()), //this means it wants to go to the next page, which is going to be the resetpasswordScreen.
  );

        }) ),
        Text("\nPassword Requirements:", style:(TextStyle(color:Colors.purple, decoration: TextDecoration.underline))),//This creates a title for underlined text
      Text("Be at least 8 characters long.\nHave at least one uppercase letter.\nHave at least one lowercase letter.\nHave at least one special character.\nHave at least one number."), //these are the password requirements that have been configured in firebase
      

      

      
    ]


    )


      //]
      //)
  );

  }
}































class ResetPasswordScreen1 extends StatefulWidget { //creates a new instance state
  const ResetPasswordScreen1({super.key}); //constructor(declared identically to the other 3 classes)
  //final List<FlSpot> pausedData2;
  @override //ensures that a new tab state is created with new changes
  State<ResetPasswordScreen1> createState() => _ResetPasswordScreenState1(); //similar to the home page, and other pages soon to be added, this will be used for resetting the password
}



class _ResetPasswordScreenState1 extends State<ResetPasswordScreen1> {//this extends the statefulwidget, to ensure changes in state are possible.

  String currentEmail="";//represents the email that the user has inputted

  void adjustEmail(String newEmail) {//this is used to dynamically adjust the value of the original email. This is a setter method based on userinputted email
    setState(() {
      currentEmail=newEmail;//previous email is now newemail
    });
  }


  String message="";//this is the message that will be displayed as output.

  Future<void> resetPassword() async {//when the resetPassword button is pressed, this function is called
  try{



    await FirebaseAuth.instance.sendPasswordResetEmail(email: currentEmail);//sends reset password email to the user
    //print("Success");
    setState(() {
      message="You should receive an email soon";
    });
    //theController2.clear();//clears request after it successfully 

  }
  on FirebaseAuthException catch (e) {//if there is some error, that error is caught
    print(e.code);
    if(e.code=='missing-email') {//checks if the email is missing(only possible error from this page)
      setState(() {
        message="Please be sure to enter your email";
      });
    }
    else if(e.code=='invalid-email') {//checks if the email is in the proper format.
      setState(() {
        message="The email you entered does not follow the required format: @provider.com, please try again";
      });
    }

    else if(e.code=='too-many-requests'||e.code=='quota-exceeded') {//if the user spam presses the signin button
    setState(() {
      message="Too many requests! Please wait a little until next attempt";
    });
    }
  }
 }


//still need to look into logic of making custom tabs after opening email links(will need to see)


final TextEditingController theController2 = TextEditingController(); //this controls the editing of the email. This may be deleted
  @override
  Widget build(BuildContext context) {//widget build line identical to home screen, except, there is no need for the super.context(), as it does not need to override this. 
  return Scaffold //this is used to show different layout options. This is going to be intended for use for the tabs.
  (

    body: 
    
    Center//Center is used here, as otherwise, it doesnt properly format.
    (child:Column//columns run vertically
    (mainAxisAlignment: MainAxisAlignment.center, //ensures both of the text fields are in the center of the screen
    children:[
       

      Text("Reset Password Page", style: TextStyle(fontSize:30, color: Colors.purple )), //this represents the ResetPassword label

    Text("\nRemember your password? SignIn here: "),//Gives information on how to signin/make an account.
      ElevatedButton(//this is a prompt to the next screen
        child: Text("Sign-In"),//the button is called signin
        onPressed: () {


  Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const SignInScreen1()), //this means it wants to go to the previous page, which is going to be the signinScreen.
  );
  })

      ,Text("\nEnter Email Here:",),//this text needs to be realigned to be the left....this needs to be edited later during the aesthetics process.
      Padding(padding: EdgeInsets.only(top:20,left: 40, right: 40, bottom: 20), //the padding allocated space of 40 to the left and right and 20 to the bottom for this widget specifically.
      
      //sized box is used here, to force limit the length of the textfield for aesthetics purposes.
      child:SizedBox(width: 270, child: TextField(
        controller: theController2,//this controls what is inside the text.
        decoration:InputDecoration(
        //creates a curved rectangle border
        border:OutlineInputBorder(), //this creates a curved rectangular border around the text.
        //Email is the label inside the textbox
        labelText: "Email", 
        
      )
      //,
      
      ,onChanged: adjustEmail, //if the text changes, adjust the email. this ensures that the very last change will be the value of the email. This logic may be adjusted when testing for functionality, will see.
      
      )
      )
      ),

      //the reset password button goes here. Look into emails, and opening up seorate tabs tomorrow.
      ElevatedButton(//this is a prompt to the next screen
        
        child: Text("Reset-Password"),//the button is called signin
        onPressed: 
            resetPassword//calls the resetpassword function.
  ,),
     Text("\n$message", style: TextStyle(color: Colors.red,)),//this displays the message onto the screen. 

      

      Text("\nDon't have an account? Make an account here: "),//Gives information on how to signup/make an account.
      ElevatedButton(//this is a prompt to the next screen
        child: Text("Sign-Up"),//the button is called signin
        onPressed: () {

  Navigator.push( //push means go to other page
            context, //the context is the build context
            MaterialPageRoute(builder: (context) => const SignUpScreen()), //this means it wants to go to the previous page, which is going to be the signupScreen.
  );
  })
      ]),
      ),
  
    
  );

  }
}