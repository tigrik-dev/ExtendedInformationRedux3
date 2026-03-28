/**
 * Tooltip for displaying enemy stats with hit chance enhancements.
 *
 * Extends the default enemy tooltip to:
 * - Show detailed stat list using StatListLib
 * - Display unit icon and dynamic coloring (e.g. flanking)
 * - Support scrolling title and masked stat list
 * - Adjust layout dynamically based on content size
 *
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITacticalHUD_EnemyTooltip_HitChance extends UITacticalHUD_EnemyTooltip;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var UIMask BodyMask, TitleMask;
var UIPanel BGBox;
var UIScrollingText StatsTitle;
var UIIcon Icon;

var int TITLE_PADDING;

var bool bTop;
var int Weight, DeadHeight;

var int TOOLTIP_ALPHA, ICON_H_PADDING, ICON_V_PADDING, ICON_SIZE, PADDING_TEXT;
					   
var localized string PrimaryBase;//, PrimarySpread, PrimaryPlusOne, EnemyStatsTitle;

/**
 * Initializes the enemy stats tooltip UI.
 *
 * Configures:
 * - Title (scrolling text)
 * - Icon and divider line
 * - Stat list and masks
 * - Layout and padding
 *
 * @param InitName Name of the panel
 * @param InitLibID Library identifier
 * @return Initialized UIPanel instance
 */
simulated function UIPanel InitEnemyStats(optional name InitName, optional name InitLibID)
{
	`TRACE_ENTRY("InitName:" @ InitName @ "InitLibID:" @ InitLibID);
	Super.InitEnemyStats(InitName, InitLibID);

	BodyArea.SetX(-width);

	StatsTitle = Spawn(class'UIScrollingText', BodyArea).InitScrollingText('Title');
	//Title.SetPosition(PADDING_LEFT + TITLE_PADDING + ICON_H_PADDING + ICON_SIZE, PADDING_TOP);
	StatsTitle.SetPosition( 2 * ICON_H_PADDING + ICON_SIZE, PADDING_TOP);
	StatsTitle.SetWidth(width - PADDING_LEFT - TITLE_PADDING - PADDING_RIGHT - ICON_SIZE - class'UIStatList'.default.PADDING_RIGHT - PADDING_TEXT);
	//StatsTitle.SetHeight(StatsTitle.height);
	TitleMask= Spawn(class'UIMask', BodyArea).InitMask('TitleMask', StatsTitle).FitMask(StatsTitle);

	Icon = Spawn(class'UIIcon', BodyArea);
	Icon.InitIcon(,,false,true,ICON_SIZE);
	Icon.SetPosition(ICON_H_PADDING, ICON_V_PADDING);

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl(Icon, , 0);
	Line.SetX(0);
	Line.SetWidth(width);

	DeadHeight=StatsTitle.Y + StatsTitle.height + PaddingForAbilityList + PADDING_BOTTOM;

	StatList.SetPosition(PADDING_LEFT, StatsTitle.Y + StatsTitle.height + PaddingForAbilityList);
	StatList.SetWidth(BodyArea.width-PADDING_RIGHT);
	StatList.SetHeight(BodyArea.Height-DeadHeight);
	StatList.PADDING_RIGHT=class'UIStatList'.default.PADDING_RIGHT/2;
	StatList.OnSizeRealized = OnStatsListSizeRealized;
	BodyMask = Spawn(class'UIMask', BodyArea).InitMask('Mask', StatList).FitMask(StatList); 
	BGBox=GetChild('BGBoxSimpleStats');
	//BodyMask = UIMask(GetChildByName('StatMask')).FitMask(StatList);

	Height=StatsHeight;
	StatsHeight=StatList.Height;
	BGBox.SetAlpha(getTOOLTIP_ALPHA()); // Setting transparency
	BodyArea.Alpha=100; // Stupid fudge!
	`TRACE_EXIT("");
	return self; 
}

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
	if ((TooltipGroup) == none) super(UIToolTip).ShowTooltip();
	else
	{
		bIsVisible=true;
		ClearTimer(nameof(Hide));
	}
	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Builds the stat list for a given unit.
 *
 * Handles:
 * - Icon setup and coloring (including flanking detection)
 * - Title text update
 * - Delegates stat generation to StatListLib
 *
 * @param kGameStateUnit Unit to generate stats for
 * @return Array of UISummary_ItemStat entries
 */
simulated function array<UISummary_ItemStat> GetStats(XComGameState_Unit kGameStateUnit)
{
	local XComGameState_BaseObject TargetedObject;
	local X2VisualizerInterface Visualizer;
	local XComTacticalController LocalController;
	`TRACE_ENTRY("UnitID:" @ kGameStateUnit.ObjectID);

	TargetedObject = `XCOMHISTORY.GetGameStateForObjectID(kGameStateUnit.ObjectID, , );
	Visualizer = X2VisualizerInterface(TargetedObject.GetVisualizer());
	LocalController = XComTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) );

	Icon.remove();

	Icon = Spawn(class'UIIcon', BodyArea);
	Icon.InitIcon(,,false,true,ICON_SIZE);
	Icon.SetPosition(ICON_H_PADDING, ICON_V_PADDING);
	Icon.bAnimateOnInit = false;

	Icon.Hide();

	Icon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);

	// Sebkulu - Find the active Unit that is in use for the current Player Visualizer to check Flank against this unit
	if(XComGameState_Unit(TargetedObject).IsFlanked(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LocalController.ControllingPlayerVisualizer.GetActiveUnit().ObjectID)).GetReference()) /*&& XComGameState_Unit(TargetedObject).GetTeam() == eTeam_Alien*/)
	{
		Icon.SetBGColorState(eUIState_Warning);
	}
	else	Icon.SetBGColorState(Visualizer.GetMyHUDIconColor());
	Icon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(Visualizer.GetMyHUDIcon()));
	Icon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(Visualizer.GetMyHUDIcon()$"_bg"));
	//Icon.SetAlpha(85);
	Icon.Show();
	//Hack!
	StatsTitle.SetHTMLText( class'UIUtilities_Text'.static.StyleText(kGameStateUnit.GetName(eNameType_FullNick), eUITextStyle_Tooltip_Title) );
	`TRACE_EXIT("");
	return class'StatListLib'.static.GetStats(kGameStateUnit);
}

/**
 * Handles layout updates when the stat list size changes.
 *
 * Adjusts:
 * - Tooltip height
 * - Background size
 * - Mask height
 * - Tooltip group positioning
 */
simulated function OnStatsListSizeRealized()
{
	`TRACE_ENTRY("");
	StatsHeight=StatList.Height;
	Height=StatsHeight	+ StatList.Y + PADDING_BOTTOM;
	BGBox.SetHeight(Height);
	StatList.SetHeight(StatsHeight);
	BodyMask.SetHeight(StatsHeight);

	if (TooltipGroup != none)
	{
		if (UITooltipGroup_Stacking(TooltipGroup) != none)
			UITooltipGroup_Stacking(TooltipGroup).UpdateRestingYPosition(self, Y);
		TooltipGroup.SignalNotify();
	}
	`TRACE_EXIT("");
}

/**
 * Overrides height setting behavior.
 *
 * Prevents resizing and triggers a redscreen warning if called.
 *
 * @param NewHeight Requested height value
 */
simulated function SetHeight(float NewHeight)
{
	`redscreen("RESIZE ATTEMPT ON STATS LIST!!!!");
}

function int getTOOLTIP_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.TOOLTIP_ALPHA);
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties 
{
	Anchor=0;

	width = 255;
	height = 390; 
	StatsHeight = 390;
	TITLE_PADDING = 10;
	//AbilitiesHeight = 300; 
	PaddingForAbilityList = 0;

	PADDING_LEFT	= 0;
	PADDING_RIGHT	= 0;
	PADDING_TOP		= 2;
	PADDING_BOTTOM	= 5;
	bTop=true;
	Weight=0;

	ICON_H_PADDING = 2;
	ICON_V_PADDING = 0;
	ICON_SIZE = 32;
	PADDING_TEXT = 0;
}