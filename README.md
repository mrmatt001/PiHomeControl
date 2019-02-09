# Project Purpose
Home control of eQ-3 Bluetooth Radiator Thermostats using Raspberry Pi 3 & PowerShell Core

Technologies used: PowerShell Core 6.2 (Preview 3)

## Hardware
Raspberry Pi 3 b

eQ-3 Rediator Thermostat (UK)
## Operating System
Raspbian Stretch Lite (2018-11-13)

# Build Steps

## Manual Commands (with keyboard / monitor / network)
    sudo rpi-update          
    sudo apt-get install git -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo raspi-config
    
##### Set new Password for Pi (option one)
##### Set hostname to PiHomeControl[X](option two | N1) 
##### Set to autologon console (option three |B1 | B2)
##### Set wifi country to location (option four | I4)
##### Enable ssh (option five | P2)
##### Enable ssh (option five | P2)

    sudo reboot

## Connect to Pi in headless mode (easier to copy commands from this page)

Run ifconfig to get the IP address and use PuTTY or other to ssh to the Pi and ditch the screen / keyboard

## Install PowerShell Core

There will probably be an updated version for this by the time you read it - replace the version with the file available. I opened up a browser on a PC and went to https://github.com/PowerShell/PowerShell/releases then copied and pasted the latest version (Preview 3 at time of writing). Use the latest / released version and update the wget / tar / rm lines accordingly

    sudo apt-get install libunwind8 -y
    wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.3/powershell-6.2.0-preview.3-linux-arm32.tar.gz
    mkdir /home/pi/powershell
    tar -xvf /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz -C /home/pi/powershell
    rm /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz
    
## Set PowerShell Core to Run at Logon
    
    sudo /home/pi/powershell/pwsh
    Add-Content -Path /home/pi/.bashrc -value "echo Launching PowerShell"
    Add-Content -Path /home/pi/.bashrc -value "sudo /home/pi/powershell/pwsh"

## Reboot the Raspberry Pi

    sudo reboot

## Clone the PiHomeControl 
To clone run:

    mkdir /home/pi/PiHomeControl
    git clone https://github.com/mrmatt001/PiHomeControl /home/pi/PiHomeControl   
    Import-Module /home/pi/PiHomeControl
    
## Option 1 : Setup the database on the Primary Pi
A Postgres database can be installed on the Pi or another server. 
To install the Postgres server run:

    Install-Postgres
    Install-HomeControlDB -DBUser dbuser -DBPassword {PASSWORD}

## Option 2 : Setup the database on another server
Install a Postgres instance. I've followed the guide at https://sondregronas.com/managing-postgresql-on-a-synology-server/ to get it working on my Synology NAS. I then ran the following commands at an SSH window on the Synology box:  

    sudo -u postgres psql -c 'CREATE DATABASE homecontrol;'
    sudo -u postgres psql homecontrol -c "create role dbuser with login password '{PASSWORD}';"
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pidevices(piid SERIAL PRIMARY KEY,pihostname VarChar(15) NOT NULL,ostype VarChar(10));'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS eq3thermostats(eq3id SERIAL PRIMARY KEY,eq3macaddress VarChar(17) UNIQUE NOT NULL,friendlyname VarChar(50),currenttemperature INT);'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pitoeq3(pihostname VarChar(15) NOT NULL,eq3macaddress VarChar(17) NOT NULL);'
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pidevices TO dbuser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON eq3thermostats TO dbuser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pitoeq3 TO dbuser;"
    sudo -u postgres psql homecontrol -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dbuser;"

## Register each Raspberry Pi to the Postrgres DB

    Register-PiDevice -DBServer {DBServer} -DBName homecontrol -DBUser dbuser -DBPassword {PASSWORD}

## Launch EQ3PiPowerShell Script    
To run the EQ3PiPowerShell script run:

    /home/pi/PiHomeControl/HomeControl.ps1