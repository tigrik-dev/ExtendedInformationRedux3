class UIScrollingTextLib extends Object;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Approximates the effective width of a UIScrollingText element.
 *
 * Since UIScrollingText does not expose real text width, this function
 * estimates it based on string length and clamps it to the mask width.
 *
 * @param ScrollingText    The UIScrollingText instance
 *
 * @return int             Estimated width used for layout calculations
 */
static function int GetScrollingTextEffectiveWidth(UIScrollingText ScrollingText)
{
    local int EstimatedWidth;
    local int CharWidth;

	`TRACE_ENTRY("");

    // Rough average
    CharWidth = 9;

    EstimatedWidth = Len(ScrollingText.text) * CharWidth;

    // Clamp to mask width (this is where scrolling begins)
	return (EstimatedWidth > ScrollingText.Width) ? int(ScrollingText.Width) : EstimatedWidth;
}