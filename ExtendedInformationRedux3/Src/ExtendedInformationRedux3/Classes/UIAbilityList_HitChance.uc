/**
 * UIAbilityList_HitChance
 *
 * Custom ability list UI component that supports hit chance visualization.
 *
 * Responsibilities:
 * - Dynamically build and update ability list items
 * - Integrate hit chance–enhanced UI elements
 * - Manage layout, scrolling, and resizing of the ability list
 *
 * @author Mr.Nice / Sebkulu
 */
class UIAbilityList_HitChance extends UIAbilityList;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var int MaxHeight;
var int LastActive;
delegate OnSizeRealized();

/**
 * Refreshes the ability list UI with new data.
 *
 * @param Data   Array of ability summaries to display
 */
simulated function RefreshData(array<UISummary_Ability> Data)
{
	local UIAbilityListItem Item; 
	local int i; 

	`TRACE_ENTRY("Data.Length:" @ Data.Length);
	//Test
	for( i = 0; i < Data.Length; i++ )
	{
		
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UIAbilityListItem_HitChance', self).InitAbilityListItem(self);
			Item.ID = i; 
			Items.AddItem(Item);
		}
		
		// Grab our target Item
		Item = Items[i]; 

		//Update Data 
		Item.Data = Data[i]; 

		Item.Show();
		Item.AnimateIn();
		Item.Title.AnimateIn();
		Item.Actions.AnimateIn();
		Item.EndTurn.AnimateIn();
		Item.Desc.AnimateIn();
		Item.Cooldown.AnimateIn();
	}
	LastActive=i-1;
	//List items no longer notify on height change, so we call OnItemChanged once directly

	// Hide any excess list items if we didn't use them. 
	for( i = Data.Length; i < Items.Length; i++ )
	{
		Items[i].Hide();
	}
	`TRACE_EXIT("LastActive:" @ LastActive);
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
	local UISummary_Ability Data;
	local X2AbilityTemplate	AbilityTemplate;
	local X2AbilityCost		Cost;

	`TRACE_ENTRY("");
	Data=kGameStateAbility.GetUISummary_Ability(UnitState);

	AbilityTemplate=kGameStateAbility.GetMyTemplate();

	foreach AbilityTemplate.AbilityCosts(Cost)
	{
		if (Cost.IsA('X2AbilityCost_ActionPoints') && !X2AbilityCost_ActionPoints(Cost).bFreeCost)
		Data.ActionCost += X2AbilityCost_ActionPoints(Cost).GetPointCost(kGameStateAbility, UnitState);
	}

	
	if (UnitState==none)
		UnitState=XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kGameStateAbility.OwnerStateObject.ObjectID));

	if (UnitState==none) return Data;

	Data.CooldownTime = AbilityTemplate.AbilityCooldown.GetNumTurns(kGameStateAbility, UnitState, none, none);
	Data.bEndsTurn = AbilityTemplate.WillEndTurn(kGameStateAbility, UnitState); // Will End Turn
	Data.Icon=kGameStateAbility.GetMyIconImage();
	//if (Data.Name == "") Data.Name=string(AbilityTemplate.DataName);
	//Data.Description=string(AbilityTemplate.DataName) @ Data.Description;

	`TRACE_EXIT("Data.ActionCost:" @ Data.ActionCost $ ", Data.CooldownTime:" @ Data.CooldownTime);

	return Data;
}

/**
 * Recalculates layout when an item changes size or visibility.
 *
 * @param ItemModified   The item that triggered the update
 */
simulated function OnItemChanged(UIAbilityListItem ItemModified )
{
	local int i;//, iStartIndex; 
	local float currentYPosition; 
	local UIAbilityListItem Item;

	`TRACE_ENTRY("");

	//iStartIndex = Items.Find(Item); 
	currentYPosition = 0;// Items[iStartIndex].Y; 

	ClearScroll();
	for( i = 0; i < Items.Length; i++ )
	{
		Item = Items[i]; 
		if( !Item.bIsVisible )
			break;
		Item.SetY(currentYPosition);
		currentYPosition += Item.height; 
	}

	if( height != currentYPosition )
	{
		height = currentYPosition;
		StretchToFit();

		if( OnSizeRealized != none )
			OnSizeRealized();

		AnimateScroll(height, MaskHeight);
	}

	`TRACE_EXIT("height:" @ height $ ", MaskHeight:" @ MaskHeight);
}

/**
 * Adjusts the visible mask height based on MaxHeight constraints.
 *
 * Mr. Nice: If a max size is defined, this list will attempt to stretch or shrink. 
 */
simulated function StretchToFit()
{
	`TRACE_ENTRY("MaxHeight:" @ MaxHeight $ ", height:" @ height);
	if( MaxHeight == 0 ) return; 

	if( height < MaxHeight )
	{
		MaskHeight = height; 
	}
	else
	{
		MaskHeight = MaxHeight;
	}
	`TRACE_EXIT("MaskHeight:" @ MaskHeight);
}

defaultproperties
{
	MaxHeight=850;
}