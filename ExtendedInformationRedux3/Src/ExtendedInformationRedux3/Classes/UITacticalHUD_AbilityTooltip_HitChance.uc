/**
 * UITacticalHUD_AbilityTooltip_HitChance
 *
 * Custom tactical HUD tooltip that displays ability information
 * enhanced with hit chance data.
 *
 * Responsibilities:
 * - Initialize and manage ability tooltip UI
 * - Integrate custom ability list with hit chance visualization
 * - Dynamically refresh tooltip content based on selected ability
 * - Handle resizing and positioning of tooltip elements
 *
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITacticalHUD_AbilityTooltip_HitChance extends UITacticalHUD_AbilityTooltip;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

//var int TOOLTIP_ALPHA; Not actually used.

var UIAbilityList_HitChance	XCOMAbilityList;
var UIMask					XCOMAbilityListMask;

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

/**
 * Initializes the ability tooltip UI panel and its components.
 *
 * @param InitName    Panel name
 * @param InitLibID   Library ID
 * @param InitX       Initial X position
 * @param InitY       Initial Y position
 * @param InitWidth   Initial width
 *
 * @return UIPanel    Initialized tooltip panel
 */
simulated function UIPanel InitAbility(optional name InitName, 
										 optional name InitLibID,
										 optional int InitX = 0, //Necessary for anchoring
										 optional int InitY = 0, //Necessary for anchoring
										 optional int InitWidth = 0)
{
	`TRACE_ENTRY("InitX:" @ InitX $ ", InitY:" @ InitY $ ", InitWidth:" @ InitWidth);
	//Super.InitAbility(InitName, InitLibID, InitX, InitY, InitWidth);
	InitPanel(InitName, InitLibID);

	Hide();

	SetPosition(InitX, InitY);
	InitAnchorX = X; 
	InitAnchorY = Y; 

	if( InitWidth != 0 )
		width = InitWidth;

	//---------------------

	BG = Spawn(class'UIPanel', self).InitPanel('BGBoxSimplAbilities', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetPosition(0, 0).SetSize(width, height);
	BG.SetAlpha(getTOOLTIP_ALPHA()); // Setting transparency

	// --------------------

	XCOMAbilityList = Spawn(class'UIAbilityList_HitChance', self);
	XCOMAbilityList.InitAbilityList('XCOMAbilityList',
		, 
		PADDING_LEFT, 
		PADDING_TOP, 
		width-PADDING_LEFT-PADDING_RIGHT, 
		height-PADDING_TOP-PADDING_BOTTOM,
		height-PADDING_TOP-PADDING_BOTTOM);
	XCOMAbilityList.OnSizeRealized=OnAbilitySizeRealized;
	XcomAbilityList.MaxHeight=MAX_HEIGHT-PADDING_TOP-PADDING_BOTTOM;
	XCOMAbilityListMask=Spawn(class'UIMask', self).InitMask('XCOMAbilityMask', XCOMAbilityList).FitMask(XCOMAbilityList); 

	`TRACE_EXIT("");
	return self; 
}

`MCM_CH_STATICVersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Refreshes tooltip data based on the currently selected ability.
 *
 * Handles:
 * - Debug fallback when no tactical controller is present
 * - Ability lookup from HUD
 * - Populating UI ability list
 */
simulated function RefreshData()
{
	local XComGameState_Ability	kGameStateAbility;
	local int					iTargetIndex; 
	local array<string>			Path; 
	local array<UISummary_Ability> UIAbilities;

	`TRACE_ENTRY("");
	if( XComTacticalController(PC) == None )
	{	
		Data = DEBUG_GetUISummary_Ability();
		RefreshDisplay();	
		return; 
	}

	Path = SplitString( currentPath, "." );	

	if (Path.Length > 5)
	{
		iTargetIndex = int(GetRightMost(Path[5]));
		kGameStateAbility = UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kAbilityHUD.GetAbilityAtIndex(iTargetIndex);
	}
	
	if( kGameStateAbility == none )
	{
		HideTooltip();
		return; 
	}

	Data = XCOMAbilityList.GetUISummary_Ability(kGameStateAbility);
	UIAbilities.AddItem(Data);
	XCOMAbilityList.RefreshData(UIAbilities);
	//RefreshDisplay();
	`TRACE_EXIT("");
}

/**
 * Builds a UI summary structure for a given ability.
 *
 * @param kGameStateAbility   Ability state object
 * @param UnitState           Optional unit owning the ability
 *
 * @return UISummary_Ability  Populated ability summary
 */
static function	UISummary_Ability GetUISummary_Ability(XComGameState_Ability kGameStateAbility, optional XComGameState_Unit UnitState)
{
	local UISummary_Ability AbilityData;
	local X2AbilityTemplate	AbilityTemplate;
	local X2AbilityCost		Cost;

	`TRACE_ENTRY("");
	AbilityData=kGameStateAbility.GetUISummary_Ability(UnitState);

	AbilityTemplate=kGameStateAbility.GetMyTemplate();

	foreach AbilityTemplate.AbilityCosts(Cost)
	{
		if (Cost.IsA('X2AbilityCost_ActionPoints') && !X2AbilityCost_ActionPoints(Cost).bFreeCost)
		AbilityData.ActionCost += X2AbilityCost_ActionPoints(Cost).GetPointCost(kGameStateAbility, UnitState);
	}

	
	if (UnitState==none)
		UnitState=XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kGameStateAbility.OwnerStateObject.ObjectID));

	if (UnitState==none) return AbilityData;

	AbilityData.CooldownTime = AbilityTemplate.AbilityCooldown.GetNumTurns(kGameStateAbility, UnitState, none, none);
	AbilityData.bEndsTurn = AbilityTemplate.WillEndTurn(kGameStateAbility, UnitState); // Will End Turn
	AbilityData.Icon = kGameStateAbility.GetMyIconImage();

	`TRACE_EXIT("ActionCost:" @ AbilityData.ActionCost $ ", CooldownTime:" @ AbilityData.CooldownTime);
	return AbilityData;
}

/**
 * Updates tooltip size and position after ability list resizing.
 *
 * Adjusts:
 * - Tooltip height
 * - Background size
 * - Vertical positioning
 * - Mask height
 */
simulated function OnAbilitySizeRealized()
{
	`TRACE_ENTRY("");
	Height = XcomAbilityList.MaskHeight +PADDING_TOP+PADDING_BOTTOM;
	BG.SetHeight( Height );
	SetY( InitAnchorY - height );
	XComAbilityListMask.SetHeight(XComAbilityList.MaskHeight);
	`TRACE_EXIT("Height:" @ Height);
}

static function int getTOOLTIP_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.TOOLTIP_ALPHA);
}

defaultproperties
{
	//height = 200; 
}

