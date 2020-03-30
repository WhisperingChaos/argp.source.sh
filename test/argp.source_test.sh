#!/bin/bash
source "./argp.source_test_sh/base/MessageInclude.sh";
source "./argp.source_test_sh/base/argp.source.sh";
source "./argp.source_test_sh/base/ArrayMapTestInclude.sh";

argp_cmd_serialize_test(){
	
	argp_cmd_serialize_direct_test

	argp_cmd_serialize_indirect_test
	
}


argp_cmd_serialize_direct_test(){

	local -a optArgList
	argp_cmd_serialize 'optArgList' "-a" "-b" "--purge" "-cde" "Arg1"
	ArrayAssertValues $LINENO 'optArgList' '-a' '-b' '--purge' '-cde' 'Arg1'

	unset optArgList
	local -a optArgList
	argp_cmd_serialize 'optArgList' "-a=bb" "--back=back" "--path" "./abc/def.txt" "--purge" "-cde" "Arg1"
	ArrayAssertValues $LINENO 'optArgList' '-a=bb' '--back=back' '--path' './abc/def.txt'   '--purge' '-cde' 'Arg1'
	
	unset optArgList
	local -a optArgList
	argp_cmd_serialize 'optArgList' '"-a=bb"' 'a"b' "a'b"
	ArrayAssertValues $LINENO 'optArgList' '"-a=bb"' 'a"b' 'a'"'"'b'
}


argp_cmd_serialize_indirect_test(){

	local -a optArgList

	local -r varExpansion='$expanededOptExpected'
	local -r expanededOptExpected='abort-double-expansion-occurred'
	argp_cmd_serialize_call_test 'optArgList' "--$varExpansion=hello" "-a" "--help" 
	ArrayAssertValues $LINENO 'optArgList' '--$expanededOptExpected=hello' '-a' '--help'

}


argp_cmd_serialize_call_test(){

	argp_cmd_serialize "$@"
}


###############################################################################
##
##  Purpose:
##    Test Option/Argument parsing algorithm.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function ArgumentsParseTest () {
  function ArgumentsParseTestCmmdLn () {
    function main () {
      declare -A ArgMap
      declare -a ArgList
      VirtArgumentsParseTest_Desc 
      if ! argp_parse 'mainArgumentList' ArgList ArgMap ; then ScriptUnwind $LINENO "Expected success but encountered failure"; fi
      VirtArgumentsParseTest_Audit 
    }
    source "./argp.source_test_sh/base/ArgumentsMainInclude.sh";
  }
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 1: 2 short options followed by 1 long one."
    echo "$FUNCNAME Test 1:   then a compound short option with an associated value"
    echo "$FUNCNAME Test 1:   ending with a single stand alone argument" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '-b' '' '--purge' 'yes' '-cde' 'hello there' 'Arg1' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' '-b' '--purge' '-cde' 'Arg1'
    echo "$FUNCNAME Test 1: Successful"
  }
  ArgumentsParseTestCmmdLn -a -b --purge=yes -cde="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo 
    echo "$FUNCNAME Test 2: 2 short options followed by 1 long one then '--' to force"
    echo "$FUNCNAME Test 2:   remaining arguments to be treated as plain arguments even though"
    echo "$FUNCNAME Test 2:   they may start with hypnens"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '-b' '' '--purge' 'yes' 'Arg1' '-abc=hello there' 'Arg2' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' '-b' '--purge' 'Arg1' 'Arg2'
    echo "$FUNCNAME Test 2: Successful"
  }
  ArgumentsParseTestCmmdLn -a -b --purge=yes -- -abc="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 3: 1 short option followed by '-' to force"
    echo "$FUNCNAME Test 3:   remaining arguments to be treated as plain arguments even though"
    echo "$FUNCNAME Test 3:   they may start with hypnens" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' '-abc=hello there' 'Arg2' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1' 'Arg2'
    echo "$FUNCNAME Test 3: Successful"
  }
  ArgumentsParseTestCmmdLn -a - -abc="hello there" mysql
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 4: 1 short option and '-'at end"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' ''
    ArrayAssertValues $LINENO 'ArgList' '-a'
    echo "$FUNCNAME Test 4: Successful"
  }
  ArgumentsParseTestCmmdLn -a -
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 5: Argument list: '-a - :'"
    echo "$FUNCNAME Test 5: 1 short option followed by the - to force the remaining" 
    echo "$FUNCNAME Test 5: tokens to be interperted as agruments."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' ':'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1'
    echo "$FUNCNAME Test 5: Successful"
  }
  ArgumentsParseTestCmmdLn -a - :
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 6: Argument list: '-a -- -t -abc=\"5\" --'"
    echo "$FUNCNAME Test 6: 1 short option followed by '--' to force the remaining" 
    echo "$FUNCNAME Test 6: tokens to be interperted as agruments."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' 'Arg1' '-t' 'Arg2' '-abc=5' 'Arg3' '--'
    ArrayAssertValues $LINENO 'ArgList' '-a' 'Arg1' 'Arg2' 'Arg3'
    echo "$FUNCNAME Test 6: Successful"
  }
  ArgumentsParseTestCmmdLn -a -- -t -abc="5" --
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 7: Argument list: '-a --purge =\"no\"'"
    echo "$FUNCNAME Test 7: 1 short option followed by a long option with whitespace"
    echo "$FUNCNAME Test 7: between the long option and assignment operator." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '' '--purge' '="no"'
    ArrayAssertValues $LINENO 'ArgList' '-a' '--purge'
    echo "$FUNCNAME Test 7: Successful"
  }
  ArgumentsParseTestCmmdLn -a --purge =\"no\"
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 8: Argument list: '=no'"
    echo "$FUNCNAME Test 8: 1 argument." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' 'Arg1' '=no'
    ArrayAssertValues $LINENO 'ArgList' 'Arg1'
    echo "$FUNCNAME Test 8: Successful"
  }
  ArgumentsParseTestCmmdLn =no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 9: Argument list: '-- =no'"
    echo "$FUNCNAME Test 9: 1 argument." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' 'Arg1' '=no'
    ArrayAssertValues $LINENO 'ArgList' 'Arg1'
    echo "$FUNCNAME Test 9: Successful"
  }
  ArgumentsParseTestCmmdLn -- =no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 10: Argument list: '-a==no'"
    echo "$FUNCNAME Test 10: 1 option" 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a' '=no'
    ArrayAssertValues $LINENO 'ArgList' '-a'
    echo "$FUNCNAME Test 10: Successful"
  }
  ArgumentsParseTestCmmdLn -a==no
  function VirtArgumentsParseTest_Desc () {
    echo
    echo "$FUNCNAME Test 11: 2 short options followed by 1 argument."
    echo "$FUNCNAME Test 11:   Arguments are separated by commas"
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-a,' '' '-b,' '' 'Arg1' 'mysql'
    ArrayAssertValues $LINENO 'ArgList' '-a,' '-b,' 'Arg1'
    echo "$FUNCNAME Test 11: Successful"
  }
  ArgumentsParseTestCmmdLn  -a, -b, -- mysql
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 12: 1 long option that encapsulates another command."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlw' 'hi --dlw=\"hello there\" bye'
    ArrayAssertValues $LINENO 'ArgList' '--dlw'
    echo "$FUNCNAME Test 12: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlw='hi --dlw=\"hello there\" bye'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 13: 1 long option that includes single quote."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlw' "hi --dlw=hello' there bye"
    ArrayAssertValues $LINENO 'ArgList' '--dlw'
    echo "$FUNCNAME Test 13: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlw="hi --dlw=hello' there bye"
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 14: 1 long option that encapsulates another command using double quotes and delimits with \ "
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlw=\"hello there bye\""
    ArrayAssertValues $LINENO 'ArgList' '--dlwc'
    echo "$FUNCNAME Test 14: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc='watch --dlw="hello there bye"'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 15: 1 long option that encapsulates another command with an option '-o' using double quotes and delimits encapsulated double quotes with backslash."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlw=\"hello -o bye\""
    ArrayAssertValues $LINENO 'ArgList' '--dlwc'
    echo "$FUNCNAME Test 15: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc='watch --dlw="hello -o bye"'
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 16: 3 long options.  One option encapsulates another command with both options and arguments using double quotes and delimits encapsulated double quotes with backslash.  While the other two options simply follow this third complex one." 
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '--dlwc' "watch --dlwc=\"images -a\"" '--dlwno-exec' '' '--dlwshow' ''
    ArrayAssertValues $LINENO 'ArgList' '--dlwc' '--dlwno-exec' '--dlwshow'
    echo "$FUNCNAME Test 16: Successful"
  }
  ArgumentsParseTestCmmdLn  --dlwc 'watch --dlwc="images -a"' --dlwno-exec --dlwshow
  function VirtArgumentsParseTest_Desc () {
    echo "$FUNCNAME Test 17: using echo without encapsulating with quotes may gobble options like '-n' used by echo."
  }
  function VirtArgumentsParseTest_Audit () { 
    AssociativeMapAssertKeyValue $LINENO 'ArgMap' '-n' '20'
    ArrayAssertValues $LINENO 'ArgList' '-n'
    echo "$FUNCNAME Test 17: Successful"
  }
  ArgumentsParseTestCmmdLn -n 20
}
###############################################################################
##
##  Purpose:
##    Test the routine that creates a new set of option/argument list and 
##    map arrays by applying a filter expression to a set of existing ones.
##
##  Outputs:   
##    When Failure: 
##      Identifies test, line numbers and reason for failure.
##
###############################################################################
function OptionsArgsFilterTest () {
  echo "$FUNCNAME Test 1: Include only the arguments in the resulting arrays." 
  echo "$FUNCNAME Test 1:   that match the pattern: 'Arg[0-9][0-9]*'"
  unset ArgList
  unset ArgMap
  unset ArgListNew
  unset ArgMapNew
  declare -a ArgList
  ArgList+=( '--bool' )
  ArgList+=( 'Arg1' )
  ArgList+=( 'Arg2' )
  ArgList+=( 'Arg3' )
  declare -A ArgMap
  ArgMap['--bool']='true'
  ArgMap['Arg1']='Arg1'
  ArgMap['Arg2']='Arg21'
  ArgMap['Arg3']='Arg3'
  declare -a ArgListNew
  declare -A ArgMapNew
  argp_options_args_filter ArgList ArgMap ArgListNew ArgMapNew '[[ "$optArg" =~ Arg[0-9][0-9]* ]]' 'true'
  ArrayAssertValuesAll $LINENO 'ArgListNew' 'Arg1' 'Arg2' 'Arg3'
  AssociativeMapAssertKeyValue $LINENO 'ArgMapNew' 'Arg1' 'Arg1' 'Arg2' 'Arg21' 'Arg3' 'Arg3'
  echo "$FUNCNAME Test 1: Successful."

  echo "$FUNCNAME Test 2: Include only options that aren't dlw ones in the resulting arrays."
  unset ArgList
  unset ArgMap
  unset ArgListNew
  unset ArgMapNew
  declare -a ArgList
  ArgList+=( '-i' )
  ArgList+=( '-t' )
  ArgList+=( '--dlwdepnd' )
  ArgList+=( '--no-cache' )
  ArgList+=( '--dlwforce' )
  ArgList+=( 'Arg1' )
  ArgList+=( 'Arg2' )
  ArgList+=( 'Arg3' )
  declare -A ArgMap
  ArgMap['--dlwdepnd']='true'
  ArgMap['--no-cache']='true'
  ArgMap['-t']='5'
  ArgMap['Arg1']='Arg1'
  ArgMap['Arg2']='Arg21'
  ArgMap['Arg3']='Arg3'
  declare -a ArgListNew
  declare -A ArgMapNew
  argp_options_args_filter ArgList ArgMap ArgListNew ArgMapNew '( [[ "$optArg"  =~ ^-[^-].*$ ]] || [[ "$optArg"  =~ ^--.*$ ]] ) && ! [[ "$optArg"  =~ ^--dlw.*$ ]]' 'true'
  ArrayAssertValuesAll $LINENO 'ArgListNew' '-i' '-t' '--no-cache'
  AssociativeMapAssertKeyValue $LINENO 'ArgMapNew' '-i' '' '-t' '5' '--no-cache' 'true'
  echo "$FUNCNAME Test 2: Successful."
}
###############################################################################
##
##  Purpose:
##    Unit test functions defined in the ArgumentsGetInclude.sh.
##
###############################################################################
function main (){
	if ! argp_cmd_serialize_test;       then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! ArgumentsParseTest;            then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
  if ! OptionsArgsFilterTest;         then ScriptUnwind $LINENO "Unexpected return code: '$?', should be '0'"; fi
}
FunctionOverrideIncludeGet
main
exit 0;
