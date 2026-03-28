/**
 * Extended soldier info tooltip that enhances the tactical HUD display.
 *
 * Responsibilities:
 * - Displays detailed unit stats using StatListLib
 * - Dynamically renders class and rank icons
 * - Handles layout differences for soldiers, civilians, and enemies
 * - Applies custom styling and transparency via MCM configuration
 *
 * Integrates into the tactical HUD tooltip system and replaces/extends
 * the default soldier info tooltip behavior.
 *
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITacticalHUD_SoldierInfoTooltip_HitChance extends UITacticalHUD_SoldierInfoTooltip;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var	int TOOLTIP_ALPHA;

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var UIPanel BGBox;
var UIScrollingText Title;
var UIPanel Line;
var UIIcon Icon, RankIcon;

var int TITLE_PADDING, DeadHeight, PaddingForAbilityList, ICON_H_PADDING, ICON_V_PADDING, ICON_SIZE, TEXT_PADDING, RANK_ICON_SIZE, RANK_ICON_H_PADDING, RANK_ICON_V_PADDING;

/**
 * Initializes the soldier stats tooltip UI.
 *
 * Sets up title, icons (class + rank), divider line, stat list,
 * and applies layout + transparency settings.
 */
simulated function UIPanel InitSoldierStats(optional name InitName, optional name InitLibID)
{
	`TRACE_ENTRY("InitName:" @ InitName @ "InitLibID:" @ InitLibID);
	Super.InitSoldierStats(InitName, InitLibID);

	Title = Spawn(class'UIScrollingText', BodyArea).InitScrollingText('Title');
	//Title.SetPosition(PADDING_LEFT + TITLE_PADDING, PADDING_TOP);
	Title.SetPosition(ICON_SIZE + 2 * ICON_H_PADDING + TEXT_PADDING, PADDING_TOP);
	Title.SetWidth(width - TITLE_PADDING - ICON_SIZE - Title.X);

	Icon = Spawn(class'UIIcon', BodyArea);
	Icon.InitIcon(,,false,true,ICON_SIZE);
	Icon.SetPosition(ICON_H_PADDING, ICON_V_PADDING);

	RankIcon = Spawn(class'UIIcon', BodyArea);
	RankIcon.InitIcon(,,false,true,RANK_ICON_SIZE);
	RankIcon.SetPosition(RANK_ICON_H_PADDING, RANK_ICON_V_PADDING);

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl(Icon, , 2);
	Line.SetX(0);
	Line.SetWidth(width);

	DeadHeight=Title.Y + Title.height + PaddingForAbilityList + PADDING_BOTTOM;	

	StatList.SetPosition(PADDING_LEFT, Title.Y + Title.height + PaddingForAbilityList);
	StatList.SetWidth(BodyArea.width-PADDING_RIGHT);
	StatList.SetHeight(BodyArea.Height-DeadHeight);
	StatList.PADDING_RIGHT=class'UIStatList'.default.PADDING_RIGHT/2;
	StatList.OnSizeRealized = OnStatsListSizeRealized;
	BodyMask = Spawn(class'UIMask', BodyArea).InitMask('Mask', StatList).FitMask(StatList); 
	BGBox=GetChild('BGBoxSimple');

	Height=StatsHeight;
	StatsHeight=StatList.Height;
	BGBox.SetAlpha(getTOOLTIP_ALPHA()); // Setting transparency
	BodyArea.Alpha=100; // Stupid fudge!
	`TRACE_EXIT("");
	return self;
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Builds and returns soldier stats for display in the tooltip.
 *
 * Handles:
 * - Special cases (Psi Witch, civilians, enemies)
 * - Icon layout (class + rank)
 * - Title formatting
 * - Delegation to StatListLib for stat generation
 */
simulated function array<UISummary_ItemStat> GetSoldierStats(XComGameState_Unit kGameStateUnit)
{
	local X2SoldierClassTemplateManager SoldierTemplateManager;

	`TRACE_ENTRY("UnitObjectID:" @ kGameStateUnit.ObjectID);
	//Icon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
	//Icon.SetBGColorState(Visualizer.GetMyHUDIconColor());
	if( kGameStateUnit.GetMyTemplateName() == 'AdvPsiWitchM2' )
	{
		SoldierTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		 
		Title.SetX(ICON_SIZE);
		Title.SetWidth(width - Title.X - TITLE_PADDING - ICON_H_PADDING - TEXT_PADDING);
		DrawIcons(ICON_SIZE * 2, -ICON_SIZE, -ICON_SIZE, class'UIUtilities_Image'.static.ValidateImagePath(SoldierTemplateManager.FindSoldierClassTemplate('PsiOperative').IconImage), RANK_ICON_SIZE, width - RANK_ICON_SIZE / 2 - TEXT_PADDING, -RANK_ICON_SIZE / 2, class'UIUtilities_Image'.static.ValidateImagePath("img:///UILibrary_Common.rank_fieldmarshall"));
	}
	else 
	{
		if( kGameStateUnit.IsSoldier() )
		{
			Title.SetX(ICON_SIZE);
			Title.SetWidth(width - Title.X - TITLE_PADDING - ICON_H_PADDING - TEXT_PADDING);
			DrawIcons(ICON_SIZE * 2, -ICON_SIZE, -ICON_SIZE, class'UIUtilities_Image'.static.ValidateImagePath(kGameStateUnit.GetSoldierClassTemplate().IconImage), RANK_ICON_SIZE, width - RANK_ICON_SIZE / 2 - TEXT_PADDING, -RANK_ICON_SIZE / 2, class'UIUtilities_Image'.static.ValidateImagePath(class'UIUtilities_Image'.static.GetRankIcon(kGameStateUnit.GetRank(), kGameStateUnit.GetSoldierClassTemplateName())));
		}
		else if( kGameStateUnit.IsCivilian() )
		{
			Title.SetX(TITLE_PADDING);
			Title.SetWidth(width - PADDING_LEFT - TITLE_PADDING - PADDING_RIGHT);
			DrawIcons();
		}
		else // is enemy
		{
			Title.SetX(ICON_SIZE + TEXT_PADDING);
			Title.SetWidth(width - Title.X - TITLE_PADDING);
			DrawIcons(ICON_SIZE, PADDING_LEFT, ICON_V_PADDING, class'UIUtilities_Image'.static.ValidateImagePath(kGameStateUnit.IsAdvent() ? "img:///UILibrary_Common.UIEvent_advent" : "img:///UILibrary_Common.UIEvent_alien"));
		}
	}
	//Icon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(kGameStateUnit.GetSoldierClassTemplate().IconImage$"_bg"));
	//Icon.SetBGShape(eDiamond);
	//Icon.SetAlpha(85);

	//Mr. Nice: just doing eNameType_FullNick worked fine for soldiers & alien/advent, but made vips/civs/resistance fighters show as rookie...
	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText(kGameStateUnit.GetName(kGameStateUnit.IsSoldier() ? eNameType_FullNick : eNameType_Full), eUITextStyle_Tooltip_Title) );
	`TRACE_EXIT("");
	return class'StatListLib'.static.GetStats(kGameStateUnit, true);
}

/**
 * Draws class and rank icons with configurable sizes and positions.
 *
 * Supports:
 * - Class icon only
 * - Rank icon only
 * - Both icons
 * - Hiding icons if not provided
 */
simulated function DrawIcons(optional int iClassIconSize, optional int iClassIconHPadding, optional int iClassIconVPadding, optional string sClassIcon, optional int iRankIconSize, optional int iRankIconHPadding, optional int iRankIconVPadding, optional string sRankIcon)
{
	`TRACE_ENTRY("ClassIconSize:" @ iClassIconSize @ "RankIconSize:" @ iRankIconSize);
	Icon.Hide();
	RankIcon.Hide();

	if(sClassIcon != "")
	{
		Icon.SetSize(iClassIconSize, iClassIconSize);
		Icon.SetPosition(iClassIconHPadding, iClassIconVPadding);
		Icon.bAnimateOnInit = false;
		Icon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(sClassIcon));
		Icon.HideBG();
		Icon.Show();
	}

	if(sRankIcon != "")
	{
		RankIcon.SetSize(iRankIconSize,iRankIconSize);
		RankIcon.SetPosition(iRankIconHPadding, iRankIconVPadding);
		RankIcon.bAnimateOnInit = false;
		RankIcon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(sRankIcon));
		RankIcon.HideBG();
		RankIcon.Show();
	}
	`TRACE_EXIT("");
}

/**
 * Callback triggered when the stat list size changes.
 *
 * Updates:
 * - Tooltip height
 * - Background size
 * - Scroll mask
 * - Tooltip vertical positioning
 */
simulated function OnStatsListSizeRealized()
{
	`TRACE_ENTRY("");
	StatsHeight=StatList.Height;
	Height=StatsHeight	+ StatList.Y + PADDING_BOTTOM;
	BGBox.SetHeight(Height);

	SetY( -180 - height);
	StatList.SetHeight(StatsHeight);
	BodyMask.SetHeight(StatsHeight);
	`TRACE_EXIT("");
}


function int getTOOLTIP_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.TOOLTIP_ALPHA);
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	width = 270;
	height = 390; 
	TITLE_PADDING = 10;
	StatsHeight=390;
//	StatsHeight=325;
	StatsWidth=270;

	//StatsHeight=200;
	//StatsWidth=200;

	PaddingForAbilityList = 0;
	PADDING_LEFT	= 0;
	PADDING_RIGHT	= 0;
	PADDING_TOP		= 5;
	PADDING_BOTTOM	= 5;
	//PADDING_BETWEEN_PANELS = 10;
	ICON_H_PADDING = 4;
	ICON_V_PADDING = 0;
	ICON_SIZE = 32;
	TEXT_PADDING = 4;
	RANK_ICON_SIZE = 48;
	RANK_ICON_H_PADDING = -16;
	RANK_ICON_V_PADDING = 32;
}
