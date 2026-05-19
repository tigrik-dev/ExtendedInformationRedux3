/**
 * Mod Configuration Menu (MCM) screen implementation for ExtendedInformationRedux3.
 *
 * Handles registration, rendering, and persistence of all configurable settings
 * related to hit chance display, shot HUD behavior, tooltip customization, and
 * visual styling. Integrates with the MCM API to expose user-adjustable options
 * and applies them at runtime.
 *
 * @author Mr.Nice / Sebkulu
 */
class ExtendedInformationRedux3_MCMScreen extends Object config(ExtendedInformationRedux3);

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_Includes.uci)
`include(ExtendedInformationRedux3\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var config int				CONFIG_VERSION;

var config bool				TH_AIM_ASSIST;
var config bool				TH_UNSAFE_AIM_ASSIST;
var config bool				HIT_CHANCE_ENABLED;
var config bool				EXPECTED_DAMAGE;
var config bool				VERBOSE_TEXT;
var config bool				DISPLAY_MISS_CHANCE;
var config bool				SHOW_TEMPLAR_MSG;
//var config float			FLYOVER_DURATION;
var config bool				SHOW_GUARANTEED_HIT;

//var config int				BAR_HEIGHT, BAR_OFFSET_X, BAR_WIDTH_MULT, GENERAL_OFFSET_Y;
//var config int				DODGE_OFFSET_X, DODGE_OFFSET_Y, CRIT_OFFSET_X, CRIT_OFFSET_Y;
var config int				BAR_ALPHA, BAR_HEIGHT, BAR_OFFSET_Y;
var config string			HIT_HEX_COLOR, CRIT_HEX_COLOR, DODGE_HEX_COLOR, MISS_HEX_COLOR, ASSIST_HEX_COLOR;
var config int				SHOTHUD_LAYOUT_LEFT_1;
var config int				SHOTHUD_LAYOUT_LEFT_2;
var config int				SHOTHUD_LAYOUT_RIGHT_1;
var config int				SHOTHUD_LAYOUT_RIGHT_2;
var config int				SHOTHUD_LEFT_1_OFFSET_X;
var config int				SHOTHUD_LEFT_2_OFFSET_X;
var config int				SHOTHUD_RIGHT_1_OFFSET_X;
var config int				SHOTHUD_RIGHT_2_OFFSET_X;

var config bool				TH_SHOW_GRAZED;
var config bool				TH_SHOW_CRIT_DMG;
var config bool				TH_AIM_LEFT_OF_CRIT;
var config bool				TH_ASSIST_BESIDE_HIT;
var config bool				TH_PREVIEW_MINIMUM;
var config bool				TH_PREVIEW_HACKING;
var config bool				TH_ASSIST_BAR;

var config bool				HIDE_STAT_CONTEST;
var config bool				PREVIEW_APPLY_CHANCE;
var config bool				SHOW_APPLY_CHANCE_MISS;
var config bool				SHOW_APPLY_CHANCE_GUARANTEED;

//var config bool				SHOW_ALWAYS_SHOT_BREAKDOWN_HUD;

var config int				TOOLTIP_ALPHA;
var config bool				ES_TOOLTIP;
var config bool				SHOW_EXTRA_WEAPONSTATS;

var config int		C_DMG_MODE;

var config int		SHOTHUD_SLOT_WIDTH;
var config int		DAMAGE_LABEL_WIDTH;

var config int		SHOTHUD_COLOR_DAMAGE;
var config int		SHOTHUD_COLOR_BONUS_DAMAGE;
var config int		SHOTHUD_COLOR_GRAZE;
var config int		SHOTHUD_COLOR_CRIT;
var config int		SHOTHUD_COLOR_EXPECTED;
var config int		SHOTHUD_COLOR_KILL_CHANCE;

var config int		STATUS_COLOR_1;
var config int		STATUS_COLOR_2;
var config int		STATUS_COLOR_3;
var config int		STATUS_COLOR_MISS;

var config int		HACK_COLOR_FAIL;
var config int		HACK_COLOR_REWARD;

var config bool		FLYOVER_SHOW_CRIT_0;
var config bool		FLYOVER_SHOW_GRAZE_0;

`MCM_API_AutoCheckBoxVars(SHOW_MITIGATION);

var localized string			sBlack;
var localized string			sWhite;
var localized string			sCyan;
var localized string			sFadedCyan;
var localized string			sFadedYellow;
var localized string			sGray;
var localized string			sGreen;
var localized string			sRed;
var localized string			sYellow;
var localized string			sPerkYellow;
var localized string			sCashGreen;
var localized string			sPurple;
var localized string			sOrange;
var localized string			sOrangeEngineering;
var localized string			sBlueScience;
var localized string			sObjIconBackground;

var array<string>				ColorArray;
var array<string>				UIStateColorArray;

var array<string>				SlotOptions;
var localized string			SlotOptions_0, SlotOptions_1, SlotOptions_2, SlotOptions_3, SlotOptions_4;

var localized string			sSettingsPage_MCMText;
var localized string			sPageTitle_MCMText;
var localized string			sGroupGeneralSettings_MCMText;
var localized string			sGroupFlyoverSettings_MCMText;
var localized string			sShowHitChance_MCMText;
var localized string			sVerboseText_MCMText;
var localized string			sDisplayMissChance_MCMText;
var localized string			sShowTemplarMessages_MCMText;
var localized string			sShowTemplarMessages_MCMTip;
var localized string			sShowAimAssist_MCMText;
var localized string			sShowAimAssist_ifUnsafe_MCMText;
var localized string			sShowAimAssist_ifUnsafe_MCMTooltip;
var localized string			sShowUnsafeAimAssist_MCMText;
var localized string			sShowUnsafeAimAssist_MCMTooltip;
var localized string			sShowUnsafeAimAssist_ifSafe_MCMTooltip;
							
//var localized string			sFlyoverDuration_MCMText;
var localized string			sShowGuaranteedHit_MCMText;

var localized string			sGroupShotBar_MCMText;
var localized string			sBarHeight_MCMText;
//var localized string			sBarOffsetX_MCMText;
var localized string			sBarOffsetY_MCMText;
var localized string			sBarAlpha_MCMText;
var localized string			sAssistBar_MCMText;
/*var localized string			sBarWidthMult_MCMText;
var localized string			sGeneralOffsetY_MCMText;
var localized string			sDodgeOffsetX_MCMText;
var localized string			sCritOFfsetX_MCMText;
var localized string			sCritOffsetY_MCMText;*/
var localized string			sHitHexColor_MCMText;
var localized string			sCritHexColor_MCMText;
var localized string			sDodgeHexColor_MCMText;
var localized string			sMissHexColor_MCMText;
var localized string			sGroupShotHUD_MCMText;
var localized string			sGroupBarColors_MCMText;
var localized string			sShowGrazed_MCMText;
var localized string			sShowCrit_MCMText;
var localized string			sAimLeftOfCrit_MCMText;
var localized string			sAssistBesideHit_MCMText;
var localized string			sPreviewMinimum_MCMText;
var localized string			sPreviewHacking_MCMText;
var localized string			sWarningMessage_MCMText;
var localized string			sAssistHexColor_MCMText;
var localized string			sShotHudDisplayLayout_MCMText;
var localized string			sLeftSide1_MCMText;
var localized string			sLeftSide2_MCMText;
var localized string			sRightSide1_MCMText;
var localized string			sRightSide2_MCMText;
var localized string			sLeftSide1Offset_MCMText;
var localized string			sLeftSide2Offset_MCMText;
var localized string			sRightSide1Offset_MCMText;
var localized string			sRightSide2Offset_MCMText;

//var localized string			sShowAlwaysShotBreakdownHUD_MCMText;
var localized string			sShowAssistAimBreakdownHUD_MCMText;
//var localized string			sGroupShotWings_MCMText;

var localized string			sToolTipAlpha_MCMText;
var localized string			sGroupToolTips_MCMTtext;
var localized string			sShowEnemyToolTip_MCMText;
var localized string			sShowExtraWeaponStats_MCMText;
var localized string			sExpectedDamage_MCMText;
var localized string			sExpectedDamage_MCMTooltip;

var localized string			sPreviewStatusEffects_MCMText;
var localized string			sPreviewStatContest_MCMText;
var localized string			sPreviewApplyChance_MCMText;
var localized string			sPreviewApplyChanceMiss_MCMText;
var localized string			sPreviewApplyChanceGuaranteed_MCMText;

var localized string			sCdmgMode_MCMText;
var array<string>				sCdmgModeTexts;
var localized string			sCdmgModeTexts_0, sCdmgModeTexts_1, sCdmgModeTexts_2, sCdmgModeTexts_3;

var localized string			sSlotWidth_MCMText;
var localized string			sDamageLabelWidth_MCMText;

var localized string			sShotHudColorSettings_MCMText;
var localized string			sShotHudDamageColor_MCMText;
var localized string			sShotHudDamageBonusColor_MCMText;

var localized string			sStatusEffectColorSettings_MCMText;
var localized string			sStatusEffect;
var localized string			sMissChanceColor_MCMText;

var localized string			sHackPreviewColorSettings_MCMText;
var localized string			sHackPreviewFailure_MCMText;
var localized string			sHackPreviewReward_MCMText;

var localized string			sFlyoverShowCrit0_MCMText;
var localized string			sFlyoverShowGraze0_MCMText;

var MCM_API_Checkbox			ShowHitChance_MCMUI;
var MCM_API_Checkbox			VerboseText_MCMUI;
var MCM_API_Checkbox			DisplayMissChance_MCMUI;
var MCM_API_Checkbox			ShowTemplarMessages_MCMUI;
var MCM_API_Checkbox			ShowAimAssist_MCMUI;
var MCM_API_Checkbox			ShowUnsafeAimAssist_MCMUI;
//var MCM_API_Slider				FlyoverDuration_MCMUI;
var MCM_API_Checkbox			ShowGuaranteedHit_MCMUI;

var MCM_API_Checkbox			ShowGrazed_MCMUI;
var MCM_API_Checkbox			ShowCrit_MCMUI;
var MCM_API_Checkbox			AimLeftOfCrit_MCMUI;
var MCM_API_Checkbox			AssistBesideHit_MCMUI;
var MCM_API_Checkbox			PreviewMinimum_MCMUI;
var MCM_API_Checkbox			PreviewHacking_MCMUI;
var MCM_API_Checkbox			AssistBar_MCMUI;
var MCM_API_Checkbox			ExpectedDamage_MCMUI;

var MCM_API_Slider			BarHeight_MCMUI;
//var MCM_API_Slider			BarOffsetX_MCMUI;
var MCM_API_Slider			BarOffsetY_MCMUI;
var MCM_API_Slider			BarAlpha_MCMUI;

var MCM_API_Dropdown			LeftSide1_MCMUI;
var MCM_API_Dropdown			LeftSide2_MCMUI;
var MCM_API_Dropdown			RightSide1_MCMUI;
var MCM_API_Dropdown			RightSide2_MCMUI;

var MCM_API_Slider				LeftSide1OffsetX_MCMUI;
var MCM_API_Slider				LeftSide2OffsetX_MCMUI;
var MCM_API_Slider				RightSide1OffsetX_MCMUI;
var MCM_API_Slider				RightSide2OffsetX_MCMUI;

var MCM_API_Dropdown			HitHexColor_MCMUI;
var MCM_API_Dropdown			CritHexColor_MCMUI;
var MCM_API_Dropdown			DodgeHexColor_MCMUI;
var MCM_API_Dropdown			MissHexColor_MCMUI;
var MCM_API_Dropdown			AssistHexColor_MCMUI;

//var MCM_API_Checkbox			ShowAlwaysShotBreakdownHUD_MCMUI;

var MCM_API_Slider				ToolTipAlpha_MCMUI;
var MCM_API_Checkbox			ShowEnemyToolTip_MCMUI;
var MCM_API_Checkbox			ShowExtraWeaponStats_MCMUI;

var MCM_API_Checkbox			HIDE_STAT_CONTEST_MCMUI;
var MCM_API_Checkbox			PREVIEW_APPLY_CHANCE_MCMUI;
var MCM_API_Checkbox			SHOW_APPLY_CHANCE_MISS_MCMUI;
var MCM_API_Checkbox			SHOW_APPLY_CHANCE_GUARANTEED_MCMUI;

var MCM_API_Dropdown			C_DMG_MODE_MCMUI;

var MCM_API_Slider				SHOTHUD_SLOT_WIDTH_MCMUI;
var MCM_API_Slider				DAMAGE_LABEL_WIDTH_MCMUI;

var MCM_API_Dropdown			SHOTHUD_COLOR_DAMAGE_MCMUI;
var MCM_API_Dropdown			SHOTHUD_COLOR_BONUS_DAMAGE_MCMUI;
var MCM_API_Dropdown			SHOTHUD_COLOR_GRAZE_MCMUI;
var MCM_API_Dropdown			SHOTHUD_COLOR_CRIT_MCMUI;
var MCM_API_Dropdown			SHOTHUD_COLOR_EXPECTED_MCMUI;
var MCM_API_Dropdown			SHOTHUD_COLOR_KILL_CHANCE_MCMUI;

var MCM_API_Dropdown			STATUS_COLOR_1_MCMUI;
var MCM_API_Dropdown			STATUS_COLOR_2_MCMUI;
var MCM_API_Dropdown			STATUS_COLOR_3_MCMUI;
var MCM_API_Dropdown			STATUS_COLOR_MISS_MCMUI;

var MCM_API_Dropdown			HACK_COLOR_FAIL_MCMUI;
var MCM_API_Dropdown			HACK_COLOR_REWARD_MCMUI;

var MCM_API_Checkbox			FLYOVER_SHOW_CRIT_0_MCMUI;
var MCM_API_Checkbox			FLYOVER_SHOW_GRAZE_0_MCMUI;

var string	HIT_HEX_COLOR_MCM, CRIT_HEX_COLOR_MCM, DODGE_HEX_COLOR_MCM, MISS_HEX_COLOR_MCM, ASSIST_HEX_COLOR_MCM;


//DEBUG
/*var config float				DODGE_OFFSET_Y;
var localized string			sDodgeOffsetY_MCMText;
var MCM_API_Slider			DodgeOffsetY_MCMUI;
`MCM_API_BasicSliderSaveHandler(DodgeOffsetYHandler,		DODGE_OFFSET_Y)*/
//DEBUG

/**
 * Initializes the MCM screen and registers it with the MCM API.
 *
 * @param Screen The UI screen instance being initialized.
 */
event OnInit(UIScreen Screen)
{
	`TRACE_ENTRY("");
	// Everything in here runs only when you need to touch MCM.
	`MCM_API_Register(Screen, ClientModCallback);
	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION,CONFIG_VERSION)

`MCM_API_BasicCheckboxSaveHandler(VerboseTextHandler, VERBOSE_TEXT)
`MCM_API_BasicCheckboxSaveHandler(DisplayMissChanceHandler, DISPLAY_MISS_CHANCE)
`MCM_API_BasicCheckboxSaveHandler(ShowTemplarMessagesHandler, SHOW_TEMPLAR_MSG)
`MCM_API_BasicCheckboxSaveHandler(ShowAimAssistHandler, TH_AIM_ASSIST)
`MCM_API_BasicCheckboxSaveHandler(ShowUnsafeAimAssistHandler, TH_UNSAFE_AIM_ASSIST)
`MCM_API_BasicCheckboxSaveHandler(ExpectedDamageHandler, EXPECTED_DAMAGE)
//`MCM_API_BasicSliderSaveHandler(FlyoverDurationHandler,		FLYOVER_DURATION)
`MCM_API_BasicCheckboxSaveHandler(ShowGuaranteedHitHandler, SHOW_GUARANTEED_HIT)

`MCM_API_BasicCheckboxSaveHandler(ShowGrazedHandler,			TH_SHOW_GRAZED)
`MCM_API_BasicCheckboxSaveHandler(ShowCritHandler,			TH_SHOW_CRIT_DMG)
`MCM_API_BasicCheckboxSaveHandler(AimLeftOfCritHandler,		TH_AIM_LEFT_OF_CRIT)
`MCM_API_BasicCheckboxSaveHandler(AssistBesideHitHandler,		TH_ASSIST_BESIDE_HIT)
`MCM_API_BasicCheckboxSaveHandler(AssistBarHandler,			TH_ASSIST_BAR)
`MCM_API_BasicCheckboxSaveHandler(PreviewMinimumHandler,		TH_PREVIEW_MINIMUM)
`MCM_API_BasicCheckboxSaveHandler(PreviewHackingHandler,		TH_PREVIEW_HACKING)

`MCM_API_BasicSliderSaveHandler(BarHeightHandler,		BAR_HEIGHT)
//`MCM_API_BasicSliderSaveHandler(BarOffsetXHandler,		BAR_OFFSET_X)
`MCM_API_BasicSliderSaveHandler(BarOffsetYHandler,		BAR_OFFSET_Y)
`MCM_API_BasicSliderSaveHandler(BarAlphaHandler,			BAR_ALPHA)

`MCM_API_BasicIndexSaveHandler(SlotLayoutHandler0,	SHOTHUD_LAYOUT_LEFT_1, SlotOptions)
`MCM_API_BasicIndexSaveHandler(SlotLayoutHandler1,	SHOTHUD_LAYOUT_LEFT_2, SlotOptions)
`MCM_API_BasicIndexSaveHandler(SlotLayoutHandler2,	SHOTHUD_LAYOUT_RIGHT_1, SlotOptions)
`MCM_API_BasicIndexSaveHandler(SlotLayoutHandler3,	SHOTHUD_LAYOUT_RIGHT_2, SlotOptions)

`MCM_API_BasicSliderSaveHandler(Left1OffsetHandler,	SHOTHUD_LEFT_1_OFFSET_X)
`MCM_API_BasicSliderSaveHandler(Left2OffsetHandler, SHOTHUD_LEFT_2_OFFSET_X)
`MCM_API_BasicSliderSaveHandler(Right1OffsetHandler, SHOTHUD_RIGHT_1_OFFSET_X)
`MCM_API_BasicSliderSaveHandler(Right2OffsetHandler, SHOTHUD_RIGHT_2_OFFSET_X)

`MCM_API_BasicDropdownSaveHandler(HitHexColorHandler,	HIT_HEX_COLOR_MCM)
`MCM_API_BasicDropdownSaveHandler(CritHexColorHandler,	CRIT_HEX_COLOR_MCM)
`MCM_API_BasicDropdownSaveHandler(DodgeHexColorHandler,	DODGE_HEX_COLOR_MCM)
`MCM_API_BasicDropdownSaveHandler(MissHexColorHandler,	MISS_HEX_COLOR_MCM)
//`MCM_API_BasicCheckboxSaveHandler(ThAssistBarHandler,		TH_ASSIST_BAR)
`MCM_API_BasicDropdownSaveHandler(AssistHexColorHandler,	ASSIST_HEX_COLOR_MCM)

//`MCM_API_BasicCheckboxSaveHandler(ShotBreakdownHUDHandler, SHOW_ALWAYS_SHOT_BREAKDOWN_HUD)

`MCM_API_BasicSliderSaveHandler(ToolTipAlphaHandler,		TOOLTIP_ALPHA)
`MCM_API_BasicCheckboxSaveHandler(ShowEnemyToolTipHandler,		ES_TOOLTIP)
`MCM_API_BasicCheckboxSaveHandler(ShowExtraWeaponStatsHandler,		SHOW_EXTRA_WEAPONSTATS)

`MCM_API_BasicCheckboxSaveHandler(PreviewStatContestHandler, HIDE_STAT_CONTEST)
`MCM_API_BasicCheckboxSaveHandler(PreviewApplyChanceHandler, PREVIEW_APPLY_CHANCE)
`MCM_API_BasicCheckboxSaveHandler(ShowApplyChanceMissHandler, SHOW_APPLY_CHANCE_MISS)
`MCM_API_BasicCheckboxSaveHandler(ShowApplyChanceGuaranteedHandler, SHOW_APPLY_CHANCE_GUARANTEED)

`MCM_API_BasicIndexSaveHandler(C_DMG_MODE_HANDLER, C_DMG_MODE, sCdmgModeTexts)

`MCM_API_BasicSliderSaveHandler(SHOTHUD_SLOT_WIDTH_HANDLER, SHOTHUD_SLOT_WIDTH)
`MCM_API_BasicSliderSaveHandler(DAMAGE_LABEL_WIDTH_HANDLER, DAMAGE_LABEL_WIDTH)

`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_DAMAGE_HANDLER, SHOTHUD_COLOR_DAMAGE, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_BONUS_DAMAGE_HANDLER, SHOTHUD_COLOR_BONUS_DAMAGE, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_GRAZE_HANDLER, SHOTHUD_COLOR_GRAZE, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_CRIT_HANDLER, SHOTHUD_COLOR_CRIT, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_EXPECTED_HANDLER, SHOTHUD_COLOR_EXPECTED, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(SHOTHUD_COLOR_KILL_CHANCE_HANDLER, SHOTHUD_COLOR_KILL_CHANCE, UIStateColorArray)

`MCM_API_BasicIndexSaveHandler(STATUS_COLOR_1_HANDLER, STATUS_COLOR_1, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(STATUS_COLOR_2_HANDLER, STATUS_COLOR_2, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(STATUS_COLOR_3_HANDLER, STATUS_COLOR_3, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(STATUS_COLOR_MISS_HANDLER, STATUS_COLOR_MISS, UIStateColorArray)

`MCM_API_BasicIndexSaveHandler(HACK_COLOR_FAIL_HANDLER, HACK_COLOR_FAIL, UIStateColorArray)
`MCM_API_BasicIndexSaveHandler(HACK_COLOR_REWARD_HANDLER, HACK_COLOR_REWARD, UIStateColorArray)

`MCM_API_BasicCheckboxSaveHandler(FLYOVER_SHOW_CRIT_0_HANDLER, FLYOVER_SHOW_CRIT_0)
`MCM_API_BasicCheckboxSaveHandler(FLYOVER_SHOW_GRAZE_0_HANDLER, FLYOVER_SHOW_GRAZE_0)

`MCM_API_AutoCheckBoxSaveHandler(SHOW_MITIGATION);

/**
 * Handles checkbox value changes and updates dependent UI elements and config values.
 *
 * @param _Setting The setting that triggered the change.
 * @param _SettingValue The new value of the setting.
 */
simulated function CheckBoxChangeHandler(MCM_API_Setting _Setting, bool _SettingValue)
{
	local name	SettingName;
	`TRACE_ENTRY("_SettingValue:" @ _SettingValue);
	SettingName = _Setting.GetName();
	switch (SettingName)
	{
		case 'ShowHitChance'		:
			VerboseText_MCMUI.SetEditable(_SettingValue);
			ShowTemplarMessages_MCMUI.SetEditable(_SettingValue);
			//FlyoverDuration_MCMUI.SetEditable(_SettingValue);
			ShowGuaranteedHit_MCMUI.SetEditable(_SettingValue);
			HIT_CHANCE_ENABLED = _SettingValue;
			break;
		case	 'ShowAimAssist'	:
			AssistBesideHit_MCMUI.SetEditable(_SettingValue);
			AssistHexColor_MCMUI.SetEditable(_SettingValue);
			AssistBar_MCMUI.SetEditable(_SettingValue);
			TH_AIM_ASSIST = _SettingValue;
			break;
		case 'ShowUnsafeAimAssist'	:
			TH_UNSAFE_AIM_ASSIST = _SettingValue;
			break;
		case 'ExpectedDamage'		:
			EXPECTED_DAMAGE = _SettingValue;
			break;
		default						: assert(false);
	}
	`TRACE_EXIT("");
}

/**
 * Builds and initializes the MCM configuration UI, including all groups and controls.
 *
 * @param ConfigAPI The MCM API instance used to construct the UI.
 * @param GameMode The current game mode.
 */
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	// Code goes here.
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group0;
	local MCM_API_SettingsGroup Group1;
	local MCM_API_SettingsGroup Group2;
	local MCM_API_SettingsGroup Group2Point2;
	local MCM_API_SettingsGroup Group2Point5;
	local MCM_API_SettingsGroup Group3;
	local MCM_API_SettingsGroup Group4;
	local MCM_API_SettingsGroup Group5;
	local MCM_API_SettingsGroup Group5_1;
	local MCM_API_SettingsGroup Group5_2;
	local MCM_API_SettingsGroup Group6;
	local bool IsAimAssistUnsafe;

	`TRACE_ENTRY("GameMode:" @ GameMode);

	InitializeSlotOptions();
	InitializeCdmgModeTexts();

	// Tigrik: IsAimAssistUnsafe: May Aim Assist cause bugs when enabled?
	IsAimAssistUnsafe = class'AimAssistLib'.static.IsAimAssistUnsafe();

	ColorArray.AddItem(sBlack);
	ColorArray.AddItem(sWhite);
	ColorArray.AddItem(sCyan);
	ColorArray.AddItem(sFadedCyan);
	ColorArray.AddItem(sFadedYellow);
	ColorArray.AddItem(sGray);
	ColorArray.AddItem(sGreen);
	ColorArray.AddItem(sRed);
	ColorArray.AddItem(sYellow);
	ColorArray.AddItem(sPerkYellow);
	ColorArray.AddItem(sCashGreen);
	ColorArray.AddItem(sPurple);
	ColorArray.AddItem(sOrange);
	ColorArray.AddItem(sOrangeEngineering);
	ColorArray.AddItem(sBlueScience);
	ColorArray.AddItem(sObjIconBackground);

	UIStateColorArray.AddItem(sGreen);
	UIStateColorArray.AddItem(sRed);
	UIStateColorArray.AddItem(sYellow);
	UIStateColorArray.AddItem(sOrange);
	UIStateColorArray.AddItem(sPurple);
	UIStateColorArray.AddItem(sCyan);
	UIStateColorArray.AddItem(sCashGreen);
	UIStateColorArray.AddItem(sFadedYellow);
	UIStateColorArray.AddItem(sFadedCyan);
	UIStateColorArray.AddItem(sGray);

	LoadSavedSettings();

	Page = ConfigAPI.NewSettingsPage(sSettingsPage_MCMText);
	Page.SetPageTitle(sPageTitle_MCMText @ class'EIR_Version'.static.GetVersionStringWithPrefix());
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group0 = Page.AddGroup('Group0', sGroupGeneralSettings_MCMText);

	// Tigrik: If enabling Aim Assist may cause bugs, then display a warning and an explanation in the tooltip
	ShowAimAssist_MCMUI				= Group0.AddCheckbox('ShowAimAssist', IsAimAssistUnsafe ? sShowAimAssist_ifUnsafe_MCMText : sShowAimAssist_MCMText, IsAimAssistUnsafe ? sShowAimAssist_ifUnsafe_MCMTooltip : sShowAimAssist_MCMText, TH_AIM_ASSIST, , CheckBoxChangeHandler);
	ShowUnsafeAimAssist_MCMUI		= Group0.AddCheckbox('ShowUnsafeAimAssist', sShowUnsafeAimAssist_MCMText, IsAimAssistUnsafe ? sShowUnsafeAimAssist_MCMTooltip : sShowUnsafeAimAssist_ifSafe_MCMTooltip, TH_UNSAFE_AIM_ASSIST, , CheckBoxChangeHandler);
	
	DisplayMissChance_MCMUI			= Group0.AddCheckbox('DisplayMissChance', sDisplayMissChance_MCMText, sDisplayMissChance_MCMText, DISPLAY_MISS_CHANCE, DisplayMissChanceHandler, );
	ExpectedDamage_MCMUI			= Group0.AddCheckbox('ExpectedDamage', sExpectedDamage_MCMText, sExpectedDamage_MCMTooltip, EXPECTED_DAMAGE, , CheckBoxChangeHandler);
	`MCM_API_AutoAddCheckBox(Group0, SHOW_MITIGATION, none);
	Group0.AddLabel('empty_line',"","");
	
	Group1 = Page.AddGroup('Group1', sGroupFlyoverSettings_MCMText);
	ShowHitChance_MCMUI				= Group1.AddCheckbox('ShowHitChance', sShowHitChance_MCMText, sShowHitChance_MCMText, HIT_CHANCE_ENABLED, , CheckBoxChangeHandler);
	VerboseText_MCMUI				= Group1.AddCheckbox('VerboseText', sVerboseText_MCMText, sVerboseText_MCMText, VERBOSE_TEXT, VerboseTextHandler, );
	ShowTemplarMessages_MCMUI		= Group1.AddCheckbox('ShowTemplarMessages', sShowTemplarMessages_MCMText, sShowTemplarMessages_MCMTip, SHOW_TEMPLAR_MSG, ShowTemplarMessagesHandler, );
	//FlyoverDuration_MCMUI			= Group1.AddSlider('FlyoverDuration', sFlyoverDuration_MCMText, sFlyoverDuration_MCMText, 1, 25, 1, FLYOVER_DURATION, FlyoverDurationHandler, );
	ShowGuaranteedHit_MCMUI			= Group1.AddCheckbox('ShowGuaranteedHit', sShowGuaranteedHit_MCMText, sShowGuaranteedHit_MCMText, SHOW_GUARANTEED_HIT, ShowGuaranteedHitHandler, );
	VerboseText_MCMUI.SetEditable(HIT_CHANCE_ENABLED);
	ShowTemplarMessages_MCMUI.SetEditable(HIT_CHANCE_ENABLED);
	//FlyoverDuration_MCMUI.SetEditable(HIT_CHANCE_ENABLED);
	ShowGuaranteedHit_MCMUI.SetEditable(HIT_CHANCE_ENABLED);
	FLYOVER_SHOW_CRIT_0_MCMUI		= Group1.AddCheckbox('FLYOVER_SHOW_CRIT_0', sFlyoverShowCrit0_MCMText, sFlyoverShowCrit0_MCMText, FLYOVER_SHOW_CRIT_0, FLYOVER_SHOW_CRIT_0_HANDLER, );
	FLYOVER_SHOW_GRAZE_0_MCMUI		= Group1.AddCheckbox('FLYOVER_SHOW_GRAZE_0', sFlyoverShowGraze0_MCMText, sFlyoverShowGraze0_MCMText, FLYOVER_SHOW_GRAZE_0, FLYOVER_SHOW_GRAZE_0_HANDLER, );
	Group1.AddLabel('empty_line',"","");

	Group2 = Page.AddGroup('Group2', sGroupShotHUD_MCMText);
	ShowGrazed_MCMUI					= Group2.AddCheckbox('ShowGrazed', sShowGrazed_MCMText, sShowGrazed_MCMText, TH_SHOW_GRAZED, ShowGrazedHandler, );
	ShowCrit_MCMUI						= Group2.AddCheckbox('ShowCrit', sShowCrit_MCMText, sShowCrit_MCMText, TH_SHOW_CRIT_DMG, ShowCritHandler, );
	PreviewMinimum_MCMUI				= Group2.AddCheckbox('PreviewMinimum', sPreviewMinimum_MCMText, sPreviewMinimum_MCMText, TH_PREVIEW_MINIMUM, PreviewMinimumHandler, );
	PreviewHacking_MCMUI				= Group2.AddCheckbox('PreviewHacking', sPreviewHacking_MCMText, sPreviewHacking_MCMText, TH_PREVIEW_HACKING, PreviewHackingHandler, );
	C_DMG_MODE_MCMUI					= Group2.AddDropdown('C_DMG_MODE', sCdmgMode_MCMText, sCdmgMode_MCMText, sCdmgModeTexts, sCdmgModeTexts[C_DMG_MODE], C_DMG_MODE_HANDLER, );
	Group2.AddLabel('empty_line',"","");

	Group2Point2 = Page.AddGroup('Group2Point2', sPreviewStatusEffects_MCMText);
	HIDE_STAT_CONTEST_MCMUI			= Group2Point2.AddCheckbox('PreviewStatContest', sPreviewStatContest_MCMText, sPreviewStatContest_MCMText, HIDE_STAT_CONTEST, PreviewStatContestHandler, );
	PREVIEW_APPLY_CHANCE_MCMUI			= Group2Point2.AddCheckbox('PreviewApplyChance', sPreviewApplyChance_MCMText, sPreviewApplyChance_MCMText, PREVIEW_APPLY_CHANCE, PreviewApplyChanceHandler, );
	SHOW_APPLY_CHANCE_MISS_MCMUI		= Group2Point2.AddCheckbox('PreviewApplyChanceMiss', sPreviewApplyChanceMiss_MCMText, sPreviewApplyChanceMiss_MCMText, SHOW_APPLY_CHANCE_MISS, ShowApplyChanceMissHandler, );
	SHOW_APPLY_CHANCE_GUARANTEED_MCMUI	= Group2Point2.AddCheckbox('PreviewApplyChanceGuaranteed', sPreviewApplyChanceGuaranteed_MCMText, sPreviewApplyChanceGuaranteed_MCMText, SHOW_APPLY_CHANCE_GUARANTEED, ShowApplyChanceGuaranteedHandler, );
	Group2Point2.AddLabel('empty_line',"","");

	Group2Point5 = Page.AddGroup('Group2Point5', sShotHudDisplayLayout_MCMText);
	LeftSide1_MCMUI						= Group2Point5.AddDropdown('LeftSide1', sLeftSide1_MCMText, sLeftSide1_MCMText, SlotOptions, SlotOptions[SHOTHUD_LAYOUT_LEFT_1], SlotLayoutHandler0, );
	LeftSide2_MCMUI						= Group2Point5.AddDropdown('LeftSide2', sLeftSide2_MCMText, sLeftSide2_MCMText, SlotOptions, SlotOptions[SHOTHUD_LAYOUT_LEFT_2], SlotLayoutHandler1, );
	RightSide1_MCMUI					= Group2Point5.AddDropdown('RightSide1', sRightSide1_MCMText, sRightSide1_MCMText, SlotOptions, SlotOptions[SHOTHUD_LAYOUT_RIGHT_1], SlotLayoutHandler2, );
	RightSide2_MCMUI					= Group2Point5.AddDropdown('RightSide2', sRightSide2_MCMText, sRightSide2_MCMText, SlotOptions, SlotOptions[SHOTHUD_LAYOUT_RIGHT_2], SlotLayoutHandler3, );
	
	LeftSide1OffsetX_MCMUI				= Group2Point5.AddSlider('LeftSide1Offset', sLeftSide1Offset_MCMText, sLeftSide1Offset_MCMText, -200, 200, 1, SHOTHUD_LEFT_1_OFFSET_X, Left1OffsetHandler, );
	LeftSide2OffsetX_MCMUI				= Group2Point5.AddSlider('LeftSide2Offset', sLeftSide2Offset_MCMText, sLeftSide2Offset_MCMText, -200, 200, 1, SHOTHUD_LEFT_2_OFFSET_X, Left2OffsetHandler, );
	RightSide1OffsetX_MCMUI				= Group2Point5.AddSlider('RightSide1Offset', sRightSide1Offset_MCMText, sRightSide1Offset_MCMText, -200, 200, 1, SHOTHUD_RIGHT_1_OFFSET_X, Right1OffsetHandler, );
	RightSide2OffsetX_MCMUI				= Group2Point5.AddSlider('RightSide2Offset', sRightSide2Offset_MCMText, sRightSide2Offset_MCMText, -200, 200, 1, SHOTHUD_RIGHT_2_OFFSET_X, Right2OffsetHandler, );
	
	SHOTHUD_SLOT_WIDTH_MCMUI			= Group2Point5.AddSlider('SHOTHUD_SLOT_WIDTH', sSlotWidth_MCMText, sSlotWidth_MCMText, 10, 100, 1, SHOTHUD_SLOT_WIDTH, SHOTHUD_SLOT_WIDTH_HANDLER, );
	DAMAGE_LABEL_WIDTH_MCMUI			= Group2Point5.AddSlider('DAMAGE_LABEL_WIDTH', sDamageLabelWidth_MCMText, sDamageLabelWidth_MCMText, 10, 500, 1, DAMAGE_LABEL_WIDTH, DAMAGE_LABEL_WIDTH_HANDLER, );

	Group2Point5.AddLabel('empty_line',"","");

	Group3 = Page.AddGroup('Group3', sGroupShotBar_MCMText);
	/*Group3.AddLabel('Warning1',sWarningMessage_MCMText,"");*/
	BarHeight_MCMUI					= Group3.AddSlider('BarHeight', sBarHeight_MCMText, sBarHeight_MCMText, 0, 20, 1, BAR_HEIGHT, BarHeightHandler, );
	//BarOffsetX_MCMUI				= Group3.AddSlider('BarOffsetX', sBarOffsetX_MCMText, sBarOffsetX_MCMText, -200, 200, 1, BAR_OFFSET_X, BarOffsetXHandler, );
	BarOffsetY_MCMUI				= Group3.AddSlider('BarOffsetY', sBarOffsetY_MCMText, sBarOffsetY_MCMText, -20, 20, 1, BAR_OFFSET_Y, BarOffsetYHandler, );
	BarAlpha_MCMUI					= Group3.AddSlider('BarAlpha', sBarAlpha_MCMText, sBarAlpha_MCMText, 0, 100, 1, BAR_ALPHA, BarAlphaHandler, );
	AimLeftOfCrit_MCMUI				= Group3.AddCheckbox('AimLeftOfCrit', sAimLeftOfCrit_MCMText, sAimLeftOfCrit_MCMText, TH_AIM_LEFT_OF_CRIT, AimLeftOfCritHandler, );
	AssistBesideHit_MCMUI			= Group3.AddCheckbox('AssistBesideHit', sAssistBesideHit_MCMText, sAssistBesideHit_MCMText, TH_ASSIST_BESIDE_HIT, AssistBesideHitHandler, );
	AssistBar_MCMUI					= Group3.AddCheckbox('AssistBar', sAssistBar_MCMText, sAssistBar_MCMText, TH_ASSIST_BAR, AssistBarHandler, );
	
	//DEBUG
	//DodgeOffsetY_MCMUI				= Group3.AddSlider('DodgeOffsetY', sDodgeOffsetY_MCMText, sDodgeOffsetY_MCMText, -30, -20, 0.01, DODGE_OFFSET_Y, DodgeOffsetYHandler, );
	//DEBUG
	
	/*BarWidthMult_MCMUI				= Group3.AddSlider('BarWidthMult', sBarWidthMult_MCMText, sBarWidthMult_MCMText, 0, 10, 1, BAR_WIDTH_MULT, BarWidthMultHandler, );
	GeneralOffsetY_MCMUI				= Group3.AddSlider('GeneralOffsetY', sGeneralOffsetY_MCMText, sGeneralOffsetY_MCMText, -100, 0, 1, GENERAL_OFFSET_Y, GeneralOffsetYHandler, );
	DodgeOffsetX_MCMUI				= Group3.AddSlider('DodgeOffsetX', sDodgeOffsetX_MCMText, sDodgeOffsetX_MCMText, -300, 600, 1, DODGE_OFFSET_X, DodgeOffsetXHandler, );
	CritOffsetX_MCMUI				= Group3.AddSlider('CritOffsetX', sCritOffsetX_MCMText, sCritOffsetX_MCMText, -300, 300, 1, CRIT_OFFSET_X, CritOffsetXHandler, );
	CritOffsetY_MCMUI				= Group3.AddSlider('CritOffsetY', sCritOffsetY_MCMText, sCritOffsetY_MCMText, -200, 200, 1, CRIT_OFFSET_Y, CritOffsetYHandler, );*/
	AssistBesideHit_MCMUI.SetEditable(TH_AIM_ASSIST);
	AssistHexColor_MCMUI.SetEditable(TH_AIM_ASSIST);
	AssistBar_MCMUI.SetEditable(TH_AIM_ASSIST);
	Group3.AddLabel('empty_line',"","");

	Group4 = Page.AddGroup('Group4', sGroupBarColors_MCMText);
	HitHexColor_MCMUI				= Group4.AddDropdown('HitHexColor', sHitHexColor_MCMText, sHitHexColor_MCMText, ColorArray, HIT_HEX_COLOR_MCM, HitHexColorHandler, );
	CritHexColor_MCMUI				= Group4.AddDropdown('CritHexColor', sCritHexColor_MCMText, sCritHexColor_MCMText, ColorArray, CRIT_HEX_COLOR_MCM, CritHexColorHandler, );
	DodgeHexColor_MCMUI				= Group4.AddDropdown('DodgeHexColor', sDodgeHexColor_MCMText, sDodgeHexColor_MCMText, ColorArray, DODGE_HEX_COLOR_MCM, DodgeHexColorHandler, );
	MissHexColor_MCMUI				= Group4.AddDropdown('MissHexColor', sMissHexColor_MCMText, sMissHexColor_MCMText, ColorArray, MISS_HEX_COLOR_MCM, MissHexColorHandler, );
	AssistHexColor_MCMUI				= Group4.AddDropdown('AssistHexColor', sAssistHexColor_MCMText, sAssistHexColor_MCMText, ColorArray, ASSIST_HEX_COLOR_MCM, AssistHexColorHandler, );
	Group4.AddLabel('empty_line',"","");
	
	/*Group5 = Page.AddGroup('Group5', sGroupShotWings_MCMText);
	ShowHitChance_MCMUI				= Group5.AddCheckbox('ShowAlwaysShotBreakdownHUD', sShowAlwaysShotBreakdownHUD_MCMText, sShowAlwaysShotBreakdownHUD_MCMText, SHOW_ALWAYS_SHOT_BREAKDOWN_HUD, ShotBreakdownHUDHandler, );
	Group5.AddLabel('empty_line',"","");*/

	Group5 = Page.AddGroup('Group5', sShotHudColorSettings_MCMText);
	SHOTHUD_COLOR_DAMAGE_MCMUI		= Group5.AddDropdown('SHOTHUD_COLOR_DAMAGE', sShotHudDamageColor_MCMText, sShotHudDamageColor_MCMText, UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_DAMAGE], SHOTHUD_COLOR_DAMAGE_HANDLER, );
	SHOTHUD_COLOR_BONUS_DAMAGE_MCMUI= Group5.AddDropdown('SHOTHUD_COLOR_BONUS_DAMAGE', sShotHudDamageBonusColor_MCMText, sShotHudDamageBonusColor_MCMText, UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_BONUS_DAMAGE], SHOTHUD_COLOR_BONUS_DAMAGE_HANDLER, );
	SHOTHUD_COLOR_GRAZE_MCMUI		= Group5.AddDropdown('SHOTHUD_COLOR_GRAZE', Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Graze]), Caps(class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[eHit_Graze]), UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_GRAZE], SHOTHUD_COLOR_GRAZE_HANDLER, );
	SHOTHUD_COLOR_CRIT_MCMUI		= Group5.AddDropdown('SHOTHUD_COLOR_CRIT', class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.CRIT_DAMAGE_LABEL, class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.CRIT_DAMAGE_LABEL, UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_CRIT], SHOTHUD_COLOR_CRIT_HANDLER, );
	SHOTHUD_COLOR_EXPECTED_MCMUI	= Group5.AddDropdown('SHOTHUD_COLOR_EXPECTED', class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.EXPECTED_DAMAGE_LABEL, class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.EXPECTED_DAMAGE_LABEL, UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_EXPECTED], SHOTHUD_COLOR_EXPECTED_HANDLER, );
	SHOTHUD_COLOR_KILL_CHANCE_MCMUI	= Group5.AddDropdown('SHOTHUD_COLOR_KILL_CHANCE', class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.KILL_CHANCE_LABEL, class'ExtendedInformationRedux3_UITacticalHUD_ShotHUD'.default.KILL_CHANCE_LABEL, UIStateColorArray, UIStateColorArray[SHOTHUD_COLOR_KILL_CHANCE], SHOTHUD_COLOR_KILL_CHANCE_HANDLER, );
	Group5.AddLabel('empty_line',"","");

	Group5_1 = Page.AddGroup('Group5_1', sHackPreviewColorSettings_MCMText);
	HACK_COLOR_FAIL_MCMUI		= Group5_1.AddDropdown('HACK_COLOR_FAIL', sHackPreviewFailure_MCMText, sHackPreviewFailure_MCMText, UIStateColorArray, UIStateColorArray[HACK_COLOR_FAIL], HACK_COLOR_FAIL_HANDLER, );
	HACK_COLOR_REWARD_MCMUI		= Group5_1.AddDropdown('HACK_COLOR_REWARD', sHackPreviewReward_MCMText, sHackPreviewReward_MCMText, UIStateColorArray, UIStateColorArray[HACK_COLOR_REWARD], HACK_COLOR_REWARD_HANDLER, );
	Group5_1.AddLabel('empty_line',"","");

	Group5_2 = Page.AddGroup('Group5_2', sStatusEffectColorSettings_MCMText);
	STATUS_COLOR_1_MCMUI		= Group5_2.AddDropdown('STATUS_COLOR_1', sStatusEffect @ "1", sStatusEffect @ "1", UIStateColorArray, UIStateColorArray[STATUS_COLOR_1], STATUS_COLOR_1_HANDLER, );
	STATUS_COLOR_2_MCMUI		= Group5_2.AddDropdown('STATUS_COLOR_2', sStatusEffect @ "2", sStatusEffect @ "2", UIStateColorArray, UIStateColorArray[STATUS_COLOR_2], STATUS_COLOR_2_HANDLER, );
	STATUS_COLOR_3_MCMUI		= Group5_2.AddDropdown('STATUS_COLOR_3', sStatusEffect @ "3", sStatusEffect @ "3", UIStateColorArray, UIStateColorArray[STATUS_COLOR_3], STATUS_COLOR_3_HANDLER, );
	STATUS_COLOR_MISS_MCMUI		= Group5_2.AddDropdown('STATUS_COLOR_MISS', sMissChanceColor_MCMText, sMissChanceColor_MCMText, UIStateColorArray, UIStateColorArray[STATUS_COLOR_MISS], STATUS_COLOR_MISS_HANDLER, );
	Group5_2.AddLabel('empty_line',"","");
	
	Group6 = Page.AddGroup('Group6', sGroupToolTips_MCMTtext);
	ToolTipAlpha_MCMUI				= Group6.AddSlider('ToolTipAlpha', sToolTipAlpha_MCMText, sToolTipAlpha_MCMText, 0, 100, 1, TOOLTIP_ALPHA, ToolTipAlphaHandler, );
	ShowEnemyToolTip_MCMUI			= Group6.AddCheckbox('ShowEnemyToolTip', sShowEnemyToolTip_MCMText, sShowEnemyToolTip_MCMText, ES_TOOLTIP, ShowEnemyToolTipHandler, );
	ShowExtraWeaponStats_MCMUI		= Group6.AddCheckbox('ShowExtraWeaponStats', sShowExtraWeaponStats_MCMText, sShowExtraWeaponStats_MCMText, SHOW_EXTRA_WEAPONSTATS, ShowExtraWeaponStatsHandler, );
	Group6.AddLabel('empty_line',"","");

	Page.ShowSettings();
	`TRACE_EXIT("");
}

/**
 * Loads saved configuration values from MCM and applies them to runtime variables.
 */
simulated function LoadSavedSettings()
{
	`TRACE_ENTRY("");
    HIT_CHANCE_ENABLED =		`MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_CHANCE_ENABLED,HIT_CHANCE_ENABLED);
    TH_AIM_ASSIST =			`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_ASSIST,TH_AIM_ASSIST);
	TH_UNSAFE_AIM_ASSIST =	`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_UNSAFE_AIM_ASSIST,TH_UNSAFE_AIM_ASSIST);
	EXPECTED_DAMAGE =		`MCM_CH_GetValue(class'MCM_Defaults'.default.EXPECTED_DAMAGE,EXPECTED_DAMAGE);
	VERBOSE_TEXT =			`MCM_CH_GetValue(class'MCM_Defaults'.default.VERBOSE_TEXT,VERBOSE_TEXT);
	DISPLAY_MISS_CHANCE =	`MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE,DISPLAY_MISS_CHANCE);
	SHOW_TEMPLAR_MSG =		`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_TEMPLAR_MSG,SHOW_TEMPLAR_MSG);
	BAR_HEIGHT =				`MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_HEIGHT,BAR_HEIGHT);
	//BAR_OFFSET_X =			`MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_OFFSET_X,BAR_OFFSET_X);
	BAR_OFFSET_Y =			`MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_OFFSET_Y,BAR_OFFSET_Y);
	BAR_ALPHA =				`MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_ALPHA,BAR_ALPHA);
	/*BAR_WIDTH_MULT =			`MCM_CH_GetValue(class'MCM_Defaults'.default.BAR_WIDTH_MULT,BAR_WIDTH_MULT);
	GENERAL_OFFSET_Y =		`MCM_CH_GetValue(class'MCM_Defaults'.default.GENERAL_OFFSET_Y,GENERAL_OFFSET_Y);
	DODGE_OFFSET_X =			`MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_OFFSET_X,DODGE_OFFSET_X);
	CRIT_OFFSET_X =			`MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_OFFSET_X,CRIT_OFFSET_X);
	CRIT_OFFSET_Y =			`MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_OFFSET_Y,CRIT_OFFSET_Y);*/
	HIT_HEX_COLOR =			`MCM_CH_GetValue(class'MCM_Defaults'.default.HIT_HEX_COLOR,HIT_HEX_COLOR);
	CRIT_HEX_COLOR =			`MCM_CH_GetValue(class'MCM_Defaults'.default.CRIT_HEX_COLOR,CRIT_HEX_COLOR);
	DODGE_HEX_COLOR =		`MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_HEX_COLOR,DODGE_HEX_COLOR);
	MISS_HEX_COLOR =			`MCM_CH_GetValue(class'MCM_Defaults'.default.MISS_HEX_COLOR,MISS_HEX_COLOR);
	ASSIST_HEX_COLOR =		`MCM_CH_GetValue(class'MCM_Defaults'.default.ASSIST_HEX_COLOR,ASSIST_HEX_COLOR);
	TH_SHOW_GRAZED =			`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_SHOW_GRAZED,TH_SHOW_GRAZED);
	TH_SHOW_CRIT_DMG =		`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_SHOW_CRIT_DMG,TH_SHOW_CRIT_DMG);
	TH_AIM_LEFT_OF_CRIT =	`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_LEFT_OF_CRIT,TH_AIM_LEFT_OF_CRIT);
	TH_ASSIST_BESIDE_HIT =	`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_ASSIST_BESIDE_HIT,TH_ASSIST_BESIDE_HIT);
	TH_ASSIST_BAR		 =	`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_ASSIST_BAR,TH_ASSIST_BAR);
	TH_PREVIEW_MINIMUM =		`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_PREVIEW_MINIMUM,TH_PREVIEW_MINIMUM);
	TH_PREVIEW_HACKING =		`MCM_CH_GetValue(class'MCM_Defaults'.default.TH_PREVIEW_HACKING,TH_PREVIEW_HACKING);
	HIT_HEX_COLOR_MCM = getStringColorFromHex(HIT_HEX_COLOR);
	CRIT_HEX_COLOR_MCM = getStringColorFromHex(CRIT_HEX_COLOR);
	DODGE_HEX_COLOR_MCM = getStringColorFromHex(DODGE_HEX_COLOR);
	MISS_HEX_COLOR_MCM = getStringColorFromHex(MISS_HEX_COLOR);
	ASSIST_HEX_COLOR_MCM = getStringColorFromHex(ASSIST_HEX_COLOR);
	TOOLTIP_ALPHA =			`MCM_CH_GetValue(class'MCM_Defaults'.default.TOOLTIP_ALPHA,TOOLTIP_ALPHA);
	ES_TOOLTIP =				`MCM_CH_GetValue(class'MCM_Defaults'.default.ES_TOOLTIP,ES_TOOLTIP);
	SHOW_EXTRA_WEAPONSTATS = `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_EXTRA_WEAPONSTATS,SHOW_EXTRA_WEAPONSTATS);
	//FLYOVER_DURATION = `MCM_CH_GetValue(class'MCM_Defaults'.default.FLYOVER_DURATION,FLYOVER_DURATION);
	SHOW_GUARANTEED_HIT =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_GUARANTEED_HIT,SHOW_GUARANTEED_HIT);
	SHOTHUD_LAYOUT_LEFT_1 =		`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_1,SHOTHUD_LAYOUT_LEFT_1);
	SHOTHUD_LAYOUT_LEFT_2 =		`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_2,SHOTHUD_LAYOUT_LEFT_2);
	SHOTHUD_LAYOUT_RIGHT_1 =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_1,SHOTHUD_LAYOUT_RIGHT_1);
	SHOTHUD_LAYOUT_RIGHT_2 =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_2,SHOTHUD_LAYOUT_RIGHT_2);
	SHOTHUD_LEFT_1_OFFSET_X =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_1_OFFSET_X,SHOTHUD_LEFT_1_OFFSET_X);
	SHOTHUD_LEFT_2_OFFSET_X =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_2_OFFSET_X,SHOTHUD_LEFT_2_OFFSET_X);
	SHOTHUD_RIGHT_1_OFFSET_X =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_1_OFFSET_X,SHOTHUD_RIGHT_1_OFFSET_X);
	SHOTHUD_RIGHT_2_OFFSET_X =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_2_OFFSET_X,SHOTHUD_RIGHT_2_OFFSET_X);
	HIDE_STAT_CONTEST =			`MCM_CH_GetValue(class'MCM_Defaults'.default.HIDE_STAT_CONTEST,HIDE_STAT_CONTEST);
	PREVIEW_APPLY_CHANCE =			`MCM_CH_GetValue(class'MCM_Defaults'.default.PREVIEW_APPLY_CHANCE,PREVIEW_APPLY_CHANCE);
	SHOW_APPLY_CHANCE_MISS =		`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_MISS,SHOW_APPLY_CHANCE_MISS);
	SHOW_APPLY_CHANCE_GUARANTEED =	`MCM_CH_GetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_GUARANTEED,SHOW_APPLY_CHANCE_GUARANTEED);
	//DEBUG
	//DODGE_OFFSET_Y =			`MCM_CH_GetValue(class'MCM_Defaults'.default.DODGE_OFFSET_Y,DODGE_OFFSET_Y);
	//DEBUG

	C_DMG_MODE					= `MCM_CH_GetValue(class'MCM_Defaults'.default.C_DMG_MODE,C_DMG_MODE);

	SHOTHUD_SLOT_WIDTH			= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_SLOT_WIDTH,SHOTHUD_SLOT_WIDTH);
	DAMAGE_LABEL_WIDTH			= `MCM_CH_GetValue(class'MCM_Defaults'.default.DAMAGE_LABEL_WIDTH,DAMAGE_LABEL_WIDTH);

	SHOTHUD_COLOR_DAMAGE		= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_DAMAGE,SHOTHUD_COLOR_DAMAGE);
	SHOTHUD_COLOR_BONUS_DAMAGE	= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_BONUS_DAMAGE,SHOTHUD_COLOR_BONUS_DAMAGE);
	SHOTHUD_COLOR_GRAZE			= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_GRAZE,SHOTHUD_COLOR_GRAZE);
	SHOTHUD_COLOR_CRIT			= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_CRIT,SHOTHUD_COLOR_CRIT);
	SHOTHUD_COLOR_EXPECTED		= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_EXPECTED,SHOTHUD_COLOR_EXPECTED);
	SHOTHUD_COLOR_KILL_CHANCE	= `MCM_CH_GetValue(class'MCM_Defaults'.default.SHOTHUD_COLOR_KILL_CHANCE,SHOTHUD_COLOR_KILL_CHANCE);
	
	STATUS_COLOR_1				= `MCM_CH_GetValue(class'MCM_Defaults'.default.STATUS_COLOR_1,STATUS_COLOR_1);
	STATUS_COLOR_2				= `MCM_CH_GetValue(class'MCM_Defaults'.default.STATUS_COLOR_2,STATUS_COLOR_2);
	STATUS_COLOR_3				= `MCM_CH_GetValue(class'MCM_Defaults'.default.STATUS_COLOR_3,STATUS_COLOR_3);
	STATUS_COLOR_MISS			= `MCM_CH_GetValue(class'MCM_Defaults'.default.STATUS_COLOR_MISS,STATUS_COLOR_MISS);

	HACK_COLOR_FAIL				= `MCM_CH_GetValue(class'MCM_Defaults'.default.HACK_COLOR_FAIL,HACK_COLOR_FAIL);
	HACK_COLOR_REWARD			= `MCM_CH_GetValue(class'MCM_Defaults'.default.HACK_COLOR_REWARD,HACK_COLOR_REWARD);

	FLYOVER_SHOW_CRIT_0			= `MCM_CH_GetValue(class'MCM_Defaults'.default.FLYOVER_SHOW_CRIT_0,FLYOVER_SHOW_CRIT_0);
	FLYOVER_SHOW_GRAZE_0		= `MCM_CH_GetValue(class'MCM_Defaults'.default.FLYOVER_SHOW_GRAZE_0,FLYOVER_SHOW_GRAZE_0);

	SHOW_MITIGATION = `GETMCMVAR(SHOW_MITIGATION);

	`TRACE_EXIT("");
}

/**
 * Resets all MCM settings to their default values.
 *
 * @param Page The settings page being reset.
 */
simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`TRACE_ENTRY("");
	ShowHitChance_MCMUI.SetValue(	class'MCM_Defaults'.default.HIT_CHANCE_ENABLED, true);
	VerboseText_MCMUI.SetValue(	class'MCM_Defaults'.default.VERBOSE_TEXT, false);
	DisplayMissChance_MCMUI.SetValue(	class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, false);
	ShowTemplarMessages_MCMUI.SetValue(	class'MCM_Defaults'.default.SHOW_TEMPLAR_MSG, false);
	BarHeight_MCMUI.SetValue(	class'MCM_Defaults'.default.BAR_HEIGHT, false);
	//BarOffsetX_MCMUI.SetValue(	class'MCM_Defaults'.default.BAR_OFFSET_X, false);
	BarOffsetY_MCMUI.SetValue(	class'MCM_Defaults'.default.BAR_OFFSET_Y, false);
	BarAlpha_MCMUI.SetValue(	class'MCM_Defaults'.default.BAR_ALPHA, false);
	/*BarWidthMult_MCMUI.SetValue(	class'MCM_Defaults'.default.BAR_WIDTH_MULT, false);
	GeneralOffsetY_MCMUI.SetValue(	class'MCM_Defaults'.default.GENERAL_OFFSET_Y, false);
	DodgeOffsetX_MCMUI.SetValue(	class'MCM_Defaults'.default.DODGE_OFFSET_X, false);
	DodgeOffsetY_MCMUI.SetValue(	class'MCM_Defaults'.default.DODGE_OFFSET_Y, false);
	CritOffsetX_MCMUI.SetValue(	class'MCM_Defaults'.default.CRIT_OFFSET_X, false);
	CritOffsetY_MCMUI.SetValue(	class'MCM_Defaults'.default.CRIT_OFFSET_Y, false);*/
	ShowGrazed_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_SHOW_GRAZED, false);
	ShowCrit_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_SHOW_CRIT_DMG, false);
	AimLeftOfCrit_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_AIM_LEFT_OF_CRIT, false);
	AssistBesideHit_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_ASSIST_BESIDE_HIT, false);
	AssistBar_MCMUI.SetValue( class'MCM_Defaults'.default.TH_ASSIST_BAR, false);
	PreviewMinimum_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_PREVIEW_MINIMUM, false);
	PreviewHacking_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_PREVIEW_HACKING, false);
	HitHexColor_MCMUI.SetValue(	getStringColorFromHex(class'MCM_Defaults'.default.HIT_HEX_COLOR), false);
	CritHexColor_MCMUI.SetValue(	getStringColorFromHex(class'MCM_Defaults'.default.CRIT_HEX_COLOR), false);
	DodgeHexColor_MCMUI.SetValue(	getStringColorFromHex(class'MCM_Defaults'.default.DODGE_HEX_COLOR), false);
	MissHexColor_MCMUI.SetValue(	getStringColorFromHex(class'MCM_Defaults'.default.MISS_HEX_COLOR), false);
	AssistHexColor_MCMUI.SetValue(	getStringColorFromHex(class'MCM_Defaults'.default.ASSIST_HEX_COLOR), false);
	ShowAimAssist_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_AIM_ASSIST, false);
	ShowUnsafeAimAssist_MCMUI.SetValue(	class'MCM_Defaults'.default.TH_UNSAFE_AIM_ASSIST, false);
	ExpectedDamage_MCMUI.SetValue(	class'MCM_Defaults'.default.EXPECTED_DAMAGE, false);
	ToolTipAlpha_MCMUI.SetValue(	class'MCM_Defaults'.default.TOOLTIP_ALPHA, false);
	ShowEnemyToolTip_MCMUI.SetValue(	class'MCM_Defaults'.default.ES_TOOLTIP, false);
	ShowExtraWeaponStats_MCMUI.SetValue(	class'MCM_Defaults'.default.SHOW_EXTRA_WEAPONSTATS, false);
	//FlyoverDuration_MCMUI.SetValue (class'MCM_Defaults'.default.FLYOVER_DURATION, false);
	ShowGuaranteedHit_MCMUI.SetValue(class'MCM_Defaults'.default.SHOW_GUARANTEED_HIT, false);
	LeftSide1_MCMUI.SetValue(SlotOptions[class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_1], false);
	LeftSide2_MCMUI.SetValue(SlotOptions[class'MCM_Defaults'.default.SHOTHUD_LAYOUT_LEFT_2], false);
	RightSide1_MCMUI.SetValue(SlotOptions[class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_1], false);
	RightSide2_MCMUI.SetValue(SlotOptions[class'MCM_Defaults'.default.SHOTHUD_LAYOUT_RIGHT_2], false);
	LeftSide1OffsetX_MCMUI.SetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_1_OFFSET_X, false);
	LeftSide2OffsetX_MCMUI.SetValue(class'MCM_Defaults'.default.SHOTHUD_LEFT_2_OFFSET_X, false);
	RightSide1OffsetX_MCMUI.SetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_1_OFFSET_X, false);
	RightSide2OffsetX_MCMUI.SetValue(class'MCM_Defaults'.default.SHOTHUD_RIGHT_2_OFFSET_X, false);
	HIDE_STAT_CONTEST_MCMUI			.SetValue(class'MCM_Defaults'.default.HIDE_STAT_CONTEST, false);
	PREVIEW_APPLY_CHANCE_MCMUI			.SetValue(class'MCM_Defaults'.default.PREVIEW_APPLY_CHANCE, false);
	SHOW_APPLY_CHANCE_MISS_MCMUI		.SetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_MISS, false);
	SHOW_APPLY_CHANCE_GUARANTEED_MCMUI	.SetValue(class'MCM_Defaults'.default.SHOW_APPLY_CHANCE_GUARANTEED, false);

	C_DMG_MODE_MCMUI					.SetValue(sCdmgModeTexts[class'MCM_Defaults'.default.C_DMG_MODE], false);

	SHOTHUD_SLOT_WIDTH_MCMUI			.SetValue(class'MCM_Defaults'.default.SHOTHUD_SLOT_WIDTH, false);
	DAMAGE_LABEL_WIDTH_MCMUI			.SetValue(class'MCM_Defaults'.default.DAMAGE_LABEL_WIDTH, false);

	SHOTHUD_COLOR_DAMAGE_MCMUI			.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_DAMAGE], false);
	SHOTHUD_COLOR_BONUS_DAMAGE_MCMUI	.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_BONUS_DAMAGE], false);
	SHOTHUD_COLOR_GRAZE_MCMUI			.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_GRAZE], false);
	SHOTHUD_COLOR_CRIT_MCMUI			.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_CRIT], false);
	SHOTHUD_COLOR_EXPECTED_MCMUI		.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_EXPECTED], false);
	SHOTHUD_COLOR_KILL_CHANCE_MCMUI		.SetValue(UIStateColorArray[class'MCM_Defaults'.default.SHOTHUD_COLOR_KILL_CHANCE], false);

	STATUS_COLOR_1_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.STATUS_COLOR_1], false);
	STATUS_COLOR_2_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.STATUS_COLOR_2], false);
	STATUS_COLOR_3_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.STATUS_COLOR_3], false);
	STATUS_COLOR_MISS_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.STATUS_COLOR_MISS], false);

	HACK_COLOR_FAIL_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.HACK_COLOR_FAIL], false);
	HACK_COLOR_REWARD_MCMUI				.SetValue(UIStateColorArray[class'MCM_Defaults'.default.HACK_COLOR_REWARD], false);

	FLYOVER_SHOW_CRIT_0_MCMUI			.SetValue(class'MCM_Defaults'.default.FLYOVER_SHOW_CRIT_0, false);
	FLYOVER_SHOW_GRAZE_0_MCMUI			.SetValue(class'MCM_Defaults'.default.FLYOVER_SHOW_GRAZE_0, false);

	`MCM_API_AutoReset(SHOW_MITIGATION);

	`TRACE_EXIT("");
}

/**
 * Saves current MCM settings and applies them to the active Tactical HUD.
 *
 * @param Page The settings page being saved.
 */
simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	local UITacticalHUD TacticalHUD;

	`TRACE_ENTRY("");
 	HIT_HEX_COLOR = getHexColorByString(HIT_HEX_COLOR_MCM);
	CRIT_HEX_COLOR = getHexColorByString(CRIT_HEX_COLOR_MCM);
	DODGE_HEX_COLOR = getHexColorByString(DODGE_HEX_COLOR_MCM);
	MISS_HEX_COLOR = getHexColorByString(MISS_HEX_COLOR_MCM);
	ASSIST_HEX_COLOR = getHexColorByString(ASSIST_HEX_COLOR_MCM);
	self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
	self.SaveConfig();

	TacticalHUD = UITacticalHUD(`PRESBASE.ScreenStack.GetScreen(class'UITacticalHUD'));
	if (TacticalHUD!=none)
	{
		ExtendedInformationRedux3_UITacticalHUD_ShotHUD(TacticalHUD.m_kShotHUD).RemoveAll().InitLayout();

		TacticalHUD.m_kTooltips.Remove();
		TacticalHUD.m_kTooltips = TacticalHUD.Spawn(class'UITacticalHUD_Tooltips', TacticalHUD).InitTooltips();
	}
	`TRACE_EXIT("");
}

/**
 * Converts a color name string into its corresponding hex value.
 *
 * @param ColorString The localized color name.
 * @return The corresponding hex color string.
 */
function string getHexColorByString(string ColorString)
{
	`TRACE_ENTRY("ColorString:" @ ColorString);
	switch (ColorString)
	{
		case		sBlack:					return "FFFFFF";
		case		sWhite:					return "000000";
		case		sCyan:					return "9acbcb";
		case		sFadedCyan:				return "546f6f";
		case		sFadedYellow:			return "aca68a";
		case		sGray:					return "828282";
		case		sGreen:					return "53b45e";
		case		sRed:					return "bf1e2e";
		case		sYellow:					return "fdce2b";
		case		sPerkYellow:				return "fef4cb";
		case		sCashGreen:				return "5CD16C";
		case		sPurple:					return "b6b3e3";
		case		sOrange:					return "e69831";
		case		sOrangeEngineering:		return "f7941e";
		case		sBlueScience:			return "27aae1";
		case		sObjIconBackground:		return "53b45e";
		default : return "828282";
	}
}

/**
 * Converts a hex color string into its corresponding localized color name.
 *
 * @param ColorString The hex color string.
 * @return The corresponding localized color name.
 */
function string getStringColorFromHex(string ColorString)
{
	`TRACE_ENTRY("ColorString:" @ ColorString);
	switch (ColorString)
	{
		case		"FFFFFF"	 : return sBlack;				
		case		"000000"	 : return sWhite;				
		case		"9acbcb"	 : return sCyan;		
		case		"546f6f"	 : return sFadedCyan;		
		case		"aca68a"	 : return sFadedYellow;		
		case		"828282"	 : return sGray;			
		case		"53b45e"	 : return sGreen;				
		case		"bf1e2e"	 : return sRed;		
		case		"fdce2b"	 : return sYellow;		
		case		"fef4cb"	 : return sPerkYellow;			
		case		"5CD16C"	 : return sCashGreen;			
		case		"b6b3e3"	 : return sPurple;				
		case		"e69831"	 : return sOrange;	
		case		"f7941e"	 : return sOrangeEngineering;
		case		"27aae1"	 : return sBlueScience;
		case		"53b45e"	 : return sObjIconBackground;
		default : return sGray;
	}
}

/**
 * Initializes slot option array using localized strings,
 * while providing English fallbacks if localization is missing.
 */
private function InitializeSlotOptions()
{
	// Already initialized
	if (SlotOptions.Length > 0) return;

    SlotOptions.Length = 5;

    SlotOptions[0] = (SlotOptions_0 != "") ? SlotOptions_0 : "None";
    SlotOptions[1] = (SlotOptions_1 != "") ? SlotOptions_1 : "Graze Chance";
    SlotOptions[2] = (SlotOptions_2 != "") ? SlotOptions_2 : "Critical Damage";
    SlotOptions[3] = (SlotOptions_3 != "") ? SlotOptions_3 : "Expected Damage";
	SlotOptions[4] = (SlotOptions_4 != "") ? SlotOptions_4 : "Kill Chance";
}

/**
 * Initializes sCdmgModeTexts array using localized strings,
 * while providing English fallbacks if localization is missing.
 */
private function InitializeCdmgModeTexts()
{
	// Already initialized
	if (sCdmgModeTexts.Length > 0) return;

    sCdmgModeTexts.Length = 4;

    sCdmgModeTexts[0] = (sCdmgModeTexts_0 != "") ? sCdmgModeTexts_0 : "Always Show Crit Bonus";
    sCdmgModeTexts[1] = (sCdmgModeTexts_1 != "") ? sCdmgModeTexts_1 : "Always Show Total Damage for Crit";
    sCdmgModeTexts[2] = (sCdmgModeTexts_2 != "") ? sCdmgModeTexts_2 : "Only Show Total Damage for Crit on All Crit Ranges";
    sCdmgModeTexts[3] = (sCdmgModeTexts_3 != "") ? sCdmgModeTexts_3 : "Only Show Total Damage for Crit on Crit Ranges Where Max Crit Bonus is Smaller than Min Crit Bonus";
}