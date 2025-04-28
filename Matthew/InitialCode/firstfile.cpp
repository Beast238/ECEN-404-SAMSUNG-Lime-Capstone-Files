#include <iostream>
#include <cstdlib>
#include <string>
#include <random>
#include <cmath>
#include <ctime>
#include <chrono>
#include <cstring> //includes cstring implementation
//#include <curl/curl.h>
#include <thread>


#include "json.hpp"
#include <fstream>
//#include "nlohmann/json.hpp"
//#include <json>

//#include <firebase>
double randompHGen() { //This function will be used in 403. It is used to randomly generate double pH values between 0 and 14. This is the first stage of the input process.
    //Note: these values will evantually be sent to database(which continously appends new rows to the same column)
    //This database will reflect these values, in real time to the webapplication.
    
    double myRand=0;//instantation of random number

    //for now pH will be limited to 0 and 14.0. This will change later on.
    myRand=rand()%1401; //sets range of random number to be between 0 and 1400 inclusive.
    double actualRand = myRand/100.0; //ensures decimals are included, and includes 0-14.0.
    return actualRand; //returns randomGenerated pH value
}


/*
double randomFlourideGen() { //This function will be used in 403. It is used to randomly generate double flouride values between 0 and 1000(units are in ppm). This is the first stage of the input process.
    //Note: these values will evantually be sent to database(which continously appends new rows to the same column)
    //This database will reflect these values, in real time to the webapplication.
    
    double myRand2=0;//instantation of random number

    myRand2=rand()%10001; //sets range of random number to be between 0 and 10000 inclusive.
    double actualRand2 = myRand2/10.0; //ensures decimals are included, and includes 0-1000.00
    return actualRand2; //returns randomGenerated pH value
}
    */


double limedispenGen() { //This function will be used in 403. It is used to randomly generate double lime dispension values between 0 and 1000(arbitary for now, will be changed later). This is the first stage of the input process.
    //Note: these values will evantually be sent to database(which continously appends new rows to the same column)
    //This database will reflect these values, in real time to the webapplication.
    
    double myRand3=0;//instantation of random number

    myRand3=rand()%10001; //sets range of random number to be between 0 and 10000 inclusive.
    double actualRand3 = myRand3/10.0; //ensures decimals are included, and includes 0-1000.0
    return actualRand3; //returns randomGenerated limedispension value
}

std::string getCurrentTime() {//returns the currenttime in terms of a string
    auto start = std::chrono::system_clock::now(); //takes current time(time right now) using chrono and system clock
    std::time_t currentTime = std::chrono::system_clock::to_time_t(start); //converts to type to 'time'. This is converted to type time_t to ensure values can evantually be converted to String.
    char* myChar=ctime(&currentTime); //converts time to cstring value
    myChar[strlen(myChar)-1]='\0'; //because the last character in the ctime is a newline, this must be adjusted(removed)
                                   //\0 represents the last character that should be considered in the size of the c-string.
    return std::string(myChar); //returns currenttime in type string
}

long long getTimeSinceEpoch() { //returns the time since the epoch(in milliseconds)
    auto start = std::chrono::system_clock::now(); //takes current time(time right now) using chrono and system clock
    auto gap = start.time_since_epoch(); //converts start to the time since epoch
    long long second = std::chrono::duration_cast<std::chrono::milliseconds>(gap).count(); //ensures that the time since epoch is in terms of millieconds). count() gives the number of time units.
    return second; //returns the currentValue in milliseconds since the EPOCH.
}


//this function adjusts the time to include the value in milliseconds.
//This is used so that the database units includes milliseconds for precision
std::string adjustString() {

    std::string substr="";//this represents the string to be adjusted
    for(int i=0;i<=getCurrentTime().length()-6;i++) {//The string loops until the character before the space(the space is before the year)
        substr+=getCurrentTime()[i];
    }

    substr+=".";//this adds a . as a form of a decimal
    substr+=std::to_string(getTimeSinceEpoch()%1000);//millisecondssinceepoch%1000 gives the number of milliseconds for the past second. This appended to the seconds value
    substr+=" ";//A space is added, so that the year comes after the space

    for(int i=getCurrentTime().length()-4;i<getCurrentTime().length();i++) {//This iterates through the year, and ensures that the year is added
        substr+=getCurrentTime()[i];
    }

    return substr;//this returns the string to be used in the database(and evantually the webapp).
}

//void sendToFirebase(double pH, double limeDisp) { //function that sends datavalues to Firebase
    //std::string dataStr1 = std::to_string(pH);//Converts the double pH value to a string, using the to_string method.
    //std::string dataStr2 = std::to_string(limeDisp); //Converts the double lime dispension rate value to a string,
    //The string command builds the request which will be sent to Firebase. It includes a string, and other aspects too.
    //Curl is a request type for sending data to servers. POST appends entries to a preexisting system(in this case, the Firebase)
    //Cstring is converted to string with string(command)
    //std::string pHcommand = "curl -X POST -d \"{\\\"pHvalue\\\": \\\"" + dataStr + "\\\", \\\"Created at\\\": \\\"" + (getCurrentTime()) +
    //std::to_string(getTimeSinceEpoch())  
    //+ "       CurrentTime: " + getCurrentTime();
    //+"\\\"}\" https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"; 
    
    //The above command sends a child(with an associated ID) to the database. Each child has three associated values: pHvalue(between 0.0 and 14.0), and time values(in both date, and time after epoch) to_string is used for sake ofString formatting.
   
    //-X POST means to send data for the request. This adds data to the URL as to whats going on. -d means the type(data)
    //There are multiple backlashes(triple backslashes) to distinguish actual backslash and syntatical backslash.
    //triple backslash: two will actually appear, while the other escapes(overrides) the quotations. Essentially, it ensures the quotation is escaped out.
    
    //system(pHcommand.c_str()); //Completes/Executes the Command(by invoking the system). Converts the datatype to a C type string. This is done bc system can only take C-type strings.
//}

//Flouride will be adjusted, after pH completely works.
//void sendflourToFirebase(double flour) { //function that sends datavalues to Firebase
    //std::string dataStr = std::to_string(flour);//Converts the double flouride value to a string, using the to_string method.

    //Follows the same logic as that of the pH function, just uses Flouride here.
    //std::string flourcommand = "curl -X POST -d \"{\\\"flourideValue(ppm)\\\": \\\"" + dataStr + "\\\", \\\"Created at\\\": \\\"" + std::to_string(getTimeSinceEpoch()) + 
    //+ getCurrentTime() + "       EpochTime: "+std::to_string(getTimeSinceEpoch())
    //+"\\\"}\" https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"; 
    
    //The above command sends a child(with an associated ID) to the database. Each child has three associated values: flourideValue(between 0.0 and 1000.0), and time values(in both date, and time after epoch)
    //-X POST means to send data for the request. This adds data to the URL as to whats going on. -d means the type(data)
    //There are multiple backlashes(triple backslashes) to distinguish actual backslash and syntatical backslash.
    //triple backslash: two will actually appear, while the other escapes(overrides) the quotations. Essentially, it ensures the quotation is escaped out.
    
    //system(flourcommand.c_str()); //Completes/Executes the Command(by invoking the system). Converts the datatype to a C type string. This is done bc system can only take C-type strings.
//}

void sendToFirebase(double pH, double limeDisp) { //function that sends datavalues to Firebase
    std::string dataStr1 = std::to_string(pH);//Converts the double pH value to a string, using the to_string method.
    std::string dataStr2 = std::to_string(limeDisp);//Converts the double lime dispension value to a string using the to_string method.

    
    //This uses both pH and lime dispension parts, and adds these values to the database.
    std::string command = "curl -X POST -d \"{\\\"LimeDispensionRate\\\": \\\"" + dataStr2 + "\\\", \\\"Created at\\\": \\\"" + (adjustString()) +
    //std::to_string(getTimeSinceEpoch())  
    //+ "       CurrentTime: " + getCurrentTime();
    "\\\", \\\"pHvalue\\\": \\\"" + dataStr1 + "\\\"}\" https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"; 
    
    //The above command sends a child(with an associated ID) to the database. Each child has three associated values: pH value(between 0.0 and 14.0), LimeDispensionValue(between 0.0 and 1000.0), and time values(in both date, and time after epoch)
    //-X POST means to send data for the request. This adds data to the URL as to whats going on. -d means the type(data)
    //There are multiple backlashes(triple backslashes) to distinguish actual backslash and syntatical backslash.
    //triple backslash: two behave as a double backslash, while the other escapes out of the quotations. 
    
    system(command.c_str()); //Completes/Executes the Command(by invoking the system). Converts the datatype to a C type string. This is done bc system can only take C-type strings.
}

//std::string 
std::string showFlourideFromFirebase() {

    //std::string web = "https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data/Flouride Data(ppm) value .json";

    


    std::string myKey="Flouride%20Data(ppm)%20value%20"; //this is the key value being used. This is how the key is shown in firebase. %20 is used for spaces
    std::string flourideCommand = "curl -X GET https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data/"+myKey+".json"; //this is used to create the command.

    std::string flourideCommand2=std::to_string(system(flourideCommand.c_str())); //here the system is being invoked, to execute the command on the terminal
    
    
    
    //std::string flouridecommand = "curl -s https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"; // this takes in the entire database, and the flouride data value will be filtered.

    //std::string strCommand=std::to_string(system(flouridecommand.c_str())); //converts command to string value

    //std::string summation=""; //this will iterate through the string.

    //for(int i=0;i<strCommand.length();i++) {
        //if(strCommand[i+2]<strCommand.length()) {
        //if(strCommand[i]=='0' || strCommand[i]=='1' || strCommand[i]=='2' || strCommand[i]=='3' || strCommand[i]=='4' || strCommand[i]=='5' || strCommand[i]=='6' || strCommand[i]=='7' || strCommand[i]=='8' || strCommand[i]=='9') {
            //if(summation.length()==0) {
              //  if(i-5>=0 && strCommand[i-5]!='t') {
      //  summation+=strCommand[i];
                //} 
            //}
            //if(summation.length()>=1) {
              //  summation+=strCommand[i];
            //}
            
            
    //}
        //if(summation!=)


    //}

    //using json = nlohmann::json;//creates instance of json

    //json parsed=json::parse(strCommand);

    //std:: string flourideVal=parsed["Flouride Data(ppm) value"];



    //for(int i=strCommand.length()-1;i>=0;i--) {
      //  if(strCommand[i]=='F') {
        //    break;
        //}
        //summation+=strCommand[i];
    //}

    //std::string myStr="";
    
    //myStr+=strCommand[strCommand.size()-8];
    //using json = nlohmann::json; //instantiating short term for json type

    //std::ifstream f("https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json");
    
    //json data = json::parse(f);

    //std::string flouride=data["Flouride Data(ppm) value "];

    //return flouride;
    //return std::to_string(strCommand[strCommand.length()-4]);
    return (flourideCommand2);
}



//Some implementation will be done here, to obtain timestamp as to when the associated pH(or Flouride value) was added to the database
//This function will obtain the timestamp of when the value was added to Firebase, and then save this value
//This value will be converted to milliseconds, and stored for future use(if it is the first value).
//A seperate variable will subtract this value, to obtain a value in reference to 0s
//The following values added(in that instance), will follow this same process(it is essentially a normalization procedure) of time.
//The datavalues for these points will be added, and these new times will be added to a 2d array(or list)(still need to look into this)
//Then, the display will performed in Flutter
//Play pause will be looked into, after this all accomplishes successfully.





//The play/pause feature will be held off on, for now.
//For a dynamically changing graph think of readability.


//The database should be continously updating every ms of time(same with the realtime values).
//For the graph, think of things such as sampling time(how often will values be displayed)? How often will values be kicked off the graph(or scaled) to make room for other values?
//The datapoints need to be updated
//Implementations: values in the graph will be updated every second(sampling time is 1sec). 
//Values at the datapoints will be decided(finalized), once the graph somewhat makes sense.
//Sampling time: 1s, reset time: 20s.
//The graph is going to be autoshifting after(0-20s, it will be 20-40s), etc.
//Make a conditional that checks if 1s has elapsed since a value has been added.



//Every 3 seconds, add an instantaneous value
//Include 20 datapoints(0-60)
//1 minute intervals are nice because 1 minute is a standardized unit.




int main() {
    std::cout << "Hello, World!" << std::endl; //test printing output
    srand(time(0)); //creates a different random number each time at run time(aka, each iteration of the loop).

    std::cout<<showFlourideFromFirebase()<<std::endl<<"\n";//this will be used later.
    //return 0;
    //return 0;
    //srand(static_cast<unsigned int>(time(0)));
    for(int i=0;i<80;i++) { //continously runs this x amount of times.
        double mypHVal=0; //represents pHValue for the current looprun
        double myVal2=0; //represents limedispension value for the current looprun
        if(i<65) //upper boundary on runtime.
        {
        mypHVal=randompHGen();//declares randomly generated pH value
        //do{
        myVal2=limedispenGen(); //declares randomly generated lime dispension value
        //}
        //while(mypHVal==myVal2);
        sendToFirebase(mypHVal, myVal2); //sends the pH and lime dispension values to firebase alongside their timestamp
        

        //this_thread::sleep_for(std::chrono::seconds(1));//this inserts a 1 s delay when putting values in the database
        //mypHVal=randompHGen();
        //sendpHToFirebase(mypHVal);
        //adjustString();
        }
        
        
        //else {
        //myVal=randomFlourideGen(); //declares randomly generated pH value
        //sendflourToFirebase(myVal);//sends this value to firebase alongside it's timestamp
    //}

        //The following is theflouride implmenetation, which will be used later
        //else {
        //myVal=randomFlourideGen();//declared randomly generated flouride value(in ppm)
        //sendflourToFirebase(myVal); //sends this value to firebase alongside it's timestamp
        //}
        
        //std::this_thread::sleep_for(std::chrono::seconds(1)); This timedelay was used to populate the data table.
    }
    
    return 7;//returns out of main.
    
}
