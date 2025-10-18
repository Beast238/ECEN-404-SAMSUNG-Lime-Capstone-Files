/*
    Property of Texas A&M University. All rights reserved.
*/

#pragma once

//WIFICONNECTION CODE:
#include "model.h"
#include "pH_driver.h"
#include <iostream>//included for couts.
#include <stdio.h>
#include <stdlib.h>//used for double conversions.
#include <sys/time.h>//header for esp system time setting
#include <time.h>//system header.
#include "custom_globals.h"

//the following three delcarations are related to the FreeRTOS library.
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"

#include "esp_timer.h"//done for esp clock timer.

#include "esp_netif_sntp.h"//SNTP Time to be used here.

#include <random>//used for random numbers.
#include "esp_wifi.h" //The Wifi library is used for monitoring and configuring specific settings. This is the most imporant library for this program
//For reference, the MCU from this program will be station based. Station based means that it will connect to a common wifi network(either TAMU Wifi or TAMU IOT), and use this network. 
//It needs to do this to connect to Firebase, as Firebase is also on Wifi


#include "esp_log.h" //This helps to log errors on to the terminal. It also tracks possible errors.
#include "esp_event.h" //Wifi events such as Wifi started, connected, disconnected, etc.

#include "nvs_flash.h" //Nvs flash will be used to store network settings and credentials.

#include "esp_netif.h" //used for soecific connections between ESP32 and Wifi

#include "esp_system.h" //General ESP32 system commands


//lwip represents the network interface type.
#include "lwip/err.h"//includes error types from lwip library
#include "lwip/sys.h"//may need this not too sure.... Is related to abstract event stuff.
//static EventGroupHandle_t s_wifi_event_group;//this is done to essentially set more indicators of state of the current wifi connection.
//For example, bit0 may represent connected, bit1 as disconnected, bit2 as getting IP address, etc.
//#include "mbedtls/esp_debug.h"

//This top code shall represent the general system requirements of the Wifi connection

#define WIFI_SSID "TAMU_IoT" //this represents the wifi for it be connected to
#define WIFI_PASS "" //this is the Wifi Password. For TAMU_IoT, there is no need for password.


//Wifi Event start just means that the wifi will be successfully started up.
//Wifi Event disconnected just means that wifi lost connection.

//For events, there is an event base(almost like a group name) and event ID(identifying the event in the group)
//In this situation, the Event Base is WIFI_EVENT
//The event ID is going to be identifying the event in WIFI_event(examples include start, disconnected, etc.)


//Below starts the Wifi Event Handling Portion. A wifi event is a change in status of the wifi connection. These change in status needed to be handled appropiately, and considered carefully.



//Below, begins the event handler portion.
//The following function type is known as the Event Handler. It is automatically called, when a new event(wifi status) is added to the stack

//int count = 0;//this boolean is made to check if wifi is connected.



#include "esp_http_client.h"//this is going to be used for the requests back and forth with Firebase. Do not mess with MakeFile!!!! It will change everything.
#include <string> //this is the import for Strings in C++
//Note: as of now, the wifi connection code is written in C, while the RESTAPI code is written in C++
//They will both be mingled/worked together in the main function.

#include <cmath>
#include <ctime>
#include <chrono>
#include <cstring> //includes cstring implementation
//#include <curl/curl.h>
#include <thread>

#include "esp_crt_bundle.h" //this is included for allowing the server verification bundle.
//This is ESPIDFs onboard bundle that is compatible with server connections.

#include "esp_task_wdt.h"//represents wdt task


bool gotIp=false;//indicator to check if IP Address was officially obtained.

//These functions are taken from c++ program made in 403. They are EXACTLY the same.
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

void setProperESP32Time(long long TimeSinceEPOCH) {//this function is being crreated, bc rn, the system time of the ESP32 is set as 1970
    //The value passed in will be in terms of milliseconds.
    //THis issue needs to be resolved

    //TimeSinceEPOCH=getTimeSinceEpoch()/1000;//obtains value from other function in seconds. Divide by 1000 is used here, as the other function is right now in MILLISECONDS SINCH EPOCH

    //printf("THIS WENT THROUGH");
    struct timeval myStruct;//struct of timeval. Timeval represents a manner to set the system clock of the esp32.

    myStruct.tv_sec=(time_t)((TimeSinceEPOCH)-(5*3600));//this is going to be the parameter that is passed in. NOTE: THIS NEEDS TO BE OF DATATYPE TIME_t!!!!!!!
    //This is because the default structure assumes this datatype.
    //Note the times 5, as local timezone is 5 hours behind GMT time
    myStruct.tv_usec=0;//remainder milliseconds is in terms of microseconds.

    settimeofday(&myStruct, NULL);//timezone can be ignored for our case, just need a time in between certificate


}

char* returnFlouride() {//returns read in Flouride value.
    //Something to keep in mind is that the quotations surrounding the number WILL be included. 
    //thus, bc the maximum characters allowed for flouride is 9, and the quotations are two characters, 
    //the maximumum amount of bytes possibly read in from database is 11.
    

//The folllowing chosen configuration specs were researched from the espidf function list in the https client page
//These were selected due to their needed context in this operation.




esp_http_client_config_t myCfg = {//this sets the configuration/settings of the Read request. 
    //This is the most basic requirement before initializing the client.


    //There are a couple of parameters of interest that will be highlighted here.


    .url="https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data/Fluoride%20Data(ppm)%20value%20.json"
    
    //as seen above url is the link to the flouride value in the database.
    //the above link is where the specific value is receieved. %20 is spaces between each word.
    //opening this link, will show the current value of Flouride......


    //GEN NOTES:
    //Placement aspects such as port, path, query can be left as default, as the url is specified.
    //UserAgent is simply used for showing current ESPIDF type.

    //For now, it is important to keep the redirects as they are
    //There is no event handler being used(as of now) for this portion.

    //isasync is defaulted to false here, as the order of operations(checking with the database, receiving, etc, should be proper)

    //.host="databaseecen403-6fb45-default-rtdb.firebaseio.com",//the host name is everything before specifying the data path.
    



    ,.method=HTTP_METHOD_GET, //this is the method type for the get request. This code is going to simply obtain the value for Flouride Data(ppm) value FROM THE DATABASE.
    
    .transport_type=HTTP_TRANSPORT_OVER_TCP, //the transport type(from database to espidf) will be TCP
    //This is because TCP was the previously used network interface(LWIP), as described in the Wifi code.
    //Even though this is TCP communication, it will still have TLS(Transport layer Security) when sending.
    //This provides encryption and safe sending of data over internet.
    //To ensure this, espidf has an onboard bundle which can be attached and used.
    //It allows for different certificates to be used.

    
    .use_global_ca_store=true//this is used here to essentially allow all certificates from the below bundle
    
    

    
    
    //The good news is, is that the certificate for Firebase is included. 
    ,.crt_bundle_attach=esp_crt_bundle_attach,//This represents the default bundle from ESPIDF, and it includes the certificate for Firebase Projects.
    .keep_alive_enable = true//ensures that when a timeout occurs, an automatic retry is done to regain connection.
    


};



esp_http_client_handle_t myVar = esp_http_client_init(&myCfg);//this starts a new receieving session. 
//It returns a variable(myVar) of type client_handle(this represents the newly made client)
//This initalizes the client(that has the previously made settings)to be used with the database.


static char Flouride[13];//this variable represents the flouride value being inputted in from the database. static is being used here, to ensure this variable will be the same, when it is being accessed again in app_main
//Size 13 is used here, just to GURANTEE that this buffer is larger than the length of what is being read in the database.
//This accounts for the maximum possible situation(11 bytes)
//Even though it is size 13, something to keep in mind is that the LAST INDEX is is the null terminator /0.
//Thus, it truly is 12 bytes.
//Something else to keep in mind is that for reading Flouride, everything is in terms of bytes NOT String length
//Bytes are the units of reading from the database, and this was a big initial issue that evantually got resolved.







esp_err_t status = esp_http_client_open(myVar, 0);//0 is used here, as nothing is actually written to the dataabase itself.
//opens connection to the database with the previously made client.


//It is important to note that because the return type is an error, this will be used
//to essentially detect whether or not the operation went through AFTER it was attempted.
//This is analgous to the ESP_ERROR_CHECKS in the part for the Wifi Code.


int myFetch=esp_http_client_fetch_headers(myVar);//this is done to later distinguish headers from body for this variable.
//allows for the body to be read in seperately with the read command.

if(status==ESP_OK) {//checks to make sure attempt to open connection is successful.
    //It is important to check this, just in case if something does go wrong.....
    
    //number of bytes read in from the database includes the flouride value itself AND two surrounding double quotes
    //As stated above, this means that the maximum amount of bytes read from the database is 11.


    int databaseflourlength=esp_http_client_read(myVar, Flouride, sizeof(Flouride)-1);//this is assuming: that the size of the variable is 12(NOTE: maximum possible length of variable from database is 11), with the index i=12 being the null terminator.
    //This is why -1 is used here as there is no need for having 13 bytes(12 is the maximum).

    //there are 3 parameters here: the created client, the string variable flouride, and then the length of flouride.
    //BECAUSE this is a cstring, it is important to note that the last character is null terminated.
    //Meaning that the true size of the buffer is 11, as the last index will be null terminated..

    //There was an issue the student was stuck on for a while: using strlen instead of using sizeof.
    //sizeof needs to be used, as the database keeps values in terms of bytes.
    //RESOLVED ISSUE: NEED TO USE BYTES(sizeof) INSTEAD OF LENGTH(strlen) WHEN READING!!!!!!!!!!!!!!!!!!
    
    //databaseflourlength returns the length of the flouride value FROM the database. Note: this length can be at most 11.
    //It is important to keep in mind that this does not need to be the same as the length of the instantiated variable(Flouride[13]).
    //It is less than or equal to 12(with the last byte being null terminated).


    //the following code section is done to resolve an edge case when increasing/decreasing the length of flouride, 
    //leads to keeping the same previous variable(has more numbers than needed to).
    //This issue arised due to the fact of the buffer possibly being greater than the actual length read in the database.
    //This code segment ensures that the null terminator occurs AFTER the second quotation mark, ensuring only necessary values are being displayed.
    int indofSecondQuote=0;//this represents the final index to be included in the print: the second double quote.
    
    for(int i=0;i<sizeof(Flouride)-1;i++) {//this goes through the size of Flouride(12 normal bytes)
        if(Flouride[i]=='\"' && i!=0) {//if the value at the index is a quotation mark(but it is NOT the first quotation mark)
            indofSecondQuote=i;//save this index as a varaible, and exit out of loop.
            break;//breaks out of the loop to save time.
        }
    }


    Flouride[indofSecondQuote+1]='\0';//the index AFTER the saved index will be the null terminator, as NOTHING should be read in after the second double quote.
    
if (ENABLE_DEBUG_LOGGING) printf("HTTP: Read returned %d bytes\n", databaseflourlength);//returns length of what is returned(NOTE: quotations will be returned as well.)
}



esp_http_client_close(myVar);//this finally closes(opposite of open) the client AFTER the operation is completed

esp_http_client_cleanup(myVar);//this finally cleans up the client AFTER the operation is completed
//cleanup helps to avoid any memory issues that could occur..

//An interesting aspect to consider is that the approach had to be changed to ensure this value could be returned.
//instead of doing init->perform->readresponse->cleanup, this was done as init->open->read->close->cleanup
//The student had some issues doing it the first way, bc perform would read all the data before readresponse would be able to use it...

//Important thing now, is that it works as it should.
/*
std::string myString="";
int count2=1;
while(myString[count2]!='\"') {
    myString[count2]=Flouride[count2];
    count2++;
}
myString[count2+1]='\0';                
*/
//return atof(myString.c_str());//final read in flouride value from Firebase
return Flouride;


}




static void my_Event_Handler(void* myArg, esp_event_base_t theBase, int32_t theID, void* theData)    {//this function is static, as it does not change
        
    //the above function has 4 arguments: 
    //myArg: other data that is not from the event
    //theBase: the event base name
    //theID: the event's ID
    //theData: the event's official data.

    //The purpose of this code is to maintain connection to the Wifi at all times
    //This code considers all the different situations(of Wifi status), and tries to adjust based on those situations.


    if(theBase == WIFI_EVENT && theID == WIFI_EVENT_STA_START) {//If the event's group is a wifi event, and the Id is start
        //what this means is that after attempting to start the wifi, the flags/response is positive
        
        esp_wifi_connect();//knowing that the response is positive/ready, this line simply connects to the wifi
        
    }

    else if(theBase == WIFI_EVENT && theID == WIFI_EVENT_STA_DISCONNECTED) {//If the event's group is a wifi event, and the Id is disconnected
        //what this means is that there is some disruption in the Wifi, the purpose of this if statement is to detect that


        if (ENABLE_DEBUG_LOGGING) printf("Wifi Connection Status: Wifi got disconnected, trying to reconnect....\n"); //display message to terminal that ESP is now disconnected.
        //reason gives the reason.

        esp_wifi_connect();//attempt to reconnect to Wifi after initial disruption
        //count=1;
    }

    
    else if(theBase == WIFI_EVENT && theID == WIFI_EVENT_STA_CONNECTED) { 
        //If the event's group is a wifi event, and the Id is connected
        //This is just a status check to ensure that the Wifi is still connected.

        if (ENABLE_DEBUG_LOGGING) printf("Wifi Connection Status: Wifi connected, nice!\n"); //display message to terminal that ESP is connected.
        //there is no need for event group here, as this section is more so longterm status(it's not a sudden thing such as start/disconnect/ip address). 
        //This is something that will ideally last for long time periods.
        //count=2;
    }

    else if(theBase==IP_EVENT && theID == IP_EVENT_STA_GOT_IP) { //If the event's group is an IP event, and the ID is a matter of getting the IP Address.
        //This is in the specific case of receiving data(specifically, the IP Address ), or, when the IP Address is changed.
        //Thus, this is meant to receive, and update the current data to the receieved IP Address.



        //the actual datatype of the IP address is ip_event_got_ip_t. Thus, we need to make a temporary variable that holds this value
        ip_event_got_ip_t* myEvent = (ip_event_got_ip_t*) theData;//this holds the value of the incoming event's IP address. This makes sense, as theData is in a raw format, and it needs to be converted into ip address formatted data
        //got_ip_t is used here, as that is the data type for receiving IP EVENTS.
        if (ENABLE_DEBUG_LOGGING) printf("Wifi Connection Status: got ip address: " IPSTR "\n", IP2STR(&myEvent->ip_info.ip));//this prints the message to the terminal. ip info just represents information found in the previously converted event. .ip is used on this, to specifically obtain the addresss.
        //IPSTR is used to format the Ip Address being found after the second comma
        
        //IP2STR simply breaks the address into different numbers(in this case, 4 numbers for the IP address) for sake of formatting.

       //gotIp=true;
       //vTaskDelay(pdMS_TO_TICKS(4000));
       //printf(returnFlouride());


       
       //printf(returnFlouride());//this HAS to be called at this stage. Communication/sending and receiving requests can ONLY be done
       //after IP Address is obtained. This is something important to consider.

       gotIp=true;//sets gotIP Address to true, as the ip address was obtained....
    }
}

/*
int returnCount() {
    return count;
}
*/
void wifi_init_phase(void) {//this function is the initalization phase of the process. While the above function accounts for different situations, and responds to those situations(event handling), this function will be used for initializing/startup
    
    
    
    //the process from the very beginning. 
    //This is seperated into 4 different parts. Initializing the Lwip(the stack),initializing the event and initializing wifi. The fourth part, is the application(program) task, which is the main method(app_main) below.
    //Initialization is the first step for all of these tasks, the steps will be detailed below as to their functional importance.

    //something may need to go here soon........

    //General Information
    //nvs flash is the most unique part of the process, however, it is required to essentially ensure that the credentials, and information, are all stored appropiately.

    //ESP Error check shows the error, and then aborts the program if needed.
    //It aborts, bc the program can not continue.
    //If there is no error, the thing inside Error check will simply execute, and the logic will continue.

    ESP_ERROR_CHECK(esp_netif_init());//If there is no error then, the LWIP(stack) will be initialized. As stated above, this is the first step in the connection portion.
    //Note that this is crucial to communicate with iOT Devices(in this case/context, ESP32).

    ESP_ERROR_CHECK(esp_event_loop_create_default()); //If there is no error then, the event task(loop) will be initialized. As stated above, this is the second step in the connection portion.

    //This next step is an intermediate step to ensure proper connection.
    //This binds the LWIP instantiated in the first line of code
    //ESP_ERROR_CHECK(
    esp_netif_create_default_wifi_sta();//initializes wifi station, and connects network interface(AKA LWIP) to the wifi station.
    //There is no need of Error check, as this already has an inherent abhort feature.

    wifi_init_config_t myWifiEvent = WIFI_INIT_CONFIG_DEFAULT();//this sets up a wifi event that is in the default initial configuration. 
    //This is done for setup for the next line
    ESP_ERROR_CHECK(esp_wifi_init(&myWifiEvent));//this initializes the actual wifi task, once the above event is ready.

    



    
    //The following code helps to synchronize these initialization steps, to the created event handler in the above code section. 
    //One interesting thing to note is that it is actually taking in the name of the made Event Handler in its parameters.

    //These instances represent different cases: instance_my_id is for Wifi related events, 
    //while instance_my_ip is for getting the actuall IP Address.
    esp_event_handler_instance_t instance_my_id;
    esp_event_handler_instance_t instance_my_ip;

    //This section of code is used for running event loop, and to do a test run.
    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,//the event base to check if this is WIFI_EVENT(explained in event handler portion)
                                                        ESP_EVENT_ANY_ID,//this flag essentially allows for any ID to be used(meaning that it can be any type of Wifi event).
                                                        &my_Event_Handler, //this takes in the name of the event handling function that was built above
                                                        NULL,//this field is for data besides event data that is needed. Here, it is NULL as this simply checks if the event is properly configured. This is analagous to arg in the event handler function(data other than data in the actual file)
                                                        &instance_my_id));//simply an instance which relates to the values needed. myId is used here as the name, as this is really for any of the Wifi events.

    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,//the event base to check if this is IP_EVENT(explained in event handler portion)
                                                        IP_EVENT_STA_GOT_IP,//this flag essentially allows for checking if the IP Address is receievd.
                                                        &my_Event_Handler,//this takes in the name of the event handling function that was built above
                                                        NULL,//this field is for data besides event data that is needed. Here, it is NULL as this simply checks if the event is properly configured
                                                        &instance_my_ip));//simply an instance which relates to the values needed. myIp is used here as the name, as it is related to obtaining the IP Address.
//Even though the above is made an instance of now, it is simply left in the queue.
//IT IS ONLY INVOKED AFTER THE WIFI START COMMAND, IN WHICH THE START WILL START UP THE WIFI!!!!
    
    
    
    //The above portion represented the initialization phase.
    //The below portion represents the Wifi SPECIFIC Configuration phase
    //This done to essentially the specify the requirements a little more, rather than keeping it as the Default one above.

    wifi_config_t myWifiConfig={//simply describes the Wifi configuration in detail
        .sta={
            .ssid="TAMU_IoT", .password=""//the network is TamuIoT, and the password is empty.
            //.ssid="ARRIS-2471", .password="373000704518"
        },
        
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));//the first thing to specify is that the Wifi mode is station NOT AP
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &myWifiConfig));//the next thing is to essentially use the described event above, 
    //which represents the wifi settings in this case. WIFI_IF_STA means that a station interface will be connected to(it is a crucial parameter.)

    
    
    
    //This portion essentially finally starts the wifi task after it has been: initialized and configured
    ESP_ERROR_CHECK(esp_wifi_start());//Error check is of course used here to ensure there are no errors.
    //Using intuition, this part will trigger the first case in the event handler.

    //there is no need to attempt a wifi connection after this, as the handler will account for it....
    
}



//This portion begins to outline/introduce the RESTAPI portions


//This will be the flow of logic:
//Ph and lime dispension will be returnables from Christin's and Ryon's subsytems
//These values will be sent as a POST method into the Firebase Database in an IDENTICAL format to the dummy data from last Spring
//This will be sent using RESTApi
//The app will evantually read this value from the database




//Flouride will go in the opposite direction.
//Because flouride is is generally made in the database(goes from app to database), then it will be read into it.
//First do flouride(as this is your value, then begin doing dummy pH/lime disp values). 
//You may need to adjust format of flouride accordingly, to ensure easy read. Not too sure if iteration is efficienct...will need to see.

//Finish flouride before tomorrow.

//cfg will be used to specify request configurations(url, type, etc)

//this will begin the reading logic
//The function definition is: String returnFlouride()














void sendTimeLimeDispandpH(double pH, double limeDisp) {//this function will be used to send both pH and limeDisp values.
        //pH and limeDisp will both be doubles, as this is how they were formatted in the helper function made in 403..
        //Note: the format of this is going to be VERY similar to the returnFlouride, with some key distnictions that will be noted.
        //2nd Note: this function declaration(having 2 parameters) is identical to C++ program created in 403, except now the body, will be using esp_http_client requests instead of raw curl commands.

        //As usual, there is a configuration instantiation.


    esp_http_client_config_t myCfg2 = {//this sets the configuration/settings of this request. 
    //This is the most basic requirement before initializing the client.


    //There are a couple of parameters of interest that will be highlighted here.


    .url="https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"
    
    , 
//as seen above url is the link to the entire database.

//Post will simply append a new instance to the database.

    //GEN NOTES:
    //.addr_type=IPADDR_TYPE_V4,
    //the above link is where the specific value is receieved.

    //Placement aspects such as port, path, query can be left as default, as the url is specified.
    //UserAgent is simply used for showing current ESPIDF type.

    //For now, it is important to keep the redirects as they are
    //There is no event handler being used(as of now) for this portion.

    //isasync is defaulted to false here, as the order of operations(checking with the database, receiving, etc, should be proper)


    .method=HTTP_METHOD_POST, //this is the method type for the POST request. 
    //This code is going to simply append a randomly generated alphanumeric ID along with some info of pH, lime dispension, and currentTimeStamp(which comes from adjustString())
    


    .transport_type=HTTP_TRANSPORT_OVER_TCP //the transport type(from database to espidf) will be TCP
    //This is because TCP was the previously used network interface, as described in the Wifi code.
    //More explanation as to why TCP is used can be found in the returnFlouride function.
    

,.use_global_ca_store=true//this is used here to essentially allow all certificates from the below bundle
    
    

    
    
    //The good news is, is that the certificate for Firebase is included.
    ,.crt_bundle_attach=esp_crt_bundle_attach,//attaches default ESPIDF Certificate Bundle WHICH INCLUDES FIREBASE!!!!
    .keep_alive_enable = true//ensures timeouts/random exits do not occur when sending by autoreconnect. This helps to reduce errors....


};




esp_http_client_handle_t myVar2 = esp_http_client_init(&myCfg2);//this starts a new sending session(in this case). 
//It returns a variable(myVar2) of type client_handle(this represents the newly made client)

std::string dataStr1 = std::to_string(pH);//Converts the double pH value to a string, using the to_string method.
std::string dataStr2 = std::to_string(limeDisp);//Converts the double lime dispension value to a string using the to_string method.
//Note: these two lines are identical to the 403 C++ program created last Spring. Firebase will contain these values as Strings, and the app will read them as Strings.....

std::string mySending=
//Identical labels as 403 C++ program....
//Now though, because a curl command is NOT used, the backslashes are reduced in quantity, as there does not need to be that many esacping of strings.
"{ \"Created at\": \"" + (adjustString()) +//TimeStamp created at..... Note: Adjust String is the official timestamp, with its appropaite decimal portions.

    "\", \"LimeDispensionRate\": \"" + dataStr2 + "\", \"pHvalue\": \"" + dataStr1 + "\"}";//Lime Dispension and pH..... As of now, these are randomly generated. 
    //For integration, other subsystem returnables will be used here.
    //this is the format of a child in the database.
    //The slashes are used to escape out....


esp_http_client_set_header(myVar2, "Content-Type", "application/json");//allows for json data to be processed when sending.........
//The above value is a json value. This is a side step, as oftentimes, ESP may not implicitly allow JSON to be sent
//Doing this helps to specify what is being sent, before the sending occurs...

if (ENABLE_DEBUG_LOGGING) printf("My Post: POST body: %s\n", mySending.c_str());//Test Print. Prints out the current instance of what is going to be sent


//this is going to specify what will be sent.
esp_err_t statusofSet=esp_http_client_set_post_field(myVar2, mySending.c_str(), mySending.length());
//Format of variables: client, cstring, and length of cstring
//Because mySending returns a string, it needed to be type casted to cstring, thus, c_str is used here.
//mySending.length() is used, bc that was the original string's length. 

//Note: this is BEFORE perform, as the espidf http_request website stated this MUST go before perform
//This logically can be attested to the fact that ESPIDF requires to have to sending data BEFORE the sending itself can be performed.





esp_err_t status2 = esp_http_client_perform(myVar2);//this is actually going to perform the task(sending to the database) itself.
//It is important to note that because the return type is an error, this will be used
//to essentially detect whether or not the operation went through AFTER it was attempted.
//This is analgous to the ESP_ERROR_CHECKS in the part for WifiConfig
//)




//this is done to check status response.
int status = esp_http_client_get_status_code(myVar2);//as of now, the status is a 200 error, meaning that the send is successful :).
if (ENABLE_INFO_LOGGING) printf("Database HTTP status = %d\n", status);//test print to see database response.




esp_http_client_cleanup(myVar2);//cleans up this instance. This is required EVERY TIME a new operation is completed. 
//Prevents any possible memory errors...

}




//esp_http_client_set_post_field, this will be used for the post request.
//esp_http_client_get_errno is a way of determining what error was found during the operation.
//esp_http_client_is_chunked_response function used to determine whether or not response is chunked.
//esp_http_client_get_status_code this is done to essentially understand what the status response is, from Firebase.
// esp_http_client_is_complete_data_received, checks if entire response is successfully read in.




//NOTE: the below two functions are temporarily used now, when doing firmware integration, these will no longer be required.....
double randompHGen() { //This function will be used in 403. It is used to randomly generate double pH values between 0 and 14. This is the first stage of the input process.
    //Note: these values will evantually be sent to database(which continously appends new rows to the same column)
    //This database will reflect these values, in real time to the webapplication.
    
    double myRand=0;//instantation of random number

    //for now pH will be limited to 0 and 14.0. This will change later on.
    myRand=rand()%1401; //sets range of random number to be between 0 and 1400 inclusive.
    double actualRand = myRand/100.0; //ensures decimals are included, and includes 0-14.0.
    return actualRand; //returns randomGenerated pH value
}


double limedispenGen() { //This function will be used in 403. It is used to randomly generate double lime dispension values between 0 and 1000(arbitary for now, will be changed later). This is the first stage of the input process.
    //Note: these values will evantually be sent to database(which continously appends new rows to the same column)
    //This database will reflect these values, in real time to the webapplication.
    
    double myRand3=0;//instantation of random number

    myRand3=rand()%10001; //sets range of random number to be between 0 and 10000 inclusive.
    double actualRand3 = myRand3/10.0; //ensures decimals are included, and includes 0-1000.0
    return actualRand3; //returns randomGenerated limedispension value
}


void database_app_main(void) //extern C is used here, to ensure that C++ does work for this project.
{
    
  


   


   //esp_err_t myVal = 
    nvs_flash_init();//An attempt is made to essentially allocate Wifi credentials, etc. on to the flash. 
    //As stated in the init phase
    //nvs flash is the most unique part of the process, however, it is required to essentially ensure that the credentials, 
    //and information, are all stored appropiately in memory.
    
    



    wifi_init_phase();//calls the driver for the: LWIP Stack, Event Task, and finally the Wifi Task.

    


vTaskDelay(pdMS_TO_TICKS(5000));//5 sec delay until system clock is set
//Also ensures ample time for ESP to get IP Address, as IP Address(Wifi Connection) is minimal basic requirement for everything to work.
//This will avoid any clock timing issues......


esp_sntp_config_t setTime = ESP_NETIF_SNTP_DEFAULT_CONFIG("pool.ntp.org");//this attempts a connection with the system clock server.
//The system clock default server(pool.ntp.org) contains ALL specs that the clock must follow, thus, it is used right here. This is a linux timeserver that can be used.
esp_netif_sntp_init(&setTime);//initializes SNTP to current time now.//this sets the SNTP time to the current time. Note that this is the default configuration to set the system clock.
//The above method was chosen over rather than having a manual clock due to accuracy concerns, and due to many tasks running at once.
//A manual clock leads to "Time Drift."(time delay accumulation), if it is not properly monitored, thus this is done in this manner.

//This portion here is used to set the time zone
setenv("TZ", "CST6CDT,M3.2.0,M11.1.0", 1);
//TZ: specifies to set timezone.
//CST6: US CENTRAL TIME IS 6 HOURS BEHIND  GMT
//CDT: THE US OBSERVES DAYLIGHT SAVINGS TIME
//M3.2.0: REPRESENTS STARTING POINT OF DAYLIGHT SAVINGS TIME(2ND SUNDAY OF EVERY MARCH)
//M11.1.0: REPRESENTS ENDING POINT OF DAYLIGHT SAVINGS TIME(1ST SUNDAY OF EVERY NOVEMEBER). This part is exclusive, as DAYLIGHTS SAVINGS doesnt start on this day
//1 simply means execute this specification.

//daylight savings time starts on the 2nd Sunday of every March, and ends on the 1st Sunday of every NOVEMBER.
//This is almost like a conditional: once the time range is out of bounds(daylight savings time is essentially over), then the gap will change accordingly.
tzset();//sets this time zone permanently.

//Once the time is set, this will run.


vTaskDelay(pdMS_TO_TICKS(5000));//5 sec delay until request starts.
//Ensures for enough time for system clock to "sink in".
//This is important, bc proper system clock is needed to be compatible with Firebase certificate(which will be encountered when sending/receiving requests)



        
        if(gotIp){//requests are ONLY SENT OR RECEIEVED if Ip Address is obtained. 
        //This is bc stable wifi connection(which means obtained ip address), is required for successful sends/receive to/from database.
            
            //For overall flow order:
            //pH/LimeDispension/TimeStamp: ESPIDF->Database->Webapp
            //Flouride: Webapp->Database->ESPIDF
            //this explains why pH/LimeDispension/TimeStamp are being sent, while Flouride is being read.
            
            {//Continously sends values to database for specific amount of time.
                //the upper bound here can be changed based on length of how long values should send for.
            
                char* cStringFluoride = returnFlouride();
                std::string stringFluoride = cStringFluoride;
                stringFluoride = stringFluoride.substr(1, stringFluoride.length() - 1);
                float floatFluoride = std::stof(stringFluoride);
                g_fluoride_ppm = floatFluoride;
                if (ENABLE_INFO_LOGGING) printf("Fluoride: %f\n", g_fluoride_ppm);
                

               


        
        double mypHVal = currentpH; //represents pHValue for the current looprun
        double myVal2 = g_flow_rate; //represents limedispension value for the current looprun
       
        //mypHVal=randompHGen();//declares randomly generated pH value. This will change with integration code.....
        //do{
        //myVal2=limedispenGen(); //declares randomly generated lime dispension value. This will change with integration code.....
            

        //break;
        //returnFlouride();

            //might need to consider this loop.......
        
        


            
        //setProperESP32Time(currTime); //this is going to set the system time appropiately. 


        sendTimeLimeDispandpH(mypHVal, myVal2);//sends pH and lime dispension value to the database.
        //The timestamp will be implicitly sent, using the adjustString() function made in ECEN 403.


        


        
       vTaskDelay(pdMS_TO_TICKS(5000));//sets specific updates if needed to. CHANGE THIS IF NEEDED DURING INTEGRATION!!!!

    //}

    }
}


void database_app_main_loop()
{
    while (true)
    {
        database_app_main();
    }
    vTaskDelete(NULL);
}
