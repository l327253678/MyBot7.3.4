; #FUNCTION# ====================================================================================================================
; Name ..........: Pico Auto Upgrade (v6.1)
; Description ...: This file contains all functions of Pico Auto Upgrade feature
; Syntax ........: ---
; Parameters ....: ---
; Return values .: ---
; Author ........: RoroTiti
; Modified ......: 22/07/2017 (full rewrite from A to Z)
; Remarks .......: This file is part of MyBotRun. Copyright 2017
;                  MyBotRun is distributed under the terms of the GNU GPL
; Related .......: ---
; Link ..........: https://www.mybot.run
; Example .......: ---
;================================================================================================================================
Func randomSleep($SleepTime, $Range = 0)
	If $g_bRunState = False Then Return
	If $Range = 0 Then $Range = Round($SleepTime / 5)
	Local $SleepTimeF = Random($SleepTime - $Range, $SleepTime + $Range, 1)
	If $g_bDebugClick Then Setlog("Default sleep : " & $SleepTime & " - Random sleep : " & $SleepTimeF, $COLOR_ORANGE)
	If _Sleep($SleepTimeF) Then Return
EndFunc   ;==>randomSleep

Func AutoUpgrade($bTest = False)
	Local $bWasRunState = $g_bRunState
	$g_bRunState = True
	Local $Result = _AutoUpgrade()
	$g_bRunState = $bWasRunState
	Return $Result
EndFunc

Func _AutoUpgrade()
	If $g_iChkAutoUpgrade = 0 Then Return ; disabled, no need to continue...

	SetLog("Entering Auto Upgrade...", $COLOR_INFO)
	Local $iLoopAmount = 0
	Local $iLoopMax = 6

	While 1

		$iLoopAmount += 1
		If $iLoopAmount >= $iLoopMax Or $iLoopAmount >= 12 Then ExitLoop ; 6 loops max, to avoid infinite loop

		ClickP($aAway, 1, 0, "#0000") ;Click Away
		randomSleep(1000)
		VillageReport()

		If $g_iFreeBuilderCount < 1 Then
			SetLog("No builder available... Skipping Auto Upgrade...", $COLOR_WARNING)
			ExitLoop
		EndIf

		; check if Save builder for walls is active
		If $g_bUpgradeWallSaveBuilder And ($g_iFreeBuilderCount < 2) Then
			SetLog("The only builder available must be kept for walls... Skipping Auto Upgrade...", $COLOR_WARNING)
			ExitLoop
		EndIf

		; check if builder head is clickable
		If Not (_ColorCheck(_GetPixelColor(275, 15, True), "F5F5ED", 20) = True) Then
			SetLog("Unable to find the Builder menu button... Exiting Auto Upgrade...", $COLOR_ERROR)
			ExitLoop
		EndIf

		; open the builders menu
		Click(295, 30)
		If _Sleep(1000) Then Return

		; search for 000 in builders menu, if 000 found, a possible upgrade is available
		If QuickMIS("BC1", $g_sImgAUpgradeZero, 180, 80 + $g_iNextLineOffset, 480, 350) Then
			SetLog("Possible upgrade found !", $COLOR_SUCCESS)
			$g_iCurrentLineOffset = $g_iNextLineOffset + $g_iQuickMISY
		Else
			SetLog("No upgrade available... Exiting Auto Upgrade...", $COLOR_INFO)
			ExitLoop
		EndIf

		; check in the line of the 000 if we can see "New" or the Gear of the equipment, in this case, will not do the upgrade
		If QuickMIS("NX",$g_sImgAUpgradeObst, 180, 80 + $g_iCurrentLineOffset - 15, 480, 80 + $g_iCurrentLineOffset + 15) <> "none" Then
			SetLog("This is a New Building or an Equipment... Looking next...", $COLOR_WARNING)
			$g_iNextLineOffset = $g_iCurrentLineOffset
			ContinueLoop
		EndIf

		; if it's an upgrade, will click on the upgrade, in builders menu
		Click(180 + $g_iQuickMISX, 80 + $g_iCurrentLineOffset)
		If _Sleep(500) Then Return

		; check if any wrong click by verifying the presence of the Upgrade button (the hammer)
		If Not QuickMIS("BC1", $g_sImgAUpgradeUpgradeBtn, 120, 630, 740, 670) Then
			SetLog("No upgrade here... Wrong click, looking next...", $COLOR_WARNING)
			;$g_iNextLineOffset = $g_iCurrentLineOffset -> not necessary finally, but in case, I keep lne commented
			ContinueLoop
		EndIf

		; get the name and actual level of upgrade selected, if strings are empty, will exit Auto Upgrade, an error happens
		$g_aUpgradeNameLevel = BuildingInfo(242, 520 + $g_iBottomOffsetY)
		If $g_aUpgradeNameLevel[0] = "" Then
			SetLog("Error when trying to get upgrade name and level... Exiting Auto Upgrade...", $COLOR_ERROR)
			ExitLoop
		EndIf

		Local $bMustIgnoreUpgrade = False
		; matchmaking between building name and the ignore list
		Switch $g_aUpgradeNameLevel[1]
			Case "Town Hall"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[0] = 1) ? True : False
			Case "Barbarian King"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[1] = 1 Or $g_bUpgradeKingEnable = True) ? True : False ; if upgrade king is selected, will ignore it
			Case "Archer Queen"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[2] = 1 Or $g_bUpgradeQueenEnable = True) ? True : False ; if upgrade queen is selected, will ignore it
			Case "Grand Warden"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[3] = 1 Or $g_bUpgradeWardenEnable = True) ? True : False ; if upgrade warden is selected, will ignore it
			Case "Clan Castle"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[4] = 1) ? True : False
			Case "Laboratory"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[5] = 1) ? True : False
			Case "Barracks"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[6] = 1) ? True : False
			Case "Dark Barracks"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[7] = 1) ? True : False
			Case "Spell Factory"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[8] = 1) ? True : False
			Case "Dark Spell Factory"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[9] = 1) ? True : False
			Case "Gold Mine"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[10] = 1) ? True : False
			Case "Elixir Collector"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[11] = 1) ? True : False
			Case "Dark Elixir Drill"
				$bMustIgnoreUpgrade = ($g_iChkUpgradesToIgnore[12] = 1) ? True : False
			Case Else
				$bMustIgnoreUpgrade = False
		EndSwitch

		; check if the upgrade name is on the list of upgrades that must be ignored
		If $bMustIgnoreUpgrade = True Then
			SetLog("This upgrade must be ignored... Looking next...", $COLOR_WARNING)
			$g_iNextLineOffset = $g_iCurrentLineOffset
			ContinueLoop
		EndIf

		; if upgrade don't have to be ignored, click on the Upgrade button to open Upgrade window
		Click(120 + $g_iQuickMISX, 630 + $g_iQuickMISY)
		If _Sleep(1000) Then Return

		Switch $g_aUpgradeNameLevel[1]
			Case "Barbarian King", "Archer Queen", "Grand Warden"
				$g_aUpgradeResourceCostDuration[0] = QuickMIS("N1", $g_sImgAUpgradeRes, 690, 540, 730, 580) ; get resource
				$g_aUpgradeResourceCostDuration[1] = getResourcesBonus(598, 519 + $g_iMidOffsetY) ; get cost
				$g_aUpgradeResourceCostDuration[2] = getHeroUpgradeTime(464, 527 + $g_iMidOffsetY) ; get duration
			Case Else
				$g_aUpgradeResourceCostDuration[0] = QuickMIS("N1", $g_sImgAUpgradeRes, 460, 510, 500, 550) ; get resource
				$g_aUpgradeResourceCostDuration[1] = getResourcesBonus(366, 487 + $g_iMidOffsetY) ; get cost
				$g_aUpgradeResourceCostDuration[2] = getBldgUpgradeTime(195, 307 + $g_iMidOffsetY) ; get duration
		EndSwitch

		; if one of the value is empty, there is an error, we must exit Auto Upgrade
		For $i = 0 To 2
			If $g_aUpgradeResourceCostDuration[$i] = "" Then
				SetLog("Error when trying to get upgrade details... Exiting Auto Upgrade...", $COLOR_ERROR)
				ExitLoop 2
			EndIf
		Next

		Local $bMustIgnoreResource = False
		; matchmaking between resource name and the ignore list
		Switch $g_aUpgradeResourceCostDuration[0]
			Case "Gold"
				$bMustIgnoreResource = ($g_iChkResourcesToIgnore[0] = 1) ? True : False
			Case "Elixir"
				$bMustIgnoreResource = ($g_iChkResourcesToIgnore[1] = 1) ? True : False
			Case "Dark Elixir"
				$bMustIgnoreResource = ($g_iChkResourcesToIgnore[2] = 1) ? True : False
			Case Else
				$bMustIgnoreResource = False
		EndSwitch

		; check if the resource of the upgrade must be ignored
		If $bMustIgnoreResource = True Then
			SetLog("This resource must be ignored... Looking next...", $COLOR_WARNING)
			$g_iNextLineOffset = $g_iCurrentLineOffset
			ContinueLoop
		EndIf

		; initiate a False boolean, that firstly says that there is no sufficent resource to launch upgrade
		Local $bSufficentResourceToUpgrade = False
		; if Cost of upgrade + Value set in settings to be kept after upgrade > Current village resource, make boolean True and can continue
		Switch $g_aUpgradeResourceCostDuration[0]
			Case "Gold"
				If $g_aiCurrentLoot[$eLootGold] >= ($g_aUpgradeResourceCostDuration[1] + $g_iTxtSmartMinGold) Then $bSufficentResourceToUpgrade = True
			Case "Elixir"
				If $g_aiCurrentLoot[$eLootElixir] >= ($g_aUpgradeResourceCostDuration[1] + $g_iTxtSmartMinElixir) Then $bSufficentResourceToUpgrade = True
			Case "Dark Elixir"
				If $g_aiCurrentLoot[$eLootDarkElixir] >= ($g_aUpgradeResourceCostDuration[1] + $g_iTxtSmartMinDark) Then $bSufficentResourceToUpgrade = True
		EndSwitch
		; if boolean still False, we can't launch upgrade, exiting...
		If Not $bSufficentResourceToUpgrade Then
			SetLog("Unsufficent " & $g_aUpgradeResourceCostDuration[0] & " to launch this upgrade...", $COLOR_WARNING)
			ExitLoop
		EndIf

		; final click on upgrade button, click coord is get looking at upgrade type (heroes have a diferent place for Upgrade button)
		Switch $g_aUpgradeNameLevel[1]
			Case "Barbarian King", "Archer Queen", "Grand Warden"
				Click(660, 560)
			Case Else
				Click(440, 530)
		EndSwitch

		; Upgrade completed, but at the same line there might be more...
		$g_iCurrentLineOffset -= $g_iQuickMISY
		$iLoopMax += 1

		; update Logs and History file
		SetLog("Launched upgrade of " & $g_aUpgradeNameLevel[1] & " to level " & $g_aUpgradeNameLevel[2] + 1 & " successfully !", $COLOR_SUCCESS)
		SetLog(" - Cost : " & _NumberFormat($g_aUpgradeResourceCostDuration[1]) & " " & $g_aUpgradeResourceCostDuration[0], $COLOR_SUCCESS)
		SetLog(" - Duration : " & $g_aUpgradeResourceCostDuration[2], $COLOR_SUCCESS)

		_GUICtrlEdit_AppendText($g_hTxtAutoUpgradeLog, _
				@CRLF & _NowDate() & " " & _NowTime() & _
				" - Upgrading " & $g_aUpgradeNameLevel[1] & _
				" to level " & $g_aUpgradeNameLevel[2] + 1 & _
				" for " & _NumberFormat($g_aUpgradeResourceCostDuration[1]) & _
				" " & $g_aUpgradeResourceCostDuration[0] & _
				" - Duration : " & $g_aUpgradeResourceCostDuration[2])

		_FileWriteLog($g_sProfileLogsPath & "\AutoUpgradeHistory.log", _
				"Upgrading " & $g_aUpgradeNameLevel[1] & _
				" to level " & $g_aUpgradeNameLevel[2] + 1 & _
				" for " & _NumberFormat($g_aUpgradeResourceCostDuration[1]) & _
				" " & $g_aUpgradeResourceCostDuration[0] & _
				" - Duration : " & $g_aUpgradeResourceCostDuration[2])

	WEnd

	; resetting the offsets of the lines
	$g_iCurrentLineOffset = 0
	$g_iNextLineOffset = 0

	SetLog("Auto Upgrade finished", $COLOR_INFO)
	ClickP($aAway, 1, 0, "#0000") ;Click Away

EndFunc   ;==>AutoUpgrade