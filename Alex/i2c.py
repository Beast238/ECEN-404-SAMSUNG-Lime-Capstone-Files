#!/usr/bin/python3
import os

SWITCH_ID = "0x70"
DAC_ID = "0x48"
BUS_ID = "0"

def set(id, addr, byt):
    if id == "SWITCH": id = SWITCH_ID
    if id == "DAC": id = DAC_ID
    return os.popen("sudo i2cset -a -y " + BUS_ID + " " + id + " " + addr + " " + byt).read().strip()

def get(id, addr):
    if id == "SWITCH": id = SWITCH_ID
    if id == "DAC": id = DAC_ID
    return os.popen("sudo i2cget -a -y " + BUS_ID + " " + id + " " + addr).read().strip()

print("Welcome to the Interactive Solenoid Control software.\nThis is a debugging utility for manually controlling solenoid valves in the Samsung Control and Dispense System for Lime Treatment.")
while True:
    inp = input("> ").split(" ")
    if len(inp) == 0:
        inp = ["help"]
    cmd = inp.pop()
    if cmd == "help":
        print("Commands:")
        print("set_valve <none/0/1/2/3> - set the currently selected valve")
        print("set_duty_cycle <percent> - set the duty cycle of the currently selected valve")
        print("get <SWITCH/DAC/slave address> <data address> - send an I2C get instruction")
        print("set <SWITCH/DAC/slave address> <data address> <value> - send an I2C set instruction")
        print("quit - exit the software")
    elif cmd == "quit":
        break
    elif cmd == "set_valve":
        try:
            arg1 = inp.pop()
            if arg1 == "none":
                set(SWITCH_ID, "0x00", "0x00")
            else:
                set(SWITCH_ID, "0x00", "0x" + str(2 ** int(arg1)))
            print('Set valve')
        except:
            print("Failed")
    elif cmd == "set_duty_cycle":
        res = ""
        try:
            arg1raw = int(float(inp.pop())/100 * 256)
            if arg1raw > 0xFF: arg1raw = 0xFF
            if arg1raw < 0: arg1raw = 0
            arg1 = hex(arg1raw)
            res = set(DAC_ID, "0x00", arg1)
        except:
            print("Failed")

        if res != "":
            try:
                if len(res) > 2 and res[:2] == "0x":
                    new_percent = float(int(res, 16)) / 256 * 100
                    print(f"Set duty cycle to {new_percent:.2f}")
            except:
                print(res)
    elif cmd == "set":
        try:
            arg1 = inp.pop()
            arg2 = inp.pop()
            arg3 = inp.pop()
            res = set(arg1, arg2, arg3)
            print(res)
        except:
            print("Failed")
    elif cmd == "get":
        try:
            arg1 = inp.pop()
            arg2 = inp.pop()
            res = get(arg1, arg2)
            print(res)
        except:
            print("Failed")