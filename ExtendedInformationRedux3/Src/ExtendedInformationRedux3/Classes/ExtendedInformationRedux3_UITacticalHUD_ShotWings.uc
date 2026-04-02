/**
 * ExtendedInformationRedux3_UITacticalHUD_ShotWings
 *
 * Handles the creation, display, and updating of the Shot Wings HUD in tactical combat.
 * This HUD shows detailed hit, damage, and critical information for abilities, including
 * multi-shot and hack breakdowns.
 *
 * Features:
 * - Left wing: Hit and Damage stats
 * - Right wing: Crit and Crit Damage stats
 * - Dynamic scrolling for long stat lists
 * - Integration with HackCalcLib and DamagePreviewLib
 * - Optional display of miss chance, trivial hits, and critical breakdowns
 *
 * @author Mr.Nice / Sebkulu
 */
class ExtendedInformationRedux3_UITacticalHUD_ShotWings extends UITacticalHUD_ShotWings dependson(HackCalcLib);

`define MINDAM(WEPDAM) ( `WEPDAM.Damage - `WEPDAM.Spread )
`define MAXDAM(WEPDAM) ( `WEPDAM.Damage + `WEPDAM.Spread + int(bool(`WEPDAM.PlusOne)) )
`define RANGESTRING(MIN, MAX)  ( `MIN == `MAX ? string(`MIN) : string(`MIN) $ "-" $ string(`MAX) )
`define RANGESTRINGO(WEPDAM) `RANGESTRING( `MINDAM(`WEPDAM), `MAXDAM(`WEPDAM) )
`define RANGESTRINGN(WEPITEM) `RANGESTRING(`WEPITEM.min, `WEPITEM.max)
`define SETCOLOR(VAL) IF(`VAL<0) {eState = eUIState_Bad;prefix="";}else {eState=eUIState_Good;prefix="+";}
`define COLORTEXT(OUTSTR, INSTR) `OUTSTR=class'UIUtilities_Text'.static.GetColoredText(`INSTR, eState)

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

//var bool SHOW_ALWAYS_SHOT_BREAKDOWN_HUD;
var bool DISPLAY_MISS_CHANCE;
var bool HIT_SHOW_NonTRIVIAL;
var bool DAMAGE_SHOW_NonTRIVIAL;
var bool CRIT_SHOW_NonTRIVIAL;
var bool CRIT_HIDE_TRIVIAL;

var localized string CRIT_DAMAGE_LABEL;
var localized string MULTIPLIER;
//var public UIText CritDamageLabel;
var public UIText CritDamageValue;
var public UIMask CritDamageMask;
var public UIPanel CritDamageBodyArea;
var public UIStatList CritDamageStatList;
var public UIScrollingText  CritDamageLabel, DamageLabelsc, HitLabelsc, CritLabelsc;

struct DamageModifier
{
	var string Label;
	var int Value;
};

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Initializes the Shot Wings HUD, creating panels, labels,
 * scrolling text, and buttons for hit, damage, crit, and crit damage.
 *
 * @param InitName Optional name for the panel initialization
 * @param InitLibID Optional library ID for panel initialization
 * @return self Returns the initialized ShotWings instance
 */
simulated function UITacticalHUD_ShotWings InitShotWings(optional name InitName, optional name InitLibID)
{
	local int ArrowButtonWidth, ArrowButtonOffset, StatsWidth, StatsOffset, LineHeight, ScrollWidth;
	local float LineOffset, ListOffset, TableGap, TmpInt;//Yes, TmpInt is now badly named! It's only used for UI positioning, and UI positions are floats
	local UIPanel HitLine, CritLine, CritDamageLine, DamageLine, HitBG, CritBG, LeftContainer, RightContainer; 

	`TRACE_ENTRY("");
	InitPanel(InitName, InitLibID);

	StatsWidth = 188;
	ScrollWidth = 136;
	StatsOffset = 24;
	ArrowButtonWidth = 16;
	ArrowButtonOffset = 4;

	//YOffset =0;// 9;
	LineHeight=class'UIStatList'.default.LineHeight;

	LineOffset=24; //Default 24, Distance from top of Table to header/list divider line
	ListOffset=3.5; //Default=4, Distance from Line to List (Line itself is 2pxl High, so ifless than two 2 will overlap line when scrolling)
	TableGap=1.5; //Default=4, Gap between the two tables in one Wing (NOT visible gap between textlines, due to descender/ascender/accent allowances in the Fonts)

	// ----------
	// The wings are actually contained within the ShotHUD so they animate in and anchor properly -sbatista
	LeftWingArea = Spawn(class'UIPanel', UITacticalHUD(Screen).m_kShotHUD); 
	LeftWingArea.bAnimateOnInit = false;
	LeftWingArea.InitPanel('leftWing');
	
	HitBG = Spawn(class'UIPanel', LeftWingArea).InitPanel('wingBG');
	HitBG.bAnimateOnInit = false;
	HitBG.ProcessMouseEvents(LeftWingMouseEvent);

	LeftContainer = Spawn(class'UIPanel', LeftWingArea);
	LeftContainer.bAnimateOnInit = false;
	LeftContainer.InitPanel('wingContainer');

	LeftWingButton = Spawn(class'UIButton', LeftContainer);
	LeftWingButton.LibID = 'X2DrawerButton';
	LeftWingButton.bAnimateOnInit = false;
	LeftWingButton.InitButton(,,OnWingButtonClicked).SetPosition(ArrowButtonOffset, (height - 26) * 0.5);
	LeftWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bLeftWingOpen ? "right" : "left");

	HitPercent = Spawn(class'UIText', LeftContainer);
	HitPercent.bAnimateOnInit = false;
	HitPercent.InitText('HitPercent');
	HitPercent.SetWidth(StatsWidth); 
	HitPercent.SetPosition(StatsOffset, 0);
	HitLabelsc = Spawn(class'UIScrollingText', LeftContainer);
	HitLabelsc.bAnimateOnInit = false;
	HitLabelsc.InitScrollingText('HitLabel',, ScrollWidth, StatsOffset, 0);
	//HitLabelsc.SetPosition(StatsOffset, 0);

	HitLine = Spawn(class'UIPanel', LeftContainer);
	HitLine.bAnimateOnInit = false;
	HitLine.InitPanel('HitHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	HitLine.SetPosition(StatsOffset, LineOffset);
	HitLine.SetSize(StatsWidth, 2);
	HitLine.SetAlpha(50);

	TmpInt = HitLine.Y + ListOffset;

	HitBodyArea = Spawn(class'UIPanel', LeftContainer); 
	HitBodyArea.bAnimateOnInit = false;
	HitBodyArea.InitPanel('HitBodyArea').SetPosition(HitLine.X, TmpInt);
	HitBodyArea.width = StatsWidth; 
	HitBodyArea.height = LineHeight*3;// - TmpInt;

	HitMask = Spawn(class'UIMask', LeftContainer).InitMask(, HitBodyArea);
	HitMask.SetPosition(HitBodyArea.X, HitBodyArea.Y); 
	HitMask.SetSize(StatsWidth, HitBodyArea.height);

	HitStatList = Spawn(class'UIStatList', HitBodyArea);
	HitStatList.bAnimateOnInit = false;
	HitStatList.InitStatList('StatListLeft',,,, HitBodyArea.Width, HitBodyArea.Height, 0, 0);

	TmpInt += LineHeight*3 + TableGap;

	DamagePercent = Spawn(class'UIText', LeftContainer);
	DamagePercent.bAnimateOnInit = false;
	DamagePercent.InitText('DamagePercent');
	DamagePercent.SetWidth(StatsWidth);
	DamagePercent.SetPosition(StatsOffset, TmpInt);
	DamageLabelsc = Spawn(class'UIScrollingText', LeftContainer);
	DamageLabelsc.bAnimateOnInit = false;
	DamageLabelsc.InitScrollingText('DamageLabel',, ScrollWidth, StatsOffset, TmpInt);
	//DamageLabelsc.InitText('DamageLabel');
	//DamageLabelsc.SetWidth(StatsWidth);
	//DamageLabelsc.SetPosition(StatsOffset, TmpInt);

	DamageLine = Spawn(class'UIPanel', LeftContainer);
	DamageLine.bAnimateOnInit = false;
	DamageLine.InitPanel('DamageHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	DamageLine.SetSize(StatsWidth, 2);
	DamageLine.SetPosition(StatsOffset, TmpInt + LineOffset);
	DamageLine.SetAlpha(50);

	TmpInt = DamageLine.Y + ListOffset;

	DamageBodyArea = Spawn(class'UIPanel', LeftContainer);
	DamageBodyArea.bAnimateOnInit = false;
	DamageBodyArea.InitPanel('DamageBodyArea').SetPosition(DamageLine.X, TmpInt);
	DamageBodyArea.width = StatsWidth;
	DamageBodyArea.height = LineHeight*2; //height - TmpInt;

	DamageMask = Spawn(class'UIMask', LeftContainer).InitMask(, DamageBodyArea);
	DamageMask.SetPosition(DamageBodyArea.X, DamageBodyArea.Y);
	DamageMask.SetSize(StatsWidth, DamageBodyArea.height);

	DamageStatList = Spawn(class'UIStatList', DamageBodyArea);
	DamageStatList.bAnimateOnInit = false;
	DamageStatList.InitStatList('DamageStatList', , , , DamageBodyArea.Width, DamageBodyArea.Height, 0, 0);

	// -----------
	// The wings are actually contained within the ShotHUD so they animate in and anchor properly -sbatista
	RightWingArea = Spawn(class'UIPanel', UITacticalHUD(Screen).m_kShotHUD); 
	RightWingArea.bAnimateOnInit = false;
	RightWingArea.InitPanel('rightWing');
	
	CritBG = Spawn(class'UIPanel', RightWingArea);
	CritBG.bAnimateOnInit = false;
	CritBG.InitPanel('wingBG');
	CritBG.ProcessMouseEvents(RightWingMouseEvent);

	RightContainer = Spawn(class'UIPanel', RightWingArea);
	RightContainer.bAnimateOnInit = false;
	RightContainer.InitPanel('wingContainer');

	RightWingButton = Spawn(class'UIButton', RightContainer);
	RightWingButton.LibID = 'X2DrawerButton';
	RightWingButton.bAnimateOnInit = false;
	RightWingButton.InitButton(,,OnWingButtonClicked).SetPosition(-ArrowButtonWidth - ArrowButtonOffset, (height - 26) * 0.5);
	RightWingButton.MC.FunctionString("gotoAndStop", "right");
	RightWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bRightWingOpen ? "right" : "left");


	CritPercent = Spawn(class'UIText', RightContainer);
	CritPercent.bAnimateOnInit = false;
	CritPercent.InitText('CritPercent');
	CritPercent.SetWidth(StatsWidth); 
	CritPercent.SetPosition(-StatsWidth - StatsOffset, 0);
	CritLabelsc = Spawn(class'UIScrollingText', RightContainer);
	CritLabelsc.bAnimateOnInit = false;
	CritLabelsc.InitScrollingText('CritLabel',, ScrollWidth, -StatsWidth - StatsOffset, 0);
	//CritLabelsc.SetWidth(StatsWidth);
	//CritLabelsc.SetPosition(-StatsWidth - StatsOffset, 0);

	CritLine = Spawn(class'UIPanel', RightContainer);
	CritLine.bAnimateOnInit = false;
	CritLine.InitPanel('CritHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	CritLine.SetSize(StatsWidth, 2);
	CritLine.SetPosition(-StatsWidth - StatsOffset, LineOffset);
	CritLine.SetAlpha(50);

	TmpInt = CritLine.Y + ListOffset;

	CritBodyArea = Spawn(class'UIPanel', RightContainer); 
	CritBodyArea.bAnimateOnInit = false;
	CritBodyArea.InitPanel('CritBodyArea').SetPosition(CritLine.X, TmpInt);
	CritBodyArea.width = StatsWidth;
	CritBodyArea.height = 3*LineHeight; 

	CritMask = Spawn(class'UIMask', RightContainer).InitMask(, CritBodyArea);
	CritMask.SetPosition(CritBodyArea.X, CritBodyArea.Y); 
	CritMask.SetSize(StatsWidth, CritBodyArea.height);

	CritStatList = Spawn(class'UIStatList', CritBodyArea);
	CritStatList.bAnimateOnInit = false;
	CritStatList.InitStatList('CritStatList',,,, CritBodyArea.Width, CritBodyArea.Height, 0, 0);

	TmpInt += LineHeight*3 + TableGap;

	CritDamageValue = Spawn(class'UIText', RightContainer);
	CritDamageValue.bAnimateOnInit = false;
	CritDamageValue.InitText('CritDamageValue');
	CritDamageValue.SetWidth(StatsWidth); 
	CritDamageValue.SetPosition(-StatsWidth - StatsOffset, TmpInt);
	CritDamageLabel = Spawn(class'UIScrollingText', RightContainer);
	CritDamageLabel.bAnimateOnInit = false;
	CritDamageLabel.InitScrollingText('CritDamageLabel',, ScrollWidth,-StatsWidth - StatsOffset, TmpInt);
	//CritDamageLabel.InitText('CritDamageLabel');
	//CritDamageLabel.SetWidth(StatsWidth);
	//CritDamageLabel.SetPosition(-StatsWidth - StatsOffset, TmpInt);

	CritDamageLine = Spawn(class'UIPanel', RightContainer);
	CritDamageLine.bAnimateOnInit = false;
	CritDamageLine.InitPanel('CritDamageHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	CritDamageLine.SetSize(StatsWidth, 2);
	CritDamageLine.SetPosition(-StatsWidth - StatsOffset, TmpInt + LineOffset);
	CritDamageLine.SetAlpha(50);

	TmpInt = CritDamageLine.Y + ListOffset;

	CritDamageBodyArea = Spawn(class'UIPanel', RightContainer); 
	CritDamageBodyArea.bAnimateOnInit = false;
	CritDamageBodyArea.InitPanel('CritDamageBodyArea').SetPosition(CritDamageLine.X, TmpInt);
	CritDamageBodyArea.width = StatsWidth;
	CritDamageBodyArea.height = LineHeight*2;//height - TmpInt; 

	CritDamageMask = Spawn(class'UIMask', RightContainer).InitMask(, CritDamageBodyArea);
	CritDamageMask.SetPosition(CritDamageBodyArea.X, CritDamageBodyArea.Y); 
	CritDamageMask.SetSize(StatsWidth, CritDamageBodyArea.height);

	CritDamageStatList = Spawn(class'UIStatList', CritDamageBodyArea);
	CritDamageStatList.bAnimateOnInit = false;
	CritDamageStatList.InitStatList('CritDamageStatList',,,, CritDamageBodyArea.Width, CritDamageBodyArea.Height, 0, 0);


	Hide();

	//bLeftWingOpen = true;
	//bRightWingOpen = true;
	`TRACE_EXIT("");
	return self; 

//return super.InitShotWings(InitName, InitLibID);
}

/**
 * Refreshes all HUD data for the currently selected ability and target.
 * Updates hit, damage, crit, and crit damage values and labels.
 */
simulated function RefreshData()
{
	//local StateObjectReference		kEnemyRef;
	local StateObjectReference		Target; 
	local AvailableAction			kAction;
	local AvailableTarget			kTarget;
	local XComGameState_Ability		AbilityState;
	local ShotBreakdown				Breakdown, skBreakdown;
	//local UIHackingBreakdown			kHackingBreakdown;
	local WeaponDamageValue			MinDamageValue, MaxDamageValue;
	local int						AllowsShield;
	local int						i, TargetIndex, iShotBreakdown, HitChance, CritChance;//, AimBonus
	local ShotModifierInfo			ShotInfo;
	local bool						bMultiShots;
	local string						TmpStr;
	local X2TargetingMethod			TargetingMethod;
	local array<UISummary_ItemStat> Stats;
	local EIHackBreakdown HackBreakdown;
	local bool bHideLeft, bHideRight;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	`TRACE_ENTRY("");
	DISPLAY_MISS_CHANCE = getDISPLAY_MISS_CHANCE();

	kAction = UITacticalHUD(Screen).GetSelectedAction();
	//kEnemyRef = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetSelectedEnemyStateObjectRef();
	History=`XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));


	// Bail ifwe have  nothing to show -------------------------------------
	if(AbilityState == none || kAction.AvailableCode != 'AA_Success')
	{
		HideState();
		return;
	}

	//Mr. Nice: Pointless check, there are no non-trival implementations of GetUISummary_HackingBreakdown() in the game!
	/*
	//Don't show this normal shot breakdown for the hacking action ------------
	AbilityState.GetUISummary_HackingBreakdown( kHackingBreakdown, kEnemyRef.ObjectID );
	if(kHackingBreakdown.bShow)
	{
		HideState();
		return; 
	}
	*/

		// Refresh game data  ------------------------------------------------------

	// ifno targeted icon, we're actually hovering the shot "to hit" info field, 
	// so use the selected enemy for calculation.
	TargetingMethod = UITacticalHUD(screen).GetTargetingMethod();
	if(TargetingMethod != none)
		TargetIndex = TargetingMethod.GetTargetIndex();
	if(kAction.AvailableTargets.Length > 0 && TargetIndex < kAction.AvailableTargets.Length)
	{
		kTarget = kAction.AvailableTargets[TargetIndex];
	}

	Target = kTarget.PrimaryTarget; 

	if(class'HackCalcLib'.static.GetHackBreakdown(AbilityState, Target, HackBreakDown))
	{
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowHit" );
		LeftWingButton.Show();
		if(bLeftWingWasOpen && !bLeftWingOpen)
		{
			OnWingButtonClicked(LeftWingButton);
			bLeftWingWasOpen = false;
		}
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowCrit" );
		RightWingButton.Show();
		if(bRightWingWasOpen && !bRightWingOpen)
		{
			OnWingButtonClicked(RightWingButton);
			bRightWingWasOpen = false;
		}


		HitLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakDown.RewardList[1].RewardTemplate.GetFriendlyName(), eUITextStyle_Tooltip_StatLabel));
		HitPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakDown.RewardList[1].Chance $ "%", eUITextStyle_Tooltip_StatValue));
		HitStatList.RefreshData(ProcessHackBreakdown(HackBreakdown, 1));

		DamageLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakdown.RatioLabel, eUITextStyle_Tooltip_StatLabel));
		DamagePercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakdown.Ratio, eUITextStyle_Tooltip_StatValue));
		DamageStatList.RefreshData(HackBreakdown.LStats);

		CritLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakDown.RewardList[2].RewardTemplate.GetFriendlyName(), eUITextStyle_Tooltip_StatLabel));
		CritPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakDown.RewardList[2].Chance $ "%", eUITextStyle_Tooltip_StatValue));
		CritStatList.RefreshData(ProcessHackBreakdown(HackBreakdown, 2));

		CritDamageLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakdown.TechLabel, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(class'WOTC_DisplayHitChance_UITacticalHUD_ShotHUD'.static.GetCritDamage(AbilityState, Target, Stats));
		CritDamageValue.SetHtmlText(class'UIUtilities_Text'.static.StyleText(HackBreakdown.TechValue, eUITextStyle_Tooltip_StatValue));
		CritDamageStatList.RefreshData(HackBreakdown.RStats);
		return;
	}
	
	iShotBreakdown = class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(AbilityState, kTarget, Breakdown);
	HitChance = (Breakdown.bIsMultishot) ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance;
	if(AbilityState.GetMyTemplateName()=='SkirmisherVengeance'
		|| AbilityState.GetMyTemplateName()=='Justice')
	{
		UnitState=XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
		AbilityState=XComGameState_Ability(History.GetGameStateForObjectID(UnitState.FindAbility('SkirmisherPostAbilityMelee').ObjectID));
		class'HitCalcLib'.static.GetShotBreakdownDiffAdjust(AbilityState, kTarget, skBreakdown);
		for(i=Breakdown.Modifiers.Length-1; i>=0; i--)
			if (Breakdown.Modifiers[i].ModType==eHit_Crit)
				Breakdown.Modifiers.Remove(i, 1);
		for(i=0; i<skBreakdown.Modifiers.Length; i++)
			if (skBreakdown.Modifiers[i].ModType==eHit_Crit)
				Breakdown.Modifiers.AddItem(skBreakdown.Modifiers[i]);
		Breakdown.ResultTable[eHit_Crit]=skBreakdown.ResultTable[eHit_Crit];
	}
	CritChance=Breakdown.ResultTable[eHit_Crit];
	
	//class'DamagePreviewLib'.static.GetDamagePreview(AbilityState, kTarget.PrimaryTarget, NormalDamage, CritDamage);

	// Hide ifrequested -------------------------------------------------------
	bHideLeft=Breakdown.HideShotBreakdown &&
		!( HIT_SHOW_NonTRIVIAL && HitChance>0 && HitChance<100 && Breakdown.Modifiers.Length!=0 //If there's no Modifiers(aka, stuff to show in the list!), then the HUD will already show all we know
		|| DAMAGE_SHOW_NonTRIVIAL); //Larger than one since one entry means just the baseweapon/ability damage, to not interesting!
	bHideRight=CritChance<0
		|| (Breakdown.HideShotBreakdown && !(CRIT_SHOW_NonTRIVIAL || CritChance>0) )
		|| (!Breakdown.HideShotBreakdown && CRIT_HIDE_TRIVIAL && CritChance<=0);
	if (bHideLeft && bHideRight)
	{
		HideState();
		return;
	}

	// Gameplay special hackery for multi-shot display. -----------------------
	if (bHideLeft) HideLeft();
	else
	{
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowHit" );
		LeftWingButton.Show();
		if(bLeftWingWasOpen && !bLeftWingOpen)
		{
			OnWingButtonClicked(LeftWingButton);
			bLeftWingWasOpen = false;
		}

		if(iShotBreakdown != Breakdown.FinalHitChance)
		{
			bMultiShots = true;
			ShotInfo.ModType = eHit_Success;
			ShotInfo.Value = iShotBreakdown - Breakdown.FinalHitChance;
			ShotInfo.Reason = class'XLocalizedData'.default.MultiShotChance;
			Breakdown.Modifiers.AddItem(ShotInfo);
			Breakdown.FinalHitChance = iShotBreakdown;
		}

		// Now update the UI ------------------------------------------------------
		Breakdown.Modifiers.Sort(SortModifiers);
		// Smart way to do things -Credit: Sectoidfodder 
		Stats = ProcessHitCritBreakdown(Breakdown, eHit_Success);
		Stats.Sort(SortAfterValue);

		if(bMultiShots)
			HitLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.MultiHitLabel, eUITextStyle_Tooltip_StatLabel));
		else if(DISPLAY_MISS_CHANCE)
			HitLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Miss], eUITextStyle_Tooltip_StatLabel));
		else
			HitLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.HitLabel, eUITextStyle_Tooltip_StatLabel));
	
		if(DISPLAY_MISS_CHANCE)
			TmpStr = (100 - clamp(HitChance, 0, 100)) $ "%";
		else
			TmpStr = HitChance $ "%";

		HitPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
		HitStatList.RefreshData(Stats);

		// Added from Vanilla file, seems like a WotC addition needed to display Damages Values on the Right Wing.
		AbilityState.GetDamagePreview(Target, MinDamageValue, MaxDamageValue, AllowsShield);

		DamageLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.DamageLabel, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(MinDamageValue.Damage) $ "-" $ string(MaxDamageValue.Damage);
		DamagePercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
		DamageStatList.RefreshData(ProcessNeoDamageBreakdown(MinDamageValue, GetWeaponBreakdown(Target, AbilityState), true));
	}

	if (bHideRight) HideRight();
	else
	{
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowCrit" );

		RightWingButton.Show();

		if(bRightWingWasOpen && !bRightWingOpen)
		{
			OnWingButtonClicked(RightWingButton);
			bRightWingWasOpen = false;
		}

		CritLabelsc.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.CritLabel, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(CritChance) $ "%";
		CritPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
		CritStatList.RefreshData(ProcessHitCritBreakdown(Breakdown, eHit_Crit));

		CritDamageLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(CRIT_DAMAGE_LABEL, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(class'WOTC_DisplayHitChance_UITacticalHUD_ShotHUD'.static.GetCritDamage(AbilityState, Target, Stats));
		CritDamageValue.SetHtmlText(class'UIUtilities_Text'.static.StyleText("+" $ TmpStr, eUITextStyle_Tooltip_StatValue));
		CritDamageStatList.RefreshData(Stats);
	}
	`TRACE_EXIT("");
}

/**
 * Shows the Shot Wings HUD, animating the Crit Damage scroll area if needed.
 */
simulated function Show()
{
	local int ScrollHeight;
	`TRACE_ENTRY("");
	super.Show();

	if(bIsVisible)
	{
		CritDamageBodyArea.ClearScroll();
		CritDamageBodyArea.MC.SetNum("_alpha", 100);
	
		//This will reset the scrolling upon showing this tooltip.
		ScrollHeight = (CritDamageStatList.height > CritDamageBodyArea.height ) ? CritDamageStatList.height : CritDamageBodyArea.height; 
		CritDamageBodyArea.AnimateScroll(ScrollHeight, CritDamageBodyArea.height);
	}
	`TRACE_EXIT("");
}

/**
 * Hides the entire Shot Wings HUD state including left and right wings.
 */
simulated function HideState()
{
	`TRACE_ENTRY("");
	Hide();
	HideLeft();
	HideRight();
	`TRACE_EXIT("");
}

simulated function HideLeft()
{
	`TRACE_ENTRY("");
		if(bLeftWingOpen)
		{
			bLeftWingWasOpen = true;
			OnWingButtonClicked(LeftWingButton);
		}
		LeftWingButton.Hide();
	`TRACE_EXIT("");
}

simulated function HideRight()
{
	`TRACE_ENTRY("");
		if(bRightWingOpen)
		{
			bRightWingWasOpen = true;
			OnWingButtonClicked(RightWingButton);
		}
		RightWingButton.Hide();
	`TRACE_EXIT("");
}

simulated function array<UISummary_ItemStat> ProcessHackBreakdown(EIHackBreakdown HackBreakdown, int i)
{
	local array<UISummary_ItemStat> Stats;
	local HackRewardInfo RewardItem;
	local UISummary_ItemStat Item, EmptyItem;

	`TRACE_ENTRY("");
	RewardItem=HackBreakdown.RewardList[i];

	Item.Label="Base Difficulty";
	Item.Value=(100-RewardItem.RewardTemplate.MinHackSuccess) $ "%";
	Stats.AddItem(Item);
	Item=EmptyItem;

	if (RewardItem.RewardTemplate.HackSuccessVariance!=0)
	{
		Item.Label="Random Variance";
		Item.Value=(-RewardItem.RollMod) $ "%";
		if (RewardItem.RollMod>0)
		{
			Item.LabelState=eUIState_Bad;
			Item.ValueState=eUIState_Bad;
		}
		else if (RewardItem.RollMod<0)
		{
			Item.LabelState=eUIState_Good;
			Item.ValueState=eUIState_Good;
		}
		Stats.AddItem(Item);
		Item=EmptyItem;
	}

	Item.Label="&#215;" $ HackBreakdown.Ratio @ MULTIPLIER;
	if(RewardItem.Chance-100+RewardItem.RollMod+RewardItem.RewardTemplate.MinHackSuccess>0)
	{
		Item.Value = "+";
		Item.ValueState=eUIState_Good;
		Item.LabelState=eUIState_Good;
		
	}
	else
	{
		Item.ValueState=eUIState_Bad;
		Item.LabelState=eUIState_Bad;
	}
	Item.Value $= (RewardItem.Chance-100+RewardItem.RollMod+RewardItem.RewardTemplate.MinHackSuccess) $ "%";
	Stats.AddItem(Item);

	`TRACE_EXIT("");
	return Stats;
}

simulated function array<UISummary_ItemStat> ProcessNeoDamageBreakdown(const out WeaponDamageValue DamageValue, array<UISummary_ItemStat> StartingStats, optional bool bNoSignFirst=false)
{
	local array<UISummary_ItemStat> Stats;
	local UISummary_ItemStat Item;
	local int i, index;
	local array<DamageModifier> DamageModifiers;
	local DamageModifier DmgModifier;
	local string strLabel, strValue, strPrefix;
	local EUIState eState;

	Stats=StartingStats;
	for( i = 0; i < DamageValue.BonusDamageInfo.Length; i++ )
	{
		if( DamageValue.BonusDamageInfo[i].Value < 0 )
		{
			eState = eUIState_Bad;
			strPrefix = "";
		}
		else
		{
			eState = eUIState_Good;
			strPrefix = "+";
		}
		DmgModifier.Label = class'Helpers'.static.GetMessageFromDamageModifierInfo(DamageValue.BonusDamageInfo[i]);
		DmgModifier.Value = DamageValue.BonusDamageInfo[i].Value;

		strLabel = class'UIUtilities_Text'.static.GetColoredText(DmgModifier.Label, eState);
		strValue = class'UIUtilities_Text'.static.GetColoredText(strPrefix $ string(DamageValue.BonusDamageInfo[i].Value), eState);

		index = DamageModifiers.Find('Label', DmgModifier.Label);
		if(index != INDEX_NONE && DmgModifier.Label!="")
		{
			DamageModifiers[index].Value += DmgModifier.Value;
			strValue = class'UIUtilities_Text'.static.GetColoredText(strPrefix $ string(DamageModifiers[index].Value), eState);
			if(Stats.Find('Label', strLabel) != INDEX_NONE)
			{
				Stats[Stats.Find('Label', strLabel)].Value = strValue;
			}
		}
		else
		{
			Item.Label = strLabel;
			Item.Value = strValue;
			Stats.AddItem(Item);
			DamageModifiers.AddItem(DmgModifier);
			bNoSignFirst=false;
		}
	}
	//for (i=i;i<4;i++)
	//{
		//Item.Label="Fluff";
		//Item.Value="500";
		//Stats.AddItem(Item);
	//}
	return Stats;
}

simulated function array<UISummary_ItemStat> ProcessHitCritBreakdown(ShotBreakdown Breakdown, int eHitType)
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local int i;
	local string strPrefix; 
	local EUIState eState_Negative, eState_Positive;

	`TRACE_ENTRY("");
	if(DISPLAY_MISS_CHANCE)
	{
		eState_Negative=eUIState_Good;
		eState_Positive=eUIState_Bad;
	}
	else
	{
		eState_Negative=eUIState_Bad;
		eState_Positive=eUIState_Good;
	}

	for( i=0; i < Breakdown.Modifiers.Length; i++)
	{	
		
		if( Breakdown.Modifiers[i].ModType == eHitType )
		{
			if(DISPLAY_MISS_CHANCE)
				Breakdown.Modifiers[i].Value = -Breakdown.Modifiers[i].Value;

			if( Breakdown.Modifiers[i].Value < 0 )
			{
				Item.LabelState = eState_Negative;
				Item.ValueState = eState_Negative;
				strPrefix = "";
			}
			else
			{
				Item.LabelState = eState_Positive;
				Item.ValueState = eState_Positive;
				strPrefix = "+";
			}

			Item.Label = Breakdown.Modifiers[i].Reason; 
			Item.Value = strPrefix $ string(Breakdown.Modifiers[i].Value) $ "%";
			Stats.AddItem(Item);
		}
	}

	if( eHitType == eHit_Crit && Stats.length == 1 && Breakdown.ResultTable[eHit_Crit] == 0 )
		Stats.length = 0; 

	`TRACE_EXIT("");
	return Stats; 
}

simulated static function array<UISummary_ItemStat> GetWeaponBreakdown(StateObjectReference TargetRef, XComGameState_Ability AbilityState, optional bool bCrit=false, optional out int CritDamage, optional out int bShouldContinue, optional out X2Effect_ApplyWeaponDamage WepDamEffect)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Item SourceWeapon, LoadedAmmo;
	local WeaponDamageValue BaseDamageValue, ExtraDamageValue, AmmoDamageValue, BonusEffectDamageValue, UpgradeDamageValue;
	local X2Condition ConditionIter;
	local name AvailableCode;
	local X2AmmoTemplate AmmoTemplate;
	local int AllowsShield;
	local name DamageType;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> AppliedDamageTypes;
	local bool bDoesDamageIgnoreShields;

	local UISummary_ItemStat Item;
	local array <UISummary_ItemStat> Stats;
	//local X2Effect_ApplyWeaponDamage WepDamEffect;
	local X2Effect Effect;
	local array<X2Effect> TargetEffects;
	local EUIState eState;
	local string prefix;

	local X2AbilityTemplate AbilityTemplate;
	local WeaponDamageValue MinDamagePreview, MaxDamagePreview;

	History = `XCOMHISTORY;
	
	AbilityTemplate = AbilityState.GetMyTemplate();
	AllowsShield = 0;

	if (AbilityTemplate.DamagePreviewFn != none)
	{
		bShouldContinue=int(!AbilityTemplate.DamagePreviewFn(AbilityState, TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield));
		if (bCrit && MaxDamagePreview.Crit!=0)
		{
			CritDamage+=MaxDamagePreview.Crit;
			Item.Value=string(MaxDamagePreview.Crit);
			Item.Label=AbilityState.GetMyFriendlyName();
			Stats.AddItem(Item);
		}
		if (bShouldContinue==0) return Stats;
	}

	bShouldContinue=0;

	TargetEffects = AbilityState.GetMyTemplate().AbilityTargetEffects;
	if (bCrit)
	{
		foreach TargetEffects(Effect)
		{
			if (X2Effect_ApplyWeaponDamage(Effect)==none)
			{
				MaxDamagePreview.Crit=0;
				Effect.GetDamagePreview(TargetRef, AbilityState, true, MinDamagePreview , MaxDamagePreview, AllowsShield);
				if ( MaxDamagePreview.Crit!=0 )
				{
					CritDamage+=MaxDamagePreview.Crit;
					Item.Value=string(MaxDamagePreview.Crit);
					Item.Label=AbilityState.GetMyFriendlyName();
					Stats.AddItem(Item);
				}
			}
			else
			{
				if (!WepDamEffect.bApplyOnHit) WepDamEffect=X2Effect_ApplyWeaponDamage(Effect);
			}
		}
	}
	else 
	{
		foreach TargetEffects(Effect)
		{
			WepDamEffect=X2Effect_ApplyWeaponDamage(Effect);
			if (WepDamEffect.bApplyOnHit) break;
		}
	}

	if (WepDamEffect==none) return Stats;

	if (AbilityState.SourceAmmo.ObjectID > 0)
		SourceWeapon = AbilityState.GetSourceAmmo();
	else
		SourceWeapon = AbilityState.GetSourceWeapon();

	If (SourceWeapon==none) return Stats;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

	if (TargetUnit != None)
	{
		foreach WepDamEffect.TargetConditions(ConditionIter)
		{
			AvailableCode = ConditionIter.AbilityMeetsCondition(AbilityState, TargetUnit);
			if (AvailableCode != 'AA_Success')
				return Stats;
			AvailableCode = ConditionIter.MeetsCondition(TargetUnit);
			if (AvailableCode != 'AA_Success')
				return Stats;
			AvailableCode = ConditionIter.MeetsConditionWithSource(TargetUnit, SourceUnit);
			if (AvailableCode != 'AA_Success')
				return Stats;
		}
		foreach WepDamEffect.DamageTypes(DamageType)
		{
			if (TargetUnit.IsImmuneToDamage(DamageType))
				return Stats;
		}
	}
	
	if (WepDamEffect.bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral)
		return Stats;

	if (!WepDamEffect.bIgnoreBaseDamage)
	{
		SourceWeapon.GetBaseWeaponDamageValue(TargetUnit, BaseDamageValue);
		WepDamEffect.ModifyDamageValue(BaseDamageValue, TargetUnit, AppliedDamageTypes);
	}
	if (WepDamEffect.DamageTag != '')
	{
		SourceWeapon.GetWeaponDamageValue(TargetUnit, WepDamEffect.DamageTag, ExtraDamageValue);
		WepDamEffect.ModifyDamageValue(ExtraDamageValue, TargetUnit, AppliedDamageTypes);
	}
	if (SourceWeapon.HasLoadedAmmo() && !WepDamEffect.bIgnoreBaseDamage)
	{
		LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.LoadedAmmo.ObjectID));
		AmmoTemplate = X2AmmoTemplate(LoadedAmmo.GetMyTemplate()); 
		if (AmmoTemplate != None)
		{
			AmmoTemplate.GetTotalDamageModifier(LoadedAmmo, SourceUnit, TargetUnit, AmmoDamageValue);
			bDoesDamageIgnoreShields = AmmoTemplate.bBypassShields || bDoesDamageIgnoreShields;
		}
		else
		{
			LoadedAmmo.GetBaseWeaponDamageValue(TargetUnit, AmmoDamageValue);
		}
		WepDamEffect.ModifyDamageValue(AmmoDamageValue, TargetUnit, AppliedDamageTypes);
	}

	eState=eUIState_Good;
	if (bCrit)
	{
		Item.Value=string(BaseDamageValue.Crit+ExtradamageValue.Crit);
		CritDamage+=BaseDamageValue.Crit+ExtradamageValue.Crit;
	}
	else Item.Value=`RANGESTRINGN( `MINDAM(BaseDamageValue) + `MINDAM(ExtraDamageValue), `MAXDAM(BaseDamageValue) + `MAXDAM(ExtraDamageValue) );
	if (Item.Value!="0")
	{
		if (bCrit) `COLORTEXT( Item.Value, "+" $ Item.Value);
		else `COLORTEXT( Item.Value, Item.Value);
		`COLORTEXT( Item.Label, SourceWeapon.GetMyTemplate().GetItemFriendlyName(SourceWeapon.ObjectID));
		Stats.additem(Item);
	}

	if (bCrit)
	{
		Item.Value=string(BonusEffectDamageValue.Crit);
		CritDamage+=BonusEffectDamageValue.Crit;
	}
	else Item.Value=`RANGESTRING(BonusEffectDamageValue);
	if (Item.Value!="0")
	{
		`SETCOLOR(BonusEffectDamageValue.Damage);
		`COLORTEXT( Item.Value, prefix $ Item.Value);
		`COLORTEXT(Item.Label, AbilityState.GetMyFriendlyName());
		Stats.additem(Item);
	}

	if (bCrit)
	{
		Item.Value=string(AmmoDamageValue.Crit);
		CritDamage+=AmmoDamageValue.Crit;
	}
	else Item.Value=`RANGESTRING(AmmoDamageValue);
	if (Item.Value!="0")
	{
		`SETCOLOR(AmmoDamageValue.Damage);
		`COLORTEXT( Item.Value, prefix $ Item.Value);
		`COLORTEXT(Item.Label, LoadedAmmo.GetMyTemplate().GetItemFriendlyName(LoadedAmmo.ObjectID));
		Stats.additem(Item);
	}

	if (WepDamEffect.bAllowWeaponUpgrade)
	{
		WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
		foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
		{
			if (WeaponUpgradeTemplate.BonusDamage.Tag == WepDamEffect.DamageTag)
			{
				UpgradeDamageValue = WeaponUpgradeTemplate.BonusDamage;

				WepDamEffect.ModifyDamageValue(UpgradeDamageValue, TargetUnit, AppliedDamageTypes);

				if (bCrit)
				{
					Item.Value=string(UpgradeDamageValue.Crit);
					CritDamage+=UpgradeDamageValue.Crit;
				}
				else Item.Value=`RANGESTRING(UpgradeDamageValue);
				if (Item.Value!="0")
				{
					`SETCOLOR(UpgradeDamageValue.Damage);
					`COLORTEXT( Item.Value,prefix $ Item.Value);
					`COLORTEXT(Item.Label, WeaponUpgradeTemplate.GetItemFriendlyName());
					Stats.additem(Item);
				}

			}
		}
	}
	bShouldContinue=1;
	return Stats;
}

// Custom sort
function int SortAfterValue(UISummary_ItemStat A, UISummary_ItemStat B) {
    return (GetNumber(B.Value) > GetNumber(A.Value)) ? -1 : 0;
}

function bool getDISPLAY_MISS_CHANCE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'ExtendedInformationRedux3_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}


defaultproperties
{
	HIT_SHOW_NonTRIVIAL=true;
	DAMAGE_SHOW_NonTRIVIAL=true;
	CRIT_SHOW_NonTRIVIAL=true;
	CRIT_HIDE_TRIVIAL=true;
}