/**
 * X2TemplatePatch
 *
 * Base "abstract" class for defining template patch logic.
 *
 * Responsibilities:
 * - Provide template identifier via GetTemplateName()
 * - Apply modifications to a given X2AbilityTemplate
 *
 * Usage:
 * - Extend this class to implement custom patches
 * - Override both GetTemplateName() and Apply()
 *
 * Design Notes:
 * - UnrealScript does not support abstract classes, so this uses runtime
 *   error reporting to enforce implementation
 * - Acts as a strategy interface for TemplatePatchLib
 *
 * Example:
 * class X2Patch_MyPatch extends X2TemplatePatch;
 *
 * @author Tigrik
 */
class X2TemplatePatch extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Returns the name of the template to patch.
 *
 * @return name   Template name (must match AbilityTemplate DataName)
 *
 * Required:
 * - MUST be overridden in subclasses
 *
 * Error Handling:
 * - Logs error and returns empty name if not implemented
 */
function name GetTemplateName()
{
    `Redscreen("X2TemplatePatch: GetTemplateName() not implemented!");
	`ERROR("GetTemplateName() not implemented!");
    return '';
}

/**
 * Applies modifications to the provided ability template.
 *
 * @param Template   Ability template to modify
 *
 * Required:
 * - MUST be overridden in subclasses
 *
 * Notes:
 * - Called for each difficulty variant of the template
 * - Should be written defensively (null checks, safe casting)
 *
 * Error Handling:
 * - Logs error if not implemented
 */
function Apply(X2AbilityTemplate Template)
{
    `Redscreen("X2TemplatePatch: Apply() not implemented!");
	`ERROR("Apply() not implemented!");
}
