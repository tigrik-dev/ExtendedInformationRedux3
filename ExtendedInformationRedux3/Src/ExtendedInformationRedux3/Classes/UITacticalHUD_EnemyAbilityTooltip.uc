/**
 * Tooltip for displaying enemy abilities in the tactical HUD.
 *
 * Extends UITooltip to:
 * - Show enemy ability list with hit chance integration
 * - Dynamically build UI based on hovered enemy
 * - Handle layout, masking, and resizing
 *
 * @author Mr. Nice / Sebkulu
 */
class UITacticalHUD_EnemyAbilityTooltip extends UITooltip;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int PaddingForAbilityList;

var int MaxHeight; 

//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
var  UIAbilityList_HitChance	AbilityList; 
var UIMask					AbilityListMask;
var UIText					Title; 
var UIPanel					BGBox;
//var UIPanel					Line; 
 
var bool bTop;

var int TOOLTIP_ALPHA;

var int Weight, DeadHeight;

/**
 * Initializes the enemy abilities tooltip UI.
 *
 * Sets up:
 * - Background panel
 * - Title text
 * - Ability list and mask
 * - Layout and padding
 *
 * @param InitName Name of the panel
 * @param InitLibID Library identifier
 * @return Initialized UIPanel instance
 */
simulated function UIPanel InitEnemyAbilities(optional name InitName, optional name InitLibID)
{
	`TRACE_ENTRY("");
	InitPanel(InitName, InitLibID);

	//height = StatsHeight + PaddingBetweenBoxes;

	Hide();

	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
	
	BGBox = Spawn(class'UIPanel', self).InitPanel('BGBoxSimpleAbility', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple)
		.SetSize(width, height);
	
	Title = Spawn(class'UIText', self).InitText('Title');
	Title.SetPosition(PADDING_LEFT, PADDING_TOP); 
	Title.SetWidth(width - PADDING_LEFT-PADDING_RIGHT); 
	//Title.SetAlpha( class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_StatLabel).Alpha );
	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.TacticalTextAbilitiesHeader, eUITextStyle_Tooltip_StatLabel) );

	//Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( Title );

	DeadHeight=PADDING_TOP+ PaddingForAbilityList + PADDING_BOTTOM;

	AbilityList = Spawn(class'UIAbilityList_HitChance', self);
	AbilityList.InitAbilityList('AbilityList',
		, 
		PADDING_LEFT, 
		PADDING_TOP + PaddingForAbilityList, 
		width-PADDING_LEFT-PADDING_RIGHT, 
		height-DeadHeight,
		height-DeadHeight);
	AbilityList.OnSizeRealized=OnAbilityListSizeRealized;
	AbilityListMask=Spawn(class'UIMask', self).InitMask('AbilityMask', AbilityList).FitMask(AbilityList); 
	
	// --------------------

	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
	//height = BodyArea.Y + BodyArea.height + PaddingBetweenBoxes + BGBox.height;

	//Re-enabling EnemyToolTip
	BGBox.SetAlpha(getTOOLTIP_ALPHA());
	`TRACE_EXIT("");
	return self; 
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Displays the tooltip if valid data is available.
 *
 * Calls RefreshData and only shows the tooltip if data exists.
 * Handles grouped tooltip behavior.
 */
simulated function ShowTooltip()
{
	`TRACE_ENTRY("");
	if (!RefreshData()) return;

	if ((TooltipGroup) == none) super.ShowTooltip();
	else
	{
		bIsVisible=true;
		ClearTimer(nameof(Hide));
	}
	`TRACE_EXIT("");
}

/**
 * Refreshes tooltip data based on the currently hovered enemy.
 *
 * Determines:
 * - Active enemy unit
 * - Retrieves ability list
 * - Updates UI list and layout
 *
 * @return True if data is valid and tooltip should be shown, false otherwise
 */
simulated function bool RefreshData()
{
	local XGUnit				ActiveUnit;
	local XComGameState_Unit	GameStateUnit;
	local array<UISummary_Ability> UIAbilities;
	local int					iTargetIndex;
	local array<string>			Path;

	`TRACE_ENTRY("");

	Path = SplitString(currentPath, ".");
	iTargetIndex = int(Split(Path[5], "icon", true));
	ActiveUnit = XGUnit(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyAtIcon(iTargetIndex));

	if( ActiveUnit == none )
	{
		//HideTooltip(); 
		return false; 
	} 
	else if( ActiveUnit != none )
	{
		GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	}
	
	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 

	UIAbilities = GetUISummary_Abilities(GameStateUnit);

	//Mr. Nice: Dropping blank abilities moved to wtihin GetUISummary_Abilities(), so all filtering in same place
	if( UIAbilities.length == 0 )
	{
		if( XComTacticalController(PC) != None )
			return false;
		else
			AbilityList.RefreshData( DEBUG_GetUISummary_Abilities() );
	}
	else
	{
		AbilityList.RefreshData(UIAbilities);
		AbilityList.OnItemChanged(none);
	}
	OnAbilityListSizeRealized();
	`TRACE_EXIT("Return: true");
	return true;
}

/**
 * Builds a list of UI ability summaries for a unit.
 *
 * Filters abilities based on:
 * - Visibility rules
 * - Template flags
 * - Valid ability data
 *
 * @param Unit Target unit
 * @return Array of UISummary_Ability entries
 */
function array<UISummary_Ability> GetUISummary_Abilities(XComGameState_Unit Unit)
{
	local array<UISummary_Ability> UIAbilities; 
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit
	local X2AbilityTemplate AbilityTemplate; 
	local UISummary_Ability AbilityData;
	local int i, len; 

	`TRACE_ENTRY("");
	len = Unit.Abilities.Length;
	for(i = 0; i < len; i++)
	{	
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Unit.Abilities[i].ObjectID));
		if( AbilityState == none) continue; 

		AbilityTemplate = AbilityState.GetMyTemplate(); 
		if( AbilityTemplate.eAbilityIconBehaviorHUD==eAbilityIconBehavior_NeverShow
			|| !AbilityTemplate.bDisplayInUITooltip )//Mr. Nice Defaults to True, so if set to False is deliberate, so obey!
			continue; 

		AbilityData = AbilityList.GetUISummary_Ability(AbilityState, Unit);

		// If Ability gest a name, add to our list of abilities 		
		if (AbilityData.Name != "")
			UIAbilities.AddItem(AbilityData);
	}
	`TRACE_EXIT("");
	return UIAbilities; 
}

/**
 * Generates debug ability data for testing UI behavior.
 *
 * @return Array of mock UISummary_Ability entries
 */
simulated function array<UISummary_Ability> DEBUG_GetUISummary_Abilities()
{
	local UISummary_Ability Data; 
	local array<UISummary_Ability> Abilities; 
	local int i; 

	`TRACE_ENTRY("");
	for( i = 0; i < 5; i ++ )
	{
		Data.KeybindingLabel = "KEY";
		Data.Name = "DESC " $ i; 
		Data.Description = "Description text area. Lorizzle for sure dolizzle shizznit amizzle, crunk adipiscing fo. Nullizzle sapien velizzle, yo volutpizzle, quizzle, daahng dawg vel, arcu. "; 
		Data.ActionCost = 1;
		Data.CooldownTime = 1; 
		Data.bEndsTurn = true;
		Data.EffectLabel = "REFLEX";
		Data.Icon = "img:///UILibrary_PerkIcons.UIPerk_gremlincommand";

	
		Abilities.additem(Data);
	}
	`TRACE_EXIT("");
	return Abilities; 
}

/**
 * Handles layout updates when the ability list size changes.
 *
 * Adjusts:
 * - Tooltip height
 * - Background size
 * - Mask height
 * - Tooltip group positioning
 */
simulated function OnAbilityListSizeRealized()
{
	`TRACE_ENTRY("");
	Height = DeadHeight + AbilityList.MaskHeight;
	BGBox.SetHeight( Height );
	AbilityListMask.SetHeight(AbilityList.MaskHeight);

	if (TooltipGroup != none)
	{
		if (UITooltipGroup_Stacking(TooltipGroup) != none)
			UITooltipGroup_Stacking(TooltipGroup).UpdateRestingYPosition(self, Y);
		TooltipGroup.SignalNotify();
	}
	`TRACE_EXIT("");
}

/**
 * Sets tooltip height and updates layout accordingly.
 *
 * Adjusts:
 * - Ability list mask
 * - Scroll behavior
 * - Background size
 *
 * @param NewHeight New height value
 */
simulated function SetHeight(float NewHeight)
{
	`TRACE_ENTRY("");
	if (Height==NewHeight) return;
	Height=NewHeight;

	AbilityList.MaskHeight=Height-DeadHeight;
	ABilityList.ClearScroll();
	AbilityList.AnimateScroll(AbilityList.height, AbilityList.MaskHeight);

	BGBox.SetHeight( Height );
	AbilityListMask.SetHeight(AbilityList.MaskHeight);
	`TRACE_EXIT("");
}

function int getTOOLTIP_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.TOOLTIP_ALPHA);
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties 
{
	width = 350;
	height = 300; 
	PaddingForAbilityList = 33;

	PADDING_LEFT	= 10;
	PADDING_RIGHT	= 10;
	PADDING_TOP		= 2;
	PADDING_BOTTOM	= 5;

	bTop=true;
	Weight=2;
	Anchor=0; //For SetSize behaviour if called more than once!
}