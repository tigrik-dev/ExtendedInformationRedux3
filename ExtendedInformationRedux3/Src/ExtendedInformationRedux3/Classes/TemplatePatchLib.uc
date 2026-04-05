/**
 * TemplatePatchLib
 *
 * Central utility responsible for applying runtime patches to XCOM 2 ability templates.
 *
 * Responsibilities:
 * - Locate ability templates (including all difficulty variants)
 * - Apply patch logic via X2TemplatePatch implementations
 * - Provide logging for patch execution and debugging
 *
 * Usage:
 * - Add new patches by creating classes extending X2TemplatePatch
 * - Register them inside PatchTemplates()
 *
 * Design:
 * - Uses a strategy-like pattern where each patch encapsulates its own logic
 * - Avoids hardcoding template modification logic in a single place
 *
 * @author Tigrik
 */
class TemplatePatchLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Entry point for applying all template patches.
 *
 * This function should be called during initialization to ensure all
 * template modifications are applied before gameplay begins.
 */
static function PatchTemplates()
{
	`TRACE_ENTRY("");
	`INFO("Patching templates");
    PatchTemplate(new class'X2Patch_PrecisionShotCritDamage');
	`TRACE_EXIT("");
}

/**
 * Applies a single template patch across all difficulty variants.
 *
 * @param Patch    Instance of X2TemplatePatch containing:
 *                 - Target TemplateName
 *                 - Patch logic to apply
 *
 * Behavior:
 * - Retrieves all difficulty variants of the template
 * - Applies the patch to each valid X2AbilityTemplate
 * - Logs success and errors
 *
 * Notes:
 * - If TemplateName is empty, logs error and aborts
 * - Safe to call multiple times (idempotent if patch is written correctly)
 */
static private function PatchTemplate(X2TemplatePatch Patch)
{
    local X2AbilityTemplateManager AbilityTemplateManager;
    local X2AbilityTemplate Template;
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local name TemplateName;

	`TRACE_ENTRY("");
    TemplateName = Patch.GetTemplateName();

    if (TemplateName == '')
    {
        `Redscreen("PatchTemplate: Empty TemplateName!");
		`ERROR("Empty TemplateName!");
        return;
    }
	`INFO("Patching template:" @ TemplateName);

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
    AbilityTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);

    foreach DifficultyVariants(DifficultyVariant)
    {
        Template = X2AbilityTemplate(DifficultyVariant);
        if (Template != none)
        {
            Patch.Apply(Template);
			`INFO("Template patched:" @ TemplateName);
        }
    }
	`TRACE_EXIT("Template:" @ TemplateName);
}