/**
 * X2Patch_PrecisionShotCritDamage
 *
 * Patch implementation that modifies the "PrecisionShotCritDamage" ability.
 *
 * Responsibilities:
 * - Locate all persistent effects on the template
 * - Override their FriendlyName for UI display consistency
 *
 * Behavior:
 * - Iterates through Template.AbilityTargetEffects
 * - Casts effects to X2Effect_Persistent
 * - Updates FriendlyName to "Precision Shot"
 *
 * @author Tigrik
 */
class X2Patch_PrecisionShotCritDamage extends X2TemplatePatch;

/**
 * Returns the template name for Precision Shot crit damage.
 *
 * @return name   'PrecisionShotCritDamage'
 */
function name GetTemplateName()
{
    return 'PrecisionShotCritDamage';
}

/**
 * Add a missing FriendlyName to the PrecisionShotCritDamage's AbilityTargetEffect
 *
 * @param Template   Ability template to modify
 *
 * Implementation Details:
 * - Iterates over AbilityTargetEffects
 * - Safely casts to X2Effect_Persistent
 * - Updates FriendlyName only if cast succeeds
 */
function Apply(X2AbilityTemplate Template)
{
	local X2Effect TargetEffect;
	local X2Effect_Persistent PersistentEffect;

	foreach Template.AbilityTargetEffects(TargetEffect)
	{
		PersistentEffect = X2Effect_Persistent(TargetEffect);

		if (PersistentEffect != none)
		{
			PersistentEffect.FriendlyName = "Precision Shot";
		}
	}
}