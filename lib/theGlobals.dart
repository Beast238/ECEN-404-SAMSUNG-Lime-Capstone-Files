//library globals;
import 'package:flutter/material.dart'; //this imports the App's material
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';//this represents the package to be used

//These values are used both in the homepage stateful class, and table stateful class.
String origpH="HomePage";//represents original pH value
String origlimedispension="HomePage2";//represents original lime dispension value
String origTime="HomePage3";//represents original time value.

DateFormat dateFormat = DateFormat("EEE MMM dd HH:mm:ss.SSS yyyy");//this date format is the new dateformat for the flutter class. This is based on the firebase timestamps.

List<DataRow> theflourideList=[];