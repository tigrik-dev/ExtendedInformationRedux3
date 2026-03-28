/**
 * UIAbilityListItem_HitChance
 *
 * Custom UI list item for displaying abilities with hit chance support.
 *
 * Responsibilities:
 * - Render ability icon and text layout
 * - Dynamically adjust layout based on icon presence
 * - Handle resizing based on description and cooldown content
 * - Notify parent list when size changes
 *
 * @author Mr.Nice / Sebkulu
 */
class UIAbilityListItem_HitChance extends UIAbilityListItem;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var UIIcon Icon;

var int TitleYPadding, BottomPadding;

/**
 * Initializes the ability list item UI elements.
 *
 * @param initList   Parent ability list
 * @param InitX      Initial X position
 * @param InitY      Initial Y position
 * @param InitWidth  Initial width of the item
 *
 * @return UIAbilityListItem   Initialized list item
 */
simulated function UIAbilityListItem InitAbilityListItem(UIAbilityList initList,
															   optional int InitX = 0, 
															   optional int InitY = 0, 
															   optional int InitWidth = 0)
{
	`TRACE_ENTRY("InitX:" @ InitX $ ", InitY:" @ InitY $ ", InitWidth:" @ InitWidth);
	Super.InitAbilityListItem(initList, InitX, InitY, InitWidth);
	Icon = Spawn(class'UIIcon', self).InitIcon('IconMC',,false,true, 36);
	Title.SetPosition(Icon.width + TitlePadding, TitleYPadding);
	Title.SetWidth(width - Title.X); 
	Line.SetY(Line.Y + TitleYPadding);
	Actions.SetPosition(0, Line.Y + ActionsPadding); 
	EndTurn.SetPosition(0, Line.Y + ActionsPadding);
	//Desc.SetPosition(0, Actions.Y + Actions.height);
	`TRACE_EXIT("");
	return self;
}

/**
 * Refreshes the visual display of the ability item.
 *
 * Handles:
 * - Icon visibility and positioning
 * - Title layout adjustments
 * - Description positioning based on cost/turn-ending
 */
simulated function RefreshDisplay()
{
	`TRACE_ENTRY("ActionCost:" @ Data.ActionCost $ ", bEndsTurn:" @ Data.bEndsTurn);
	// Sebkulu - DynamicLoadObject is used to test also the incapacity of game to load an icon even if the path to it is correctly set in template
	if (Data.Icon == "" || DynamicLoadObject(Repl(Data.Icon, "img:///", "", false), class'Texture2D') == none)
	{
		Icon.Hide();
		Title.SetPosition(0, TitleYPadding);
		Title.SetWidth(width); 

	}
	else
	{
		Icon.LoadIcon(Data.Icon);
		Icon.Show();
		Title.SetPosition(Icon.width + TitlePadding, TitleYPadding);
		Title.SetWidth(width - Title.X); 
	}

	if (Data.ActionCost==0 && !Data.bEndsTurn)
		Desc.SetY(Actions.Y);
	else Desc.SetY(Actions.Y + Actions.height);
	Super.RefreshDisplay();
	onTextSizeRealized();
	`TRACE_EXIT("");
}

/**
 * Recalculates and applies item height based on text content.
 *
 * Adjusts layout depending on cooldown visibility and ensures
 * the parent list is notified when size changes.
 */
simulated function onTextSizeRealized()
{
	local int iCalcNewHeight;
	`TRACE_ENTRY("CooldownTime:" @ Data.CooldownTime);
	if (Data.CooldownTime != 0)
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



defaultproperties
{
	TitleYPadding = 4;
	ActionsPadding = 8;
	BottomPadding=6;
}