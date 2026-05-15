/**
 * ExtendedInformationRedux3_UITacticalHUD_ShotHUD
 *
 * Custom tactical HUD class responsible for displaying shot-related
 * information in XCOM 2 with the Extended Information Redux 3 mod.
 *
 * Responsibilities:
 * - Display Hit, Crit, Graze, and Miss chances for abilities
 * - Show Crit Damage preview for abilities with damage output
 * - Handle dynamic UI layout based on screen resolution and DLC availability
 * - Render visual hit bars and UI text elements, including assist and aim bonuses
 * - Integrate counterattack logic for melee and special abilities
 * - Respect user-configurable settings from the Mod Config Menu (MCM)
 *
 * @author Mr.Nice / Sebkulu
 */
class ExtendedInformationRedux3_UITacticalHUD_ShotHUD extends UITacticalHUD_ShotHUD config(ShotHUD) dependson(ExtendedInformationRedux3_UITacticalHUD_ShotWings, HackCalcLib);

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\LangFallBack.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_UtilityMacros.uci)

var UIBGBox BarBoxes[5];
var UIScrollingText SlotValues[4];
var UIScrollingText SlotLabels[4];

// In which ShotHUD slots should "Critical Damage" be printed. "Left 1" = 0, "Left 2" = 1, "Right 1" = 2, "Right 2" = 3
var array<int> CritDamageSlotIndices;
var array<int> GrazeChanceSlotIndices;
var array<int> ExpectedDamageSlotIndices;

var int BAR_HEIGHT, BAR_OFFSET_X, BAR_OFFSET_Y, BAR_POSITION_Y, GENERAL_OFFSET_Y;
var int MAX_ABILITIES_PER_ROW;
var int LabelFontSize, ValueFontSize, TEXTWIDTH;
var int BAR_ALPHA;
var string BarColours[5];
var int GRAZE_CRIT_LAYOUT;
var float LabelsOffset, BAR_WIDTH_MULT;

var bool HIT_SHOW_NonTRIVIAL;
var bool GRAZE_SHOW_NonTRIVIAL;
var bool CRIT_SHOW_NonTRIVIAL;
var bool CRIT_HIDE_TRIVIAL;
var bool BAR_HIDE_TRIVIAL;

var bool TH_ASSIST_BAR;
var bool DISPLAY_MISS_CHANCE;
var bool TH_SHOW_GRAZED;
var bool TH_SHOW_CRIT_DMG;
var bool TH_AIM_LEFT_OF_CRIT;
var bool TH_ASSIST_BESIDE_HIT;
var bool TH_PREVIEW_MINIMUM;

var array<int> SHOTHUD_LAYOUT;

var localized string CRIT_DAMAGE_LABEL, GRAZE_CHANCE_LABEL, MISS_CHANCE_LABEL, EXPECTED_DAMAGE_LABEL;

struct ShotHUDSlotOffset
{
	var int OffsetX;
	var int OffsetY;
	var bool bAlignRight;
};

struct ResOffsetSt
{
	var string Res;
	var float offset;
	var int ResX;
	var int ResY;
};

var config array<ShotHUDSlotOffset> SlotOffsets;
var config array<ResOffsetSt> ResOffset;

var config bool bEnableTestMode;
var config int iMockHit, iMockGraze, iMockMinDamage, iMockMaxDamage, iMockCritChance, iMockCritMinDamageBonus, iMockCritMaxDamageBonus;
var config float fMockExpectedDamage;

/**
 * Initializes the Shot HUD and sets up layout.
 *
 * @return self Reference to this initialized ShotHUD instance.
 */
simulated function UITacticalHUD_ShotHUD InitShotHUD()
{
	`TRACE_ENTRY("");
	Super.InitShotHUD();
	InitLayout();
	`TRACE_EXIT("");
	return self;
}

/**
 * Initializes layout, UI elements, and offsets for the ShotHUD.
 */
simulated function InitLayout()
{
	local int Index, i;
	local int ResX, ResY;
	local int RenderWidth, RenderHeight, FullWidth, FullHeight, AlreadyAdjustedVerticalSafeZone;
	local float RenderAspectRatio, FullAspectRatio;
	local string searchString, searchString2;

	`TRACE_ENTRY("");
	LabelsOffset = 0;
	Movie.GetScreenDimensions(RenderWidth, RenderHeight, RenderAspectRatio, FullWidth, FullHeight, FullAspectRatio, AlreadyAdjustedVerticalSafeZone);
	ResX = RenderWidth;
	ResY = RenderHeight;
	searchString = "p" $ ResX $ "x" $ ResY;

	Index = ResOffset.Find('Res', searchString);

	if(Index == INDEX_NONE)
	{
		FindClosestRes(ResX, ResY);
		searchString2 = "p" $ ResX $ "x" $ ResY;
		Index = ResOffset.Find('Res', searchString2);
	}

	if(Index != INDEX_NONE)
	{
		LabelsOffset = ResOffset[Index].offset;
	}

	// Init MCM Config Variables
	BAR_HEIGHT = getBAR_HEIGHT();
	BAR_ALPHA = getBAR_ALPHA();
	BAR_OFFSET_Y = BAR_POSITION_Y -BAR_HEIGHT + getBAR_OFFSET_Y();
	BarColours[0] = getHIT_HEX_COLOR();
	BarColours[1] = getCRIT_HEX_COLOR();
	BarColours[2] = getDODGE_HEX_COLOR();
	BarColours[3] = getASSIST_HEX_COLOR();
	BarColours[4] = getMISS_HEX_COLOR();
	SHOTHUD_LAYOUT = getSHOTHUD_LAYOUT();
		
	TH_ASSIST_BAR = getTH_ASSIST_BAR();
	TH_SHOW_GRAZED = getTH_SHOW_GRAZED();
	TH_SHOW_CRIT_DMG = getTH_SHOW_CRIT_DMG();
	TH_ASSIST_BESIDE_HIT = getTH_ASSIST_BESIDE_HIT();
	TH_AIM_LEFT_OF_CRIT = getTH_AIM_LEFT_OF_CRIT();
	TH_PREVIEW_MINIMUM = getTH_PREVIEW_MINIMUM();
	DISPLAY_MISS_CHANCE = getDISPLAY_MISS_CHANCE();

	for (i = 0; i < 4; i++)
	{
		SlotValues[i] = CreateShotHUDText(self);
		SlotLabels[i] = CreateShotHUDText(self);
	}

	// Clear the arrays prior to populating them
	GrazeChanceSlotIndices.Length = 0;
	CritDamageSlotIndices.Length = 0;
	ExpectedDamageSlotIndices.Length = 0;

	// Determine in which Shot HUD slots to print stats
	for (i = 0; i < SHOTHUD_LAYOUT.Length; i++)
	{
		// Collapse Slot 1 into Slot 0 if Slot 0 is unused
		if (i == 1 && SHOTHUD_LAYOUT[0] == 0 && SHOTHUD_LAYOUT[1] != 0)
		{
			AddStatToSlotArray(SHOTHUD_LAYOUT[1], 0);
			continue;
		}

		// Skip actual Slot 1 because it was remapped
		if (i == 1 && SHOTHUD_LAYOUT[0] == 0 && SHOTHUD_LAYOUT[1] != 0) continue;

		AddStatToSlotArray(SHOTHUD_LAYOUT[i], i);
	}
	
	for(Index=0; Index<ArrayCount(BarBoxes); Index++)
	{
		BarBoxes[Index]=Spawn(class'UIBGBox', self)
			.InitBG(,,, 60, BAR_HEIGHT)
			.SetBGColor("gray_highlight");
		BarBoxes[Index].SetColor(BarColours[Index])
			.AnchorBottomCenter()
			.SetAlpha(BAR_ALPHA);
		BarBoxes[Index].Hide();
	}
	`TRACE_EXIT("");
}

/**
 * Finds the closest matching resolution from the ResOffset array.
 *
 * @param out ResX Width of the closest resolution.
 * @param out ResY Height of the closest resolution.
 */
simulated function FindClosestRes(out int ResX, out int ResY)
{
	local ResOffsetSt ResOffsetItem;
	local int tempInt, smallestDiff, i, tempResX, tempResY;
	
	`TRACE_ENTRY("");
	foreach ResOffset(ResOffsetItem, i)
	{
		tempInt = Abs(ResY - ResOffsetItem.ResY);
		if ((tempResY == 0) || (tempResY != 0 && tempInt < smallestDiff))
		{
			smallestDiff = tempInt;
			tempResY = ResOffsetItem.ResY;
		}
	}
	foreach ResOffset(ResOffsetItem, i)
	{
		if (tempResY == ResOffsetItem.ResY)
		{
			tempInt = Abs(ResX - ResOffsetItem.ResX);
			if ((tempResX == 0) || (tempResX != 0 && tempInt < smallestDiff))
			{
				smallestDiff = tempInt;
				tempResX = ResOffsetItem.ResX;
			}
		}
	}
	ResX = tempResX;
	ResY = tempResY;
	`TRACE_EXIT("ResX:" @ ResX $ ", ResY:" @ ResY);
}

/**
 * Updates Shot HUD every frame to reflect current ability and target state.
 */
simulated function Update() 
{
    local bool isValidShot, IsSkPostMelee;
    local string ShotName, ShotDescription, StatContestEffectChances, ApplyChanceAbilityChances;
    local int HitChance, skHitChance, CritChance, GrazeChance, TargetIndex, AimBonus, skAimBonus, BarOffsetY;
    local ShotBreakdown kBreakdown;
    local StateObjectReference Target, EmptyRef;
    local XComGameState_Ability SelectedAbilityState, skAbilityState;
    local X2AbilityTemplate SelectedAbilityTemplate;
    local AvailableAction SelectedUIAction;
    local AvailableTarget kTarget;
    local XGUnit ActionUnit;
    local UITacticalHUD TacticalHUD;
    local UIUnitFlag UnitFlag;
    //local WeaponDamageValue MinDamageValue, MaxDamageValue;
    local X2TargetingMethod TargetingMethod;
    local bool WillBreakConcealment, WillEndTurn, bHide;
	local DamageBreakdown NormalDamage, CritDamage;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	// New from Grimy Shot Bar
	local string FontString;
   	local int offsetX, Current, i, j;
	local float Chance[4];
	local float fExpectedDamage;

	`TRACE_ENTRY("");
    TacticalHUD = UITacticalHUD(Screen);
	History=`XCOMHISTORY;
 
    SelectedUIAction = TacticalHUD.GetSelectedAction();
	fExpectedDamage = 0.0;
	if (SelectedUIAction.AbilityObjectRef.ObjectID > 0)
	{ //If we do not have a valid action selected, ignore this update request
		SelectedAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
		UnitState=XComGameState_Unit(History.GetGameStateForObjectID(SelectedAbilityState.OwnerStateObject.ObjectID));
		ActionUnit = XGUnit(UnitState.GetVisualizer());
		TargetingMethod = TacticalHUD.GetTargetingMethod();
		if( TargetingMethod != None )
		{
			TargetIndex = TargetingMethod.GetTargetIndex();
			if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
			{
				kTarget = SelectedUIAction.AvailableTargets[TargetIndex];
				Target = kTarget.PrimaryTarget;

			}
		}

		//Update L3 help and OK button based on ability.
		//*********************************************************************************
		if (SelectedUIAction.bFreeAim)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = true;
		}
		else if (SelectedUIAction.AvailableTargets.Length == 0 || SelectedUIAction.AvailableTargets[0].PrimaryTarget.ObjectID < 1)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = false;
		}
		else
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), Movie.IsMouseActive());
			isValidShot = true;
		}
 
		//Set shot name / help text
		//*********************************************************************************
		ShotName = SelectedAbilityState.GetMyFriendlyName(kTarget.PrimaryTarget);
 
		if (SelectedUIAction.AvailableCode == 'AA_Success')
		{
			ShotDescription = SelectedAbilityState.GetMyHelpText();
			if (ShotDescription == "") ShotDescription = "Missing 'LocHelpText' from ability template.";
		}
		else
		{
			ShotDescription = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(SelectedUIAction.AvailableCode);
		}
 
 
		WillBreakConcealment = SelectedAbilityState.MayBreakConcealmentOnActivation(Target.ObjectID);
		WillEndTurn = SelectedAbilityState.WillEndTurn();

		StatContestEffectChances = getHIDE_STAT_CONTEST() ? "" : class'StatContestLib'.static.GetStatContestEffectChancesString(SelectedAbilityState, Target, kTarget);
		if (StatContestEffectChances != "")
		{
			ShotDescription = StatContestEffectChances $ "\n" $ ShotDescription;
		} 
		else
		{
			ApplyChanceAbilityChances = getPREVIEW_APPLY_CHANCE() ? class'ApplyChanceLib'.static.GetApplyChancesString(SelectedAbilityState, Target, kTarget) : "";
			if (ApplyChanceAbilityChances != "") ShotDescription = ApplyChanceAbilityChances $ "\n" $ ShotDescription;
		}

		//AS_SetShotInfo(ShotName, ShotDescription, WillBreakConcealment, WillEndTurn);
		// Display Hack Info if relevant
		AS_SetShotInfo(ShotName, UpdateHackDescription(SelectedAbilityState, Target, ShotDescription), WillBreakConcealment, WillEndTurn);
 
		// Disable Shot Button if we don't have a valid target.
		AS_SetShotButtonDisabled(!isValidShot);
 
		ResetDamageBreakdown();
		
		if (SelectedUIAction.AvailableCode != 'AA_Success')
		{
			HideAll();
			return;
		}

		if(SelectedAbilityTemplate.DataName=='SkirmisherVengeance'
			|| SelectedAbilityTemplate.DataName=='Justice')
		{
			IsSkPostMelee=true;
			skAbilityState=XComGameState_Ability(History.GetGameStateForObjectID(UnitState.FindAbility('SkirmisherPostAbilityMelee').ObjectID));
		}
		else skAbilityState=SelectedAbilityState;
		// In the rare case that this ability is self-targeting, but has a multi-target effect on units around it,
		// look at the damage preview, just not against the target (self).
		if (SelectedAbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Self')
			&& SelectedAbilityTemplate.AbilityMultiTargetStyle != none
			&& SelectedAbilityTemplate.AbilityMultiTargetEffects.Length > 0 )
		{
			class'DamagePreviewLib'.static.GetDamagePreview(skAbilityState, EmptyRef, NormalDamage, CritDamage);
		}
		else class'DamagePreviewLib'.static.GetDamagePreview(skAbilityState, Target, NormalDamage, CritDamage);

        //Set up percent to hit / crit values
        //*********************************************************************************
        if (SelectedAbilityTemplate.AbilityToHitCalc != none && SelectedAbilityState.iCooldown == 0)
		{
			//Mr. Nice: these three lines from Firaxis original)
           /*****************************************************/
            class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(SelectedAbilityState, kTarget, kBreakdown, AimBonus);
			HitChance = Clamp(((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);
		    if(IsSkPostMelee)
		    {
			   class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(skAbilityState, kTarget, kBreakdown, SkAimBonus);
   			   skHitChance=Clamp(((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);
			}
			else
			{
				skHitChance=HitChance;
				skAimBonus=AimBonus;
			}

			// Calculate and save Expected Damage if it needs to be displayed by either method
			if (getEXPECTED_DAMAGE() || ExpectedDamageSlotIndices.Length > 0)
			{
				fExpectedDamage = class'ExpectedDamageLib'.static.GetExpectedDamage(kBreakdown, NormalDamage, CritDamage);
			}

			// If test mode is enabled - test how ShotHUD looks like with certain values in it
			if (bEnableTestMode)
			{
				HitChance = iMockHit;
				kBreakdown.ResultTable[eHit_Crit] = iMockCritChance;
				kBreakdown.ResultTable[eHit_Graze] = iMockGraze;
				NormalDamage.Min = iMockMinDamage;
				NormalDamage.Max = iMockMaxDamage;
				CritDamage.Min = iMockCritMinDamageBonus;
				CritDamage.Max = iMockCritMaxDamageBonus;
				fExpectedDamage = fMockExpectedDamage;
			}

			// Tigrik: Print e.g. "Damage: 3-5"
			PrintShotDamage(kBreakdown, NormalDamage, CritDamage, fExpectedDamage);

			CritChance = kBreakdown.ResultTable[eHit_Crit];
			GrazeChance= kBreakdown.ResultTable[eHit_Graze];
           /*****************************************************/

 			
			// If User selected to display the Modified Hit Chance
			BarOffsetY=BAR_OFFSET_Y;
			if (TacticalHUD.m_kAbilityHUD.ActiveAbilities > MAX_ABILITIES_PER_ROW)
			{
				BarOffsetY += GENERAL_OFFSET_Y;
			}

			bHide = HitChance < 0 || kBreakdown.HideShotBreakdown;
			
			if (!bHide || HIT_SHOW_NonTRIVIAL && HitChance>0 && HitChance<100)
			{
				if (DISPLAY_MISS_CHANCE)
				{
					//Mr.Nice: Why special case Miss==0? We might as well manually draw it the whoLe time....
					//Flipped version only used once, and now want the real hitchance later too, so don't bother changing the variable.
					//HitChance = 100 - HitChance;
					// DEBUG TEST
					//if (HitChance == 0) AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.MISS_CHANCE, eUIState_Header), HitChance + 0.0);
					//AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(class'X2Action_ApplyWeaponDamageToUnit_HITCHANCE'.default.MISS_CHANCE, eUIState_Header), HitChance);
					//if (HitChance == 0)
					//{
						MC.ChildSetBool("statsHit", "_visible", true);
						MC.ChildSetString("statsHit.shotLabel", "htmlText", class'UIUtilities_Text'.static.GetColoredText(Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss]), eUIState_Header));
						MC.ChildSetString("statsHit.shotValue", "htmlText", (100-HitChance) $ "%");
					//}
				}
				else AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(m_sShotChanceLabel, eUIState_Header), HitChance);
				TacticalHUD.SetReticleAimPercentages(float(HitChance) / 100.0f, float(CritChance) / 100.0f);
			}
			else
			{
				AS_SetShotChance("", -1);
				TacticalHUD.SetReticleAimPercentages(-1, -1);
			}
			
			// Expand the width of slots if a slot to the right is empty
			UpdateShotHUDSlotWidths();

			if( CritChance>-1 &&(
				(!bHide && !(CRIT_HIDE_TRIVIAL && CritDamage.InfoList.Length==0 && CritChance<=0))
				|| (bHide && CRIT_SHOW_NonTRIVIAL &&(CritDamage.Min>0 || CritDamage.Max>0))) )
			{
				if(TH_SHOW_CRIT_DMG)
				{
					foreach CritDamageSlotIndices(j)
					{
						FontString = class'DamageLib'.static.GetCritDamageString(NormalDamage, CritDamage);
						FontString = class'UIUtilities_Text'.static.GetColoredText(FontString, class'ColorLib'.static.IndexToEUIState(get_SHOTHUD_COLOR_CRIT()), , SlotOffsets[j].bAlignRight ? "right" : "left");
						FontString = class'UIUtilities_Text'.static.AddFontInfo(FontString,false,true, , ValueFontSize);
						SlotValues[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)));
						SlotValues[j].SetHTMLText(FontString);
						SlotValues[j].Show();
				
						FontString = CRIT_DAMAGE_LABEL;
						FontString = class'UIUtilities_Text'.static.GetColoredText(FontString,eUIState_Header, LabelFontSize, SlotOffsets[j].bAlignRight ? "right" : "left");
						SlotLabels[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)) + LabelsOffset);
						SlotLabels[j].SetHTMLText(FontString);
						SlotLabels[j].Show();
					}
				}
				else
				{
					foreach CritDamageSlotIndices(j)
					{
						SlotValues[j].Hide();
						SlotLabels[j].Hide();
					}
				}
				if (!bHide || CritChance!=0)
					AS_SetCriticalChance(class'UIUtilities_Text'.static.GetColoredText(m_sCritChanceLabel, eUIState_Header), CritChance);
				else
					AS_SetCriticalChance("", -1);
			}
			else
			{
				AS_SetCriticalChance("", -1);
				foreach CritDamageSlotIndices(j)
				{
					SlotValues[j].Hide();
					SlotLabels[j].Hide();
				}
			}

			if (TH_SHOW_GRAZED && (!bHide || GRAZE_SHOW_NonTRIVIAL) && GrazeChance > 0)
			{
				foreach GrazeChanceSlotIndices(j)
				{
					FontString = GrazeChance $ "%";
					FontString = class'UIUtilities_Text'.static.GetColoredText(FontString, class'ColorLib'.static.IndexToEUIState(get_SHOTHUD_COLOR_GRAZE()), , SlotOffsets[j].bAlignRight ? "right" : "left");
					FontString = class'UIUtilities_Text'.static.AddFontInfo(FontString,false,true, , ValueFontSize);
					SlotValues[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)));
					SlotValues[j].SetHTMLText(FontString);
					SlotValues[j].Show();
					FontString = Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Graze]);
					FontString = class'UIUtilities_Text'.static.GetColoredText(FontString,eUIState_Header,LabelFontSize ,SlotOffsets[j].bAlignRight ? "right" : "left");
					SlotLabels[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)) + LabelsOffset);
					SlotLabels[j].SetHTMLText(FontString);
					SlotLabels[j].Show();
				}
			}
			else
			{
				foreach GrazeChanceSlotIndices(j)
				{
					SlotValues[j].Hide();
					SlotLabels[j].Hide();
				}
			}
				
			// Generate the shot breakdown bar
			if ( BAR_HEIGHT > 0 && !bHide &&
			!(BAR_HIDE_TRIVIAL && CritDamage.InfoList.Length==0 && CritChance<=0 && GrazeChance<=0) )
			{	   //Mr. Nice: If you're going to replicate the % results from RollforAbilityHit, then copy it's code structure!
					// Note RollforabilityHit() is an empty function is the basic X2AbilitytoHitCalc class, below is _StandardAim drived
					// In principle, other X2AbilitytoHitCalc implementations could use shotbreakdown differently, or even not use it at all!
					for (i = 0; i < eHit_Miss; ++i)	 //  If we don't match a result before miss, then it's a miss.
					{
						Chance[i]= max(0, min(Current + kBreakdown.ResultTable[i], 100) - max(Current, 0) );
						Current += kBreakdown.ResultTable[i];
					//`redscreen(`showvar(Current));
					}
					//`redscreen(`showvar(HitChance));
					Chance[eHit_Miss]=100-HitChance;
				
				if (IsSkPostMelee)
				{
					Chance[eHit_Success]+=skAimBonus;
					AimBonus*=Chance[eHit_Success]/100.0;
					for (i = 0; i < eHit_Miss; ++i)	
						Chance[i]*=float(HitChance)/float(skHitChance);
					Chance[eHit_Miss]=100-HitChance;//Incase counters have set it to 0!
					Chance[eHit_Success]-=AimBonus;
				}

				if (TH_ASSIST_BAR)
				{
					Chance[eHit_Success] += AimBonus; //Assist bonus directly adds to eHit_Success changes;
					AimBonus=0; //Hide the seperate aimbonus bar;
				}

				offsetX = int((BAR_WIDTH_MULT * (-50)) + 0.5f) + BAR_OFFSET_X;
				//Mr. Nice: offsetX is an out parameter, and is incremented in SetBox() as required.
				switch(int(TH_AIM_LEFT_OF_CRIT) + 2* int(TH_ASSIST_BESIDE_HIT))
				{
					case 1+0:
						SetBox(BarBoxes[0], Chance[eHit_Success], offsetX, BarOffsetY);
						SetBox(BarBoxes[1], Chance[eHit_Crit], offsetX, BarOffsetY);
						SetBox(BarBoxes[2], Chance[eHit_Graze], offsetX, BarOffsetY);
						SetBox(BarBoxes[3], AimBonus, offsetX, BarOffsetY);
					break;
					case 1+2:
						SetBox(BarBoxes[0], Chance[eHit_Success], offsetX, BarOffsetY);
						SetBox(BarBoxes[3], AimBonus, offsetX, BarOffsetY);
						SetBox(BarBoxes[1], Chance[eHit_Crit], offsetX, BarOffsetY);
						SetBox(BarBoxes[2], Chance[eHit_Graze], offsetX, BarOffsetY);
					break;
					case 0+0:
						SetBox(BarBoxes[1], Chance[eHit_Crit], offsetX, BarOffsetY);
						SetBox(BarBoxes[0], Chance[eHit_Success], offsetX, BarOffsetY);
						SetBox(BarBoxes[2], Chance[eHit_Graze], offsetX, BarOffsetY);
						SetBox(BarBoxes[3], AimBonus, offsetX, BarOffsetY);
					break;
					case 0+2:
						SetBox(BarBoxes[1], Chance[eHit_Crit], offsetX, BarOffsetY);
						SetBox(BarBoxes[0], Chance[eHit_Success], offsetX, BarOffsetY);
						SetBox(BarBoxes[3], AimBonus, offsetX, BarOffsetY);
						SetBox(BarBoxes[2], Chance[eHit_Graze], offsetX, BarOffsetY);
					break;
				}
				//Mr. Nice: No longer optional to call SetBox for miss, since SetBox is what hides it if needed
				SetBox(BarBoxes[4], Chance[eHit_Miss], offsetX, BarOffsetY);
			}
			else for (i=0; i<arraycount(BarBoxes); i++) BarBoxes[i].Hide();
		}
		else
		{
			// Calculate and save Expected Damage if it needs to be displayed by either method
			if (getEXPECTED_DAMAGE() || ExpectedDamageSlotIndices.Length > 0)
			{
				fExpectedDamage = class'ExpectedDamageLib'.static.GetExpectedDamage(kBreakdown, NormalDamage, CritDamage);
			}
			// Tigrik: Print e.g. "Damage: 3-5"
			PrintShotDamage(kBreakdown, NormalDamage, CritDamage, fExpectedDamage);

			HideAll();
		}

		// Print Expected Damage in any ShotHUD layout slots "Left 1", "Left 2", "Right 1" or "Right 2" selected by MCM options
		if (!bHide && (fExpectedDamage > 0.0))
		{
			foreach ExpectedDamageSlotIndices(j)
			{
				FontString = class'ExpectedDamageLib'.static.FormatExpectedDamageString(fExpectedDamage);
				FontString = class'UIUtilities_Text'.static.GetColoredText(FontString, class'ColorLib'.static.IndexToEUIState(get_SHOTHUD_COLOR_EXPECTED()), , SlotOffsets[j].bAlignRight ? "right" : "left");
				FontString = class'UIUtilities_Text'.static.AddFontInfo(FontString,false,true, , ValueFontSize);
				SlotValues[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)));
				SlotValues[j].SetHTMLText(FontString);
				SlotValues[j].Show();
				FontString = EXPECTED_DAMAGE_LABEL;
				FontString = class'UIUtilities_Text'.static.GetColoredText(FontString,eUIState_Header,LabelFontSize ,SlotOffsets[j].bAlignRight ? "right" : "left");
				SlotLabels[j].SetPosition(SlotOffsets[j].OffsetX-(TEXTWIDTH*int(SlotOffsets[j].bAlignRight))+IndexToOffsetX(j),(AlignOffsetY(TacticalHUD, SlotOffsets[j].OffsetY)) + LabelsOffset);
				SlotLabels[j].SetHTMLText(FontString);
				SlotLabels[j].Show();
			}
		} else
		{
			foreach ExpectedDamageSlotIndices(j)
			{
				SlotValues[j].Hide();
				SlotLabels[j].Hide();
			}
		}

        TacticalHUD.m_kShotInfoWings.Show();
 
        //Show preview points, must be negative
        UnitFlag = XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.GetFlagForObjectID(Target.ObjectID);
        if(UnitFlag != none)
		{
			if (TH_PREVIEW_MINIMUM)
				SetAbilityMinDamagePreview(UnitFlag, skAbilityState, Target);
			else
				XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.SetAbilityDamagePreview(UnitFlag, skAbilityState, Target);
		}
 
        //@TODO - jbouscher - ranges need to be implemented in a template friendly way.
        //Hide any current range meshes before we evaluate their visibility state
        if (!ActionUnit.GetPawn().RangeIndicator.HiddenGame) ActionUnit.RemoveRanges();
    }
 
    if (`REPLAY.bInTutorial)
		{
        if (SelectedAbilityTemplate != none && `TUTORIAL.IsNextAbility(SelectedAbilityTemplate.DataName) && `TUTORIAL.IsTarget(Target.ObjectID))
            ShowShine();
        else HideShine();
    }
	RefreshTooltips();
	`TRACE_EXIT("");
}

/**
 * Hides all shot HUD elements without removing them from memory.
 * Clears hit bars, graze/crit labels, and damage values to prepare
 * the HUD for a new shot display.
 */
simulated function HideAll()
{
	local int i;

	`TRACE_ENTRY("");
	AS_SetShotChance("", -1);
	AS_SetCriticalChance("", -1);
	for (i=0; i<arraycount(BarBoxes); i++) BarBoxes[i].Hide();
	for (i=0; i<arraycount(SlotValues); i++)
	{
		SlotValues[i].Hide();
		SlotLabels[i].Hide();
	}
	`TRACE_EXIT("");
}

/**
 * Removes all shot HUD elements permanently, freeing memory.
 * This includes bar boxes and labels for graze and critical damage.
 *
 * @return self Returns the HUD object for method chaining
 */
simulated function ExtendedInformationRedux3_UITacticalHUD_ShotHUD RemoveAll()
{
	local int i;
	`TRACE_ENTRY("");
	for (i=0; i<arraycount(BarBoxes); i++) BarBoxes[i].Remove();
	for (i=0; i<arraycount(SlotValues); i++)
	{
		SlotValues[i].Remove();
		SlotLabels[i].Remove();
	}
	`TRACE_EXIT("");
	return self;
}

/**
 * Configures a single hit/crit/graze bar box in the HUD.
 *
 * @param BarBox The UI bar box to configure
 * @param Chance Hit chance (0-100) for this bar
 * @param offsetX Horizontal offset, updated after placing the bar
 * @param offsetY Vertical offset for the bar
 */
simulated function SetBox (UIBGBox BarBox, int Chance, out int offsetX, int offsetY)
{
	local int bWidth;

	`TRACE_ENTRY("");
	if (Chance <=0)
	{
		BarBox.Hide();
		return;
	}

	bWidth=Chance*BAR_WIDTH_MULT;
	BarBox.SetPosition(offsetX, offsetY);
	BarBox.SetWidth(bWidth);
	BarBox.Show();

	offsetX += bWidth;
	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)
 
// GRIMY - Added this to do a minimum damage preview.
// Recreated the preview function in order to minimize # of files edited, and thus conflicts
static function SetAbilityMinDamagePreview(UIUnitFlag kFlag, XComGameState_Ability AbilityState, StateObjectReference TargetObject) {
    local XComGameState_Unit FlagUnit;
    local int shieldPoints, AllowedShield;
    local int possibleHPDamage, possibleShieldDamage;
    local WeaponDamageValue MinDamageValue;
    local WeaponDamageValue MaxDamageValue;
 
	`TRACE_ENTRY("");
    if(kFlag == none || AbilityState == none) {
        return;
    }
 
    AbilityState.GetDamagePreview(TargetObject, MinDamageValue, MaxDamageValue, AllowedShield);
 
    FlagUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID));
    shieldPoints = FlagUnit != none ? int(FlagUnit.GetCurrentStat(eStat_ShieldHP)) : 0;
 
    possibleHPDamage = MinDamageValue.Damage;
    possibleShieldDamage = 0;
 
    // MaxHP contains extra HP points given by shield
    if(shieldPoints > 0 && AllowedShield > 0) {
        possibleShieldDamage = min(shieldPoints, MinDamageValue.Damage);
        possibleShieldDamage = min(possibleShieldDamage, AllowedShield);
        possibleHPDamage = MinDamageValue.Damage - possibleShieldDamage;
    }
 
    if (!AbilityState.DamageIgnoresArmor() && FlagUnit != none)
        possibleHPDamage -= max(0,FlagUnit.GetArmorMitigationForUnitFlag() - MinDamageValue.Pierce);
 
    kFlag.SetShieldPointsPreview( possibleShieldDamage );
    kFlag.SetHitPointsPreview( possibleHPDamage );
    kFlag.SetArmorPointsPreview(MinDamageValue.Shred, MinDamageValue.Pierce);
	`TRACE_EXIT("");
}

/**
 * Prepends formatted hack reward description to the ShotDescription string.
 *
 * Retrieves hack reward data for the given ability and target, formats the
 * reward names and their respective chances, and inserts the result before
 * the existing ShotDescription (on a new line).
 *
 * @param AbilityState    Ability state used to calculate hack breakdown
 * @param Target          Target reference for the hack attempt
 * @param ShotDescription Original shot description text
 *
 * @return string         Updated ShotDescription with hack info prepended
 */ 
function string UpdateHackDescription(
    XComGameState_Ability AbilityState,
    StateObjectReference Target,
    string ShotDescription
)
{
    local EIHackBreakdown HackBreakdown;
    local HackRewardInfo RewardItem;
    local string HackDescription;
    local int i;
    local int Chance;
    local string Label;
    local EUIState _Color;

    local int AddedCount; // how many valid rewards we actually used

    `TRACE_ENTRY("");

    if (!class'HackCalcLib'.static.GetHackBreakdown(AbilityState, Target, HackBreakdown))
    {
        `TRACE_EXIT("No hack breakdown");
        return ShotDescription;
    }

    if (HackBreakdown.RewardList.Length == 0)
    {
        `DEBUG("No rewards in breakdown");
        `TRACE_EXIT("ShotDescription:" @ ShotDescription);
        return ShotDescription;
    }

    AddedCount = 0;

    for (i = 0; i < HackBreakdown.RewardList.Length; i++)
    {
        // Stop after 3 valid rewards (matches game UI)
        if (AddedCount >= 3)
            break;

        RewardItem = HackBreakdown.RewardList[i];

        if (RewardItem.RewardTemplate == none)
        {
            `DEBUG("Skipping reward: no template at index" @ i);
            continue;
        }

        Label = RewardItem.RewardTemplate.GetFriendlyName();
        Chance = Clamp(RewardItem.Chance, 0, 100);
        _Color = RewardItem.RewardTemplate.bBadThing ? class'ColorLib'.static.IndexToEUIState(get_HACK_COLOR_FAIL()) : class'ColorLib'.static.IndexToEUIState(get_HACK_COLOR_REWARD());

        if (AddedCount == 0)
        {
            // First reward: label only
            HackDescription =
                class'UIUtilities_Text'.static.GetColoredText(Label, _Color);
        }
        else if (AddedCount == 1)
        {
            // Second reward: " - "
            HackDescription $= " - " $
                class'UIUtilities_Text'.static.GetColoredText(
                    Label $ ": " $ Chance $ "%",
                    _Color
                );
        }
        else // AddedCount == 2
        {
            // Third reward: ", "
            HackDescription $= ", " $
                class'UIUtilities_Text'.static.GetColoredText(
                    Label $ ": " $ Chance $ "%",
                    _Color
                );
        }

        AddedCount++;
    }

    if (HackDescription != "")
    {
        ShotDescription = HackDescription $ "\n" $ ShotDescription;
    }

    `TRACE_EXIT("ShotDescription:" @ ShotDescription);
    return ShotDescription;
}

/**
 * Formats and displays shot damage information in the UI.
 *
 * Responsibilities:
 * - Convert NormalDamage range into a formatted string
 * - Optionally append Expected Damage value
 * - Apply color formatting based on whether bonus damage is present
 * - Push the final formatted string into the UI via AddDamage()
 *
 * Behavior:
 * - If NormalDamage is greater than zero:
 *     - Displays damage range (e.g., "3-5")
 *     - Optionally appends Expected Damage in parentheses (e.g., "3-5 (4.2)")
 *
 * @param kBreakdown		Shot breakdown containing hit/crit/graze probabilities
 * @param NormalDamage		Base damage breakdown (min/max + modifiers)
 * @param CritDamage		Critical damage breakdown (used for Expected Damage calculation)
 * @param fExpectedDamage	Expected damage, unformatted
 */
function PrintShotDamage(ShotBreakdown kBreakdown, DamageBreakdown NormalDamage, DamageBreakdown CritDamage, float fExpectedDamage)
{
	local string ShotDamage;

	`TRACE_ENTRY("NormalDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(NormalDamage) $ ", CritDamage:" @ class'DamagePreviewLib'.static.DamageBreakdownToString(CritDamage));

	if (NormalDamage.Min > 0 || NormalDamage.Max > 0)
	{
		ShotDamage=`RANGESTRING(NormalDamage.Min, NormalDamage.Max);

		// Tigrik: Append Expected Damage if MCM option 'Show Expected Damage' is enabled and if it's greater than 0.0
		if (getEXPECTED_DAMAGE() && (fExpectedDamage > 0.0))
		{
			ShotDamage $= " (" $ class'ExpectedDamageLib'.static.FormatExpectedDamageString(fExpectedDamage) $ ")";
		}

        if(NormalDamage.Bonus>0)
		{	
			AddDamageScrollable(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, GetDamageColor(NormalDamage), 38), true);
		}
		else
		{
			AddDamageScrollable(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, GetDamageColor(NormalDamage), 38), true);
		}
    }
	`TRACE_EXIT("");
}

/**
 * Adds a damage value that preserves vanilla layout behavior while
 * overlaying a scrolling text element when the text exceeds a maximum width.
 *
 * The original UIText remains present (but invisible) so that
 * RepositionDamageContainer() continues to calculate layout correctly.
 *
 * @param Label         Damage text HTML (e.g. colored "200-300")
 * @param bIsLastOne    If true, divider is omitted
 */
simulated function AddDamageScrollable(string Label, optional bool bIsLastOne)
{
    local UIPanel Divider;
    local UIText LayoutText;
    local UIScrollingText ScrollText;

    // Invisible layout text
    LayoutText = Spawn(class'UIText', DamageContainer);
    LayoutText.InitText(, Label, true, RepositionDamageContainer).SetHeight(50);
    LayoutText.bAnimateOnInit = false;
    LayoutText.SetAlpha(0);

    // Visible scrolling text
    ScrollText = Spawn(class'UIScrollingText', DamageContainer);

    ScrollText.InitScrollingText('', "", float(get_DAMAGE_LABEL_WIDTH()), 0, 0, true);

	Label = class'UIUtilities_Text'.static.AddFontInfo(Label, false, true, , 38);
	ScrollText.SetWidth(get_DAMAGE_LABEL_WIDTH());
    ScrollText.SetHTMLText(Label);
    ScrollText.bAnimateOnInit = false;

    if (!bIsLastOne)
    {
        Divider = Spawn(class'UIPanel', DamageContainer);
        Divider.InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetSize(2, 40);
        Divider.bAnimateOnInit = false;
    }
}

/**
 * Aligns scrolling overlays with their corresponding layout UIText controls.
 *
 * Same as the original function, except that it calls SyncDamageScrollingTextPositions() at the end
 */
simulated function RepositionDamageContainer()
{
	local int i, NextX;
	local UIPanel Control;
	local UIText Text;
	local bool bAllTextRealized;

	// Do nothing if we just added the label and nothing else
	if(DamageContainer.NumChildren() == 1)
		return;
	
	NextX = 0;
	bAllTextRealized = true;
	for(i = 0; i < DamageContainer.Children.Length; ++i)
	{
		Control = DamageContainer.GetChildAt(i);
		Control.SetX(NextX);
		NextX += 10;

		Text = UIText(Control);
		if( Text != none )
		{
			if( Text.TextSizeRealized )
				NextX += (i > 0) ? FMin(Text.Width, float(get_DAMAGE_LABEL_WIDTH())) : Text.Width;
			else
				bAllTextRealized = false;
		}
	}

	if( bAllTextRealized )
	{
		DamageContainer.SetX(NextX * -0.5);
		DamageContainer.Show();
		DamageContainer.AnimateIn(0);

		SyncDamageScrollingTextPositions();
	}
}

/**
 * Aligns scrolling overlays with their corresponding layout UIText controls.
 */
simulated function SyncDamageScrollingTextPositions()
{
    local int i;
    local UIText LayoutText;
    local UIScrollingText ScrollText;

    for (i = 0; i < DamageContainer.Children.Length; ++i)
    {
        LayoutText = UIText(DamageContainer.GetChildAt(i));

        if (LayoutText != none)
        {
            // Find scrolling text immediately after it
            if (i + 1 < DamageContainer.Children.Length)
            {
                ScrollText = UIScrollingText(DamageContainer.GetChildAt(i + 1));

                if (ScrollText != none)
                {
                    ScrollText.SetX(LayoutText.X);
                    ScrollText.SetY(LayoutText.Y);
                }
            }
        }
    }
}

/**
 * Determines which color to use for the damage.
 * 
 * Behavior:
 * - Returns an associated color for the MCM option SHOTHUD_COLOR_BONUS_DAMAGE if NormalDamage has any bonus damage
 * - Returns an associated color for the MCM option SHOTHUD_COLOR_DAMAGE otherwise
 * @param NormalDamage	Base damage breakdown (min/max + modifiers)
 */
function EUIState GetDamageColor(DamageBreakdown NormalDamage)
{
	return (NormalDamage.Bonus > 0) ? class'ColorLib'.static.IndexToEUIState(get_SHOTHUD_COLOR_BONUS_DAMAGE()) : class'ColorLib'.static.IndexToEUIState(get_SHOTHUD_COLOR_DAMAGE());
}

/**
 * Adjusts the vertical offset for Shot HUD elements based on the number of active abilities.
 *
 * If the number of abilities exceeds the maximum allowed per row, an additional global
 * vertical offset is applied to prevent UI overlap with the expanded ability bar.
 *
 * @param TacticalHUD   Reference to the tactical HUD containing ability information
 * @param OffsetY       Base vertical offset for the UI element
 *
 * @return int          Adjusted vertical offset value
 */
private function int AlignOffsetY(UITacticalHUD TacticalHUD, int OffsetY)
{
	return (TacticalHUD.m_kAbilityHUD.ActiveAbilities > MAX_ABILITIES_PER_ROW) ? (OffsetY + GENERAL_OFFSET_Y) : OffsetY;
}
/**
 * Creates and initializes a UIScrollingText element for use in the Shot HUD.
 *
 * The text element is configured with default properties including bottom-center anchoring,
 * predefined width, and hidden visibility. Unlike UIText, this implementation enables
 * automatic horizontal scrolling when the text exceeds the specified width.
 *
 * This ensures consistent setup for all Shot HUD text elements such as values and labels,
 * while supporting overflow handling via scrolling.
 *
 * @param ShotHUD           Reference to the Shot HUD that will own the created text element
 *
 * @return UIScrollingText  Newly created and initialized UIScrollingText instance
 */
private function UIScrollingText CreateShotHUDText(UITacticalHUD_ShotHUD ShotHUD)
{
    local UIScrollingText Text;

    Text = Owner.Spawn(class'UIScrollingText', ShotHUD);
    Text.InitScrollingText('', "", float(get_SHOTHUD_SLOT_WIDTH()), 0, 0);
    Text.AnchorBottomCenter();
    Text.SetWidth(get_SHOTHUD_SLOT_WIDTH());
    Text.Hide();

    return Text;
}

/**
 * Maps a slot index to its corresponding horizontal offset value
 * for the Shot HUD elements. The offsets are retrieved from MCM
 * configuration (or defaults if not set).
 *
 * Index mapping:
 * - 0 ? Left Side 1 offset
 * - 1 ? Left Side 2 offset
 * - 2 ? Right Side 1 offset
 * - 3 ? Right Side 2 offset
 *
 * If an invalid index is provided, the function returns 0 as a safe fallback.
 *
 * @param i
 *     Zero-based index identifying the HUD slot.
 *
 * @return
 *     The configured horizontal offset (in pixels) for the specified slot,
 *     or 0 if the index is out of range.
 */
private function int IndexToOffsetX(int i)
{
    switch (i)
    {
        case 0: return getSHOTHUD_LEFT_1_OFFSET_X();
        case 1: return getSHOTHUD_LEFT_2_OFFSET_X();
        case 2: return getSHOTHUD_RIGHT_1_OFFSET_X();
        case 3: return getSHOTHUD_RIGHT_2_OFFSET_X();
    }

    return 0; // fallback for unexpected indices
}

/**
 * Returns true if any of the provided slot index arrays contains SlotIndex.
 */
private function bool IsSlotUsedAnywhere(int SlotIndex, array<int> A,array<int> B,
    array<int> C
)
{
    local int k;

    for (k = 0; k < A.Length; ++k)
        if (A[k] == SlotIndex) return true;

    for (k = 0; k < B.Length; ++k)
        if (B[k] == SlotIndex) return true;

    for (k = 0; k < C.Length; ++k)
        if (C[k] == SlotIndex) return true;

    return false;
}

/**
 * Updates slot widths based on global usage of all slot index arrays.
 * Expand the width of slots if a slot to the right is empty.
 *
 * Rules:
 * - Slot 0 expands if any stat uses 0 and none use 1
 * - Slot 2 expands if any stat uses 2 and none use 3
 * - Otherwise slots use base width
 */
private function UpdateShotHUDSlotWidths()
{
    local bool bUses0, bUses1, bUses2, bUses3;
    local int BaseWidth;

    BaseWidth = get_SHOTHUD_SLOT_WIDTH();

    // Detect usage across all stats
    bUses0 = IsSlotUsedAnywhere(0, CritDamageSlotIndices, GrazeChanceSlotIndices, ExpectedDamageSlotIndices);
    bUses1 = IsSlotUsedAnywhere(1, CritDamageSlotIndices, GrazeChanceSlotIndices, ExpectedDamageSlotIndices);
    bUses2 = IsSlotUsedAnywhere(2, CritDamageSlotIndices, GrazeChanceSlotIndices, ExpectedDamageSlotIndices);
    bUses3 = IsSlotUsedAnywhere(3, CritDamageSlotIndices, GrazeChanceSlotIndices, ExpectedDamageSlotIndices);

    // --- Left side ---
    if (bUses0 && !bUses1)
    {
        SlotValues[0].SetWidth(Max(BaseWidth, 114));
        SlotLabels[0].SetWidth(Max(BaseWidth, 114));
    }
    else
    {
        SlotValues[0].SetWidth(BaseWidth);
        SlotLabels[0].SetWidth(BaseWidth);
    }

    // --- Right side ---
    if (bUses2 && !bUses3)
    {
        SlotValues[2].SetWidth(Max(BaseWidth, 114));
        SlotLabels[2].SetWidth(Max(BaseWidth, 114));
    }
    else
    {
        SlotValues[2].SetWidth(BaseWidth);
        SlotLabels[2].SetWidth(BaseWidth);
    }

    // Always reset the paired slots (important!)
    SlotValues[1].SetWidth(BaseWidth);
    SlotLabels[1].SetWidth(BaseWidth);

    SlotValues[3].SetWidth(BaseWidth);
    SlotLabels[3].SetWidth(BaseWidth);
}

/**
 * Adds a stat type to the appropriate Shot HUD slot array.
 */
private function AddStatToSlotArray(int StatType, int SlotIndex)
{
    switch (StatType)
    {
        case 1:
            GrazeChanceSlotIndices.AddItem(SlotIndex);
            break;
        case 2:
            CritDamageSlotIndices.AddItem(SlotIndex);
            break;
        case 3:
            ExpectedDamageSlotIndices.AddItem(SlotIndex);
            break;
    }
}

function bool GetDISPLAY_MISS_CHANCE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}

function bool GetTH_SHOW_GRAZED()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_SHOW_GRAZED, class'ExtendedInformationRedux3_MCMScreen'.default.TH_SHOW_GRAZED);
}

function bool GetTH_SHOW_CRIT_DMG()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_SHOW_CRIT_DMG, class'ExtendedInformationRedux3_MCMScreen'.default.TH_SHOW_CRIT_DMG);
}

function bool GetTH_AIM_LEFT_OF_CRIT()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_LEFT_OF_CRIT, class'ExtendedInformationRedux3_MCMScreen'.default.TH_AIM_LEFT_OF_CRIT);
}

function bool GetTH_PREVIEW_MINIMUM()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_PREVIEW_MINIMUM, class'ExtendedInformationRedux3_MCMScreen'.default.TH_PREVIEW_MINIMUM);
}

function int getBAR_HEIGHT()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_HEIGHT, class'ExtendedInformationRedux3_MCMScreen'.default.BAR_HEIGHT);
}

/*function int getBAR_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.BAR_OFFSET_X);
}*/

function int getBAR_OFFSET_Y()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_OFFSET_Y, class'ExtendedInformationRedux3_MCMScreen'.default.BAR_OFFSET_Y);
}

function int getBAR_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.BAR_ALPHA);
}

/*function int getBAR_WIDTH_MULT()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_WIDTH_MULT, class'ExtendedInformationRedux3_MCMScreen'.default.BAR_WIDTH_MULT);
}

function int getGENERAL_OFFSET_Y()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.GENERAL_OFFSET_Y, class'ExtendedInformationRedux3_MCMScreen'.default.GENERAL_OFFSET_Y);
}

function int getDODGE_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.DODGE_OFFSET_X);
}

function int getCRIT_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.CRIT_OFFSET_X);
}

function int getCRIT_OFFSET_Y()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_OFFSET_Y, class'ExtendedInformationRedux3_MCMScreen'.default.CRIT_OFFSET_Y);
}*/

function string getHIT_HEX_COLOR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_HEX_COLOR, class'ExtendedInformationRedux3_MCMScreen'.default.HIT_HEX_COLOR);
}

function string getCRIT_HEX_COLOR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_HEX_COLOR, class'ExtendedInformationRedux3_MCMScreen'.default.CRIT_HEX_COLOR);
}

function string getDODGE_HEX_COLOR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_HEX_COLOR, class'ExtendedInformationRedux3_MCMScreen'.default.DODGE_HEX_COLOR);
}

function string getMISS_HEX_COLOR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.MISS_HEX_COLOR, class'ExtendedInformationRedux3_MCMScreen'.default.MISS_HEX_COLOR);
}

function string getASSIST_HEX_COLOR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.ASSIST_HEX_COLOR, class'ExtendedInformationRedux3_MCMScreen'.default.ASSIST_HEX_COLOR);
}

function array<int> getSHOTHUD_LAYOUT()
{
	local array<int> Result;

	Result.AddItem(`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_1, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LAYOUT_LEFT_1));
	Result.AddItem(`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_2, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LAYOUT_LEFT_2));
	Result.AddItem(`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_1, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LAYOUT_RIGHT_1));
	Result.AddItem(`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_2, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LAYOUT_RIGHT_2));

	return Result;
}

function bool getTH_ASSIST_BESIDE_HIT()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_ASSIST_BESIDE_HIT, class'ExtendedInformationRedux3_MCMScreen'.default.TH_ASSIST_BESIDE_HIT);
}

function bool getTH_ASSIST_BAR()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_ASSIST_BAR, class'ExtendedInformationRedux3_MCMScreen'.default.TH_ASSIST_BAR);
}

function bool getEXPECTED_DAMAGE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.EXPECTED_DAMAGE, class'ExtendedInformationRedux3_MCMScreen'.default.EXPECTED_DAMAGE);
}

function bool getHIDE_STAT_CONTEST()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HIDE_STAT_CONTEST, class'ExtendedInformationRedux3_MCMScreen'.default.HIDE_STAT_CONTEST);
}

function bool getPREVIEW_APPLY_CHANCE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.PREVIEW_APPLY_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.PREVIEW_APPLY_CHANCE);
}

function int getSHOTHUD_LEFT_1_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_1_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LEFT_1_OFFSET_X);
}

function int getSHOTHUD_LEFT_2_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_2_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_LEFT_2_OFFSET_X);
}

function int getSHOTHUD_RIGHT_1_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_1_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_RIGHT_1_OFFSET_X);
}

function int getSHOTHUD_RIGHT_2_OFFSET_X()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_2_OFFSET_X, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_RIGHT_2_OFFSET_X);
}

//DEBUG
/*function float getDODGE_OFFSET_Y()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_OFFSET_Y, class'ExtendedInformationRedux3_MCMScreen'.default.DODGE_OFFSET_Y);
}*/
//DEBUG

function int get_SHOTHUD_SLOT_WIDTH()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_SLOT_WIDTH, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_SLOT_WIDTH);
}

function int get_DAMAGE_LABEL_WIDTH()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DAMAGE_LABEL_WIDTH, class'ExtendedInformationRedux3_MCMScreen'.default.DAMAGE_LABEL_WIDTH);
}

function int get_SHOTHUD_COLOR_DAMAGE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_DAMAGE, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_COLOR_DAMAGE);
}

function int get_SHOTHUD_COLOR_BONUS_DAMAGE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_BONUS_DAMAGE, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_COLOR_BONUS_DAMAGE);
}

function int get_SHOTHUD_COLOR_GRAZE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_GRAZE, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_COLOR_GRAZE);
}

function int get_SHOTHUD_COLOR_CRIT()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_CRIT, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_COLOR_CRIT);
}

function int get_SHOTHUD_COLOR_EXPECTED()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_EXPECTED, class'ExtendedInformationRedux3_MCMScreen'.default.SHOTHUD_COLOR_EXPECTED);
}

function int get_HACK_COLOR_FAIL()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HACK_COLOR_FAIL, class'ExtendedInformationRedux3_MCMScreen'.default.HACK_COLOR_FAIL);
}

function int get_HACK_COLOR_REWARD()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.HACK_COLOR_REWARD, class'ExtendedInformationRedux3_MCMScreen'.default.HACK_COLOR_REWARD);
}


defaultproperties
{
	//ASSIST_HEX_COLOR="b6b3e3" ; //PURPLE

	// ShotBar position, size, and offset settings, should not be altered whatsoever
	// so created those default values inside the class to not expose them in MCM any more
	BAR_WIDTH_MULT = 2.5;
	BAR_HEIGHT = 10;
	BAR_OFFSET_X = 3;
	//BAR_OFFSET_Y = -122;
	//BAR_POSITION_Y = -119;
	BAR_POSITION_Y = -108;
	GENERAL_OFFSET_Y = -32;
	LabelsOffset = -23;
	LabelFontSize = 18;
	ValueFontSize = 28;
	MAX_ABILITIES_PER_ROW = 15;
	//TEXTWIDTH=100;
	TEXTWIDTH=150;

	HIT_SHOW_NonTRIVIAL=true;
	GRAZE_SHOW_NonTRIVIAL=true;
	CRIT_SHOW_NonTRIVIAL=true;
	CRIT_HIDE_TRIVIAL=true;
	BAR_HIDE_TRIVIAL=true;
	//TH_ASSIST_BAR=true;
}