/**
 * UIEffectListItem_HitChance
 *
 * Custom UI list item for displaying unit effects with cooldown information.
 *
 * Responsibilities:
 * - Render effect icon and title layout
 * - Display formatted cooldown text
 * - Dynamically adjust layout based on content
 * - Notify parent list when size changes
 *
 * @author Mr.Nice / Sebkulu
 */
class UIEffectListItem_HitChance extends UIEffectListItem;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var UIText CoolDown;

/**
 * Initializes the effect list item UI elements.
 *
 * @param initList   Parent effect list
 * @param InitX      Initial X position
 * @param InitY      Initial Y position
 * @param InitWidth  Initial width
 *
 * @return UIEffectListItem   Initialized list item
 */
simulated function UIEffectListItem InitEffectListItem(UIEffectList initList,
															   optional int InitX = 0, 
															   optional int InitY = 0, 
															   optional int InitWidth = 0)
{
	`TRACE_ENTRY("InitX:" @ InitX $ ", InitY:" @ InitY $ ", InitWidth:" @ InitWidth);
	Super.InitEffectListItem(initList, InitX, InitY, InitWidth);
	CoolDown = Spawn(class'UIText', self).InitText('EffectiNumTurns', "", true);
	CoolDown.SetWidth(width);
	`TRACE_EXIT("");
	return self;
}

/**
 * Refreshes the visual display of the effect item.
 *
 * Handles:
 * - Icon validation and layout adjustments
 * - Title positioning
 * - Cooldown text rendering
 */
simulated function RefreshDisplay()
{
	`TRACE_ENTRY("Cooldown:" @ Data.Cooldown);
	// Sebkulu - DynamicLoadObject is used to test also the incapacity of game to load an icon even if the path to it is correctly set in template
	if (DynamicLoadObject(Repl(Data.Icon, "img:///", "", false), class'Texture2D') == none)
	{
		Data.Icon = "";
		Title.SetPosition(0, TitleYPadding);
		Title.SetWidth(width); 
	}
	else
	{
		Title.SetPosition( Icon.Y + Icon.width + TitleXPadding, TitleYPadding );
		Title.SetWidth(width - Title.X); 
	}

	Super.RefreshDisplay();
	Cooldown.SetHTMLText( GetCooldownString( Data.Cooldown ) );
	onTextSizeRealized();
	`TRACE_EXIT("");
}

/**
 * Formats cooldown value into a styled UI string.
 *
 * @param iCooldown   Cooldown value in turns
 *
 * @return string     Styled cooldown string
 */
simulated function string GetCooldownString( int iCooldown )
{
	`TRACE_ENTRY("iCooldown:" @ iCooldown);
	if( iCooldown > 0 ) return 
		class'UIUtilities_Text'.static.StyleText( class'UIMissionSummary'.default.m_strTurnsRemainingLabel, eUITextStyle_Tooltip_StatLabel)
		@ class'UIUtilities_Text'.static.StyleText(string(iCooldown), eUITextStyle_Tooltip_AbilityValue);
	else if (iCooldown==-1) return
		class'UIUtilities_Text'.static.StyleText( class'UIMissionSummary'.default.m_strTurnsRemainingLabel, eUITextStyle_Tooltip_StatLabel)
		@ class'UIUtilities_Text'.static.StyleText(string(0), eUITextStyle_Tooltip_AbilityValue);
	else return "";
}

/**
 * Recalculates and updates item height based on text and cooldown content.
 *
 * Notifies parent list if size changes.
 */
simulated function onTextSizeRealized()
{
	local int iCalcNewHeight;

	`TRACE_ENTRY("Cooldown:" @ Data.Cooldown);

	if (Data.Cooldown != 0)
		iCalcNewHeight = Desc.Y + Desc.height + Cooldown.Height; 
	else 
		iCalcNewHeight = Desc.Y + Desc.height + BottomPadding;

	if (iCalcNewHeight != Height )
	{
		Height = iCalcNewHeight;  
		Cooldown.SetY(Desc.Y + Desc.height);
		List.OnItemChanged(self);
	}
	`TRACE_EXIT("Height:" @ Height);
}
