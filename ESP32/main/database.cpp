//WIFICONNECTION CODE:

#include <stdio.h>


//the following three delcarations are related to the FreeRTOS library.
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"


#include "esp_wifi.h" //The Wifi library is used for monitoring and configuring specific settings. This is the most imporant library for this program
//For reference, the MCU from this program will be station based. Station based means that it will connect to a common wifi network(either TAMU Wifi or TAMU IOT), and use this network. 
//It needs to do this to connect to Firebase, as Firebase is also on Wifi


#include "esp_log.h" //This helps to log errors on to the terminal. It also tracks possible errors.
#include "esp_event.h" //Wifi events such as Wifi started, connected, disconnected, etc.

#include "nvs_flash.h" //Nvs flash will be used to store network settings and credentials.

#include "esp_netif.h" //used for soecific connections between ESP32 and Wifi

#include "esp_system.h" //General ESP32 system commands


//lwip represents the network type.
#include "lwip/err.h"//includes error types from lwip library
#include "lwip/sys.h"//may need this not too sure.... Is related to abstract event stuff.
//static EventGroupHandle_t s_wifi_event_group;//this is done to essentially set more indicators of state of the current wifi connection.
//For example, bit0 may represent connected, bit1 as disconnected, bit2 as getting IP address, etc.


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



bool gotIp=false;


char* returnFlouride() {//returns read in Flouride value.



esp_http_client_config_t myCfg = {//this sets the configuration/settings of the Read request. 
    //This is the most basic requirement before initializing the configuration.


    //There are a couple of parameters of interest that will be highlighted here.


    .url="https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data/Fluoride%20Data(ppm)%20value%20.json"
    
    //as seen above url is the link to the flouride value in the database.
    //the above link is where the specific value is receieved. %20 is spaces between each word.

    , 
    //Placement aspects such as port, path, query can be left as default, as the url is specified.
    //UserAgent is simply used for showing current ESPIDF type.

    //For now, it is important to keep the redirects as they are
    //There is no event handler being used(as of now) for this portion.

    //isasync is defaulted to false here, as the order of operations(checking with the database, receiving, etc, should be proper)

    .host="databaseecen403-6fb45-default-rtdb.firebaseio.com",//the host name is everything before specifying the data path.

    .method=HTTP_METHOD_GET, //this is the method type for the get request. This code is going to simply obtain the value for Flouride Data(ppm) value
    .transport_type=HTTP_TRANSPORT_OVER_TCP //the transport type(from database to espidf) will be TCP
    //This is because TCP was the previously used network interface, as described in the Wifi code.
    
    //,.skip_cert_common_name_check=true;
    //if any errors occur look into address_type
    //,.addr_family=AF_INET,

};

esp_http_client_handle_t myVar = esp_http_client_init(&myCfg);//this starts a new receieving session. 
//It returns a variable(myVar) of type client_handle(this represents the newly made client)

esp_err_t status = esp_http_client_perform(myVar);//this is actually going to perform the function itself.
//It is important to note that because the return type is an error, this will be used
//to essentially detect whether or not the operation went through AFTER it was attempted.
//This is analgous to the ESP_ERROR_CHECKS in the part for WifiConfig


char Flouride[9];//this variable represents the flouride value being inputted in from the database.
//std::string returnableFlouride;
if(status==ESP_OK) {//checks to make sure attempt is successful before beginning to read it in.
    int databaseflourlength=esp_http_client_read_response(myVar, Flouride, strlen(Flouride)-1);
    //there are 3 parameters here: the created client, the string variable flouride, and then the length of flouride.
    //BECAUSE this is a cstring, it is important to note that the last character is null terminated.
    //Meaning that the true size is just 8
    
    //databaseflourlength returns the length of the flouride value FROM the database.
    //It is important to keep in mind that this does not need to be the same as the length of the instantiated variable(Flouride[9]).
    //It is less than or equal to the length of the instantiated variable.


    Flouride[8]='\0';//sets the last index of flouride as null terminator.

    //for(int i=0;i<strlen(Flouride)-1;i++) {//stops before null character, that is why its -1 instead of the full length.
      //  returnableFlouride+=Flouride[i];
    //}
}


//for this operation, client_read response was used







//ESP_LOG_BUFFER_HEX()


esp_http_client_cleanup(myVar);//this closes the current connection being made, as the value has been read in.
//This stops the communication back and forth, for this instance.



return Flouride;//final read in flouride value from Firebase


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


        ESP_LOGI("Wifi Connection Status", "Wifi got disconnected, trying to reconnect...."); //display message to terminal that ESP is now disconnected.
        //reason gives the reason.

        esp_wifi_connect();//attempt to reconnect to Wifi after initial disruption
        //count=1;
    }

    
    else if(theBase == WIFI_EVENT && theID == WIFI_EVENT_STA_CONNECTED) { 
        //If the event's group is a wifi event, and the Id is connected
        //This is just a status check to ensure that the Wifi is still connected.

        ESP_LOGI("Wifi Connection Status", "Wifi connected, nice!"); //display message to terminal that ESP is connected.
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
        ESP_LOGI("Wifi Connection Status", "got ip address:" IPSTR, IP2STR(&myEvent->ip_info.ip));//this prints the message to the terminal. ip info just represents information found in the previously converted event. .ip is used on this, to specifically obtain the addresss.
        //IPSTR is used to format the Ip Address being found after the second comma
        
        //IP2STR simply breaks the address into different numbers(in this case, 4 numbers for the IP address) for sake of formatting.

       //gotIp=true;
       //vTaskDelay(pdMS_TO_TICKS(4000));
       //printf(returnFlouride());


       
       //printf(returnFlouride());
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

    
    
    
    //The above portion represented the initialization phase.
    //The below portion represents the Wifi SPECIFIC Configuration phase
    //This done to essentially the specify the requirements a little more, rather than keeping it as the Default one above.

    wifi_config_t myWifiConfig={//simply describes the Wifi configuration in detail
        .sta={
            .ssid="TAMU_IoT", .password=""//the network is TamuIoT, and the password is empty.
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




void sendTimeLimeDispandpH(double pH, double limeDisp) {//this function will be used to send both pH and limeDisp values.
        //pH and limeDisp will both be doubles, as this code is in C.
        //Note: the format of this is going to be VERY similar to the returnFlouride, with some key distnictions that will be noted.
        //2nd Note: this function declaration(having 2 parameters) is identical to C++ program created in 403, except now the body, will be using esp_http_client requests instead of raw curl commands.

        //As usual, there is a configuration instantiation.


    esp_http_client_config_t myCfg2 = {//this sets the configuration/settings of this request. 
    //This is the most basic requirement before initializing the configuration.


    //There are a couple of parameters of interest that will be highlighted here.


    .url="https://databaseecen403-6fb45-default-rtdb.firebaseio.com/data.json"
    
    , 
//as seen above url is the link to the entire database.

//Post will simply append a new instance to the database.

    //Note: Wifi IP is: 10.250.55.99
    //.addr_type=IPADDR_TYPE_V4,
    //the above link is where the specific value is receieved.

    //Placement aspects such as port, path, query can be left as default, as the url is specified.
    //UserAgent is simply used for showing current ESPIDF type.

    //For now, it is important to keep the redirects as they are
    //There is no event handler being used(as of now) for this portion.

    //isasync is defaulted to false here, as the order of operations(checking with the database, receiving, etc, should be proper)

    .host="databaseecen403-6fb45-default-rtdb.firebaseio.com",//the host name is everything before specifying the data path. Same host as before

    .method=HTTP_METHOD_POST, //this is the method type for the POST request. 
    //This code is going to simply append a randomly generated alphanumeric ID along with some info of pH, lime dispension, and currentTimeStamp(which comes from adjustString())
    


    .transport_type=HTTP_TRANSPORT_OVER_TCP //the transport type(from database to espidf) will be TCP
    //This is because TCP was the previously used network interface, as described in the Wifi code.
    
    //,.skip_cert_common_name_check=true;
    //if any errors occur look into address_type
    //,.addr_family=AF_INET,




};




esp_http_client_handle_t myVar2 = esp_http_client_init(&myCfg2);//this starts a new sending session(in this case). 
//It returns a variable(myVar2) of type client_handle(this represents the newly made client)

esp_err_t statusofSet=esp_http_client_set_post_field(myVar2, adjustString().c_str(), strlen(adjustString().c_str())-1);//Note: Adjust String is the official timestamp, with its appropaite decimal portions.
//Because AdjustString returns a string, it needed to be type casted to cstring, thus, c_str is used here.
//this needs to be adjusted, to also include pH and lime dispension.
//Note: this is before perform, as the espidf http_request website stated this MUST go before perform
//This logically can be attested to the fact that it requires to have to be valid sending data BEFORE the sending itself can be performed.





esp_err_t status2 = esp_http_client_perform(myVar2);//this is actually going to perform the function itself.
//It is important to note that because the return type is an error, this will be used
//to essentially detect whether or not the operation went through AFTER it was attempted.
//This is analgous to the ESP_ERROR_CHECKS in the part for WifiConfig
//)


esp_http_client_cleanup(myVar2);//cleans up this instance.

}




//esp_http_client_set_post_field, this will be used for the post request.
//esp_http_client_get_errno is a way of determining what error was found during the operation.
//esp_http_client_is_chunked_response function used to determine whether or not response is chunked.
//esp_http_client_get_status_code this is done to essentially understand what the status response is, from Firebase.
// esp_http_client_is_complete_data_received, checks if entire response is successfully read in.








void database_app_main(void) //extern C is used here, to ensure that C++ does work for this project.
{


    //esp_err_t myVal = 
    nvs_flash_init();//An attempt is made to essentially allocate Wifi credentials, etc. on to the flash. 
    //As stated in the init phase
    //nvs flash is the most unique part of the process, however, it is required to essentially ensure that the credentials, 
    //and information, are all stored appropiately in memory.
    
    
    //Note: memory deletion, and reinstantiation was previously done here, now its deleted.



    wifi_init_phase();//calls the driver for the: LWIP Stack, Event Task, and finally the Wifi Task.

    //esp_log_level_set("*", ESP_LOG_WARN);//this just prints out specific warnings.
    
//Test Printing

    
    
    
    /*
    try {
        printf(returnFlouride());
    }
    
    catch() {
        printf("Wifi Isnt proper buddy");
    }
   */

    //sendTimeLimeDispandpH(5.5, 8.9);//this will ideally send a new child to Firebase.
    //The main takeaway of doing this, is that the format of this data needs to be IDENTICAL to the format of the dummy data from 403
    //If that is true, everything(except maybe timing concerns which can be fixed) will be PERFECT!!!




}
