/**
 * StringLib
 *
 * Utility class for strings.
 *
 * Responsibilities:
 * - Provide simple helpers to detect uppercase and lowercase characters
 * - Support text parsing logic (e.g. effect label formatting in _EffectLib)
 *
 * Notes:
 * - Designed for single-character string inputs
 * - Uses ASCII range comparisons ("A"-"Z", "a"-"z")
 * - Does NOT support locale-specific or Unicode casing rules
 *
 * @author Tigrik
 */
class StringLib extends Object;

/**
 * Checks whether a character is an uppercase Latin letter
 *
 * @param C        Input character (expected length = 1)
 *
 * @return bool    True if uppercase
 */
static function bool IsUpper(string C)
{
    return C >= "A" && C <= "Z";
}

/**
 * Checks whether a character is a lowercase Latin letter
 *
 * @param C        Input character (expected length = 1)
 *
 * @return bool    True if lowercase
 */
static function bool IsLower(string C)
{
    return C >= "a" && C <= "z";
}