#!/bin/bash
##############################################################################
#
#   Purpose:
#     Parse command line arguments into an associative array and preserve their
#     positioning via a regular array.  There are essentially two
#     classes of arguments: options and arguments.  Options control behavior
#     while arguments identify the objects as targets of a command
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its descendants.
#
#   Input:
#     $1 - Variable name to a standard array containing the option/argument
#          values passed from the command line.
#     $2 - Variable name to standard array which will contain 
#          associative array keys ordered by their position
#          in command line.
#     $3 - Variable name to associative array which will contain
#          argument values and be keyed by either the option
#          label or "ArgN" for arguments that don't immediately
#          follow an option.  Where "N" is the argument's position
#          relative to other arguments.
#     $4 - (optional or '') Variable name to a standard array enumerating
#          options that can be used more than once on the command line.
#     $5 - (optional or '') Token type to assign to a single - surrounded
#          by whitespace.  
#  
#   Output:
#     $2 - Variable name to standard array which will contain 
#          associative array keys ordered by their position
#          in command line.
#     $3 - associative array which will contain
#          argument values and be keyed by either the option
#          label or "ArgN" for arguments that don't immediately
#          follow an option.
#
#   Return Code:     
#     When Failure: 
#       Indicates unknown parse state or token type.
#
###############################################################################
argp_parse() {
  local -r cmmdLnArgListNm="$1"
  local -r argumentListNm="$2"
  local -r argumentMapNm="$3"
  local -A optionRepeatMap
  local optionRepeatCheckFun=''
  if [ -n "$4" ]; then
    argp__opt_repeat_map_init 'optionRepeatMap' "$4"
  fi
  if (( ${#optionRepeatMap[@]} > 0 )); then
    optionRepeatCheckFun=' argp__option_repeat_check optionRepeatMap optionName'
  fi
  local -r optionRepeatCheckFun
  local singleDashTokenClass='BeginArgs'
  if [ "$5" == 'Argument' ]; then singleDashTokenClass='Argument'; fi
  local -r singleDashTokenClass
  eval local -r tokenMaxCnt=\"\$\{\#$cmmdLnArgListNm\[\@\]\}\"
  local tokenClass
  local tokenValue
  local -i argumentCntr=1
  local -i argumentListIx=0
  local stateCurr='stateOptArg'
  local -i tokenIx
  for (( tokenIx=0 ; tokenIx < tokenMaxCnt ; ++tokenIx )); do
    eval local tokenValue=\"\$\{$cmmdLnArgListNm\[\$tokenIx\]\}\"
    argp__token_class "$tokenValue" "$singleDashTokenClass" 'tokenClass'
    case "$stateCurr" in
      stateOptArg)
        if [ "$tokenClass" == 'Option' ]; then
           argp__option_split "$tokenValue" 'optionName' 'optionValue'
          $optionRepeatCheckFun
          eval $argumentMapNm\[\"\$optionName\"\]=\"\$optionValue\"
          eval $argumentListNm\[\$argumentListIx\]=\"\$optionName\"
          (( ++argumentListIx ))
          if [ -z "$optionValue" ]; then stateCurr='stateOption'; fi
        elif [ "$tokenClass" == 'Argument' ]; then
          eval $argumentMapNm\[\"Arg\$argumentCntr\"\]=\"\$tokenValue\"
          eval $argumentListNm\[\$argumentListIx\]=\"Arg\$argumentCntr\"
          (( ++argumentListIx ))
          (( ++argumentCntr ))
        elif [ "$tokenClass" == 'BeginArgs' ]; then
          stateCurr='stateArgOnly'
        else return 1; fi
        ;;
      stateOption)
        if [ "$tokenClass" == 'Option' ]; then
           argp__option_split "$tokenValue" 'optionName' 'optionValue'
          $optionRepeatCheckFun
          eval $argumentMapNm\[\"\$optionName\"\]=\"\$optionValue\"
          eval $argumentListNm\[\$argumentListIx\]=\"\$optionName\"
          (( ++argumentListIx ))
          if [ -n "$optionValue" ]; then stateCurr='stateOptArg'; fi
        elif [ "$tokenClass" == 'Argument' ]; then
          eval $argumentMapNm\[\"\$optionName\"\]=\"\$tokenValue\"
          stateCurr='stateOptArg'
        elif [ "$tokenClass" == 'BeginArgs' ]; then
          stateCurr='stateArgOnly'
        else return 1; fi      
        ;;
      stateArgOnly)
        eval $argumentMapNm\[\"Arg\$argumentCntr\"\]=\"\$tokenValue\"
        eval $argumentListNm\[\$argumentListIx\]=\"Arg\$argumentCntr\"
        (( ++argumentListIx ))
        (( ++argumentCntr ))
        ;;
      *) return 1 ;;
    esac
  done
}
###############################################################################
#
#   Purpose:
#     Given an array and corresponding map of options and arguments, 
#     produce a result array and map that are reflective of only the
#     options/arguments and their values selected by a boolean expression
#     passed as a filter to this routine.
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its decendents.
#
#   Inputs:
#     $1 - Variable name of array containing list of option and argument labels.
#     $2 - Variable name of corresponding associative map potentially 
#          containing option/argument values.
#     $3 - Variable name of array to receive filtered list of option and
#          argument labels.  Position reflects the ordering of the original
#          array $1.
#     $4 - Variable name of map to receive the filtered option/argument values.
#     $5 - A bash boolean expression passed into this routine.  Typically
#          encapsulated in single quotes.
#          Ex: The following expression includes any option that isn't
#              a dlw option:'( [[ "$optArg"  =~ ^-[^-].*$ ]] || [[ "$optArg"  =~ ^--.*$ ]] ) && ! [[ "$optArg"  =~ ^--dlw.*$ ]]'
#     $6 - A boolean valuethat determines if the filter
#          specified by $5:
#            'true' -  When the expression evaluates to true, include the
#                      option/argument in the result.
#            'false' - When the expression evaluates to true, exclude the
#                      option/argument from the result.
#  
#   Outputs:
#     When Failure: 
#       Either it silently fails or causes a bash scripting error.
#     When Success:
#       The passed array variables $3 & $4 contain only those options matching
#       the provided filter.
#
###############################################################################
argp_options_args_filter() {
  local optArgListNm="$1"
  local optArgMapNm="$2"
  local optArgListMmNew="$3"
  local optArgMapNmNew="$4"
  local filterExpression="$5"
  local includeFilter="$6"
  local branchThen='true;'
  local branchElse='continue;'
  if ! $includeFilter; then
    branchThen='continue;'
    branchElse='true;'
  fi
  eval local -r optionList_np=\"\$\{$optArgListNm\[\@\]\}\"
  local optArg
  for optArg in $optionList_np
  do
    eval \i\f $filterExpression\;\ \t\h\e\n\ $branchThen \e\l\s\e $branchElse \f\i
    eval $optArgListMmNew\+\=\(\"\$optArg\"\)
    eval $optArgMapNmNew\[\"\$optArg\"\]\=\$\{$optArgMapNm\[\"\$optArg\"\]\}
  done
}

###############################################################################
# Private functions below.
###############################################################################

###############################################################################
#
#   Purpose:
#     Examines the current token to determine its token class:
#       1. 'Option'    - an option: begins with '-' is immediately followed
#                        one or more characters that aren't whitespace.
#       2. 'BeginArgs' - end of option/begining of only arguments indicator:
#                        equals only: '--' or '-'
#       3. 'Argument'  - otherwise its considered an argument.
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its decendents.
#
#   Input:
#     $1 - Token value: can be an entire option, argument or directive like '--' 
#     $2 - Token class assigned to a '-' surrounded by whitespace. It can be
#          configured as BeginArgs or as an 'Argument'. 
#     $3 - Variable name to return the determined class for the current token.
#  
#   Output:
#     $3 - Variable name will be assigned token class.
#
###############################################################################
argp__token_class () {
  local -r tokenValue="$1"
  local -r singleDashTokenClass="$2"
  local -r tokenClassNM="$3"
  # default classification is 'Argument'
  eval $tokenClassNM\=\'Argument\'
  if [ "${tokenValue:0:1}" == '-' ]; then
    if [ "${tokenValue}" == '--' ] ; then 
      eval $tokenClassNM\=\'BeginArgs\'
    elif [ "${tokenValue}" == '-' ]; then
      eval $tokenClassNM\=\"\$singleDashTokenClass\"
    else
      # begins with a dash but isn't just a dash :: 'Option'
      eval $tokenClassNM\=\'Option\'
    fi
  fi
}
###############################################################################
#
#   Purpose:
#     Extract option name and potentially it's associated value from token
#     classified as an option.
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its decendents.
#
#   Input:
#     $1 - Token string.
#     $2 - Variable name that will be assigned the option's name.
#     $3 - Variable name that might contain a value.
#  
#   Output:
#     $2 - Variable name containing the option's name.
#     $3 - Variable name that might contain a value.
#
###############################################################################
argp__option_split () {
  local -r tokenValue="$1"
  local -r optionNameNM="$2"
  local -r optionValueNm="$3"
  local -r name_np="${tokenValue%%=*}"
  local -r value_np="${tokenValue:${#name_np}+1}"
  eval $optionNameNM=\"\$name_np\"
  eval $optionValueNm=\"\$value_np\"
}
##############################################################################
#
#   Purpose:
#     Initialize map of option names that can be repeated on the command line.
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its descendants.
#
#   Input:
#     $1 - Variable name referring to a bash map representing an
#          an option repeat list.  The map associates the option name
#          with its current repetition count.
#     $2 - Variable name referring to a list of options that may 
#          appear more than once on the command line.
#  
#   Output:
#     $1 - Bash map now updated to reflect the options that can repeat with
#          current occurrence count initialized to 1.
#
###############################################################################
argp__opt_repeat_map_init(){
  local -r optionRepMap_ref="$1"
  local -r optionRepList_ref="$2"
  eval local \-r repLstMax\=\"\$\{\#$optionRepList_ref\[\@\]\}\"
  for (( ix=0; ix < repLstMax; ix++ )); do
    eval let $optionRepMap_ref\[\"\$\{$optionRepList_ref\[\$ix\]\}\"\]\=1
  done
}
##############################################################################
#
#   Purpose:
#     Determine if named option can be repeated.  If so, then format the option
#     name: <optionName>=<repetitionCount>.  RepetitionCount starts at 1.
#     given option named "-c" its first named occurrence would be '-c=1'
#
#   Assumption:
#     Since bash variable names are passed to this routine, these names
#     cannot overlap the variable names locally declared within the
#     scope of this routine or its descendants.
#
#   Input:
#     $1 - Variable name referring to a bash map representing an
#          an option repeat list.  The map associates the option name
#          with its current repetition count.
#     $2 - Variable name referring to the option name, which includes 
#          '-' and '--' prefixes and will be applied as a key for $1 
#  
#   Output:
#     $1 - Bash map may be updated to reflect new repetition count.
#     $2 - Option name, if it appears in the map, will be renamed
#          to reflect its repetition instance.
#
###############################################################################
argp__option_repeat_check(){
  local -r optionRepMap_ref="$1"
  local -r optionName_ref="$2"
  eval local \-r repeatTotal\=\"\$\{$optionRepMap_ref\[\"\$$optionName_ref\"\]\}\"
  if [ -z "$repeatTotal" ]; then return; fi
  eval let $optionRepMap_ref\[\"\$$optionName_ref\"\]\+\+
  eval $optionName_ref=\"\$$optionName_ref\=\$\{repeatTotal\}\"
}
###############################################################################
#
# The MIT License (MIT)
# Copyright (c) 2014-2020 Richard Moyse License@Moyse.US
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###############################################################################

