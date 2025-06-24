This is the location to store all your scam programs.

When you create a new scam, use the powershell script "CreateNewScmUsingTemplate" to create a copy of the clean template it will ask for new names.
	>>this will also update the state variable name + usage with the new name

Example usage of all library controls, can be found in: 
	SCM_TemplateMachinePart 

A clean template (used by the script as source):
	SCM_TemplateClean



Structure:
	SCM_MachinePart 
		> This is the block that needs calling in main.
		> In here you create the state-machine and all controls (sensors/motors/etc)

	/EnumsAndState
		> eXXX : enum holding your states
			Needs updating to your situation
		> sXXX : state controller used in SCM_XXX to change state
			No need to update, the powershell script already did that (changed the state-enum)
			Responsible for:
				-logging
				-HMI info
				-Stepmode
				-.P_StepTime = tracking step time > can be used for example in simulation to simulate a sensor high after a delay when the step gets high
			Most logic is in the library, only the parts that are project dependant (state enum) are located in this file in your project

	/HMI
		HMI structure for SCM_xxx
		The following needs updating to your situation:
			> HMI_ERR_XXX	: Errors
				note:	
					should be SET (example in activation of eS.Init> HMI.ERR.InitNotEmpty S= PC_Conveyor.Q_Detect)
					leave reset to automatic handling
			> HMI_WRN_XXX	: Warnings
				note:
					should be activated (example: HMI.WRN.Empty := NOT PC_Magazine.Q_Detect)
			> HMI_MAN_XXX	: Manuals the SCM_ should react to when the organiser is in manual_K. 
							  Normally not used for a SCM_  controls like motors/servo's/etc do use this
			> HMI_STS_XXX	: Statusses/Indicators/Values/Pushbuttons that are not persistent
			> HMI_SP_XXX	: Setpoints, these variables are used for the recipe in the HMI
							  Only read these variables! (otherwise the HMI-recipe won't get updated)	
							  Persistent

		No need to update:
			> HMI_XXX		: HMI-variable-handler
				Handles:
					-resetting errors
					-resetting manuals
					-detecting errors + logging
					-setting parent in error
						*normally not used in a SCM_, but this is how a control puts the scam in error when is has an error itself with I_HMI_Parent
					-signaling HMI-application to update warnings/errors (the HMI does not constantly poll all these variables, only when the plc says so)
			note:
				HMI.P_STS_InError	>> you can use this property as status if this scam is in error (including child-controls)
									>> it is also possible to put the SCM_ in error as is done when for example if I_ES_OK is false
										*This will cause the organiser to go to error, but no alarm is shown in the HMI! (for I_ES_OK, utl_general will generate a "ES-circuit not ok" alarm)
										The normal way to set the block in error is by setting a bool in HMI.ERR.xxxx