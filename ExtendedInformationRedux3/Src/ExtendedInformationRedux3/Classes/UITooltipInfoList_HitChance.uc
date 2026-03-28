/**
 *	Description:
 *		Custom tooltip info list that extends weapon/tooltips UI to include
 *		additional weapon stat information (e.g. upgrade bonuses like +aim, +crit).
 *		Integrates with MCM settings to optionally display extended stats.
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITooltipInfoList_HitChance extends UITooltipInfoList;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var bool SHOW_EXTRA_WEAPONSTATS;

/**
 * Refreshes tooltip display with provided summary items.
 *
 * @param SummaryItems	Array of item stats to render in the tooltip.
 */
simulated function RefreshDisplay(array<UISummary_ItemStat> SummaryItems)
{
	local int i;
	local UIText LabelField, DescriptionField;

	`TRACE_ENTRY("SummaryItems.Length:" @ SummaryItems.Length);
	if (SummaryItems.Length == 0)
	{
		`TRACE("No SummaryItems, hiding tooltip");
		Hide();
		Height = 0;
		OnTextSizeRealized();
		return;
	}

	if (TitleTextField == none)
	{
		`TRACE("Creating TitleTextField");
		TitleTextField = Spawn(class'UIScrollingText', self).InitScrollingText('Title', "", width - PADDING_RIGHT - PADDING_LEFT, PADDING_LEFT);
	}
	TitleTextField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[0].Label, SummaryItems[0].LabelStyle));
	
	for (i = 1; i < SummaryItems.Length; i++)
	{
		`TRACE("Processing item index:" @ i);
		// Place new items if we need to. 
		if (i > LabelFields.Length)
		{
			LabelField = Spawn(class'UIText', self).InitText(Name("Label"$i));
			LabelField.SetWidth(Width - PADDING_LEFT - PADDING_RIGHT);
			LabelField.SetX(PADDING_LEFT);
			LabelFields.AddItem(LabelField);

			DescriptionField = Spawn(class'UIText', self).InitText(Name("Description"$i));
			DescriptionField.SetWidth(Width - PADDING_LEFT - PADDING_RIGHT);
			DescriptionField.SetX(PADDING_LEFT);
			DescriptionFields.AddItem(DescriptionField);
		}

		//Hijack to add stats changes.
		LabelField = LabelFields[i - 1];
		LabelField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[i].Label, SummaryItems[i].LabelStyle), OnChildTextRealized);
		LabelField.Show();
		LabelField.AnimateIn();

		DescriptionField = DescriptionFields[i - 1];
		`TRACE("Label:" @ SummaryItems[i].Label);
		`TRACE("Value:" @ SummaryItems[i].Value);
		DescriptionField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[i].Value $ GetExtraWeaponStats(SummaryItems[i].Label), SummaryItems[i].ValueStyle), OnChildTextRealized);
		DescriptionField.Show();
		DescriptionField.AnimateIn();
	}

	// Hide any excess list items if we didn't use them. 
	for (i = SummaryItems.Length; i < LabelFields.Length; i++)
	{
		`TRACE("Hiding unused field index:" @ i);
		LabelFields[i].Hide();
		DescriptionFields[i].Hide();
	}

	OnChildTextRealized();
	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Returns extra weapon stat string for a given label if applicable.
 *
 * @param label	The stat label to check against weapon upgrades.
 * @return		Formatted bonus string (e.g. ": +10%") or empty string.
 */
function string GetExtraWeaponStats(string label)
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local XComGameState_Item kPrimaryWeapon;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local string str;

	`TRACE_ENTRY("label:" @ label);
	if (getSHOW_EXTRA_WEAPONSTATS())
	{
		kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
		kPrimaryWeapon = kGameStateUnit.GetPrimaryWeapon();
		UpgradeTemplates = kPrimaryWeapon.GetMyWeaponUpgradeTemplates();

		foreach UpgradeTemplates(UpgradeTemplate)
		{
			if (UpgradeTemplate.GetItemFriendlyName() == label)
			{
				str=": +" $ UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
				if( UpgradeTemplate.AddHitChanceModifierFn != none
					|| UpgradeTemplate.AddCritChanceModifierFn != None
					|| UpgradeTemplate.FreeFireCostFn !=none
					|| UpgradeTemplate.FreeKillFn !=none )
					str $= "%";
				return str;
			}
		}
	}
	`TRACE_EXIT("");
	return "";
}

function bool getSHOW_EXTRA_WEAPONSTATS()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_EXTRA_WEAPONSTATS, class'ExtendedInformationRedux3_MCMScreen'.default.SHOW_EXTRA_WEAPONSTATS);
}

/*defaultproperties
{
	SHOW_EXTRA_WEAPONSTATS=true;
}*/