/**
 * X2EventListener_ExtendedInformation
 *
 * Custom event listener for Extended Information Redux.
 * 
 * Responsibilities:
 * - Create data templates for custom events
 * - Clear breakdowns at the end of player turns
 * - Integrate with tactical game ruleset observers
 *
 * @author Mr.Nice
 */
class X2EventListener_ExtendedInformation extends X2EventListener;

`include(ExtendedInformationRedux3\Src\ExtendedInformationRedux3\EIR_LoggerMacros.uci)

/**
 * Creates an array of data templates used by this listener.
 *
 * @return array<X2DataTemplate>  List of templates
 */
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`TRACE_ENTRY("");
	Templates.AddItem( AddClearBreakdownEvent() );

	`TRACE_EXIT("");
	return Templates;
}

/**
 * Generates a template for clearing tactical breakdowns at end of player turn.
 *
 * @return X2EventListenerTemplate  The event listener template
 */
static function X2EventListenerTemplate AddClearBreakdownEvent()
{
	local X2AbilityPointTemplate Template;

	`TRACE_ENTRY("");
	`CREATE_X2TEMPLATE(class'X2AbilityPointTemplate', Template, 'EIClearBreakdown');
	Template.AddEvent('PlayerTurnEnded', ClearBreakdown);

	`TRACE_EXIT("");
	return Template;
}

/**
 * Clears all breakdowns when the player turn ends.
 *
 * @param EventData     The event data object
 * @param EventSource   The source of the event
 * @param GameState     Current game state
 * @param Event         Name of the event
 * @param CallbackData  Optional callback data
 *
 * @return EventListenerReturn  Result of event processing
 */
static function EventListenerReturn ClearBreakdown(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2GameRulesetEventObserverInterface Observer;

	`TRACE_ENTRY("");
	Observer = `GAMERULES.GetEventObserverOfType(class'X2TacticalGameRuleset_BreakdownObserver');
	X2TacticalGameRuleset_BreakdownObserver(Observer).Breakdowns.Length = 0;
	`TRACE_EXIT("");
	return ELR_NoInterrupt;
}