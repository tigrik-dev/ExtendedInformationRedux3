/**
 * Tooltip class for displaying buffs, penalties, and passive effects
 * in the tactical HUD with hit chance integration.
 *
 * Extends the default buffs tooltip to:
 * - Support passive effect display
 * - Dynamically adjust layout and size
 * - Integrate custom effect lists with hit chance UI
 * - Control visibility and refresh timing for smoother UX
 *
 * @author tjnome / Mr.Nice / Sebkulu
 */
class UITacticalHUD_BuffsTooltip_HitChance extends UITacticalHUD_BuffsTooltip;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

var int TOOLTIP_ALPHA;

`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var bool bShowPassive;

var EPerkBuffCategory Category;

var bool bTop, ShowTip;

var int Weight, DeadHeight;

/**
 * Initializes the bonuses/penalties tooltip panel and its UI components.
 *
 * Configures:
 * - Background panel and transparency
 * - Header (icon + title)
 * - Effect list and mask
 * - Layout depending on tooltip type (bonus, penalty, passive)
 *
 * @param InitName Name of the panel
 * @param InitLibID Library identifier
 * @param bIsBonusPanel Whether this is a bonus panel (otherwise penalty)
 * @param bIsSoldier Whether this tooltip is for a soldier
 * @param InitX Initial X position
 * @param InitY Initial Y position
 * @param bShowOnRight Whether tooltip should appear on the right side
 * @return Initialized UIPanel instance
 */
simulated function UIPanel InitBonusesAndPenalties(optional name InitName, optional name InitLibID, optional bool bIsBonusPanel, optional bool bIsSoldier, optional float InitX = 0, optional float InitY = 0, optional bool bShowOnRight)
{
	`TRACE_ENTRY("");
	InitPanel(InitName, InitLibID);

	Hide();
	SetPosition(InitX, InitY);
	AnchorX = InitX; 
	AnchorY = InitY; 

	ShowOnRightSide = bShowOnRight;
	ShowBonusHeader = bIsBonusPanel;
	IsSoldierVersion = bIsSoldier;

	if (bShowPassive)
	{
		Category=ePerkBuff_Passive;
		Width=class'UITacticalHUD_AbilityTooltip'.default.width;
		bTop=true;
	}
	
	BGBox = Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	BGBox.SetWidth(width); // Height set in size callback


	Header = Spawn(class'UIPanel', self).InitPanel('HeaderArea').SetPosition(PADDING_LEFT,0);
	Header.SetHeight(headerHeight);

	if (!bShowPassive)
	{
		if (bIsBonusPanel)
		{
			Category=ePerkBuff_Bonus;
			HeaderIcon = Spawn(class'UIPanel', Header).InitPanel('BonusIcon', class'UIUtilities_Controls'.const.MC_BonusIcon).SetSize(20,20);
		}
		else
		{
			Category=ePerkBuff_Penalty;
			HeaderIcon = Spawn(class'UIPanel', Header).InitPanel('PenaltyIcon', class'UIUtilities_Controls'.const.MC_PenaltyIcon).SetSize(20,20);
		}
	}
	
	HeaderIcon.SetY(8);

	Title = Spawn(class'UIText', Header).InitText('Title');
	if (HeaderIcon == none) Title.SetPosition(0, 2); 
	else Title.SetPosition(10+HeaderIcon.Width, 2); 
	Title.SetWidth(width - PADDING_LEFT - HeaderIcon.width); 
	//Title.SetAlpha( class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_StatLabel).Alpha );
		
	// --------------------------------------------- 
	
	DeadHeight=PADDING_TOP+PADDING_BOTTOM+headerHeight;

	ItemList = Spawn(class'UIEffectList_HitChance', self);
	ItemList.InitEffectList('ItemList',
		, 
		PADDING_LEFT, 
		PADDING_TOP + headerHeight, 
		width-PADDING_LEFT-PADDING_RIGHT, 
		Height-DeadHeight,
		Height-DeadHeight,
		MaxHeight,
		OnEffectListSizeRealized);

	ItemListMask = Spawn(class'UIMask', self).InitMask('Mask', ItemList).FitMask(ItemList); 

	// --------------------------------------------- 
	//A delay is unnecessay when the 'hover' display is simulated by a button press
	if(!Movie.IsMouseActive())
	{
		tDelay = 0;
	}	

	BGBox.SetAlpha(getTOOLTIP_ALPHA()); // Setting transparency
	`TRACE_EXIT("");
	return self; 
}

/**
 * Displays the tooltip after refreshing its data.
 *
 * Mr.Nice: UITacticalHUD_BuffsTooltip shows before it Refreshes?! Other tooltips Refresh first, which makes sense to avoid possibly showing partial tooltip data for a frame or so.
 *
 * Ensures:
 * - Data is up-to-date before showing
 * - Tooltip visibility is controlled via ShowTip flag
 * - Handles grouped tooltips correctly
 */
simulated function ShowTooltip()
{
	`TRACE_ENTRY("");
	RefreshData();
	if (ShowTip) 
	{
		if ((TooltipGroup) == none) super(UIToolTip).ShowTooltip();
		else
		{
			bIsVisible=true;
			ClearTimer(nameof(Hide));
		}
	}
	`TRACE_EXIT("");
}


`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'ExtendedInformationRedux3_MCMScreen'.default.CONFIG_VERSION)

/**
 * Refreshes tooltip data based on the currently hovered unit or target.
 *
 * Determines:
 * - Active unit (player or enemy)
 * - Relevant effects based on category
 * - Updates UI list and header text
 *
 * Handles cases where:
 * - No unit is found
 * - No effects are available
 */
simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Unit	kGameStateUnit;
	local int					iTargetIndex; 
	local array<string>			Path; 
	local array<UISummary_UnitEffect> Effects; 

	`TRACE_ENTRY("");
	//Trigger on the correct hover item 
	if( XComTacticalController(PC) != None )
	{	
		if( IsSoldierVersion )
		{
			kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		}
		else
		{
			Path = SplitString( currentPath, "." );	

			if (Path.Length > 5)
			{
				iTargetIndex = int(Split( Path[5], "icon", true));
				kActiveUnit = XGUnit(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyAtIcon(iTargetIndex));
			}
		}
	}

	// Only update if new unit
	if( kActiveUnit == none )
	{
		if( XComTacticalController(PC) != None )
		{
			//HideTooltip(); Showtooltip refreshes data before showing now
			ShowTip=false;
			return; 
		}
	} 
	else if( kActiveUnit != none )
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}

	Effects = GetUnitEffectsByCategory(kGameStateUnit);

	switch (Category)
	{
		case ePerkBuff_Bonus:
			Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.BonusesHeader, eUITextStyle_Tooltip_StatLabel) );
			break;
		case ePerkBuff_Penalty:
			Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.PenaltiesHeader, eUITextStyle_Tooltip_StatLabel) );
			break;
		case ePerkBuff_Passive:
			Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'UITacticalCharInfoScreen'.default.Header_Passives, eUITextStyle_Tooltip_StatLabel) );
	}

	if( Effects.length == 0)
	{
		if( XComTacticalController(PC) != None )
		{
			ShowTip=false;
			return;
		}
		else
			ItemList.RefreshData( DEBUG_GetData() );
	}
	else
	{
		ItemList.RefreshData( Effects );
		ItemList.OnItemChanged(none);
	}

	ShowTip=true;
	//OnEffectListSizeRealized();
	`TRACE_EXIT("");
}

/**
 * Retrieves unit effects filtered by the current category.
 *
 * Includes:
 * - Active effects applied to the unit
 * - Effects applied by the unit (source effects)
 * - Special handling for rupture effect
 *
 * @param kGameStateUnit Unit to retrieve effects for
 * @return Array of UISummary_UnitEffect matching the category
 */
simulated function array<UISummary_UnitEffect> GetUnitEffectsByCategory(XComGameState_Unit kGameStateUnit)
{
	local UISummary_UnitEffect Item, EmptyItem;  
	local array<UISummary_UnitEffect> List; 
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;

	`TRACE_ENTRY("");
	History = `XCOMHISTORY;

	foreach kGameStateUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bDisplayInUI && Persist.BuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, kGameStateUnit))
			{
				Item = EmptyItem;
				FillUnitEffect(kGameStateUnit, EffectState, Persist, false, Item);
				if(Item.Name != "")
				List.AddItem(Item);
			}
		}
	}
	foreach kGameStateUnit.AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bSourceDisplayInUI && Persist.SourceBuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, kGameStateUnit))
			{
				Item = EmptyItem;
				FillUnitEffect(kGameStateUnit, EffectState, Persist, true, Item);
				if(Item.Name != "")
				List.AddItem(Item);
			}
		}
	}
	if (Category == ePerkBuff_Penalty)
	{
		if (kGameStateUnit.GetRupturedValue() > 0)
		{
			Item = EmptyItem;
			Item.AbilitySourceName = 'eAbilitySource_Standard';
			Item.Icon = class 'X2StatusEffects'.default.RuptureIcon;
			Item.Name = class'X2StatusEffects'.default.RupturedFriendlyName;
			Item.Description = class'X2StatusEffects'.default.RupturedFriendlyDesc;
			List.AddItem(Item);
		}
	}

	// Sebkulu - Removing empty name abilities after their creation...
	// oddly *not adding* them in the first place still creates an empty Item at the end of List array
	/*for(i = 0; i < List.Length; ++i)
	{
		if (List[i].Name == "" || List[i].Name == " ") List.Remove(--i, 1);
	}
	*/
	`TRACE_EXIT("");
	return List; 
	
}

/**
 * Populates a UISummary_UnitEffect structure with effect data.
 *
 * Handles:
 * - Source vs target effects
 * - Name, description, and icon assignment
 * - Cooldown calculation
 * - Localization expansion for descriptions
 *
 * @param kGameStateUnit Target unit
 * @param EffectState Effect game state
 * @param Persist Effect template
 * @param bSource Whether this is a source-applied effect
 * @param Summary Output summary structure
 */
simulated function FillUnitEffect(const XComGameState_Unit kGameStateUnit, const XComGameState_Effect EffectState, const X2Effect_Persistent Persist, const bool bSource, out UISummary_UnitEffect Summary)
{
	local X2AbilityTag AbilityTag;

	`TRACE_ENTRY("");
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = EffectState;

	if (bSource)
	{
		Summary.Name = Persist.SourceFriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.SourceFriendlyDescription);
		if (!(bShowPassive && Persist.bInfiniteDuration)) Summary.Description $= "\n" $ CooldownDescription(EffectState, Persist);
		//Summary.Description = `XEXPAND.ExpandString(Persist.SourceFriendlyDescription);
		Summary.Icon = Persist.SourceIconLabel;

		if (Persist.bInfiniteDuration)
			Summary.Cooldown = 0;
		else
			Summary.Cooldown = EffectState.iTurnsRemaining;

		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}
	else
	{
		Summary.Name = Persist.FriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.FriendlyDescription);
		if (!(bShowPassive && Persist.bInfiniteDuration)) Summary.Description $= "\n" $ CooldownDescription(EffectState, Persist);
		//Summary.Description = `XEXPAND.ExpandString(Persist.FriendlyDescription);
		Summary.Icon = Persist.IconImage;

		if (Persist.bInfiniteDuration) 
		{
			if (kGameStateUnit.StunnedActionPoints > 0)
				Summary.Cooldown = (class'X2CharacterTemplateManager'.default.StandardActionsPerTurn / kGameStateUnit.StunnedActionPoints);
			else if(kGameStateUnit.StunnedThisTurn > 0 && kGameStateUnit.StunnedActionPoints == 0)
				Summary.Cooldown = -1;
		}
		else
			Summary.Cooldown = EffectState.iTurnsRemaining;

		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}

	AbilityTag.ParseObj = None;
	`TRACE_EXIT("");
}

/**
 * Generates a textual description of an effect's cooldown behavior.
 *
 * Includes:
 * - Persistent effects
 * - Turn-based ticking rules
 * - Action-based expiration
 * - Team-based turn ending
 *
 * @param EffectState Effect game state
 * @param Persist Effect template
 * @return Human-readable cooldown description
 */
simulated function string CooldownDescription (const XComGameState_Effect EffectState, const X2Effect_Persistent Persist)
{
	local XComGameState_Player PlayerState;

	`TRACE_ENTRY("");
	// Adds information if the effect is Persistent of not
	if (Persist.bInfiniteDuration)
		return "Persistent effect";

	// Add information if the turn counter ticks on alien and players turn. 
	//Should probably 2x turns to get a real counter in this case
	if (Persist.bIgnorePlayerCheckOnTick)
		return "Effect ticks on alien and players turn";

	if (Persist.WatchRule == eGameRule_UseActionPoint)
		return "Effect removed after action";
	
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));
	`TRACE_EXIT("");
	return (WatchRule(Persist) @ GetTeam(PlayerState) @ "turn");
}

/**
 * Returns a string representing the team associated with the player state.
 * Get information if it ends on aliens or players turn.
 *
 * @param PlayerState Player game state
 * @return Team name string
 */
static final function string GetTeam(const XComGameState_Player PlayerState)
{
	`TRACE_ENTRY("");
	switch (PlayerState.GetTeam())
	{
		case eTeam_XCom:
			return "Player's";
			break;
		case eTeam_Alien:
			return "Aliens";
			break;
		case eTeam_Neutral:
			return "Civilians";
			break;
		default:
			return "Player's";
			break;
	}
}

/**
 * Converts the effect watch rule into a readable string.
 * Get information from WatchRule if the effects on on start/after action/after turn ended.
 *
 * Describes when an effect ends based on game rules.
 *
 * @param Persist Effect template
 * @return Watch rule description string
 */
static final function string WatchRule(const X2Effect_Persistent Persist)
{
	`TRACE_ENTRY("");
	switch (Persist.WatchRule)
	{
		case eGameRule_PlayerTurnBegin:
			return "Ends on the start of";
			break;
		case eGameRule_PlayerTurnEnd:
			return "Ends on the end of";
			break;
		default:
			return "Ends on the start of";
			break;
	}
}

/**
 * Sets the height of the tooltip and updates layout accordingly.
 *
 * Adjusts:
 * - Effect list mask height
 * - Scroll behavior
 * - Background panel size
 *
 * @param NewHeight New height value
 */
simulated function SetHeight(float NewHeight)
{
	`TRACE_ENTRY("");
	if (Height==NewHeight) return;
	Height=NewHeight;

	ItemList.MaskHeight=Height-DeadHeight;
	ItemList.ClearScroll();
	ItemList.AnimateScroll(ItemList.height, ItemList.MaskHeight);

	BGBox.SetHeight( Height );
	ItemListMask.SetHeight(ItemList.MaskHeight);
	`TRACE_EXIT("");
}

function int getTOOLTIP_ALPHA()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA, class'ExtendedInformationRedux3_MCMScreen'.default.TOOLTIP_ALPHA);
}

defaultproperties
{
	bShowPassive=false;
	bTop=false;
	Weight=1;
	PADDING_TOP=5;
	PADDING_BOTTOM=5;
	MaxHeight=850;	
}