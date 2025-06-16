Breaking changes from 0.6.8 + new changes during 0.7 development until release 1 (not released yet, but pretty close)

Changed libary blocks
	cntrl_Signal 
		>>split into:
		cntrl_Input  		>> only logging + RE/FE detection
		cntrl_InputHmiSts	>> "" + HMI Status  			(usefull for inputs from external machines which should also be visible on the HMI like: I_SN_DSC_ReadyToReceive)
		cntrl_InputHmiStsErr	>> "" + HMI Error 			(usefull for inputs that detect an error state like: I_PB_ES_HMI / I_DR_ES_Entrance / I_PS_Air / etc)
		*No need anymore for creating seperate errors for ps_airsupply / pb_es_hmi etc / etc >> just instantiate as cntrl_InputHmiStsErr , and there you go error already created.

	*If during an upgrade of your project you hit more of these kind of changes >> send me an email so I can include them in this document.
	*Also íf you think things should be added / explained differently >> please say so.

cntrl_OrganiserFake: A block with the organiser interface with almost no logic, to manipulate OrgControl signals
	>> used in cases where you don't have an organiser but you do want to use library blocks which need an organiser.


utl_General 
	>> since all blocks now need an organiser instance we might have a litle issue here since general usually doesn't belong to 1 specific organiser (if it does in your case then you can use that).
	What you can do is create a fake organiser with: cntrl_OrganiserFake, call it with you reset signals and feed the instance to the library blocks that need it.


Structure of the HMI bits changed
	-in <V0.7 all HMI bits were centralised in big structs in main: main.HMI_Errors / etc 
	Now each object (controls + scams) centralises the HMI bits in HMI:ObjectVariant:HMI_BaseBlock per object.
	Although this is a function_block, it is mostly used as struct and it shouldn't be called

	The HMI is now smart enough to go through all variables and filter only the HMI variables (*.HMI.ERR/WRN/SP/STS/MAN*.)  => previously it filtered for MAIN.HMI_*
	*NOTE: yes this break OOP a little much, because the HMI will read/write local object variables!
			The alternative is the old way (which also breaks oop since variables in main are local as well) >> should have been declared in a global datatype
			>>Moral of the story, we don't break OOP! But for the HMI we look through the fingers ?.

	>Create your own implementation of this baseblock with your customised errors/warnings/statusses/setpoints structs (these structs are the same as previously)
		see in the template: FUNCTION_BLOCK HMI_TemplateClean EXTENDS HMI_BaseBlock
	>Create an instance of this type in your object in VAR with the name "HMI" (name==important) and adapt old usages to new way (example: IO_HMI_ERR.myError S= condition --> HMI.ERR.myError S= condition)
	>You have to call HMI.Update (...) 
		-if there is no parent (normal situation for a scam) then set argument I_HMI_Parent := 0, otherwise supply parent connection (this will propagate the error state to the parent block)
		*this will handle:  resetting of errors / detecting of error active / loggging of first x-errors / resetting of manuals / notify HMI of warning/error changes
	>Now you're done with the HMI variables.  
		*the new way saves you a lot of work vs how it was handled in 0.6.8. You can just throw in any library control instance and the HMI vars just work. No extra HMI declarations needed anymore.


Scam/Organiser structure changed
	>>Organiser communication grouped in 1 variable (interface), it lost scam in- and outputs (I_ProgRest/Error + Q_Control)
		-I_OrgControl:OrgControl is now: I_Organiser: ItfOrganiser >> connect the organiser instance to this input
			>>at the organiser itself you don't have to group all corresponding prog.rest / prog.error signals anymore
		-Usage Q_ProgStatus changed >> first collect statusses in internal variable HM_ProgStatus (rename original and move to var) and then call I_Organiser.M_UpdateProgStatus with this variable
			-step by step update:
				-remove assignment of prog_error
				-assignment of prog_rest stays the same
				-assignment of prog_exception is done in exceptions (copy from template)
				-assignment of error can be done in activations
				-call organiser method to update prog status
				Example (in the template this is done in StepActivations below the CASE..END_CASE):
					//update organiser with local status
						HM_ProgStatus.Prog_Error :=	//emergencystop not ok
							NOT I_K_ES_OK
							//optional >> request go to error state from external
							OR I_K_ExternalError
							//error active in this block or one of the linked children
							OR HMI.P_STS_InError;
					I_Organiser.M_UpdateProgStatus(HM_ProgStatus);
				*the call of the organiser method will determine prog-rest/auto/execption for all scams belonging to this organiser.
			
		-Usage of all organiser mode statusses is now: I_Organiser.Auto_K / etc  (it looks almost the same as original but is different under the surface >> now accessing these variables directly in the organiser)
		-All library controls now need this input as I_OrgControl

	>>HMI variables are now kept local
		-make sure you have done section which explains this
		-remove all IO_HMI_STS/ERR/WRN/MAN
		-remove resetting of errors + detection of errors

	//state transitions
	>>the block now should implement: ItfEnumConverter (copy implementation P_EnumAsInt and P_EnumAsString from the template). This provides properties to convert an enum to string / int value.
		*needed for utl_step to change step by int and log state as string
	>>step transitions handler updated (utl_Step) >> it now requires ItfEnumProvider as input (THIS^). With the enumprovider the utility can manipulate the enum state as int and log as string.
		<V0.7 >> if you were not using a step utility, then now it's time to switch.
		-it is now called in A_Exceptions (if your exeptions are default, you can copy this whole action from the template, make sure the update the enum "eTMP" to your version)
			>>remove call from activations
		-When setting a new step, you only need to supply the new state, optionally you can enter extra info for logging and activate step-hold-mode  (see scm_templateClean for full usage)
			*minimal version: Step.M_Step(I_NewStep:= eMySteps.someStep);	
	>>In A_StepTransitions, the logic around the main CASE .. END_CASE changed a litle (see the template) >> copy/replace by template example

	>> <V0.7 code split in Actions: exceptions / simulation / transitions / activations
		*you don't HAVE to do it but it is strongly recommended. It can be really nice to have a vertical split view and then on 1 side the step transistions and on the other the step activations.