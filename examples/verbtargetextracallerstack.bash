#!/usr/bin/env bash
#
# generate some functions in "verb_target_extra{_extra,...}" format
#
# XXX - "stack" is not right, need a depth tracking wrapper with a counter for indent level
# XXX - increment n, filter functions and add caller as necessary
# XXX - should verb be action? action-target-options? important!
#
# this can be used to get and use function-name-encoded info with a standarized naming scheme
# - like package name at runtime using function name
# - or "what to do"
# - if this is "install" with "name1", do this, if it's "name2" do this other thing
#
# useful funcs
# - {get,has}{verb,target,extra}
#
# also show caller info and stack here and there
#
# recursion detection - loop too... hmmmmmm...
#
# splicing into functions:
# - "call func args"
# - wrapper, check for flag
# - should probably check that something is actually a function with declare, otherwise just eval?
# - "save old func" should probably save the body only
#   - declare -a newfunc=()
#   - mapfile -t newfunc < <(declare -p func)
#   - unset newfunc[$((${#newfunc[@]}-1))] # delete last '}'
#   - shift # get 'funcname () '
#   - shift # get first '{'
# - probably need a "wrapper wrapper" that just prints the new function with amendments
#   - would allow replacements
#   - func -> newfunc -> func=newfunc -> delete newfunc
#   - with callbacks/callhook below...
#   - could use for e.g. a package to tell upstream "if you install yourself, upgrade me too"
#   - no special handling, just throw a check in a function or an overrides dir that's sourced
# - if flag, save function, insert code...
#   - like to show stack...:
#   - { printf "%$((${#FUNCNAME[@]}*2))s" ; printf " * ${FUNCNAME[0]} : ${@}" ; } 1>&2
#     -or { l=${#FUNCNAME[@]} ; for i in ${!FUNCNAME[@]} ; do e=$(((${i}+1)%${l})) ; printf "%$((${e}*2))s" ; echo "* ${FUNCNAME[${i}]}" ; done ; } | tac 1>&2
#   - "eval newfunc argument1 argument2 ..."
#   - restore oldfunc
#   - delete newfunc
#
# variables and functions can be named the same thing
# - essentially getter/setter/...
# - useful for object oriented stuff?
# - could dump, eval-able var[#]="${v[${n}}" in iteration
# - serialize, deserialize, append, prepend, insert, ...
# - rehydrate self???
#   - save the var with declare -p
#   - then the func with declare -f
#   - store in hash as deserialized object/state/whatever with known keys
#   - type tracking...
#   - for nested types, need type - really only need to handle:
#     - hash  of hashes : hh
#     - hash  of arrays : ha
#     - hash  of values : hv
#     - array of hashes : ah
#     - array of arrays : aa
#     - array of values : av
#       - everything else should be composable
#       - i.e. a hash of hashes of arrays of hashes of an array of values -> hh, ha, ah, ha, av
#       - given a spec: hh[ha[hv[..]]] generate type_..._function automatically
#   - could be a parser/virtual cpu,,, see the mess below
#   - case/esac would be better here but ehhh
#   - pass custom-format storage to function to modify the variable
#     - might need a wrapper to setup type detection/behavior...
#     - recursively iterate through structure and build out state hashes via type information below
#     - track type, depth, ..., via : / , _ separators
#     - "hashname['top']['sub'][#]" hh[ha[av]]] - set/get the element at list position # from within the sub hash, which is in the top hash
#     - "listname[#]['homedir']" ah - given a uid #, get/set the homedir from that accounts stored hash
#   - "varfuncwrapper create varfuncname type/schema array/hash/.../definition function/definition"
#   - hha -> hh[ha[av]] expansion/setup
#   - varfunc has get/set/serialize/deserialize/eval/... by default
#   - base64 encode internally?
# - hmm, little example:
#     #!/usr/bin/env bash
#     # unset varfunc ; unset -f varfunc
#     # { declare -p varfunc ; declare -f varfunc ; } 2>/dev/null
#     # declare -a varfunc=( zero one two )
#     # { declare -p varfunc ; declare -f varfunc ; } 2>/dev/null
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two")
#     function varfunc() {
#       local v=${FUNCNAME[0]}
#       { test $# -eq 0 && cmd=id ; } || { cmd=$1 ; shift ; }
#       { test $cmd == append && while $(test $# -ne 0) ; do eval "${v}+=( \"$1\" )" ; shift ; done ; } \
#       || { test $cmd == serialize && declare -p ${v} ; } \
#       || { test $cmd == id && echo this is $v ; }
#     }
#     # varfunc
#     this is varfunc
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two")
#     # varfunc append three
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three")
#     # varfunc four five
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three")
#     # varfunc append four five
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three" [4]="four" [5]="five")
#     # varfunc append "six seven" eight "nine ten"
#     # varfunc serialize
#     declare -a varfunc=([0]="zero" [1]="one" [2]="two" [3]="three" [4]="four" [5]="five" [6]="six seven" [7]="eight" [8]="nine ten")
#
# - could also be used as a recursive/type thing
#   - storage, state, and... other
#   - json, yaml, toml, etc.
#   - building evalable nested data structures
#     - function type_ha_func() { # do something related to a hash of arrays ; }
#     - function type_ah_func() { # ditto for array of hashes ; }
#   - could generate specific datatype functions
#     - function typefuncgen() { type=${1} ; eval "function type_${type}_func() { # ... ; }" ; }
#     - need base (hash, array, value, ...) cases
#     - use a separator (_ or | or : or / or ...) to create nested structures
#       - programming language type stuff...
#       - need a depth marker as well?
#       - h: for hash
#       - a: for array, below?
#         - l: for list?
#         - (evalable? {#..#}/{,}/... notation?! lol!)
#       - d:0 by default
#         - would apply to every element after set
#         - or until parser finds separator
#         - so need to track state/reset for multi-level data
#       - b: for bool flag (true/false is 0/1 in shell?, but should be b:1 if bool, default to b:0 for not)
#       - i: for integer
#         - n: for number
#         - i: for idempotent? r:?
#       - f: float
#       - r: read-only flag
#         - or raw? absolutely need a "just give me the raw representation of this, whatever it is"
#       - w: read/write flag
#       - x: execute ${encodedcommand}, needed in hash-key compat format
#         - c: for "callable"? r/w/x is more understandable
#       - e: ${varname} type to expand an environment variable
#         - (v: varname instead of "variable" in type below?)
#         - thus becoming self aware
#         - could even be _the_ base type
#         - i.e. on recursion/setting/etc. _everything_ is converted to an e:varname type and eval-ed
#         - i just invented something like dumb xml in shell script
#           - programmable since you can just store strings and everything will be eval-ed
#           - very useful! goofy!
#           - basically hungarian notation! but worse.
#       - with (h,a,...) type attached (hash, array guuhhhhhhh value/variable)
#       - create/access/eval hash
#       - ${type}_${name}[(a|h):k(/|_)...]
#         - e.g. a hash of arrays for saving function bodies would be something like
#         - ha_[h:func_a:body]
#         - h:func will be the name of a function
#         - a:body will actually just be iterated over index
#         - equivalent to var[${funcname}][#]
#       - elements can be accessed/set in env this way
#         - ${type}_${name}[h:${key}_a:${index}_...]
#         - use [(a:index0|h:hash0)/h:hash1/hash2/.../(h:hashN|a:indexN)] notation for datatypes
#         - on lookup, if that var doesn't exist, create it
#         - for loading data, have to track depth, which can also be explicitly set via d: below
#       - for storage etc use depth as well
#         - i.e. json, yaml, etc. expansion using types
#         - if a list/array print this header for this format, if header this, bool, etc.
#         - iterate through type/name/depth
#         - enables multiple representations
#           - raw shell - base
#           - json / yaml - storage
#         - requires pretty strict schema
#           - conversions into shell from storage? hard
#           - data not in the schema will be ignored (i.e., no type_######_func) or crash?
#         - if state (functions, values, counters, etc.) can be captured, shell storage could allow full replay
#           - like literally, executable function and data state is interpretable
#           - counters could register themselves as important and saved in state
#           - metadata/state element as well
#           - could send a "backup signal" to dump state...
#           - functions could be marked idempotent in copy/save/restore (or at runtime)
#         - with a parser i could build a language that "compiles to shell"
#           - or a compiler backend...
#           - or an assembler in bash...
#             - printf can write binary data: https://stackoverflow.com/questions/43214001/how-to-write-binary-data-in-bash
#             - instruction type/instruction/... value type/val1/...
#             - instruction hash that stores what to do when called with the data provided
#             - global state tracker, functions save/restore/set as needed
#           - or... an assembler FOR bash
#             - wasm for shell
#             - the shell machine
#             - just implement llvm... vm?
#             - low-level-shell
#             - could build a parser...
#               - character-by-character
#               - tokenize
#               - track depth
#               - store parsed elements w/depth+state
#               - need a simpler format than hash of hash of ... arrays/values
#               - { depth state token previous next }
#
# - virtual machine bit/byte code interpreter
#   - oh lord
#   - all things are possible in parsers
#   - bitness? 8 is minimum _usable_, might be too slow even for that. 32-bit tho...
#   - build a tower of interpreters? i.e., 8-bit machine in posix shell, 16-bit, 32-bit, ...
#   - 8-bit vm -> assembler -> compiler -> 16-bit vm -> assembler -> ...
#   - forth for a stack machine might be the most straightforward (see infinite stacks below, also: openboot?)
#   - get to 16-bit you can port unix+c
#     - gets a pdp-11 cross compiler for free, from there bob's your uncle
#     - could even do tcp protocols "network" with /dev/tcp, and socat for udp (or tun/tap/ptp/... ethernet frames)
#     - in backend, could use openssl, curl, etc. with a socket
#     - then pdp-11 vm
#     - then xv6 vm/port, with cross compilers and networking...
#     - then... repeat with bigger/higher-bit cpus/mems/... until you get to gcc, bsd/linux, etc.
#     - or build a real physical computer from nothing? including an operating system? are you nuts?
#     - forth idea could build a stack machine that hosts itself
#   - heirarchical machine from oisc/one instruction set computer (memory machines/transport triggered) up?
#     - start with a signal (toggle high/low), it feeds/acts as a clock that feeds two clocks (2-bit primitive program counter)
#     - 4-bit, 8-bit, 16-bit, ...
#     - stack/heap growth with big bitness/savvy enough memory model
#     - 8 bit word/byte w/memory machine tied to each address
#     - essentially a distributed set of registers "do something when this happens"
#     - could build a larger cpu with an array of these
#       - assuming we want to build an 8-bit word length
#       - X (2^8 gives us 256 8-bit/1-byte) words wide (essentially every "register" is a memory address), word length plus overhead deep
#       - each "register" (memory element) has (at least) 12+ bits (~16, for bus+overhead) as its control "cpu"
#         - basically, essentially, at least a 4-bit cpu that's a state machine built out of gates
#         - really need sparse array...
#         - packing/padding for 8->16, etc.
#         - could have multiple banks... interrupt, etc.
#         - and/or cascading memory controllers for bitness widening
#           - memory controller controller takes row X and reads word-width columns
#           - memory controller controller reads its own message tag, figures load/store, then reads/writes rows/colums
#           - row-columns made of 256x8-bit bytes (words) of storage per element
#             - equates to 128x16-bit, or 64x32-bit, or 32x64-bit, or...
#           - columns dictate bitness - 16-bit is 2 columns, 32-bit is 4, 64 is 8, ...?
#           - rows dictate amount of total memory?
#             - total: ((2^w)*w) where w is word length
#             - 8-bit: ((2^8)*8) = 256 words of length 8-bit: 2048 (2K), 16-bit: ((2^16)*16) = 1048576 (1M), ...
#           - tricky dealing with bit widths. but "main" cpu will essentially just be bigger version of this
#           - i.e., a direct 16-bit address will have basically 16 probably 5-bit computers
#           - harvard vs von neuman? hmm
#         - memory element just idles normally checking for tags and passing bits
#         - high-level controller isa is basically
#           - load memoryaddress
#           - store number at memoryaddress
#           - to talk to memory elements needs a tag (register) so more state, and a "command"
#           - basically just pushing packets to a queue then popping off on memory
#         - number encoding will need bit # (1-8 / 0-7) so 3 bits (parity not a bad idea?)
#         - memory state:
#           - word (8 bits), tag (3 bits), msg (2 bits?), ready bit, in bit, out bit (16 bits...)
#           - (invisible) readonly flag for r0: always zero
#           - read packet of data
#           - if tag matches act on in bit stream and write to out bit stream (short circuit)
#           - otherwise just write in to out, which is wired up to next tagged memory element via bus
#         - for toggles, just increment since overflow - "declare -i i=0 ; ((i=(i+1)%2))"
#         - memory "register" isa:
#           - ready
#           - idle
#             - or toggle state as 1/0
#             - only allow set tag on not ready/idle
#           - set tag #
#           - set bit # to 0
#           - set bit # to 1
#           - conditional set bit # (0 if set, 1 if not? is toggle?)
#           - toggle bit # (read bit, increment via toggle above, write bit)
#           - 0 all
#           - 1 all
#           - invert
#           - xor
#           - nop
#           - shift left
#           - shift right
#           - read bit / byte / word # (load)
#           - write bit / byte / word # (store)
#         - "bus" related commands - should be covered by read/write but will also need completion acknowledgement
#           - don't need sign (or bcd?) for memory controller/register - it's just storing bits
#           - readbus/writebus handlers - each memory element is essentially a vampire tap that runs a little machine to operate on bits in a word
#           - iterate through stream, checking tag
#           - input/output can be queues
#             - shift off first element
#             - read a "packet" - msg tag, element tag
#             - if not for us, continue
#             - pc here can be 8-bit, 0-255, with second 8-bit map which indicates which memory register tags are in flight 0/1
#             - read tag once, compare per clock, act accordingly (not realistic but faster than reading an entire queue of stuff
#           - check tag - if match, do instruction and ack
#           - reset, acknowledge, resend, etc.
#           - register tags with target in instruction encoding
#           - memory controller sends, register acts, drops response onto bus, controller receives
#           - memory controller state? flag register? ...???
#           - each message also has a tag
#             - how big? just use pc? one instruction per clock?
#             - 3-bits means there could always be something for every address... (i.e. refresh tag# to simulate ddr ;D)
#             - 4-bits means you can do "global" flag - every register should do this
#           - send: memtag#:msgtag#:encodedinstruction
#           - receive: msgtag#:encodedresponse - 11-bits or more
#             - need memtag#? will be "first acknowledged" since we dump to bus
#           - should memory registers be able to latch the bus? "process message # right now (just shift off packet), then unlatch"
#             - essentially locking, would probably need "commands" back to controller in message response, act accordingly in controller
#             - would open up length tag - i.e., start processing and don't stop until you've done X things
#             - memory register arrays would need another pc each, 8-bit, again?
#             - detect tag -> reset memory registry pc -> start counting and pulling packets off bus
#           - controller (and memory registers) need "all tags do this?" (i.e., reset)
#           - memory register tags
#             - id for sending data to byte/register storage machine
#             - memory elements start out in ready state, all tags set to beginning sentinel (0 or 255)
#             - controller drops "tag255:settagto0 wait:tag0 tag0:idle wait:tag0"
#             - repeat for "tag255:settag1 ... tag1:idle ..."
#             - "one at a time" communication on bus - would need a proper protocol for multiplex
#             - controller state needs a bool flag (bit) for zeroed, current message tag, outstanding message, ...
#             - iterate through again zeroing all elements
#         - each of these memory "registers" also has connections to a "bus" - basically input/output (above)
#         - (could do register-register control too, with wide/deep enough bitness and decent protocol)
#         - ipl loads the higher level cpu on the oisc, which is literally just 0/1 gate
#           - it just toggles, basically acting like a clock/oscillator
#           - two downstream oisc using input from clock can create a 2 bit program counter
#           - work your way up to an 8-bit+ pc
#           - at that point you can start using your "memory" registers
#             - do it all again for the cpu to actually use that memory
#             - talking to the memory controller
#             - using another state machine, with another program counter, with a different register set, ...
#             - again, could have 256 8-bit registers but only present #
#             - need sign bit here, ... !
#             - isa is essentially encoded into lower registers - "firmware", "microcode"
#             - instruction dispatch - maps instruction to 1 to ~2+ registers
#             - another "packet" on a bus, this time the tag is the opcode
#             - variable length instructions? nah... wasteful for fixed length but significantly easier
#             - instruction has at least one sorta ghost/window register
#             - isa itself uses "raw" registers (all 256) and designates # of registers
#             - w0-w256 are raw registers
#             - w0:1 - nop (top half of register set for smuggling data?), w2:3 add family, w4:5 jump, branch, ...
#             - r0: always zero, r1-r#: general purpose, ..., what else? look at mips/risc-v/openrisc/...?
#             - state machine control flow uses pc/ip/stack/... for execution
#             - stack grows down from "top (last)" register
#             - heap is separate memory array described above
#           - isa
#             - load / store
#             - add / sub
#             - push / pop
#             - jmp / jne / jz / etc.
#             - cmp / cas / etc.
#             - bra?
#             - mul/div implemented on add/sub?
#             - ... many more
#       - base on 680x/650x (8b data, 16b address)? 8008 (8b,14b)/8080 (8b,16b)? z80 (8b,16b)?
#       - 16b: 65c816 (8b external/16b internal/24b address)? ...
#       - kinda like the belt cpu?
#       - kinda like the barrel cpu?
#       - kinda like conway's game of life?
#       - kinda like computing from nothing but a switch?
#       - kinda like bootstrapping the universe?
#   - could essentially implement a load/store architecture using depth/state tracking
#   - instruction set... two or three operand... 2 or 3 operand...
#   - calling convention (higher level - callee or caller saves/restores?)
#   - register, memory, opcode dispatch, character display, ... arrays
#   - how many registers?
#   - stacks for each register
#     - or hash of lists for state of registers?
#     - either way a push/pop to save state is relatively easy
#       - would need to do a copy for something like this to work
#       - save: for r in ${!register[@]} ; do r[${#r[@]}]="${r[$((${r[${#r[@]}-1))]}" ; done
#       - restore: for r in ${!register[@]} ; do unset r[${#r[$((${#r[@]}-1))]}] ; done
#       - would need a state tracker here too - a counter? latching?
#       - serialize register set, push, increment / pop, deseralize, decrement?
#       - "infinite stack"
#         - stack pointer, basically
#         - save: copy the top # elements to end of list, increment counter
#         - restore: remove last # elements of list, decrement counter
#       - could combine these to have multiple processor states...
#         - could essentially build another level of processer directly in ISA
#         - i.e. 2x8-bit states and mux/carry/etc. flags could allow for a 16-bit alu
#         - overflow/carry/etc. trigger state swap
#         - bitslice idea all over again
#           - memory bank... internal and external busses
#           - internal bus is tag:message:opcode in/message:signal (flags) back to mc
#           - external bus - propagate carry/remainder/overflow
#           - 256x8 (2KB) could be wired up serially to
#           - dual port? memory controller per bank with go/nop flag
#           - pause downstreams as control is transfered between banks
#           - memory controller controller reads external bus and directs traffic from bank to bank based on state
#   - clock, program counter, stack, stack pointer, instruction pointer, interrupts, ...
#   - overflow detection, remainder, etc.
#     - test "${register[r#]}" -gt 255 # overflow detected; interrupt, etc.
#     - $((${register[r#]}%256)) # remainder, set flag, etc.
#   - queue for instructions?
#   - host/vm socket communication: at least stdin/stdout/stderr; need bidirectional multiplexed?
#   - could "freeze" whole machine using state stuff above
#   - like... save the vm program itself along with state, it's literally a shell script
#   - could keep a bit of program counter history to read the next instruction, rollback and dump
#   - "memory pointers" et al for indirection/instruction set/memory model
#     - i.e. one level of indirection: "load what is at the memory address in memory[#] into register[#]"
#     - "load what's on top of stack into register[#]" or "memory[#]" or "register-to-register" or "stack into memory at address stored at memory[#]"
#     - "load r1,r2" register-register; "load si,r3" stack indirect, "store mi,st" memory indirect to top of stack; ...
#     - load relative to r#/m#/...?
#   - memory... byte addressed or word addressed (or both, byte@ is splice into word@, halfword for 16-bit+?) or bit addressed or linear or...
#   - memory protection/mmu? tagged, content-addressible, ... memory? whoa
#     - memory register windows w/content-addressible - give me byte @ #, two bytes (16-bit word) at ##, 32-bit word at ####, ...
#     - word, halfword, nibble, byte, long, long long, ...
#   - endianness???
#   - pause machine (background lol)
#   - debug/monitor - eval individual instructions
#     - pause / single step / etc.
#     - register/stack/pc display
#   - small virtual assembly language for main cpu
#   - "enough for c"
#   - assembler first
#   - output stuff to console, that's it, branch forever, etc.
#   - linker/loader. boyyyyyyy.
#   - intermediate languages...
#   - work up to c...
#   - c compiler targeting virtual assembly
#   - "dump state" for image is very lisp-y
#   - boiling the oceans
#
# - callbacks?
#   - crosware...
#   - "applycallback func" - reify funcs after round of sourcing profile
#   - use a stack/array?
#     - global hash with serialized array of callbacks?
#       - "addcallback func 'cmd one' 'cmd two'"
#       - crosware rcallbacks=( "targetfunc 'cmd1 ; cmd2' 'second set'" "targetgfunc2 'cmd3 | cmd4'" )
#       - serialze original function to a function hash (once, based on hash key existence)
#       - check hash keys for func, initialize to empty array () if not found
#       - if found, rehydrate to temp array
#       - append any args to the array
#       - serialize and save to hash value for func key
#       - rehydrate serialized original func and append all callbacks to array
#       - eval the new function array to replace it
#   - "callback 'callback_def callback_args' func func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - shift off callback
#   - save function
#   - insert depth tracker above
#   - replace last element with "callback_def callback args"
#   - "eval newfunc func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - restore oldfunc
#   - delete newfunc
# - call should not call itself
#   - if function is call just, eval "${@}"
#   - same for callback, if function is callbaack, eval call "${@}"
# - "callhook 'custom pre' 'custom post' func arg1 arg2 ..."
#   - both
# - "call{insert,replace} pos# 'custom command args' func"
#   - default position to 0
#   - insert a custom command at the specified location
#     - newfunc=( $(declare -f func | getfuncbody) )
#     - newfunc[0]="function function_${RANDOM}()"
#     - for e in $(seq ${#} -1 ${i}) ; do newfunc[${e}]="${newfunc[$((${e}-1))]}" ; done
#     - newfunc[${i}]="custom command args"
#   - replace is just newfunc[${i}]="custom command args"
# - "call{prepend,append} 'custom command' func"
#   - prepend: insert at line 0 of func body
#   - append: just tack onto the end of the func body
# - "callreinplace '^bash|(-|_)regex(\.pattern|)$' 'custom replacement' func
#   - if [[ $line =~ $pattern ]] ...
# - "callbuild func 'command 1' 'command 2' 'command3 | command4'
#   - append to func body
# - passing a whole lot of function bodies around
# - could lead to self-modifying shell script, o h t h e h o r r o r
#
# useful funcs
# - variables : "varexists varname"    "vartype varname"
# - array     : "arrayexists arrayvar" "isarray arrayvary" "createarray arrayvar" "savearray arrayvar" "uniqarray arrayvar"
# - hash      : "hashexists hashvar"   "ishash hashvar"    "createhash hashvar"   "getkeys hashvar"    "haskey hashvar key" "savehash hashvar"
#

function showstack() {
  echo stack:
  n=2
  for i in $(seq $((${#FUNCNAME[@]}-1)) -1 0) ; do
    for d in $(seq 0 $((${n}-1))) ; do
      echo -n " "
    done
    echo ${FUNCNAME[${i}]}
    ((n=n+2))
  done
}

function showcallerinfo() {
  fn=${FUNCNAME[1]}
  IFS=_ read v t e <<< $fn
  e=${fn#${v}_${t}_}
  if [ -z "${t}" ] ; then
    echo $fn : not in verb target extra format
  else
    echo $fn : verb: $v , target: $t , extra: $e
  fi
  showstack
  echo
}

function k_l_m_n() {
  showcallerinfo
}

function h_i_j() {
  k_l_m_n
  k_l_m_n
}

function d_e_f() {
  h_i_j
}

function a_b_c() {
  showcallerinfo
  d_e_f
}

function runner() {
  showcallerinfo
  a_b_c
  k_l_m_n
}

showcallerinfo
runner
