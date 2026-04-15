*******************
***Template info***
*******************

XAE recommended options
	Start XAE as administrator > faster + less errors, beckhoff recommendation.
		One way of doing is is to start via system icon

	Disable warning library not compatible with twincat older than xxx
		Options/twincat/plc environment/libraries/tab advanced/ disable warning library format

	Multiple project files / line'ids separate
		Options/twincat/XAE environment/file settings/Enable Multiple Project Files  true, you can enable more here if you need it
		Options/twincat/plc environment/WriteOptions/	Set all to true
	
	Smart coding
		Options/twincat/plc environment/Smart Coding/	Declare unkown variables auto >> false (no irritating popups at new variable)  
														parallelism >> you can increase this to more, I'm not seeing much difference if any

	Keyboard shortcut
		Options/Environment/Keyboard/PLC.WriteValues  ctrl + `  or whatever you want

	Visualisation
		Options/twincat/plc environment/visualisation/ >set to grid, grid should be a factor of 2 (this is what everything in the library is build on)

	DarkMode:
		*Note the editor is a codesys plugin so it won't react to vs-studio options.
		To set this plugin in dark mode:
			-tools\options\twincat\plc environment\text editor\theme > select vsdark
			2 things are not nice and can be fixed in the file used for vsdark: C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Components\Plc\Build_4026.21\Themes\
				-top line of a folded section is unreadable
					colors\general:
							"foldLineForeground": "codeForeground",
							"foldLineBackground": "codeControl",
				-in online mode it switches to light mode....
					 "online": {
							"monitoringForeground": "codeForeground",
							"monitoringBackground": "darkMagenta",   >> changed. This is the background for numbers but also changes the window background to black?!?!

Solution / project settings
	-PLC/settings/enable folder view
		>>in the instance data, the in-/outputs are now in tree form instead of a (very) long list of io-variables
	-PLC/Project/project/properties/create global version structure
		>>default off, turned on for the plc/library
		*Is used by the library and the template project to show version info in the HMI
		**If you get compiler errors @ these variables not available then: disable this setting, SAVE, enable the setting. Now a new file will be created and error is gone.
	-PLC/Project/project/properties/allow check functions for compiled library 
		>>default on. 
		TODO >> turned it off for the boikon lib and project lib to see if that saves time in compiling etc. Check if this has nasty side-effects (not detecting out of boundary / div 0 / etc)
						
	-PLC/Project/YourLibrary/properties/enable referenced library 
		>> handy if this is a library project of your plc project which has it included as a library. Now changes in the library project are reflected immediatly in you plc project (no need to save-install the library project)
		*don't set for your plc project

Project directory structure:
	DevelopmentPlayground: REMOVE >> Used for maintaining + testing the library and template
	_Globals	: globals and constants
	_Scam/		: State machines
	_Controls	: Project specific controls (one offs, no library candidates / not yet implemented in the library)
	_Utils		: Project specific utilities (one offs, no library candidates / not yet implemented in the library)
	General		: Signals that do not belong to a specific part of the machine like: Bknlibrary / emergency stop / reset ethercat / saving setpoints / shutdown / etc
	Main			: The main is included with an example organiser and SCM_MachinePart linked together
	Version		: Autogeneratated, holds the global struct with constant variable for the version number. !Do not change!
	/CheckBounds : Should only be activated for testing/debugging. After testing this function should be removed/excluded from build (because it's a performance hog)

Important notes to take into considiration:
	FB_Init(int a, int b)	:	When initialising an instance for a FB , DO NOT connect variables to method parameters a / b, only use literals (like: [1] / [3.333] / [ 'mystring' ])
									Reason being, the variable you connect might not have been initialised yet and is still 0!!!
									>>If you do need access to variables set in FB_Init then create a property for those variables

********************************
***General twincat 3 know how***
********************************
Value decalarations
	VAR_TEMP: in PRG/FB > values are forgotten
	VAR_INST : in FB.method > value is not forgotten when method is done
	VAR_STAT: in FB > variable is shared in all instances (so all instances access the same memory)
	VAR CONSTANT > variables can't be changed in code anymore

	9_123_567	>> underscores are ignored so this is: 9123567
	16#FFFF		>>hexadecimal notation

	VAR a,b,c,d,e : int; END_VAR  >>declare multiple variables of the same type in one go

	Array-Initialisation examples:
		-single dimension
			aIntArray:		ARRAY[0..4] OF INT := [0,1];
			aIntArray:		ARRAY[0..4] OF INT := [0,1,2,3,4];
			aIntArray:		ARRAY[0..9] OF INT := [5(0), 1, 2, 3(-1)];

		-multi dimension
			aIntArray:	ARRAY[0..2, 0..1] OF INT := [ 2(0), 2(1), 2(2) ];
			aIntArray:	ARRAY[0..2] OF ARRAY[0..1] OF INT := [ [0,1], [2,3], [4,5] ];

		-usage of constants
			X:	INT := 3;
			Y:	INT := 2;
			aIntArray:	ARRAY[1..X, 1..Y] OF INT						:= [ (X*Y)(1) ];
			aIntArray:	ARRAY[1..X] OF ARRAY[1..Y] OF INT 	:= [ (X)( [ (Y)(1) ] )];	
			aIntArray:	ARRAY[1..(2*X)] OF INT 							:= [ (X-Y)(1), X(1), Y(1) ];

		-structs
			aStruct:		ARRAY [0..5] OF ST_Struct := 	[ 
								4((xBool := TRUE)),							//note: 4 times the struct so you get double brackets:  4(())
								(xBool := TRUE, lrReal := 5.0)	];
		-functionblocks
			aFb_Test: 		ARRAY [0..1] OF FB_Test := [ 
								2((p_Prop := 5, iVar := 2, iIn := 6, iOut := 9))	];

		-functionblocks with fb_init, also initialising properties:
			aFb_Test:		ARRAY [0..1] OF FB_Test(-1) := [ 2((p_Prop := 10)) ];


protection levels:
	PUBLIC			>> Access for everyone
	PRIVATE		>> Access is restricted to the program, function block, or GVL.
	PROTECTED	>> Access is restricted to the program, function block, or GVL with its derivations.
	INTERNAL		>> Access to the method is restricted to the namespace (library).

visu programming: 
	textfield variable formatting: https://infosys.beckhoff.com/english.php?content=../content/1033/tc3_plc_intro/3524724747.html#3524762891&id=
	for time use %s (don't forget to also assign onmouseup event correctly)

Attributes warnings
	sometimes this style works (in code)
		{attribute 'warning disable' := 'C0327'}
	other times only this (type definition)
		{warning disable C0327}

	Rule SA0004 cannot be disabled by a pragma or an attribute

	there are several ways to suppress warnings >> it's a mess! 	
		{analysis -0175}								>>disables analysis warning SA0175 suspicious operation on string
		{attribute 'suppress_wrn_C0410'}		>>oh nooo... the number in the warning is c5410 but this is how you disable it????
		{attribute 'no-analysis'}					>>exclude object from analysis
		{attribute 'analysis' := '-33'}				>>deactivate errors: unused variable '-27' = name already used
		{warning disable/restore xxxx}
			C0125>> ... is assigned to more than one enumeration
			C0139>> code has no effect
			C0195 / C0196>> signed to unsigned / unsigned to signed
			C0197>> implicit conversion ... possible loss of information
			C0371>> acces from external context (using for example IO_STS in a method while declared in the main body)
		
	mostly used attributes
		{region 'my private space'}  {endregion} >>just like in c# create foldable blocks
			>>I prefer to make regions with tabs >> folding in the editor is based on tabs!
		{info 'shows this text as info during compiling'}
		{warning 'shows this text as warning during compiling'}
		{error 'shows this text as error during compiling'}
		{attribute 'qualified_only'}				//forces the user to add the DUT name in front of the variables (needed if for example 2 enum structs have the same keys)
		{attribute 'displaymode':='bin'}		//or 'dec' or 'hex' forces said display mode of the variable during monitoring
		{attribute 'global_init_slot':= 'x'}	//determines which blocks get initialised first. Globals have a adefault value of 49990 and POU's 50000
		{attribute 'hide'}							//hides block in a library from a project and hide from online view
		{attribute 'hide_all_locals'}			//hides local variables for online view
 
	property attributes
		{attribute 'monitoring':='call'}			//Forces during monitoring the get property is executed so a value can be seen (otherwise no monitoring of values when you looking at them online)

	program attributes
		{attribute 'no_explicit_call' := 'do not call this POU directly, because ...'}

//interesting new features of tc3
TYPE REFERENCE		
	>> use if you want to pass by reference instead of value, and the type is known
			input assignment: "REF=[instance]" instead of ":=[value]"   !!!CRASH if this is done wrong!!!
			__ISVALIDREF(myVar) >> returns true if a valid reference is supplied
	>> Probably easier to just use VAR_INOUT >> behaves exactly the same way, but this requires the user to assign something to these inputs, the reference type is declared in VAR_INPUT and can be left unassigned !!!CRASH if never assigned and used in the block!!!
		*you still can run into the same crash with a VAR_INOUT variable if it is used in a method and this method is called before the block call (where the IO must be assigned and from that point on no crashes).
		These are the pesky IO-warnings you get during build > solve these warnings or face the consequences!!!

TYPE ANY					
	>> use if you need to do pointer stuff
	Type "Any" is better than "Pointer To" ,  at assigning the input you can just pass the instance.  No need for ADR() and SIZEOF() what would be needed @ type: POINTER TO XXX
		Example: utl_ANY_Reset(HMI.ERRORS);

BIT SET/RESET
	myBool S= myOtherbool; //sets mybool if myOtherbool is true
	myBool R= myOtherbool; //Reset

CONDITIONAL OPERATORS
	OR_ELSE >> stop checking other conditions at the first true. c# ~ ||
	AND_THEN >> stop checking other conditions at the first false. c# ~ &&   >>example prevent BSOD: IF (ptr <> 0 AND_THEN ptr ^ = 99) THEN...  you don't need to nest after the null check

FB_Init
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


Communication between 2 plc's via eap
	https://www.plccoder.com/communicating-between-beckhoff-controllers-via-eap/
	*alternatively use ADS with BknLibrary.utl_AdsSymbolRead


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

		Basic types not recognised anymore by the compiler
			>> did you remove the tc3_Module reference from the references?? Thats forbidden...
			   *After re-adding it still required some fiddling around to get it working again. >> clean all, clean windows temp, clean tmc, if needed remove task re-add task,..
	
		
	
	
	Fixed by beckhoff:
	T_MaxString == FORBIDDEN TO USE FOR HMI VARS. Just use "myString:STRING(255);" instead.
		The new beckhoff symbolic ads way of using variables, does not play nice with T_Maxstring! This is an understatement... It will do BAD things to your plc memory.
		*beckhoff fixed this on my request :) >> use a recent twincatAds.dll / nuget twincat ads-package

	4026.14 check all library: lots of c0090 / c0086 / c0077 visu errors.  Don't know why.....
