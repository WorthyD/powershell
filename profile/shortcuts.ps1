function dev() {
    cd $env:devPath
}

function xp() {
    explorer .
}
function nvimedit() {
    cd $env:nvimPath
}

function giteager() {
    git add .
    git commit -a -m "Stuff"
    git push
}


function nuke_node { rimraf .\node_modules } 

function foo() {
    & "$env:foobarPath\foobar2000.exe"
}

function fp() {
    & "$env:foobarPath\foobar2000.exe" /playpause
}

function fpause() {
    & "$env:foobarPath\foobar2000.exe" /stop
}

function fn() {
    & "$env:foobarPath\foobar2000.exe" /next
}

function winp() {
    & "C:\Users\jisaaec\OneDrive - J.B. Hunt Transport\Documents\PowerShell\CLEveR.exe" stop
}


function edithost() {
    Start-Process code -ArgumentList C:\Windows\System32\drivers\etc\hosts -Verb RunAs
}

# function blync-list{
#  echo 'busy blync- clear busy dnd'
# }

# function bl-clear(){
#     Set-BLyncLight -Color Green 
# }
# function avail(){
#     Set-BLyncLight -Color Orange
# }
# function busy(){
#     Set-BLyncLight -Color Orange
# }
# function bl-busy(){
#     Set-BLyncLight -Color Orange
# }
# function bl-dnd(){
#     Set-BLyncLight -Color Magenta 
# }


# Function Set-BLyncLight {
# #Version 2

# [CmdletBinding()]
# Param(
#    [Parameter(Mandatory=$True,Position=1)]
#    [string]$Color,
#    [switch]$LightFlash,
#    [int]$LightFlashSpeed,
#    [switch]$DimLight,
#    [int]$MusicTone,
#    [int]$MusicVolume,
#    [int]$MusicPlayDuration,
#    [int]$ColorFlashCount
   
# )

# #Region Load blynclight API

# Add-Type -Path "C:\Egnyte\Private\daniel.worthy\Documents\blync-app\Blynclight.dll"

# $oBlynclightController = New-Object -TypeName Blynclight.BlynclightController
# #Endregion

# if ($oBlynclightController.InitBlyncDevices() -ne 0) {
# 	#Set Color
# 	if ($Color) {
# 		Switch ($Color) {
# 			Blue {$oBlynclightController.TurnOnBlueLight(0) | Out-Null}
# 			Cyan {$oBlynclightController.TurnOnCyanLight(0) | Out-Null}
# 			Green {$oBlynclightController.TurnOnGreenLight(0) | Out-Null}
# 			Magenta {$oBlynclightController.TurnOnMagentaLight(0) | Out-Null}
# 			Orange {$oBlynclightController.TurnOnOrangeLight(0) | Out-Null}
# 			Red {$oBlynclightController.TurnOnRedLight(0) | Out-Null}
# 			White {$oBlynclightController.TurnOnWhiteLight(0) | Out-Null}
# 			Yellow {$oBlynclightController.TurnOnRGBLights(0,255,255,0) | Out-Null}
# 			Police {
# 				if (!$ColorFlashCount) {
# 					$ColorFlashCount = 100
# 				}
# 				$i = 0
# 				do {
# 					$oBlynclightController.TurnOnBlueLight(0) | Out-Null
# 					Start-Sleep -milliseconds 500
# 					$oBlynclightController.TurnOnRedLight(0) | Out-Null
# 					Start-Sleep -milliseconds 500
# 					$i++
# 				}
# 				while ($i -lt $ColorFlashCount)
# 				$oBlynclightController.TurnOnBlueLight(0) | Out-Null
			
# 			}
# 			Fire {
# 				if (!$ColorFlashCount) {
# 					$ColorFlashCount = 100
# 				}
# 				$i = 0
# 				do {
# 					$oBlynclightController.TurnOnRedLight(0) | Out-Null
# 					Start-Sleep -milliseconds 500
# 					$oBlynclightController.TurnOnRGBLights(0,255,255,0) | Out-Null
# 					Start-Sleep -milliseconds 500
# 					$i++
# 				}
# 				while ($i -lt $ColorFlashCount)
# 				$oBlynclightController.TurnOnRedLight(0) | Out-Null
			
# 			}
# 			Off {$oBlynclightController.ResetLight(0) | Out-Null}
# 			Default {
# 				[int]$red=$Color.Split(",")[0]
# 				[int]$green=$Color.Split(",")[1]
# 				[int]$blue=$Color.Split(",")[2]
# 				$oBlynclightController.TurnOnRGBLights(0,$red,$green,$blue) | Out-Null
# 			}
# 		}
# 	}
# 	#Set Light Flash
# 	if ($LightFlash) {
# 		#Set Light Flash Speed
# 		if (!$LightFlashSpeed) {
# 			#Set light flash speed to medium if speed not specified
# 			$oBlynclightController.SelectLightFlashSpeed(0,2) | Out-Null
# 		}
# 		else {
# 			$oBlynclightController.SelectLightFlashSpeed(0,$LightFlashSpeed) | Out-Null
# 		}
# 		$oBlynclightController.StartLightFlash(0) | Out-Null
# 	}
# 	else {
# 		$oBlynclightController.StopLightFlash(0) | Out-Null
# 	}
# 	#Set Dim
# 	if ($DimLight) {
# 		$oBlynclightController.SetLightDim(0) | Out-Null
# 	}
# 	else {
# 		$oBlynclightController.ClearLightDim(0) | Out-Null
# 	}
# 	$oBlynclightController.CloseDevices(0)
# }

# else {Write "No BLyncLight device found."}
# }
