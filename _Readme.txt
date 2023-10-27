The files located under template should be copied to the project and adapted as needed.
_Globals/	: project related globals and constants
_Scam/		: Standard blocks >> can be left out if not needed
_Controls	: Project specific controls (one offs, no bknlibrary candidates)
_General	: General stuff, like Bknlibrary / signals / emergency stop / reset ethercat / saving setpoints / shutdown / etc

Main		: The main is included with an example organiser and SCM_MachinePart linked together
			  >>adapt and clean OR remove and use the SCM_TemplateClean as base for your new scam blocks.
CheckBounds : Should only be activated for testing/debugging. After testing this function should be removed/excluded from build

Important notes to take into considiration:
FB_Init(int a, int b)	:	When initialising an instance for a FB , DO NOT connect variables to method parameters a / b, only use literals (like: [1] / [3.333] / [ 'mystring' ])
							Reason being, the variable you connect might not have been initialised yet and is still 0!!!
							Work around, add a property in the block which changes the same variable and in the FB_Init of the FB where the instance is initialised, set the values
							Most library items already have these properties
							>Ask me if unclear HP


//interesting pragma's
{region 'my private space'}  {endregion} >>just like in c# create foldable blocks
{info 'shows this text as info during compiling'}
{warning 'shows this text as warning during compiling'}
{warning disable/restore xxxx}
	C0125>> ... is assigned to more than one enumeration
	C0139>> code has no effect
	C0195 / C0196>> signed to unsigned / unsigned to signed
	C0197>> implicit conversion ... possible loss of information
	C0371>> acces from external context (using for example IO_STS in a method while declared in the main body)
	maybe these work as well???> https://content.helpme-codesys.com/en/CODESYS%20Static%20Analysis/_san_struct_reference_rules.html
{error 'shows this text as error during compiling'}
{attribute 'no-analysis'}				//deactivate all intellisense errors
{attribute 'analysis' := '-33'}			//deactivate error unused variable for next variable/struct
{attribute 'analysis' := '-27'}			//SA0027 >> name already used (when using for enums, it doesn't work to place it at the top. Must be above problem line of code)
{attribute 'qualified_only'}			//forces the user to add the DUT name in front of the variables (needed if for example 2 enum structs have the same keys)
{attribute 'displaymode':='bin'}		// or 'dec' or 'hex' forces said display mode of the variable during monitoring
{attribute 'global_init_slot':= 'x'}	//cdetermines which blocks get initialised first. Globals have a adefault value of 49990 and POU's 50000
{attribute 'hide_all_locals'}			//(top of declacations) or 'hide' (above variable): hides all or single local variable(s) in online view'
Properties
{attribute 'monitoring':='call'}		//Forces during monitoring the get property is executed so a value can be seen (otherwise no monitoring of values)
Programs
{attribute 'no_explicit_call' := 'do not call this POU directly, because ...'}


//interesting new features of tc3
Type "Reference To" versus "Pointer To" 
	input assignment: "REF=myTYpe" instead of "=ADR(myTYpe)"   
	type value: no need for ^ when accessing the value
	__ISVALIDREF(myType) >> returns true if a valid reference is supplied
	>>compiler type checks when assigning 2 references
	>>cleaner code
Type "Any" better than "Pointer To" if "Reference To" can not be used, basically it automaticly creates a struct with address and sizeoff
	Example: declaration var input {I_myAny:Any;} code {memset(I_myAny.adr, 0, I_myAny.size)};
myBool S= myOtherbool; //sets mybool if myOtherbool is true
myBool R= myOtherbool; //Reset
OR_ELSE >> stop checking other conditions at the first true
AND_THEN >> stop checking other conditions at the first false   >>example prevent BSOD: IF (ptr <> 0 AND_THEN ptr ^ = 99) THEN...
action FB_init: acts a little like a constructor in C# Used a lot in the bkn-lib for configuration settings. Be very carefully with this beast! Ask me (HP), for some instructions
Property: properties can now be made. Used in the bkn-lib to give access to configuration settings set by FB_Init (only done on rare occasion, if needed then add more)'
Pointer acces:	myBytePointer[3] >> type pointers can be treated as arrays of the type, so for this byte-type this equals (myBytepointer+3)^
				myStringPointer[1] >> points to the next string + 80 bytes!!!
__VARINFO: returns all kind of nice info for a variable, also the name!
__NEW / __DELETE: declare memory during runtime
__TRY, __CATCH, ... : OMG don not use this (there is a nice example TO catch DIV BY zero)'
THIS instance / program? pointer to itself
SUPER^ access baseblock
Profiler >> measure excution time of blocks.   Example: myProfiler(START:=TRUE,RESET:=TRUE); your code; dbgProfiler(START:=FALSE);

Speed optimization:
	-declare variables in order of size (first the bytes then the words then ... etc)

Beckhoff bugs:
	Actual:
		visu: textlist for a combobox for a visu in a library
			Dont activate filter for missing text (if you're skipping numbers). It will show ok but if you click on the combobox, the hmi will crash
			See cntrl_Srv_GEH6000 combobox for movemode (turned filtering off because of crashing)

		comments: when retrieving symbol comment info over ADS for use in the boikon hmi
			some combinations of adding comment in the line before a variable, not commenting on the same line behind the variable and commenting the next variable,
			will mess up the variable comment when retrieving symbols over ADS. It may include ";" characters! (caused mayhem in the boikon-hmi error list, the boikon hmi now ignores comments which includes forbidden characters)

		TO_BOOL(symbolOfTypeLongWord) is 2times slower than (symbolOfTYpeLongWord<>0)

		Error: "Unkown type: 'int#1'" popping up on fb_init and property.get of blocks
			>> caused by assigning values to enum with SHL() example: TYPE eVacuumGeneratorConfig:(	DisableEs := SHL(2#1,0),HoldAutoState 	:= SHL(2#1,1))WORD;
			   solved by adding to_type >> DisableEs := TO_WORD(SHL(2#1,0))
			   also solved Nicer by having at least 1 enum that is not assigned with SHL >> Default := DisableEs+HoldAutoState


	Fixed by beckhoff:
	T_MaxString == FORBIDDEN TO USE FOR HMI VARS. Just use "myString:STRING(255);" instead.
		The new beckhoff symbolic ads way of using variables, does not play nice with T_Maxstring! This is an understatement... It will do BAD things to your plc memory.
		*beckhoff fixed this on my request :) >> use a recent twincatAds.dll / nuget twincat ads-package
