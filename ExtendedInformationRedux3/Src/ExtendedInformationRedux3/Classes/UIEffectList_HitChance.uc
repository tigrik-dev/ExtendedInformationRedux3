/**
 * UIEffectList_HitChance
 *
 * Custom UI list component for displaying unit effects with hit chance integration.
 *
 * Responsibilities:
 * - Dynamically create and manage effect list items
 * - Update UI elements based on incoming effect data
 * - Hide unused UI elements to maintain clean presentation
 *
 * @author Mr.Nice / Sebkulu
 */
class UIEffectList_HitChance extends UIEffectList;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Refreshes the effect list UI with new effect data.
 *
 * @param Data   Array of unit effects to display
 */
simulated function RefreshDisplay(array<UISummary_UnitEffect> Data)
{
	local UIEffectListItem Item; 
	local int i; 

	`TRACE_ENTRY("Data.Length:" @ Data.Length);
	//Test

	for( i = 0; i < Data.Length; i++ )
	{
		
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UIEffectListItem_HitChance', self).InitEffectListItem(self);
			Item.ID = i; 
			Items.AddItem(Item);
		}
		
		// Grab our target Item
		Item = Items[i]; 

		//Update Data 
		Item.Data = Data[i]; 

		Item.Show();
	}

	// Hide any excess list items if we didn't use them. 
	for( i = Data.Length; i < Items.Length; i++ )
	{
		Items[i].Hide();
	}
	`TRACE_EXIT("Items.Length:" @ Items.Length);
}

