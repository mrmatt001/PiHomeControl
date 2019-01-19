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

## Setup the database on the Primary Pi
To install the Postgres server run:

    mkdir /home/pi/PiHomeControl
    git clone https://github.com/mrmatt001/PiHomeControl /home/pi/PiHomeControl   
    Import-Module /home/pi/PiHomeControl
    Install-Postgres

## Launch EQ3PiPowerShell Script    
To run the EQ3PiPowerShell script run:

    /home/pi/PiHomeControl/HomeControl.ps1